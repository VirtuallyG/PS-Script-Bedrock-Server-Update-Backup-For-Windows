# PS-Script-Bedrock-Server-Update-Backup-For-Windows
Powershell Script for automatic updating a bedrock server and backup the Worlds folder

This script will check for new updates for the Windows bedrock server. If an update is found it will stop the server, backup the worlds, backup config files, download, extract, install the update, restore the config files and restart the server. If there are no new updates, the script will stop the server, backup the worlds, and restart the server. If there has been no changes to the world saves since the last backup, the script will skip the backup.

INSTRUCTIONS:

(1)  PASTE THIS SCRIPT IN NOTEPAD AND SAVE IT IN YOUR SERVER DIRECTORY WITH .PS1 FILE EXTENSION (ex C:\Users\USER\Minecraft Server\Bedrock Server\UpdateBackupScript.ps1)

(2) CHANGE $gameDir VARIABLE TO YOUR SERVER DIRECTORY AND SAVE THE SCRIPT

(3) RIGHT CLICK THE .PS1 FILE AND CHOOSE "RUN WITH POWERSHELL" TO TEST IT, MAKE SURE IT WORKS

(4) CREATE POWERSHELL TASK IN WINDOWS TASK SCHEDULER TO RUN PERIODICALLY (WHEN NOBODY IS LIKELY TO BE CONNECTED TO SERVER) Google how to setup a powershell script to run as a scheduled task



TASK SCHEDULER SETUP

(1) OPEN TASK SCHEDULER

(2) CREATE TASK (UNDER ACTIONS ON RIGHT HAND SIDE)

(3) GENERAL TAB - NAME [ANY NAME YOU WISH], SECURITY OPTIONS [RUN WHETHER USER IS LOGGED ON OR NOT] [DO NOT STORE PASSWORD] [RUN WITH HIGHEST PRIVILEGES]

(4) TRIGGERS TAB - [NEW] BEGIN THE TASK ON A SCHEDULE [CHOOSE HOW OFTEN YOU WANT THE SCRIPT TO RUN] [OK] YOU CAN THEN CLICK [NEW] AGAIN AND BEGIN THE TASK AT STARTUP [DELAY TASK FOR 1 MINUTE] [ENABLED] UNCHECK EVERYTHING ELSE [OK]

(5) ACTION TAB - [NEW] - ACTION [START A PROGRAM] - PROGRAM / SCRIPT [powershell] - ADD ARGUMENTS [-noprofile -executionpolicy bypass -File "C:\Users\USER\Minecraft Server\Bedrock Server\Update Bedrock Server Update and Backup.ps1"] (REPLACE THIS PATH WITH THE PATH TO YOUR SCRIPT - MUST BE IN QUOTES IF SPACES ARE IN THE PATH) [OK]

(6) [OK]

(7) CLICK [TASK SCHEDULER LIBRARY] ON THE LEFT SIDE - FIND THE NAME OF YOU TASK THAT YOU CREATED IN STEP 2 - RIGHT CLICK THE TASK - [RUN]

(9) AFTER A FEW MINUTES YOU SHOULD BE ABLE TO SEE AN UPDATED LOG FILE IN YOUR SERVER DIRECTORY/ScriptLogs


If you like this script, consider buying me a coffee

Buy Me A Coffee https://bmc.link/virtuallyg
