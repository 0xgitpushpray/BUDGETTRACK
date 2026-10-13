param(
  [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"
$hostAddress = [System.Net.IPAddress]::Loopback
$port = if ($env:PORT) { [int]$env:PORT } else { 3000 }

if ($port -lt 1 -or $port -gt 65535) {
  throw "PORT must be an integer between 1 and 65535."
}

$files = @{
  "/" = @("index.html", "text/html; charset=utf-8")
  "/index.html" = @("index.html", "text/html; charset=utf-8")
  "/app.js" = @("app.js", "text/javascript; charset=utf-8")
  "/styles.css" = @("styles.css", "text/css; charset=utf-8")
}

function Send-Response {
  param(
    [System.IO.Stream]$Stream,
    [int]$StatusCode,
    [string]$StatusText,
    [string]$ContentType,
    [byte[]]$Body,
    [bool]$HeadOnly = $false
  )

  $header = "HTTP/1.1 $StatusCode $StatusText`r`nContent-Type: $ContentType`r`nContent-Length: $($Body.Length)`r`nConnection: close`r`nX-Content-Type-Options: nosniff`r`n`r`n"
  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
  $Stream.Write($headerBytes, 0, $headerBytes.Length)
  if (-not $HeadOnly -and $Body.Length -gt 0) {
    $Stream.Write($Body, 0, $Body.Length)
  }
  $Stream.Flush()
}

$listener = [System.Net.Sockets.TcpListener]::new($hostAddress, $port)
try {
  $listener.Start()
} catch {
  throw "Could not start the local server on 127.0.0.1:$port. $($_.Exception.Message)"
}

$url = "http://127.0.0.1:$port"
Write-Host "Daybook is running at $url. Press Ctrl+C to stop."
if (-not $NoBrowser) {
  try {
    Start-Process $url
  } catch {
    Write-Warning "Could not open a browser automatically. Open $url in your browser."
  }
}

try {
  while ($listener.Server.IsBound) {
    $client = $listener.AcceptTcpClient()
    $stream = $null
    $reader = $null
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
      $requestLine = $reader.ReadLine()
      if (-not $requestLine) {
        continue
      }

      $request = $requestLine -split " ", 3
      while (($line = $reader.ReadLine()) -ne "") {
        if ($null -eq $line) { break }
      }

      if ($request.Length -lt 2) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Bad Request")
        Send-Response $stream 400 "Bad Request" "text/plain; charset=utf-8" $body
        continue
      }

      $method = $request[0]
      if ($method -ne "GET" -and $method -ne "HEAD") {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Method Not Allowed")
        Send-Response $stream 405 "Method Not Allowed" "text/plain; charset=utf-8" $body
        continue
      }

      $target = ($request[1] -split "\?", 2)[0]
      $target = [System.Uri]::UnescapeDataString($target)
      if (-not $files.ContainsKey($target)) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
        Send-Response $stream 404 "Not Found" "text/plain; charset=utf-8" $body ($method -eq "HEAD")
        continue
      }

      $file = $files[$target]
      $filePath = Join-Path $PSScriptRoot $file[0]
      $body = [System.IO.File]::ReadAllBytes($filePath)
      Send-Response $stream 200 "OK" $file[1] $body ($method -eq "HEAD")
    } catch {
      Write-Error "Could not handle a local request: $($_.Exception.Message)" -ErrorAction Continue
      if ($stream) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Internal Server Error")
        try {
          Send-Response $stream 500 "Internal Server Error" "text/plain; charset=utf-8" $body
        } catch {
          Write-Error "Could not send the error response: $($_.Exception.Message)" -ErrorAction Continue
        }
      }
    } finally {
      if ($reader) { $reader.Dispose() }
      if ($client) { $client.Close() }
    }
  }
} finally {
  $listener.Stop()
}
