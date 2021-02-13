#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=HiLink.exe
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <String.au3>

Opt("TrayMenuMode", 1) ; Default tray menu items (Script Paused/Exit) will not be shown.

Global $sCurlPath = "C:\BdR\Domotica\curl_wget"
;Global $sCurlPath = "C:\Apps\Curl"
Global $sHost = "http://192.168.8.1"

runCurl("api/device/information")
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
;runCurl("api/monitoring/status")
; SMS Notifications
;runCurl("api/monitoring/check-notifications")
;runCurl("api/sms/sms-count")
;runCurl("api/sms/sms-list", "<request><PageIndex>1</PageIndex><ReadCount>10</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>1</Ascending><UnreadPreferred>1</UnreadPreferred></request>")
;runCurl("api/monitoring/traffic-statistics")
;runCurl("api/monitoring/month_statistics")

; Reset TrafficStats / Clear History
;runCurl("api/monitoring/clear-traffic", "<request><ClearTraffic>1</ClearTraffic></request>")

;runCurl("api/net/current-plmn")

; Reboot Device
;runCurl("api/device/control", "<request><Control>1</Control></request>")

; Dialup Info
;runCurl("api/dialup/connection")

; Reconnect Hack (https://blog.idorobots.org/entries/hacking-huawei-e3372-hilink..html)
;runCurl("api/dialup/connection", "<request><RoamAutoConnectEnable>0</RoamAutoConnectEnable><MaxIdelTime>86400</MaxIdelTime><ConnectMode>0</ConnectMode><MTU>1500</MTU><auto_dial_switch>1</auto_dial_switch><pdp_always_on>0</pdp_always_on></request>")

;$iMsgCount = SmsCount()
$iMsgCount = 0
If $iMsgCount > 0 Then
	SmsDelete(1)
	If @error Then
		ConsoleWrite("Error" & @CRLF)
	Else
		$iMsgCount = SmsCount()
	EndIf
EndIf

Func SmsCount()
	$iSmsCount = 0
	$sXml = runCurl("api/sms/sms-count")

	$aSmsCount = _StringBetween($sXml, "<LocalInbox>", "</LocalInbox>")
	If Not @error Then
		ConsoleWrite("SMS Inbox messages: " & $aSmsCount[0] & @CRLF & @CRLF)
		$iSmsCount = Int($aSmsCount[0])
	EndIf

	Return $iSmsCount
EndFunc   ;==>SmsCount

Func SmsDelete($iMax)
	If $iMax > 50 Then SetError(1)
	If SmsCount() < $iMax Then SetError(1)
	If @error Then Return

	; BoxType 1 is inbox, 2 is sentbox
	$sSmsList = runCurl("api/sms/sms-list", "<request><PageIndex>1</PageIndex><ReadCount>" & $iMax & "</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>1</Ascending><UnreadPreferred>1</UnreadPreferred></request>")
	$aList = StringSplit($sSmsList, "</Message>", $STR_ENTIRESPLIT)
	$sIndexes = ""
	For $sMsg In $aList
		$aIndex = _StringBetween($sMsg, "<Index>", "</Index>")
		If Not @error Then
			$sIndexes &= "<Index>" & $aIndex[0] & "</Index>"
		EndIf
	Next
	ConsoleWrite("SMS Msg indexes to delete: " & $sIndexes & @CRLF)

	;	runCurl("api/sms/delete-sms", "<request>" & $sIndexes & "</request>")
EndFunc   ;==>SmsDelete

Func getSession()
	$sCurlParameters = '-s "http://192.168.8.1/api/webserver/SesTokInfo"'
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlParameters, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$sOutput = StdoutRead($iPID)
	; ConsoleWrite("Session: " & $sOutput & @CRLF)

	$aCookie = _StringBetween($sOutput, "<SesInfo>", "</SesInfo>")
	$aToken = _StringBetween($sOutput, "<TokInfo>", "</TokInfo>")

	$sCurlSession = '-H "Cookie: ' & $aCookie[0] & '" '
	$sCurlSession &= '-H "__RequestVerificationToken: ' & $aToken[0] & '" '
	; ConsoleWrite("Session: " & $sCurlSession & @CRLF)
	Return $sCurlSession
EndFunc   ;==>getSession

Func runCurl($sApi, $sXml = "")
	$sUrl = $sHost
	$sUrl &= "/" & $sApi

	$sCurlCommand = "-s " ; Silent
	$sCurlCommand &= "-X " ; HTTP GET/POST
	If StringLen($sXml) = 0 Then
		$sCurlCommand &= "GET "
	Else
		$sCurlCommand &= "POST "
	EndIf
	$sCurlCommand &= '"' & $sUrl & '" '
	$sCurlCommand &= getSession()
	If StringLen($sXml) > 0 Then
		$sCurlCommand &= "-d " ; Data
		$sCurlCommand &= '"' & $sXml & '"'
	EndIf
	; ConsoleWrite("CurlCommand:" & @CRLF & $sCurlCommand & @CRLF & @CRLF)

	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$response = StdoutRead($iPID)
	$sTitle = _StringTitleCase(StringReplace(StringMid($sApi, StringInStr($sApi, "/") + 1), "/", " "))
	ConsoleWrite($sTitle & ":" & @CRLF & $response & @CRLF & @CRLF)
;	ParseXml($response)
	Return $response
EndFunc   ;==>runCurl

Func ParseXml($sXml)
	$aTags = StringSplit($sXml, "</", $STR_ENTIRESPLIT)
	For $sTag In $aTags
		$sTag = StringMid($sTag, StringInStr($sTag, "<", 0, -1) + 1)
		If StringLen($sTag) > 0 Then
			$sTag = StringReplace($sTag, ">", ": ")
			ConsoleWrite($sTag & @CRLF)
		EndIf
	Next
EndFunc   ;==>ParseXml
