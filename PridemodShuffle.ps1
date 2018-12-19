# FileShuffle.ps1
# v2

# Uses robocopy to copy files from domain to another untrusted domain.
# Will Green

# Collection of account, host, and credential info. Password encoded and stored in a text file.

# Pull values from the config file "shuffleconfig"
$shuffleconfig = 'D:\app\Scripts\FileShuffle.config'
$configvaluestring = Get-Content $shuffleconfig | Out-String
$configstringconvert = $configvaluestring -replace '\\', '\\'
$configvalues = ConvertFrom-StringData $configstringconvert
$shufflelog = $configvalues.SHUFFLELOG

Write-Output "-" >> $shufflelog
Write-Output "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): SCRIPT EXECUTED" >> $shufflelog

# Check script lock, if no lock, create lock, run, and unlock when complete, else, exit.
if (Test-Path FileShuffleLOCK)
{

    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): Script tried to start while already RUNNING..."
    Exit

}

# Create lock file to lock script so it cannot be ran while already running
New-Item -Path . -Name "FileShuffleLOCK" -ItemType "File" -Value "FileShuffle.ps1 is currently RUNNING!"

# Set variables (many pulled from the PridemodShuffle.config file
$username = $configvalues.USERNAME
$encodedpw = Get-Content $configvalues.PWSECUREFILE
$password = [System.Text.Encoding]::UTF8.GetString(([System.Convert]::FromBase64String($encodedpw)|?{$_})) | ConvertTo-SecureString -AsPlainText -Force
#$password = Get-Content $configvalues.PWSECUREFILE | ConvertTo-SecureString
$kofaxserver = $configvalues.KOFAXSERVER
$kofaxserverfullpath = $kofaxserver + $configvalues.SENDTOPATH
$cifsharepath = $configvalues.SENDFROM
#$nogotime = (Get-Date).AddHours(-$configvalues.PAUSEHRTIME)
$nogotime = (Get-Date).AddMinutes(-$configvalues.PAUSEHRTIME)
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

$allfolders = Get-ChildItem -Name -Path $cifsharepath -Directory -Recurse
$folders = @()
$allfiles = Get-ChildItem -Name -Path $cifsharepath -File
$files = @()

# Create PSDrive to KOFAX
New-PSDrive -name K -Root "$kofaxserverfullpath" -Credential $creds -PSProvider filesystem -Persist

# Build an array of files whom are older than the nogotime variable to prevent accidental copy of in-progress XML files.
foreach ($j in $allfiles)
{

    $filewritecheck = $(Get-Item "$cifsharepath\$j").LastWriteTime
    
    if ($filewritecheck -lt $nogotime)
    {
    
        $files += $j
    } 

}

# Build an array of folders whom are older than the nogotime variable to prevent accidental copy of in-progress images.
foreach ($i in $allfolders)
{

    $writecheck = $(Get-Item "$cifsharepath\$i").LastWriteTime
    
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

# Perform the image folder copy using robo 
foreach ($i in $folders)
{
 
    $exists = Test-Path K:\$i
    
    if ($exists -eq $false) {New-Item K:\$i -ItemType Directory}

    robocopy "$cifsharepath\$i" "K:\$i"

    # Log what has been copied
    $trimstring = "K:" + "\" + $i.Remove(0,5).Insert(0,'XXXXX')
    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): $trimstring"
    Get-ChildItem "K:\$i" | Select-Object -ExpandProperty Name >> $shufflelog

    # Delete original images
    Remove-Item -Path $cifsharepath\$i -Recurse

}

# Copy the XML files over with robo
foreach ($j in $files)
{
  
    $fileexists = Test-Path K:\$j
    
    if ($fileexists -eq $false) {New-Item K:\$j -ItemType File}

    robocopy "$cifsharepath" "K:" $j

     # Log what has been copied
    $filetrimstring = "K:" + "\" + $j.Remove(0,5).Insert(0,'XXXXX')
    Add-Content $shufflelog "$(Get-Date -Format "yyyy MMM dd HH:mm:ss"): $filetrimstring"
    Get-ChildItem "K:\$j" | Select-Object -ExpandProperty Name >> $shufflelog

    # Delete original XML
    Remove-Item -Path $cifsharepath\$j

}

# Remove script lock & K drive
Remove-Item -Path "FileShuffleLOCK"
Remove-PSDrive -Name K
