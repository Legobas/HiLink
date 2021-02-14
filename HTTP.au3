#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_AU3Check_Parameters=-d
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

TCPStartup()

Global $HttpSocket = -1
Global $HttpRecvTimeout = 5000

Func HttpConnect($host)
	Dim $ip = $host
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
	Local $sHttpMessageSize = 5000
	Dim $headers[1][2] ; An Array of the headers found
	Dim $numheaders = 0 ; The number of headers found
	Dim $body = "" ; The body of the message
	Dim $HTTPVersion ; The HTTP version of the server (almost always 1.1)
	Dim $HTTPResponseCode ; The HTTP response code like 200, or 404
	Dim $HTTPResponseReason ; The human-readable response reason, like "OK" or "Not Found"
	Dim $bytesreceived = 0 ; The total number of bytes received
	Dim $data = "" ; The entire raw message gets put in here.
	Dim $chunked = 0 ; Set to 1 if we get the "Transfer-Encoding: chunked" header.
	Dim $chunksize = 0 ; The size of the current chunk we are processing.
	Dim $chunkprocessed = 0 ; The amount of data we have processed on the current chunk.
	Dim $contentlength ; The size of the body, if NOT using chunked transfer mode.

	While 1
		Local $bytes = TCPRecv($HttpSocket, $sHttpMessageSize)
		$data &= $bytes
		If StringLen($bytes) == 0 Or StringLen($bytes < $sHttpMessageSize) Then ExitLoop
		Sleep(100)
	WEnd
	;ConsoleWrite($data & @CRLF)

	$body = StringMid($data, StringInStr($data, @CRLF & @CRLF) + 2)
	;ConsoleWrite(@CRLF & "[" & $body & "]" & @CRLF & @CRLF)
	
	Return $body
EndFunc   ;==>HttpRead
