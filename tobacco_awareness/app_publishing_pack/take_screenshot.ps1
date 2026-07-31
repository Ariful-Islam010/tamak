$adbPath = "C:\Users\hp\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    Write-Host "Error: Android SDK adb not found at $adbPath" -ForegroundColor Red
    exit 1
}

$deviceList = & $adbPath devices
Write-Host "Checking connected devices..."
Write-Host $deviceList

$ssFolder = Join-Path -Path $PSScriptRoot -ChildPath "assets/screenshots"
if (-not (Test-Path $ssFolder)) {
    New-Item -ItemType Directory -Force -Path $ssFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$fileName = "screenshot_$timestamp.png"
$devicePath = "/sdcard/$fileName"
$localPath = Join-Path -Path $ssFolder -ChildPath $fileName

Write-Host "Capturing screen on device..." -ForegroundColor Green
& $adbPath shell screencap -p $devicePath

Write-Host "Transferring screenshot to computer..." -ForegroundColor Green
& $adbPath pull $devicePath $localPath | Out-Null

# Clean up on device
& $adbPath shell rm $devicePath

Write-Host "Screenshot saved successfully to:" -ForegroundColor Cyan
Write-Host $localPath -ForegroundColor Yellow
