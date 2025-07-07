# Right Click the file and choose [Run with PowerShell] to stop a server that was started in the background by the Task Scheduler
#CHANGE THE VARIABLE BELOW TO YOUR SERVER EXECUTABLE NAME IF DIFFERENT FROM DEFAULT, AND SAVE THE SCRIPT
$bedServerExe = "bedrock_server_competitive.exe"

# Check for the process and stop it if it exists
$processName = $bedServerExe -replace '.exe',''

Write-Host "Checking for server process: $processName"
Start-Sleep -Seconds 2

$process = Get-Process -Name $processName -ErrorAction SilentlyContinue

if ($process) {
    Write-Host "Process found. STOPPING SERVICE..."
    Stop-Process -Name $processName
    Write-Host "Process stopped"
    Start-Sleep -Seconds 10
} else {
    Write-Host "Process was not found. Nothing to stop."
    Start-Sleep -Seconds 10
}
