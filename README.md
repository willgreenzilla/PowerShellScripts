# PowerShellScripts
A collection of PowerShell scripts that I put together to accomplish various work related tasks. Nothing fancy.

# KofaxUp2DownV2.ps1
Simple script to convert a KOFAX upload file into a DOWNLOAD file as what would be received from the mainframe. This is to allow testing of KOFAX imports without the mainframe in dev and test environments.

# ESUBNameFixer.ps1
Script to add pdf or tif extension to images missing the appropriate extension or containing a file name that exceeds the max allowed length that are located in a batch directory received from the document transporter but failed being ingested into KOFAX via the XML importer. The script strips the error and processing info from the XML file and updates the file location names and paths to match the newly renamed image files and writes to a log file the changes made and for what batch.  This is a very specific script for KOFAX and our custom environment.

# PridemodShuffleBXFR.ps1
Simple script to copy folders, folder contents, and files from one folder on one server to another folder on another domain of which there is no trust between domains, just a domain account with permission to work on both servers. Files are copied over a set last access age to prevent accidental copies of files not yet completely copied into the initial directory. Config file sets the server details and username info, etc. Password is encrypted and read in when the script is executed. Built for a specific workaround to move a large quantity of records between servers from LiveCycle to be fed into KOFAX. This version uses Bitstransfer which had issues running as a service account within a scheduled task. Also had issues with fips security and pwoershell encryption. Replaced by FileShuffle.ps1 and was re-named to this.

# FileShuffle.ps1
Simple script to copy folders, folder contents, and files from one folder on one server to another folder on another domain of which there is no trust between domains, just a domain account with permission to work on both servers. Files are copied over a set last write time to prevent accidental copies of files not yet completely copied into the initial directory. Config file sets the server details and username info, etc. Password is encoded and read in when the script is executed. To be ran from task scheduler. Built for a specific workaround to move a large quantity of records between servers from LiveCycle to be fed into KOFAX. This version uses robocopy and does work when kicked off via a scheduled task and runs under a service account.
