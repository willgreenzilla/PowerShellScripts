# ErrorLogScanner.ps1
# v2

# Will Green
# 12/14/2018

# Add/remove errors from the scan_script_error_list.txt file for what to scan for in the logs.
# Add/remove full paths to what log directories to scan. Adjust $servercount value to equal the number
# of full paths to be scanned. Full compiled output of report will be sent to a file named: Scan-Report-DATE-TIME.txt

# Set variables 
$servercount = "4"
$errorlistfile = $PSScriptRoot + '\' + "scan_script_error_list.txt"
$scandir = Get-Content -Path $errorlistfile -First $servercount
$reportfile = "Scan-Report-$(Get-Date -format "yyyyMMMdd-hhhhmm").txt"
$errorreport = $PSScriptRoot + '\' + $reportfile
$errorlist = Get-Content -Path $errorlistfile | Select -Skip $servercount

# Create report file
New-Item -Path $PSScriptRoot -Name $reportfile

# Loop thru list of log location paths
foreach ($loc in $scandir)
{
    $loglist = Get-ChildItem -Name "TextLog_*" -Path $loc
    $loghost = $loc.SubString(2).Split('.')[0]
    $logapp = $loc.SubString(2).Split('\')[8]
    Add-Content $errorreport "***************************************"
    Add-Content $errorreport "SERVER: $loghost | APP: $logapp"
    Add-Content $errorreport "***************************************"

# Loop thru list of logs
    foreach ($log in $loglist)
    {

# Loop thru list of errors
        foreach ($scanerror in $errorlist)
        {

            Select-String -Path "$loc\$log" -Pattern $scanerror | Select-Object Filename,Line | Add-Content $errorreport -PassThru
    
        }

    }

}