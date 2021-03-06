# ESUBNameFixer.ps1

# Fixes ESUB images lacking a pdf or tif file extension by adding the appropriate extension and
# fixing the errors and name matching within the XML document. Also truncates image names that are
# to long and adjusts the XML to match. Writes out to log in the Temp directory to track batches 
# that are corrected and what was changed within the XML file.

# Will Green
# 10/10/2018

Function Get-XMLDocument($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName
}

Function Pause
{
    Read-Host 'Press any key to close window' | Out-Null
}

# Default directory to grab XML file from
$xmlfilepath = "X:\ESub\BatchesToBeReviewed"
#$xmlfilepath = "C:\Users\william.green\Desktop\ESub\BatchesToBeReviewed"

# Temp ESUB directory that the fixed XML file is built within
$temppath = "X:\ESub\Temp"
#$temppath = "C:\Users\william.green\Desktop\ESub\Temp"

# ESub Watch folder
$watchfolder = "X:\ESub\Watch"
#$watchfolder = "C:\Users\william.green\Desktop\ESub\Watch"

# Input file with file path and cancel button handling
Write-Output "`nSelect XML file to FIX...`n"
$inputfile = Get-XMLDocument "$xmlfilepath"

if ($inputfile -eq "") {
    Write-Output "No XML file selected!`n"
    exit
}

$inputdata = (Get-Content $inputfile)

# Setup for building the temp file
$tempinputfile = Split-Path $inputfile -leaf

# Temp file
$tempfile = $tempinputfile + "-tmp"

# Temp file full path and location
$tempoutputfile = $temppath + "\" + $tempfile

# XML initial corrections
((Get-Content -Path $inputfile) -replace '<ImportSession ErrorCode.+','<ImportSession>') | Set-Content -Path $tempoutputfile
((Get-Content -Path $tempoutputfile) -replace ' Processed="1">','>') | Set-Content -Path $tempoutputfile
((Get-Content -Path $tempoutputfile) -replace 'ErrorCode=.+','/>') | Set-Content -Path $tempoutputfile

# NOTE: TIF = II* / PDF = %PDF

# Loop thru batch directory images and determine which are pdfs and which are tifs for those without extensions
$batchfilename = [System.Io.Path]::GetFileNameWithoutExtension($tempinputfile)
$batchimages = $watchfolder + "\" + $batchfilename
$makeintopdfs = Get-ChildItem -Recurse $batchimages -exclude *.pdf,*.tif,*.PDF,*.TIF | Select-String -Pattern "%PDF" | Select-Object -ExpandProperty Path -Unique Path
$makeintotifs = Get-ChildItem -Recurse $batchimages -exclude *.pdf,*.tif,*.PDF,*.TIF | Select-String -Pattern "II\*" | Select-Object -ExpandProperty Path -Unique Path

# Rename pdfs (add .pdf extension) and update the XML
ForEach ($imagefile in $makeintopdfs) {
    
    Rename-Item $imagefile ($imagefile + ".pdf")
    Write-Output "$imagefile was RENAMED to:`n$imagefile.pdf`n"
    $oldpdf = Split-Path $imagefile -leaf
    $newfullpdf = ($imagefile + ".pdf")
    $newpdf = Split-Path $newfullpdf -leaf
    ((Get-Content -Path $tempoutputfile) -replace $oldpdf,$newpdf) | Set-Content -Path $tempoutputfile
        
}

# Rename tifs (add .tif extension) and update the XML
ForEach ($imagefile in $makeintotifs) {
    
    Rename-Item $imagefile ($imagefile + ".tif")
    Write-Output "$imagefile was RENAMED to:`n$imagefile.tif`n"
    $oldtif = Split-Path $imagefile -leaf
    $newfulltif = ($imagefile + ".tif")
    $newtif = Split-Path $newfulltif -leaf
    ((Get-Content -Path $tempoutputfile) -replace $oldtif,$newtif) | Set-Content -Path $tempoutputfile
        
}

# Truncate long filenames and update XML to match
$bignameimages = Get-ChildItem -Path $batchimages -File | Where-Object{$_.FullName.Length -gt 100} | Select-Object Name | Select-Object -ExpandProperty Name

ForEach ($bigname in $bignameimages) {
    
    $crushbigname = $bigname -replace " ",""
    $crushbigname = $crushbigname -replace ",",""
    $bignameextension = $crushbigname.Substring($crushbigname.Length -4)
    $crushbigname = $crushbigname.Substring(0,30) + "$bignameextension"
    
    $fullbigname = "$batchimages" + "\" + "$bigname"
    $fullcrushbigname = "$batchimages" + "\" + "$crushbigname"

    Rename-Item $fullbigname $fullcrushbigname
    Write-Output "$bigname was RENAMED to:`n$crushbigname`n"
    
    ((Get-Content -Path $tempoutputfile) -replace $bigname,$crushbigname) | Set-Content -Path $tempoutputfile
        
}

# Shuffle around files... Make backup of the original XML and name it -original and move temp file into review folder with batch XML name
Rename-Item $inputfile ($inputfile + "-original")
Move-Item -Path $tempoutputfile -Destination $inputfile
Write-Output "XML file has been updated SUCCESSFULLY...`n`nAll operations have been completed for batch $batchfilename`n"

# Append batch id to corrected batch log file
#$fixedlogfile = "X:\ESub\Temp\corrected-batch-log.txt"
$fixedlogfile = "C:\Users\william.green\Desktop\ESub\Temp\corrected-batch-log.txt"
Add-Content $fixedlogfile "$(Get-Date -format "yyyy MMM dd hh:mm:ss"): $batchfilename"

# Display diff of original and fixed XML file and add to log
$inputfileoriginal = "$inputfile-original"
$changediff = $(Compare-Object (Get-Content $inputfile) (Get-Content $inputfileoriginal)) | Out-String
Write-Output "XML File Update Results...`n$changediff"
Add-Content $fixedlogfile "$changediff"

# Pause for user input to close window
Pause

# To append pdf extension by hand copy/paste the following (minus the #)...
#Get-ChildItem -Path "$inputfile" -exclude *.pdf,*.tif,*.ps1 | Where-Object{!$_.PsIsContainer} | Rename-Item -newname {$_.name + ".pdf"}
