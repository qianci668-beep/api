$ErrorActionPreference = 'Stop'
$backup = 'D:\codex\richang\Agent2APIRepair\agent2api.before-preserve-system-prompt.exe'
$destination = 'C:\Program Files\Agent2API\agent2api.exe'
if (!(Test-Path -LiteralPath $backup)) { throw 'Backup executable missing.' }
$active = @(Get-Process -Name agent2api -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $destination })
foreach ($process in $active) {
    Stop-Process -Id $process.Id
    $process.WaitForExit(10000) | Out-Null
}
if (@(Get-Process -Name agent2api -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $destination }).Count) {
    throw 'Agent2API is still running; no files replaced.'
}
Copy-Item -LiteralPath $backup -Destination $destination -Force
if ((Get-FileHash -LiteralPath $backup).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
    throw 'Executable verification failed.'
}
Start-Process -FilePath $destination -Verb RunAs
Write-Output 'Restored the previous Agent2API executable; configuration was not changed.'
