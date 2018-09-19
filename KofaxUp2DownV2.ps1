# Converts a KOFAX Upload into a Download to bypass mainframe for testing purposes.
# V2
# Will Green
# 7/30/2018

Function Get-Filename($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
 
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName
}

Function Save-Browser($initialSaveDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

 $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.SelectedPath = $initialSaveDirectory
 $FolderBrowserDialog.Description = "Converted file download save location"
 
 if ($FolderBrowserDialog.ShowDialog() -eq "OK")
 {
  $folder += $FolderBrowserDialog.SelectedPath
 }
 return $folder
}

Function Insert-Content
{
    param ( [String]$Path )
    process
    {
        $( ,$_; Get-Content $Path -ea SilentlyContinue) | Out-File $Path
    }
}

# Default file select path start location
#$userpath = "$($env:USERPROFILE)\Desktop"
$userpath = "X:\DECC\send"

# Default file save path start location
$defaultsavedir = "X:\DECC\receive\"

# Input file with file path and cancel button handling
Write-Output "Select file to convert..."

$inputfile = Get-Filename "$userpath"

if ($inputfile -eq "") {
 exit
} else {
 Write-Output "Select file save location..."}

$inputdata = (Get-Content $inputfile)

# Save file with file path and cancel button handling
$outputdir = Save-Browser "$defaultsavedir"
$outputfile = $outputdir + "\" + "$(Get-Date -format "yyyMMddhhmm")-DOWNLOAD"

if ($outputfile -eq "") {
 exit
}
 
# Date grab
$dayofyear = "{0:000}" -f (Get-Date).DayofYear

# Conversion
$inputdata | Where-Object {$_ -notmatch "^H"} | Set-Content $outputfile
(Get-Content $outputfile) | foreach-Object {$_ -replace "^T","A"} | Out-File $outputfile
(Get-Content $outputfile) | foreach-Object {$_.Substring(0,$_.Length-22)} | Out-File $outputfile
(Get-Content $outputfile) | foreach-Object {$_ + $_.Substring(102,8) + "999999999" + "$(Get-Date -format "yyyy")" + $dayofyear + "                     "} | Out-File $outputfile

# Add date
"$(Get-Date -format "yyyyMMdd")" | Insert-Content $outputfile

# Finish
Write-Output "Upload to Download conversion COMPLETE!"
Start-Sleep 1
