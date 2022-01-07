' ' //////////////////////////////////////////////////////////////
' ' PUBLIC APIs
' ' //////////////////////////////////////////////////////////////
'  1. startTaplytics
'  2. getRunningExperimentsAndVariations
'  3. getVariationForExperiment
'  4. getValueForVariable
'  5. logEvent
'  6. setUserAttributes
'  7. resetAppUser
'  8. startNewSession

function init()
  m._clientConfig = invalid
  m._clientConfigReady = false
  m.TaplyticsPrivateAPI = m.top.findNode("TaplyticsPrivateAPI")
  m.TaplyticsPrivateAPI.ObserveField("clientConfig", "_onClientConfig")
  m.global.addFields({taplyticsInfo: {}, taplyticsReady: false})
end function

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
function getRunningExperimentsAndVariations() as object
  return getExperimentsAndVariationsWithStatus("all")
end function

function getActiveExperimentsAndVariations() as object
  return getExperimentsAndVariationsWithStatus("active")
end function

function getExperimentsAndVariationsWithStatus(status) as object
  response = {}
  if m._clientConfigReady
    experiments = m._clientConfig["experiments"]
    if experiments <> invalid
      response.experiments = {}
      for each experiment in experiments
        if status = "all" or experiment.status = status then
          variations = experiment.variations
          arrayOfVar = []
          for each variation in variations
            arrayOfVar.push(variation.name)
          end for
          response.experiments.AddReplace(experiment.name, arrayOfVar)
        end if
      end for
    end if
  else
    response.FAILURE = true
  end if
  return response
end function

function getDetailedExperiments() as object
  if m._clientConfigReady
    experiments = m._clientConfig["experiments"]
    return experiments
  end if

  return invalid
end function

function isUserExperiment(name as string) as boolean
  if m._clientConfigReady
    expN = m._clientConfig["expN"]
    if expN <> invalid
      for each experiment in expN
        if experiment.e = name then return true
      end for
    end if
  end if

  return false
end function

'*******************************************************************************
function getValueForVariable(params as object) as dynamic

  if m.top.enablePrint then print "[taplytics] ENTER getValueForVariable>>>"
  if m.top.enablePrint then print "[taplytics] Variable name --> ", params.name
  if m.top.enablePrint then print "[taplytics] Default value --> ", params.default

  value = params.default

  if m._clientConfigReady
    variable = m._clientConfig["dynamicVars." + params.name]
    if variable <> invalid
      if variable.isActive = true and variable.value <> invalid
        if m.top.enablePrint then print "[taplytics] found active test variable --> ", variable.value
        value = variable.value
      end if
    else
      feature = m._clientConfig["ff." + params.name]
      if feature <> invalid
        if feature.status = "active" and feature.enabled <> invalid
          if m.top.enablePrint then print "[taplytics] found active feature variable --> ", feature.enabled
          value = feature.enabled
        end if
      end if
    end if
  end if

  if m.top.enablePrint then print "[taplytics] Variable value: ", value

  return value
end function

'*******************************************************************************
function hasActiveExperiment() as boolean
  if m._clientConfigReady
    'This has to be based on a filtered expN set, removing feature flags.  Use global info array.
    expN = m.global.taplyticsInfo.experiments
    if expN <> invalid and expN.count() > 0
      return true
    end if
  end if

  return false
end function

'*******************************************************************************
function getVariationForExperiment(experimentName as string) as object
  if m.top.enablePrint then print "[taplytics] ENTER getVariationForExperiment>>>"
  if m.top.enablePrint then print "[taplytics] Experiment name --> ", experimentName
  response = invalid

  if m._clientConfigReady
    expN = m._clientConfig["expN"]
    if expN <> invalid
      for each experiment in expN
        if experiment.e = experimentName
          response = experiment.v
          exit for
        end if
      end for
    end if
  end if

  if m.top.enablePrint then print "[taplytics] variant: ", response

  return response
end function

'*******************************************************************************
function getFeatures(status = "all") as object
  if m.top.enablePrint then print "[taplytics] ENTER getFeatures>>>"
  response = []

  if m._clientConfigReady
    features = m._clientConfig["ff"]
    if features <> invalid
      for each featureKey in features
        feature = features[featureKey]
        if status = "all" or status = feature.status
          temp = {
            variable: featureKey
          }
          temp.append(feature)
          if m.top.enablePrint then print "[taplytics] feature variable: ", temp.name
          response.push(temp)
        end if
      end for
    end if
  end if

  return response
end function

'*******************************************************************************
function logEvent(params as object) as object
  if m.top.enablePrint then print "[taplytics] ENTER logEvent>>>"
  if m.top.enablePrint then print "[taplytics] Event name --> ", params.eventName
  if m.top.enablePrint and params.eventValue <> invalid then print "[taplytics] Event value --> ", params.eventValue
  m.TaplyticsPrivateAPI.logEvent = params
end function

'*******************************************************************************
function resetAppUser() as object
  if m.top.enablePrint then print "[taplytics] ENTER resetAppUser>>>"
  m.TaplyticsPrivateAPI.resetAppUser = true
  ' DISABLED: Causes resetAppUser call to fail because it cancels async Request and then startSession call still fails
  'm.TaplyticsPrivateAPI.startTaplytics = {}
end function

'*******************************************************************************
function setUserAttributes(params as object) as object
  if m.top.enablePrint then print "[taplytics] ENTER setUserAttributes>>>"
  m.TaplyticsPrivateAPI.setUserAttributes = params
end function

'*******************************************************************************
function startNewSession() as object
  if m.top.enablePrint then print "[taplytics] ENTER startNewSession>>>"
  m.TaplyticsPrivateAPI.startTaplytics = {}
end function

'*******************************************************************************
function startTaplytics(params as object) as object
  if m.top.enablePrint then print "[taplytics] ENTER startTaplytics>>>"
  m.TaplyticsPrivateAPI.startTaplytics = params
end function

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
function _onClientConfig()
  if m.top.enablePrint then print "[taplytics] ENTER _onClientConfig>>>"
  m._clientConfig = m.TaplyticsPrivateAPI.clientConfig
  m._clientConfigReady = true

  taplyticsInfo = {
    experiments: []
    variables: {}
    features: {}
  }

  featureArray = []

  features = m._clientConfig["ff"]
  if features <> invalid
    for each featureKey in features
      feature = features[featureKey]
      if feature.status = "active"
        featureEntry = { variable: featureKey }
        featureEntry.append(feature)
        taplyticsInfo.features[featureKey] = featureEntry

        'make an array of names so we can filter them from expN
        featureArray.push(featureEntry.name)
      end if
    end for
  end if

  variables = m._clientConfig["dynamicVars"]
  if variables <> invalid
    for each variable in variables
      var = variables[variable]
      if var <> invalid and var.isActive = true
        taplyticsInfo.variables[variable] = var
      end if
    end for
  end if

  expN = m._clientConfig["expN"]
  if expN <> invalid
    for each experiment in expN
      ' Only put experiments into this.  Feature Flags should not be included in the experiments array, so they don't get added to the GA dimensions.
      if not _arrayHasValue(featureArray, experiment.e)
        expEntry = { name: experiment.e, variant: experiment.v }
        taplyticsInfo.experiments.push(expEntry)
      end if
    end for
  end if

  if m.top.enablePrint then print "[taplytics] Setting Taplytics Info global:"

  m.global.taplyticsInfo = taplyticsInfo
  m.global.taplyticsReady = true
  m.top.ready = true
end function

function _arrayHasValue(objects, value) as boolean
  if objects = invalid then return false

  for each obj in objects
    if obj = value then return true
  end for

  return false
end function
