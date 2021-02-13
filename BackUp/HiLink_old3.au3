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

runCurl("api/monitoring/status")
;runCurl("api/sms/sms-list", "<request><PageIndex>1</PageIndex><ReadCount>10</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>1</Ascending><UnreadPreferred>1</UnreadPreferred></request>")

;getSmsNotifications()
;getStatus()
;getTrafficStats()
;getMonthStats()
;resetTrafficStats()
;getNetwork()
;getDeviceInfo()
;reboot()
;getDialupInfo()
;reconnectHack()

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
	$sCurlSession = getSession()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/sms/sms-count" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & $sCurlSession, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$sOutput = StdoutRead($iPID)
	; ConsoleWrite("SMS Count: " & $sOutput & @CRLF)

	$aSmsCount = _StringBetween($sOutput, "<LocalInbox>", "</LocalInbox>")
	If Not @error Then
		ConsoleWrite("SMS Inbox messages: " & $aSmsCount[0] & @CRLF)
		$iSmsCount = Int($aSmsCount[0])
	EndIf

	Return $iSmsCount
EndFunc   ;==>SmsCount

Func SmsDelete($iMax)
	If $iMax > 50 Then SetError(1)
	If SmsCount() < $iMax Then SetError(1)
	If @error Then Return

	$sCurlSession = getSession()

	$sCurlMessage = '-H "Content-Type: text/xml" '
	; BoxType 1 is inbox, 2 is sentbox
	$sCurlMessage &= '-d "<request><PageIndex>1</PageIndex><ReadCount>' & $iMax & '</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>1</Ascending><UnreadPreferred>1</UnreadPreferred></request>"'

	$sCurlCommand = '-s -X POST "http://192.168.8.1/api/sms/sms-list" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & $sCurlSession & $sCurlMessage, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$sOutput = StdoutRead($iPID)
	; ConsoleWrite($sOutput & @CRLF)
	$aList = StringSplit($sOutput, "</Message>", $STR_ENTIRESPLIT)
	$sIndexes = ""
	For $sMsg In $aList
		$aIndex = _StringBetween($sMsg, "<Index>", "</Index>")
		If Not @error Then
			$sIndexes &= "<Index>" & $aIndex[0] & "</Index>"
		EndIf
	Next
	; ConsoleWrite("SMS Msg indexes to delete: " & $sIndexes & @CRLF)

	$sCurlSession = getSession()
	$sCurlCommand = '-s -X POST "http://192.168.8.1/api/sms/delete-sms" '
	$sCurlMessage = '-d "<request>' & $sIndexes & '</request>"'
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & $sCurlSession & $sCurlMessage, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$sOutput = StdoutRead($iPID)
	; ConsoleWrite($sOutput & @CRLF)
EndFunc   ;==>SmsDelete

Func getDialupInfo()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/dialup/connection" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("DialupInfo:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getDialupInfo

Func reconnectHack()
	$sCurlCommand = '-s -X POST "http://192.168.8.1/api/dialup/connection" '
	$sCurlMessage = '-d "<request><RoamAutoConnectEnable>0</RoamAutoConnectEnable><MaxIdelTime>86400</MaxIdelTime><ConnectMode>0</ConnectMode><MTU>1500</MTU><auto_dial_switch>1</auto_dial_switch><pdp_always_on>0</pdp_always_on></request>"'
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession() & $sCurlMessage, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("DialupInfo:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>reconnectHack

Func reboot()
	$sCurlCommand = '-s -X POST "http://192.168.8.1/api/device/control" '
	$sCurlMessage = '-d "<request><Control>1</Control></request>"'
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession() & $sCurlMessage, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("Reboot:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>reboot

Func getSmsNotifications()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/monitoring/check-notifications" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("SmsNotifications:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getSmsNotifications

; Status 112: "No autoconnect"
; Status 113: "No autoconnect (roaming)"
; Status 114: "No reconnect on timeout"
; Status 115: "No reconnect on timeout (roaming)"
; Status 900: "Connecting"
; Status 901: "Connected"
; Status 902: "Disconnected"
; Status 903: "Disconnecting"
; Other     : "Unknown status"
Func getStatus()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/monitoring/status" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("Status:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getStatus

Func getTrafficStats()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/monitoring/traffic-statistics" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("TrafficStats:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getTrafficStats

Func getMonthStats()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/monitoring/month_statistics" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("MonthStats:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getMonthStats

Func resetTrafficStats()
	$sCurlCommand = '-s -X POST "http://192.168.8.1/api/monitoring/clear-traffic" '
	$sCurlMessage = '-d "<request><ClearTraffic>1</ClearTraffic></request>"'
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession() & $sCurlMessage, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("Reset Traffic Stats:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>resetTrafficStats

Func getNetwork()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/net/current-plmn" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("Network:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getNetwork

Func getDeviceInfo()
	$sCurlCommand = '-s -X GET "http://192.168.8.1/api/device/information" '
	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand & getSession(), $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	ConsoleWrite("DeviceInfo:" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>getDeviceInfo

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
	ConsoleWrite("CurlCommand:" & @CRLF & $sCurlCommand & @CRLF & @CRLF)

	$iPID = Run(@ComSpec & ' /C curl.exe ' & $sCurlCommand, $sCurlPath, 0, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	$sP1 = _StringTitleCase(StringMid($sApi, StringInStr($sApi, "/", 1, -1) + 1))
	$sP2 = _StringTitleCase(StringMid($sApi, StringInStr($sApi, "/", 0, -1) + 1))
	ConsoleWrite( & ":" & @CRLF & StdoutRead($iPID) & @CRLF & @CRLF)
EndFunc   ;==>runCurl
