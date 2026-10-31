$ErrorActionPreference = 'Stop'
$source = 'D:\codex\richang\Agent2APIRepair\source\target\release\workbuddy-proxy-desktop.exe'
$destination = 'C:\Program Files\Agent2API\agent2api.exe'
$backup = 'D:\codex\richang\Agent2APIRepair\agent2api.before-preserve-system-prompt.exe'
if (!(Test-Path -LiteralPath $source)) { throw 'Compiled executable missing.' }
if (!(Test-Path -LiteralPath $destination)) { throw 'Installed executable missing.' }
$active = @(Get-Process -Name agent2api -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $destination })
foreach ($process in $active) {
    Stop-Process -Id $process.Id
    $process.WaitForExit(10000) | Out-Null
}
$remaining = @(Get-Process -Name agent2api -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $destination })
if ($remaining.Count) { throw 'Agent2API is still running; no files replaced.' }
if (!(Test-Path -LiteralPath $backup)) {
    Copy-Item -LiteralPath $destination -Destination $backup
}
Copy-Item -LiteralPath $source -Destination $destination -Force
if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
    throw 'Executable verification failed.'
}
Start-Process -FilePath $destination -Verb RunAs
Write-Output "Installed repaired executable; backup: $backup"
