'//////////////////////////////////////////////////////////////////////////////
sub init()
	m.log = ""
	m.TaplyticsAPI = m.top.FindNode("TaplyticsAPI")
	m.TaplyticsAPI.observeField("ready", "onTaplyticsReady")
	m.TaplyticsAPI.callFunc("startTaplytics", {})
	variableValue = m.TaplyticsAPI.callFunc("getValueForVariable", {name: "Foo", default: "xxx"})
	print "variableValue(oninit) : ", variableValue 'SHOULD PRINT NOTREADY TEXT'
end sub

sub onTaplyticsReady()
	if m.TaplyticsAPI.ready = true then
		test()
		log = m.top.findNode("log")
		log.text = m.log
	end if
end sub

sub test()

	printLog("*****************************************************************")
	printLog("****************** getValueForVariable **************************")
	variableValue = m.TaplyticsAPI.callFunc("getValueForVariable", {name: "Foo", default: "xxx"})
	printLog("Foo variableValue : ", variableValue)
	print "*****************************************************************"

	print "*****************************************************************"
	printLog("****************** getRunningExperimentsAndVariations ***********")
	ExpAndVar = m.TaplyticsAPI.callFunc("getRunningExperimentsAndVariations")
	if ExpAndVar.FAILURE = invalid
		for each experiment in ExpAndVar.experiments
			printLog("experiment :", experiment)
			printLog("variations :", ExpAndVar.experiments[experiment])
		end for
	end if
	print "*****************************************************************"

	print "*****************************************************************"
	printLog("****************** getVariationForExperiment ********************")
	getVariationForExperiment = m.TaplyticsAPI.callFunc("getVariationForExperiment", "Example")
	printLog("getVariationForExperiment : ",getVariationForExperiment)
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** logEvent *************************************"
	m.TaplyticsAPI.callFunc("logEvent", {eventName: "goalTest"})
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** setUserAttributes ****************************"
	m.TaplyticsAPI.callFunc("setUserAttributes", {firstName: "XavierTestToto1"})
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** resetAppUser *********************************"
	m.TaplyticsAPI.callFunc("resetAppUser")
	print "*****************************************************************"

end sub

sub printLog(message as String, obj = invalid as Object) 
	objStr = ""
	if obj <> invalid then objStr = FormatJSON(obj)

	m.log = m.log + message + objStr + chr(10)
	print message
end sub 
