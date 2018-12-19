# FileShuffleEncoder.ps1

# Encodes the domain XXX user account password: domain\useraccount

# Pull values from the config file "shuffleconfig"
$shuffleconfig = 'D:\app\Scripts\FileShuffle.config'
$configvaluestring = Get-Content $shuffleconfig | Out-String
$configstringconvert = $configvaluestring -replace '\\', '\\'
$configvalues = ConvertFrom-StringData $configstringconvert

# Set the secure file from the config file info
$securefile = $configvalues.PWSECUREFILE

# Input box to enter user password to encode
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$boxtitle = 'Encode Account Password'
$boxmsg = 'Enter user password to encode...'
$password = [Microsoft.VisualBasic.Interaction]::InputBox($boxmsg, $boxtitle)

# Encode password, write to $securefile
$bytes = [System.Text.Encoding]::Unicode.GetBytes($password)
$encodedtext = [Convert]::ToBase64String($bytes)
Write-Output $encodedtext > $securefile

# Show the password to verify it will decode as expected
$decodedtext = [System.Text.Encoding]::UTF8.GetString(([System.Convert]::FromBase64String($encodedtext)|?{$_}))
Write-Output "`nVerify password is correct...`n`n$decodedtext`n"
Pause
