param([int]$Port = 8080, [switch]$NoBrowser)
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch { Write-Host "Port $Port is busy. Close the other window and try again."; exit 1 }
Write-Host ""
Write-Host "  Site is running:  http://localhost:$Port/"
Write-Host "  Close this window to stop the server."
Write-Host ""
if (-not $NoBrowser) { Start-Process "http://localhost:$Port/" }
$mime = @{ '.html'='text/html; charset=utf-8'; '.js'='application/javascript'; '.css'='text/css';
           '.webp'='image/webp'; '.png'='image/png'; '.jpg'='image/jpeg'; '.json'='application/json'; '.svg'='image/svg+xml'; '.mp3'='audio/mpeg'; '.m4a'='audio/mp4' }
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $res = $ctx.Response
  try {
    $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    if ($rel -eq '') { $rel = 'index.html' }
    $file = [IO.Path]::GetFullPath((Join-Path $root $rel))
    if ($file.StartsWith($root) -and (Test-Path -LiteralPath $file -PathType Leaf)) {
      $bytes = [IO.File]::ReadAllBytes($file)
      $ext = [IO.Path]::GetExtension($file).ToLower()
      if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] } else { $res.ContentType = 'application/octet-stream' }
      $res.Headers.Add('Cache-Control','no-cache')
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $res.StatusCode = 404 }
  } catch { } finally { try { $res.Close() } catch { } }
}
