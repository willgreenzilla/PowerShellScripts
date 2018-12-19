# PridemodShuffleBXFR.ps1

# Uses bitstransfer module to copy files from core to busppn.
# Replaced by PridemodShuffle.ps1 using robocopy.
# Will Green

Import-Module bitstransfer

# Collection of account, host, and credential info. Credentials stored in a secure text file.

# Note: Password needs to be encrypted as the user whom will be running the scheduled task to initiate the script.
# Command to generate the encrypted password:
#
# Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File D:\Scripts\pridemodsecure.txt

# Pull values from the config file "shuffleconfig"
$shuffleconfig = 'D:\Pridemod\Scripts\PridemodShuffle.config'
$configvaluestring = Get-Content $shuffleconfig | Out-String
$configstringconvert = $configvaluestring -replace '\\', '\\'
$configvalues = ConvertFrom-StringData $configstringconvert
$shufflelog = $configvalues.SHUFFLELOG

# Check script lock, if no lock, create lock, run, and unlock when complete, else, exit.
if (Test-Path PridemodShuffleLOCK)
{

    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): Script tried to start while already RUNNING..."
    Exit

}

# Create lock file to lock script so it cannot be ran while already running
New-Item -Path . -Name "PridemodShuffleLOCK" -ItemType "File" -Value "PridemodShuffle.ps1 is currently RUNNING!"

# Set variables (many pulled from the PridemodShuffle.config file
$username = $configvalues.USERNAME
$password = Get-Content $configvalues.PWSECUREFILE | ConvertTo-SecureString
$kofaxserver = $configvalues.KOFAXSERVER
$kofaxserverfullpath = $kofaxserver + $configvalues.SENDTOPATH
$cifsharepath = $configvalues.SENDFROM
#$nogotime = (Get-Date).AddHours(-$configvalues.PAUSEHRTIME)
$nogotime = (Get-Date).AddMinutes(-$configvalues.PAUSEHRTIME)
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password
$allfolders = Get-ChildItem -Name -Path $cifsharepath -Directory -Recurse
$folders = @()
$allfiles = Get-ChildItem -Name -Path $cifsharepath -File
$files = @()

# Build an array of files whom are older than the nogotime variable to prevent accidental copy of in-progress XML files.
foreach ($j in $allfiles)
{

    $filewritecheck = $(Get-Item "$cifsharepath\$j").LastAccessTime
    
    if ($filewritecheck -lt $nogotime)
    {
    
        $files += $j
    } 

}

# Build an array of folders whom are older than the nogotime variable to prevent accidental copy of in-progress images.
foreach ($i in $allfolders)
{

    $writecheck = $(Get-Item "$cifsharepath\$i").LastAccessTime
    
    if ($writecheck -lt $nogotime)
    {
    
        $folders += $i
    } 

}

# If no images to copy make a log of this
if (!$allfolders -And !$folders)
{

    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): NO IMAGE FILES to COPY... Skipping."

}

# If folder(s) present but not enough time has passed make a log of this
if ($allfolders -And !$folders)
{

    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): IMAGE Items PENDING but NOTHING READY to COPY... Skipping."

}

# If no XML files to copy make a log of this
if (!$allfiles -And !$files)
{

    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): NO XML FILES to COPY... Skipping."

}

# If folder(s) present but not enough time has passed make a log of this
if ($allfiles -And !$files)
{

    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): XML FILE Items PENDING but NOTHING READY to COPY... Skipping."

}

# Perform the image folder copy using Bitstransfer 
foreach ($i in $folders)
{
 
    $exists = Test-Path $kofaxserverfullpath\$i
    
    if ($exists -eq $false) {New-Item $kofaxserverfullpath\$i -ItemType Directory}
    
    $fbitsjob = Start-BitsTransfer -Source $cifsharepath\$i\*.* -Destination $kofaxserverfullpath\$i -Credential $cred -Asynchronous -Priority Low

    while( ($fbitsjob.JobState.ToString() -eq 'Transferring') -or ($fbitsjob.JobState.ToString() -eq 'Connecting') )

    {

        Sleep 1

    }

    Switch($fbitsjob.JobState)
    {

        "Transferred" {Complete-BitsTransfer -BitsJob $fbitsjob}
        "Error" {$fbitsjob | Format-List >> $shufflelog}

    }

    # Log what has been copied
    $trimstring = "$kofaxserverfullpath" + "\" + $i.Remove(0,5).Insert(0,'XXXXX')
    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): $trimstring"
    Get-ChildItem "$kofaxserverfullpath\$i" | Select-Object -ExpandProperty Name >> $shufflelog

    # Delete original images
    Remove-Item -Path $cifsharepath\$i -Recurse

}

# Copy the XML files over with Bitstransfer
foreach ($j in $files)
{
  
    $fileexists = Test-Path $kofaxserverfullpath\$j
    
    if ($fileexists -eq $false) {New-Item $kofaxserverfullpath\$j -ItemType File}

    $bitsjob = Start-BitsTransfer -Source $cifsharepath\$j -Destination $kofaxserverfullpath -Credential $cred -Asynchronous -Priority Low
    
    while( ($bitsjob.JobState.ToString() -eq 'Transferring') -or ($bitsjob.JobState.ToString() -eq 'Connecting') )
    {

        Sleep 1

    }

    Switch($bitsjob.JobState)
    {

        "Transferred" {Complete-BitsTransfer -BitsJob $bitsjob}
        "Error" {$fbitsjob | Format-List >> $shufflelog}

    }

     # Log what has been copied
    $filetrimstring = "$kofaxserverfullpath" + "\" + $j.Remove(0,5).Insert(0,'XXXXX')
    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): $filetrimstring"
    Get-ChildItem "$kofaxserverfullpath\$j" | Select-Object -ExpandProperty Name >> $shufflelog

    # Delete original XML
    Remove-Item -Path $cifsharepath\$j

}

# Remove script lock
Remove-Item -Path "PridemodShuffleLOCK"
