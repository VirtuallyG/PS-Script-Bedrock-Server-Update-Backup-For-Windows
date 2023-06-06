echo "MINECRAFT BEDROCK SERVER UPDATE SCRIPT (6/6/2023)"
# MICROSOFT POWERSHELL SCRIPT
# INSTRUCTIONS:
# (1)  PASTE THIS SCRIPT IN NOTEPAD AND SAVE IT IN YOUR SERVER DIRECTORY WITH .PS1 FILE EXTENSION (ex C:\Users\USER\Minecraft Server\Bedrock Server\UpdateBackupScript.ps1)
# (2) CHANGE $gameDir VARIABLE BELOW TO YOUR SERVER DIRECTORY AND SAVE THE SCRIPT
$gameDir = "C:\Users\USER\Minecraft Server\Bedrock Server"
# (3) RIGHT CLICK THE .PS1 FILE AND CHOOSE "RUN WITH POWERSHELL" TO TEST IT, MAKE SURE IT WORKS
# (4) CREATE POWERSHELL TASK IN WINDOWS TASK SCHEDULER TO RUN PERIODICALLY (WHEN NOBODY IS LIKELY TO BE CONNECTED TO SERVER)
 
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
# The $numbackup variable below is how many backups the script will keep. This can be any number but be aware of your space requirements.
# This script does not check for available space so be sure to keep this number within your hard drive's capacity.

# FUNCTION TO BACKUP UP WORLDS FOLDER KEEPING LATEST BACKUPS SPECIFIED
function Backup-Worlds {
	# Variables able to be configured:

    # WORLDS FOLDER TO BE BACKED UP
    $source = Join-Path -Path $gameDir -ChildPath worlds
	  # DESTINATION OF BACKUP (You can change this to a specific directory if want to save outside of
    # the bedrock server folder, (ex. $destination = "D:\Games\Mincraft\ServerGameDataBackup")
    $destination = Join-Path -Path $gameDir -ChildPath ScriptBackups
    # NUMBER OF BACKUPS TO KEEP
    $numbackup = 10

    #DO NOT CHANGE VARIABLES BELOW UNLESS YOU KNOW WHAT YOU ARE DOING



    $date = Get-Date -Format "yyyy-MM-dd_HHmmss"

    # Create the backup folder if it doesn't exist
    if (!(Test-Path -Path $destination)) {
        New-Item -ItemType Directory -Path $destination
    }

    # Backup worlds folder to the dated subfolder
    $backupPath = Join-Path -Path $destination -ChildPath $date
    New-Item -ItemType Directory -Path $backupPath
    Copy-Item -Path $source -Destination $backupPath -Recurse

    # Remove older backups based on variable in $numbackup 
    Get-ChildItem -Path $destination -Directory |
        Sort-Object -Property CreationTime -Descending |
        Select-Object -Skip $numbackup |
        Remove-Item -Recurse -Force
}

cd $gameDir 
 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
# BUGFIX: HAD TO INVOKE-WEBREQEUEST WITH A DIFFERENT CALL TO FIX A PROBLEM WITH IT NOT WORKING ON FIRST RUN
try
{
	$requestResult = Invoke-WebRequest -Uri 'https://www.minecraft.net/en-us/download/server/bedrock' -TimeoutSec 1
}
catch
{
	# NO ACTION, JUST SILENCE ERROR
} 
 
# START WEB REQUEST SESSION
$session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
$session.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36'
$InvokeWebRequestSplatt = @{
    UseBasicParsing = $true
    Uri             = 'https://www.minecraft.net/en-us/download/server/bedrock'
    WebSession      = $session
	TimeoutSec		= 10
    Headers         = @{
        "accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
        "accept-encoding" = "gzip, deflate, br"
        "accept-language" = "en-US,en;q=0.8"
    }
}
 
# GET DATA FROM WEB
try
{
	$requestResult = Invoke-WebRequest @InvokeWebRequestSplatt
}
catch
{
	# IF ERROR, CAN'T PROCEED, SO EXIT SCRIPT
	echo "WEB REQUEST ERROR"
	Start-Sleep -Seconds 10
	exit
} 
 
# PARSE DOWNLOAD LINK AND FILE NAME
$serverurl = $requestResult.Links | select href | where {$_.href -like "https://minecraft.azureedge.net/bin-win/bedrock-server*"}
$url = $serverurl.href
$filename = $url.Replace("https://minecraft.azureedge.net/bin-win/","")
$url = "$url"
$output = "$gameDir\ScriptUpdateFiles\$filename" 
 
write-output "NEWEST UPDATE AVAILABLE: $filename"
 
# CHECK IF FILE ALREADY DOWNLOADED
if(!(Test-Path -Path $output -PathType Leaf))
{ 
	# STOP SERVER
	if(get-process -name bedrock_server -ErrorAction SilentlyContinue)
	{
		echo "STOPPING SERVICE..."
		Stop-Process -name "bedrock_server" 
	}

 	# Perform backup of worlds folder
	echo "Backing up Worlds folder"
    Start-Sleep -Seconds 3
	Backup-Worlds
    echo "WORLDS FOLDER BACKUP COMPLETE"
    Start-Sleep -Seconds 5

	# DO A BACKUP OF CONFIG 
	if(!(Test-Path -Path "ScriptUpdateFiles"))
	{
		New-Item -ItemType Directory -Name ScriptUpdateFiles 
	}
 
	if(Test-Path -Path "server.properties" -PathType Leaf)
	{
		echo "BACKING UP server.properties..."
		Copy-Item -Path "server.properties" -Destination ScriptUpdateFiles 
	}
	else # NO CONFIG FILE MEANS NO VALID SERVER INSTALLED, SOMETHING WENT WRONG...
	{
		echo "NO server.properties FOUND ... EXITING"
		Start-Sleep -Seconds 10
		exit
	}
 
	if(Test-Path -Path "allowlist.json" -PathType Leaf)
	{
		echo "BACKING UP allowlist.json..."
		Copy-Item -Path "allowlist.json" -Destination ScriptUpdateFiles
	}
 
	if(Test-Path -Path "permissions.json" -PathType Leaf)
	{
		echo "BACKING UP permissions.json..."
		Copy-Item -Path "permissions.json" -Destination ScriptUpdateFiles 
	}
 
	# DOWNLOAD UPDATED SERVER .ZIP FILE
	Write-Output "DOWNLOADING $filename..."
	$start_time = Get-Date 
	Invoke-WebRequest -Uri $url -OutFile $output 
 
	# UNZIP
	echo "UPDATING SERVER FILES..."
	Expand-Archive -LiteralPath $output -DestinationPath $gameDir -Force 
 
	# RECOVER BACKUP OF CONFIG 
	echo "RESTORING server.properties..."
	Copy-Item -Path ".\ScriptUpdateFiles\server.properties" -Destination .\ 
 
	if(Test-Path -Path "allowlist.json" -PathType Leaf)
	{
		echo "RESTORING allowlist.json..."
		Copy-Item -Path ".\ScriptUpdateFiles\allowlist.json" -Destination .\ 
	}
 
	if(Test-Path -Path "permissions.json" -PathType Leaf)
	{
		echo "RESTORING permissions.json..."
		Copy-Item -Path ".\ScriptUpdateFiles\permissions.json" -Destination .\ 
	}
 
	# START SERVER
	echo "STARTING SERVER..."
	Start-Process -FilePath bedrock_server.exe 
} 
else
{
	echo "UPDATE ALREADY INSTALLED..."
	# STOP SERVER
	if(get-process -name bedrock_server -ErrorAction SilentlyContinue)
	{
		echo "STOPPING SERVICE..."
		Stop-Process -name "bedrock_server" 
	}

 	# Perform backup of worlds folder
	echo "Backing up Worlds folder"
    Start-Sleep -Seconds 3
	Backup-Worlds
    echo "WORLDS FOLDER BACKUP COMPLETE"
    Start-Sleep -Seconds 5

	# START SERVER
	echo "STARTING SERVER..."
	Start-Process -FilePath bedrock_server.exe 
}
 
Start-Sleep -Seconds 5
exit

