#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_AU3Check_Parameters=-d
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

AutoItSetOption("TCPTimeout", 1000)

TCPStartup()

Global $HttpSocket = -1

Func HttpConnect($host)
	Local $ip = $host
	If Not StringIsInt(StringReplace($ip, ".", "")) Then
		TCPNameToIP($host)
	EndIf
	$HttpSocket = TCPConnect($ip, 80)

	If ($HttpSocket == -1) Then
		ConsoleWrite("HTTP Connect Error" & @CRLF)
		Exit
	EndIf
EndFunc   ;==>HttpConnect

Func HttpClose()
	TCPCloseSocket($HttpSocket)
	$HttpSocket = -1
EndFunc   ;==>HttpClose

Func HttpGet($host, $url, ByRef $aHeaders)
	Dim $command

	If StringLeft($url, 1) <> "/" Then $url = "/" & $url
	$command = "GET " & $url & " HTTP/1.1" & @CRLF
	$command &= "Host: " & $host & @CRLF
	If UBound($aHeaders) > 1 Then
		$command &= $aHeaders[0] & @CRLF
		$command &= $aHeaders[1] & @CRLF
	EndIf
	$command &= "Connection: close" & @CRLF
	$command &= "" & @CRLF
	ConsoleWrite($command)

	Local $bytes = TCPSend($HttpSocket, $command)
	If $bytes == 0 Then
		ConsoleWrite("HTTP GET Error" & @CRLF)
		Exit
	EndIf
EndFunc   ;==>HttpGet

Func HttpPost($host, $url, ByRef $aHeaders, $data = "")
	Dim $command
	Dim $datasize = StringLen($data)
	
	If StringLeft($url, 1) <> "/" Then $url = "/" & $url
	$command = "POST " & $url & " HTTP/1.1" & @CRLF
	$command &= "Host: " & $host & @CRLF
	If UBound($aHeaders) > 1 Then
		$command &= $aHeaders[0] & @CRLF
		$command &= $aHeaders[1] & @CRLF
	EndIf
	$command &= "Connection: close" & @CRLF
	$command &= "Content-Type: application/x-www-form-urlencoded" & @CRLF
	$command &= "Content-Length: " & $datasize & @CRLF
	$command &= "" & @CRLF
	$command &= $data & @CRLF
	ConsoleWrite($command)
	
	Local $bytes = TCPSend($HttpSocket, $command)
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
	ConsoleWrite("data: " & @CRLF & $data & @CRLF)

	$body = StringMid($data, StringInStr($data, @CRLF & @CRLF) + 2)
	;ConsoleWrite(@CRLF & "[" & $body & "]" & @CRLF & @CRLF)

	If StringLen(StringStripWS($body, $STR_STRIPALL)) = 0 Then
		ConsoleWrite("Error: No body found")
		Exit
	EndIf
	
	Return $body
EndFunc   ;==>HttpRead
