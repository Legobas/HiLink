#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=HiLink.exe
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=HiLink
#AutoIt3Wrapper_Res_Description=Huawei E3372h-153 HiLink Client
#AutoIt3Wrapper_Res_Fileversion=1.0.0.27
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_AU3Check_Parameters=-d
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <String.au3>
#include "HTTP.au3"

Opt("TrayMenuMode", 1)

Global $sProgramName = StringReplace(@ScriptName, ".exe", "")
Global $sCurlPath = ""
Global $sHost = "192.168.8.1"
Global $bDebug = False
Local $sCommand = ""
Local $sApi = ""
Local $sXml = ""
Local $iMsgCount = 0

;Local $CmdLine[2] = [1, 'info']

If $CmdLine[0] < 1 Then
	usage()
	Exit (1)
Else
	For $n = 1 To $CmdLine[0]
		; ConsoleWrite($CmdLine[$n] & @CRLF)
		Switch StringLeft($CmdLine[$n], 2)
			Case "-c"
				$sCommand = $CmdLine[$n + 1]
			Case "-h"
				$sHost = $CmdLine[$n + 1]
			Case "-d"
				$bDebug = True
			Case Else
				If $CmdLine[0] = 1 Then $sCommand = $CmdLine[$n]
		EndSwitch
	Next
EndIf
If @error Then
	usage()
	Exit (1)
EndIf

;Check curl on path
;https://curl.se/download.html

Switch $sCommand
	Case 'info'
		$sApi = "api/device/information"
	Case 'status'
		$sApi = "api/monitoring/status"
	Case 'net'
		$sApi = "api/net/current-plmn"
	Case 'sms'
		$sApi = "api/monitoring/check-notifications"
		ConsoleWrite("# SMS Notifications" & @CRLF)
	Case 'smscount'
		$sApi = "api/sms/sms-count"
	Case 'smslist'
		$sApi = "api/sms/sms-list"
		$sXml = "<request><PageIndex>1</PageIndex><ReadCount>10</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>1</Ascending><UnreadPreferred>1</UnreadPreferred></request>"
	Case 'stats'
		$sApi = "api/monitoring/traffic-statistics"
	Case 'monthstats'
		$sApi = "api/monitoring/month_statistics"
	Case 'resetstats'
		$sApi = "api/monitoring/clear-traffic"
		$sXml = "<request><ClearTraffic>1</ClearTraffic></request>"
		ConsoleWrite("# Reset TrafficStats / Clear History" & @CRLF)
	Case 'reboot'
		$sApi = "api/device/control"
		$sXml = "<request><Control>1</Control></request>"
		ConsoleWrite("# Reboot Device" & @CRLF)
	Case 'con'
		$sApi = "api/dialup/connection"
		ConsoleWrite("# Dialup Info" & @CRLF)
	Case 'hack'
		$sApi = "api/dialup/connection"
		$sXml = "<request><RoamAutoConnectEnable>0</RoamAutoConnectEnable><MaxIdelTime>86400</MaxIdelTime><ConnectMode>0</ConnectMode><MTU>1500</MTU><auto_dial_switch>1</auto_dial_switch><pdp_always_on>0</pdp_always_on></request>"
		ConsoleWrite("# Reconnect Hack (https://blog.idorobots.org/entries/hacking-huawei-e3372-hilink..html)" & @CRLF)
	Case 'emptyinbox'
		$iMsgCount = SmsCount()
		If $iMsgCount > 50 Then $iMsgCount = 50
		ConsoleWrite("# Delete " & $iMsgCount & " SMS messages from inbox" & @CRLF)
		SmsDelete($iMsgCount)
		If @error Then
			ConsoleWrite("Error" & @CRLF)
		EndIf
		Exit
EndSwitch

If StringLen($sApi) == 0 Then
	ConsoleWrite("Incorrect Parameter(s)" & @CRLF & @CRLF)
	usage()
	Exit (1)
EndIf

If $bDebug Then
	ConsoleWrite("Host: " & $sHost & @CRLF)
	ConsoleWrite("API: " & $sApi & @CRLF)
	If StringLen($sCurlPath) > 0 Then
		ConsoleWrite("Path to cUrl.exe: " & $sCurlPath & @CRLF)
	EndIf
	ConsoleWrite(@CRLF)
EndIf

runCurl($sApi, $sXml)
Exit

; Status:
; Status 112: "No autoconnect"
; Status 113: "No autoconnect (roaming)"
; Status 114: "No reconnect on timeout"
; Status 115: "No reconnect on timeout (roaming)"
; Status 900: "Connecting"
; Status 901: "Connected"
; Status 902: "Disconnected"
; Status 903: "Disconnecting"
; Other     : "Unknown status"

Func SmsCount()
	Local $iSmsCount = 0
	Local $sSmsXml = runCurl("api/sms/sms-count")
	Local $aSmsCount = _StringBetween($sSmsXml, "<LocalInbox>", "</LocalInbox>")
	If Not @error Then
		If $bDebug Then
			ConsoleWrite("SMS Inbox messages: " & $aSmsCount[0] & @CRLF)
		EndIf
		$iSmsCount = Int($aSmsCount[0])
	EndIf

	Return $iSmsCount
EndFunc   ;==>SmsCount

Func SmsDelete($iMax)
	If $iMax > 50 Then SetError(1)
	If SmsCount() < $iMax Then SetError(1)
	If @error Then Return

	; BoxType 1 is inbox, 2 is sentbox
	Local $sSmsList = runCurl("api/sms/sms-list", "<request><PageIndex>1</PageIndex><ReadCount>" & $iMax & "</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>1</Ascending><UnreadPreferred>1</UnreadPreferred></request>")
	Local $aList = StringSplit($sSmsList, "</Message>", $STR_ENTIRESPLIT)
	Local $sIndexes = ""
	For $sMsg In $aList
		Local $aIndex = _StringBetween($sMsg, "<Index>", "</Index>")
		If Not @error Then
			$sIndexes &= "<Index>" & $aIndex[0] & "</Index>"
		EndIf
	Next
	If $bDebug Then
		ConsoleWrite("SMS Msg indexes to delete: " & $sIndexes & @CRLF)
	EndIf

	runCurl("api/sms/delete-sms", "<request>" & $sIndexes & "</request>")
EndFunc   ;==>SmsDelete

Func getSessionHeaders()
	Local $url = "/api/webserver/SesTokInfo"
	HttpConnect($sHost)
	Dim $aHeaders[1] = [""]
	HttpGet($sHost, $url, $aHeaders)
	Local $sResponse = HttpRead()
	HttpClose()

	;ConsoleWrite("Session: " & $sResponse & @CRLF)
	Local $aCookie = _StringBetween($sResponse, "<SesInfo>", "</SesInfo>")
	Local $aToken = _StringBetween($sResponse, "<TokInfo>", "</TokInfo>")

	Dim $aSession[2]
	$aSession[0] = "Cookie: " & $aCookie[0]
	$aSession[1] = "__RequestVerificationToken: " & $aToken[0]
	Return $aSession
EndFunc   ;==>getSessionHeaders

Func runCurl($sApi, $sRequestXml = "")
	Local $aHeaders = getSessionHeaders()
	HttpConnect($sHost)
	If StringLen($sRequestXml) = 0 Then
		HttpGet($sHost, $sApi, $aHeaders)
	Else
		If $bDebug Then
			ConsoleWrite("# Request:" & @CRLF)
			ConsoleWrite($sRequestXml & @CRLF & @CRLF)
		EndIf
		HttpPost($sHost, $sApi, $aHeaders, $sRequestXml)
	EndIf
	Local $sResponse = HttpRead()
	HttpClose()

	Local $sTitle = _StringTitleCase(StringReplace(StringMid($sApi, StringInStr($sApi, "/") + 1), "/", " "))
	If $bDebug Then
		ConsoleWrite("# Response:" & @CRLF)
		ConsoleWrite($sResponse & @CRLF & @CRLF)
	EndIf
	ConsoleWrite("# " & $sTitle & ":" & @CRLF)
	ParseXml($sResponse)
	Return $sResponse
EndFunc   ;==>runCurl

Func ParseXml($sXml)
	Local $aTags = StringSplit($sXml, "<")
	Local $sItem = ""
	For $sTag In $aTags
		$sTag = StringStripWS($sTag, $STR_STRIPLEADING)
		$sTag = StringStripWS($sTag, $STR_STRIPTRAILING)
		; ConsoleWrite("[" & $sTag & "]" & @CRLF)
		If StringLeft($sTag, 1) == "/" Then
			If StringInStr($sItem, StringMid($sTag, 2)) > 0 Then
				$sItem = StringReplace($sItem, ">", ": ")
				ConsoleWrite($sItem & @CRLF)
			EndIf
			$sItem = ""
		Else
			$sItem = $sTag
		EndIf
	Next
	ConsoleWrite(@CRLF)
EndFunc   ;==>ParseXml

Func usage()
	Local $build = " x32"
	If @AutoItX64 Then
		$build = " x64"
	EndIf
	Local $sVersion = StringLeft(FileGetVersion(@ScriptDir & "\" & @ScriptName, "FileVersion"), 5)
	ConsoleWrite($sProgramName & $build & " " & $sVersion & @CRLF)
	ConsoleWrite("Usage: " & @CRLF)
	ConsoleWrite("command (without other parameters)" & @CRLF)
	ConsoleWrite("-c command (-c info)" & @CRLF)
	ConsoleWrite("   commands: info, status, net, sms, smscount, smslist, stats, monthstats, resetstats, reboot, con, hack, emptyinbox" & @CRLF)
	ConsoleWrite("-h host (default " & $sHost & ")" & @CRLF)
	ConsoleWrite("-d debug (show XML messages)" & @CRLF)
	ConsoleWrite("-a api path (-a api/**/**)" & @CRLF)
	ConsoleWrite("-x request XML (-x ""<request>***</request>"")" & @CRLF)
	ConsoleWrite(@CRLF)
	ConsoleWrite("Examples:" & @CRLF)
	ConsoleWrite($sProgramName & " info" & @CRLF)
	ConsoleWrite($sProgramName & " -c info" & @CRLF)
	ConsoleWrite($sProgramName & " -a api/device/information" & @CRLF)
	ConsoleWrite($sProgramName & ' -a api/monitoring/clear-traffic -x "<request><ClearTraffic>1</ClearTraffic></request>"' & @CRLF)
	ConsoleWrite(@CRLF)
EndFunc   ;==>usage
