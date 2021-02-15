#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_AU3Check_Parameters=-d
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

AutoItSetOption("TCPTimeout", 1000)

TCPStartup()

Global $HttpSocket = -1

Func HttpConnect($sIpAddress)
	$HttpSocket = TCPConnect($sIpAddress, 80)

	If ($HttpSocket == -1) Then
		ConsoleWrite("HTTP Connect Error" & @CRLF)
		Exit
	EndIf
EndFunc   ;==>HttpConnect

Func HttpClose()
	TCPCloseSocket($HttpSocket)
	$HttpSocket = -1
EndFunc   ;==>HttpClose

Func HttpGet($sIpAddress, $sUri, ByRef $aHeaders)
	Dim $sRequest

	If StringLeft($sUri, 1) <> "/" Then $sUri = "/" & $sUri
	$sRequest = "GET " & $sUri & " HTTP/1.1" & @CRLF
	$sRequest &= "Host: " & $sIpAddress & @CRLF
	If UBound($aHeaders) > 1 Then
		$sRequest &= $aHeaders[0] & @CRLF
		$sRequest &= $aHeaders[1] & @CRLF
	EndIf
	$sRequest &= "Connection: close" & @CRLF
	$sRequest &= "" & @CRLF
	If $iDebugLevel > 1 Then
		ConsoleWrite("# HTTP Request:" & @CRLF)
		ConsoleWrite($sRequest)
	EndIf

	Local $bytes = TCPSend($HttpSocket, $sRequest)
	If $bytes == 0 Then
		ConsoleWrite("HTTP GET Error" & @CRLF)
		Exit
	EndIf
EndFunc   ;==>HttpGet

Func HttpPost($sIpAddress, $sUri, ByRef $aHeaders, $sXml)
	Dim $sRequest
	Dim $datasize = StringLen($sXml)
	
	If StringLeft($sUri, 1) <> "/" Then $sUri = "/" & $sUri
	$sRequest = "POST " & $sUri & " HTTP/1.1" & @CRLF
	$sRequest &= "Host: " & $sIpAddress & @CRLF
	If UBound($aHeaders) > 1 Then
		$sRequest &= $aHeaders[0] & @CRLF
		$sRequest &= $aHeaders[1] & @CRLF
	EndIf
	$sRequest &= "Connection: close" & @CRLF
	$sRequest &= "Content-Type: application/x-www-form-urlencoded" & @CRLF
	$sRequest &= "Content-Length: " & $datasize & @CRLF
	$sRequest &= "" & @CRLF
	$sRequest &= $sXml & @CRLF
	If $iDebugLevel > 1 Then
		ConsoleWrite("# HTTP Request:" & @CRLF)
		ConsoleWrite($sRequest)
		ConsoleWrite(@CRLF)
	EndIf
	
	Local $bytes = TCPSend($HttpSocket, $sRequest)
	If $bytes == 0 Then
		ConsoleWrite("HTTP POST Error" & @CRLF)
		Exit
	EndIf
EndFunc   ;==>HttpPost

Func HttpRead()
	Local $body = ""
	Local $data = ""

	While 1
		Local $bytes = TCPRecv($HttpSocket, 500)
		If @error Then
			ConsoleWrite("HTTP Error:" & @error)
			Exit
		EndIf
		$data &= $bytes
		If StringLen($bytes) == 0 Then ExitLoop
		Sleep(100)
	WEnd
	If $iDebugLevel > 1 Then
		ConsoleWrite("# HTTP Response:" & @CRLF)
		ConsoleWrite($data & @CRLF)
	EndIf

	$body = StringMid($data, StringInStr($data, @CRLF & @CRLF) + 2)
	;ConsoleWrite(@CRLF & "[" & $body & "]" & @CRLF & @CRLF)

	If StringLen(StringStripWS($body, $STR_STRIPALL)) = 0 Then
		ConsoleWrite("Error: No body found")
		Exit
	EndIf
	
	Return $body
EndFunc   ;==>HttpRead
