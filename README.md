# PowerShellScripts
A collection of PowerShell scripts that I put together to accomplish various work related tasks. Nothing fancy.

# KofaxUp2DownV2.ps1
Simple script to convert a KOFAX upload file into a DOWNLOAD file as what would be received from the mainframe. This is to allow testing of KOFAX imports without the mainframe in dev and test environments.

# ESUBNameFixer.ps1
Script to add pdf or tif extension to images missing the appropriate extension or containing a file name that exceeds the max allowed length that are located in a batch directory received from the document transporter but failed being ingested into KOFAX via the XML importer. The script strips the error and processing info from the XML file and updates the file location names and paths to match the newly renamed image files and writes to a log file the changes made and for what batch.  This is a very specific script for KOFAX and our custom environment.
