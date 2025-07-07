Write-Host "MINECRAFT BEDROCK SERVER UPDATE SCRIPT (7/7/2025)"
Write-Host "`n" "`n" "`n" 
# MICROSOFT POWERSHELL SCRIPT
# INSTRUCTIONS:
# (1)  PASTE THIS SCRIPT IN NOTEPAD AND SAVE IT IN YOUR SERVER DIRECTORY WITH .PS1 FILE EXTENSION (ex C:\Users\YourUserNameHere\Minecraft Server\Bedrock Server\UpdateBackupScript.ps1)
# (2) CHANGE THE VARIABLES BELOW TO YOUR SERVER DIRECTORY AND EXECUTABLE NAME, AND SAVE THE SCRIPT
$gameDir = "C:\Users\YourUserNameHere\Minecraft Server\Bedrock Server"
$bedServerExe = "bedrock_server.exe"
# (3) RIGHT CLICK THE .PS1 FILE AND CHOOSE "RUN WITH POWERSHELL" TO TEST IT, MAKE SURE IT WORKS
# (4) CREATE POWERSHELL TASK IN WINDOWS TASK SCHEDULER TO RUN PERIODICALLY (WHEN NOBODY IS LIKELY TO BE CONNECTED TO SERVER AS IT IS LIKELY TO BE STOPPED)
 
# CREDITS: u/WhetselS u/Nejireta_ u/rockknocker u/VirtuallyG
# Buy Me A Coffee https://bmc.link/virtuallyg

# LINKS: 	https://www.reddit.com/r/PowerShell/comments/xy9xqh/script_for_updating_minecraft_bedrock_server_on/
#			https://www.dvgaming.de/minecraft-pe-bedrock-windows-automatic-update-script/
#           https://www.reddit.com/r/Minecraft/comments/yw2gd1/minecraft_bedrock_server_autoupdate_script_for/

 
# OPTIONAL BACKUP SETTINGS AND INSTRUCTIONS BELOW:
# The $source variable below is the location of the Worlds folder. By default it looks in the $gameDir/Worlds.
# you can change $source to a specific directory by changing the variable to any path (ex. $source = "C:\MyServerFolder\MyWorldsFolder")
# The $destination variable below is the location that the script will backup the Worlds folder. By Default it set to the $gameDir/ScriptBackups
# you can change the backup folder name by changing the word "ScriptBackups" below or you can specify a specific directory on
# any drive by changing the variable to any path (ex. $destination = "C:\MyServerBackup\WorldsFolderBackup")
# The $numBackup variable below is how many backups the script will keep. This can be any number but be aware of your space requirements.
# This script does not check for available space so be sure to keep this number within your hard drive's capacity.


# FUNCTION TO BACKUP UP WORLDS FOLDER KEEPING LATEST BACKUPS SPECIFIED
$logFilePath = Join-Path -Path $gameDir -ChildPath ScriptLogs\Log.txt
Start-Transcript -Path $logFilePath -Force
function Backup-Worlds {
	# Variables able to be configured:

    # WORLDS FOLDER TO BE BACKED UP
    $source = Join-Path -Path $gameDir -ChildPath worlds
	# DESTINATION OF BACKUP (You can change this to a specific directory if want to save outside of
    # the bedrock server folder, (ex. $destination = "D:\Games\Mincraft\ServerGameDataBackup")
    $destination = Join-Path -Path $gameDir -ChildPath ScriptBackups
    # NUMBER OF BACKUPS TO KEEP
    $numBackup = 10

    #CHANGEING VARIABLES BELOW MAY CAUSE UNEXPECTED RESULTS

    # Get the last modified date of the most recently modified file within all the subfolders inside the "worlds" folder
    $latestModification = Get-ChildItem -Path $source -Recurse -File | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

    # Check if there is any existing backup
    $existingBackups = Get-ChildItem -Path $destination -Directory | Sort-Object -Property CreationTime -Descending
    if ($existingBackups) {
        # Get the last backup date
        $lastBackupDate = $existingBackups[0].CreationTime

        # Calculate the time difference between the last backup and the latest modification
        $timeDifference = New-TimeSpan -Start $lastBackupDate -End $latestModification.LastWriteTime

        # Skip backup if the difference is less than or equal to 5 minutes to allow time to start server. Starting the server modifies the worlds
        if ($timeDifference.TotalMinutes -le 5) {
            Write-Host "NO MODIFICATIONS FOUND AFTER THE LAST BACKUP. SKIPPING BACKUP"
            return
        }
    }

	#DATE VARIABLE FOR BACKUP FOLDER NAME
    $date = Get-Date -Format "yyyy-MM-dd_HHmmss"

	# STOP SERVER
	if(get-process -name ($bedServerExe -replace '.exe','') -ErrorAction SilentlyContinue)
	{
		Write-Host "STOPPING SERVICE..."
		Stop-Process -name ($bedServerExe -replace '.exe','')
	}

    # Create the backup folder if it doesn't exist
    if (!(Test-Path -Path $destination)) {
        New-Item -ItemType Directory -Path $destination
    }

    # Backup worlds folder to the dated subfolder
    $backupPath = Join-Path -Path $destination -ChildPath $date
    New-Item -ItemType Directory -Path $backupPath
    Copy-Item -Path $source -Destination $backupPath -Recurse
	Write-Host "WORLDS FOLDER BACKUP COMPLETE"
	Start-Sleep -Seconds 3

    # Remove older backups based on variable in $numBackup
	Write-Host "REMOVING OLDER BACKUPS" 
    Get-ChildItem -Path $destination -Directory |
        Sort-Object -Property CreationTime -Descending |
        Select-Object -Skip $numBackup |
        Remove-Item -Recurse -Force
	Start-Sleep -Seconds 2
}

Set-Location $gameDir 
 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
# =====================================================================================================
# Update method changed 7-7-2025 to use a community database instead of scraping the Microsoft website.
# Added a fallback for increased reliability.
# Thanks to J44kkim4 for suggesting an alternative method
# =====================================================================================================

$url = $null
# --- PRIMARY METHOD ---
Write-Host "Fetching latest version information from primary source (Bedrock-OSS)..."
try {
    $versionsUrl = "https://raw.githubusercontent.com/Bedrock-OSS/BDS-Versions/main/versions.json"
    $versionData = Invoke-RestMethod -Uri $versionsUrl
    $latestVersionString = $versionData.windows.stable
    if ($latestVersionString) {
		# Construct the URL using the known, correct pattern and the latest version string
        $url = "https://www.minecraft.net/bedrockdedicatedserver/bin-win/bedrock-server-$($latestVersionString).zip"
        Write-Host "✅ Primary source successful."
    }
}
catch {
    Write-Host "⚠️ Primary source failed. Trying fallback method..."
    # --- FALLBACK METHOD --- Thanks to J44kkim4
    try {
        $jsonUrl = "https://raw.githubusercontent.com/kittizz/bedrock-server-downloads/main/bedrock-server-downloads.json"
        $jsonData = Invoke-RestMethod -Uri $jsonUrl
        $latestVersion = $jsonData.release.PSObject.Properties.Name | Sort-Object {[version]$_} -Descending | Select-Object -First 1
        $url = $jsonData.release.$latestVersion.windows.url
        if ($url) {
            Write-Host "✅ Fallback source successful."
        }
    } catch {
        Write-Host "❌ Fallback source also failed."
        Write-Host "Error: $($_.Exception.Message)"
        # This catch block is intentionally empty to allow the final check to handle the exit.
    }
}

# Check if either method successfully found a URL
if (-not $url) {
    Write-Host "❌ Could not determine download URL from any source. Exiting." -ForegroundColor Red
    Stop-Transcript
    Start-Sleep -Seconds 20
    exit
}

# Extract filename from the URL and define the output path
$filename = [System.IO.Path]::GetFileName($url)
$output = Join-Path -Path $gameDir -ChildPath "ScriptUpdateFiles\$filename"
 
Write-Host "✅ NEWEST MINECRAFT SERVER VERSION: $($filename -replace '.zip','')"
 
# CHECK IF FILE ALREADY DOWNLOADED
if(!(Test-Path -Path $output -PathType Leaf))
{ 
	# STOP SERVER
	if(get-process -name ($bedServerExe -replace '.exe','') -ErrorAction SilentlyContinue)
	{
		Write-Host "STOPPING SERVICE..."
		Stop-Process -name ($bedServerExe -replace '.exe','')
	}

 	# PERFORM BACKUP OF WORLDS FOLDER
	Write-Host "BACKING UP WORLDS FOLDER"
    Start-Sleep -Seconds 2
	Backup-Worlds

	# DO A BACKUP OF CONFIG 
	if(!(Test-Path -Path "ScriptUpdateFiles"))
	{
		New-Item -ItemType Directory -Name ScriptUpdateFiles 
	}
 
	if(Test-Path -Path "server.properties" -PathType Leaf)
	{
		Write-Host "BACKING UP server.properties..."
		Copy-Item -Path "server.properties" -Destination ScriptUpdateFiles 
	}
	else # NO CONFIG FILE MEANS NO VALID SERVER INSTALLED, SOMETHING WENT WRONG...
	{
		Write-Host "NO server.properties FOUND ... EXITING"
		Start-Sleep -Seconds 10
		exit
	}
 
	if(Test-Path -Path "allowlist.json" -PathType Leaf)
	{
		Write-Host "BACKING UP allowlist.json..."
		Copy-Item -Path "allowlist.json" -Destination ScriptUpdateFiles
	}
 
	if(Test-Path -Path "permissions.json" -PathType Leaf)
	{
		Write-Host "BACKING UP permissions.json..."
		Copy-Item -Path "permissions.json" -Destination ScriptUpdateFiles 
	}
 
	# DOWNLOAD UPDATED SERVER .ZIP FILE
	Write-Host "DOWNLOADING $filename..."
	$start_time = Get-Date 
	Invoke-WebRequest -Uri $url -OutFile $output 
 
	# UNZIP
	Write-Host "UPDATING SERVER FILES..."
	Expand-Archive -LiteralPath $output -DestinationPath $gameDir -Force 
 
    # HANDLE CUSTOM EXECUTABLE NAME
    if ($bedServerExe -ne "bedrock_server.exe") {
        Write-Host "Handling custom executable name..."
        $oldExePath = Join-Path -Path $gameDir -ChildPath $bedServerExe
        $newExePath = Join-Path -Path $gameDir -ChildPath "bedrock_server.exe"
        
        if (Test-Path -Path $oldExePath) {
            Write-Host "Removing old server executable: $bedServerExe"
            Remove-Item -Path $oldExePath -Force
        }
        
        Write-Host "Renaming new server executable to: $bedServerExe"
        Rename-Item -Path $newExePath -NewName $bedServerExe
    }

	# RECOVER BACKUP OF CONFIG 
	Write-Host "RESTORING server.properties..."
	Copy-Item -Path ".\ScriptUpdateFiles\server.properties" -Destination .\ 
 
	if(Test-Path -Path ".\ScriptUpdateFiles\allowlist.json" -PathType Leaf)
	{
		Write-Host "RESTORING allowlist.json..."
		Copy-Item -Path ".\ScriptUpdateFiles\allowlist.json" -Destination .\ 
	}
 
	if(Test-Path -Path ".\ScriptUpdateFiles\permissions.json" -PathType Leaf)
	{
		Write-Host "RESTORING permissions.json..."
		Copy-Item -Path ".\ScriptUpdateFiles\permissions.json" -Destination .\ 
	}
 
	# START SERVER
	Write-Host "STARTING SERVER..."
	Start-Process -FilePath "$gameDir\$bedServerExe" 
} 
else
{
	Write-Host "UPDATE ALREADY INSTALLED..."
	
 	# PERFORM BACKUP OF WORLDS FOLDER
	Write-Host "BACKING UP WORLDS FOLDER..."
    Start-Sleep -Seconds 3
	Backup-Worlds

	# START SERVER
	$exePath = "$gameDir\$bedServerExe"
    $logFile1 = $date._output.txt
    $logFile2 = $date._errors.txt
	if (-not (Get-Process -Name ($bedServerExe -replace '.exe','') -ErrorAction SilentlyContinue)) { 
		Write-Host "STARTING SERVER..."
        start-process $exePath
		#start-process -filepath $exePath
        Write-Host "STARTED"
        Start-Sleep -Seconds 2
        } 
}
Write-Host "CLOSING SCRIPT"
Stop-Transcript 
Start-Sleep -Seconds 5
exit
