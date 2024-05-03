Set-Location -Path "C:\Audit\"
.\BiosConfigUtility.exe /getconfig:bios.txt

$File = Get-Content '.\bios.txt'
$NewFile = $File.Replace(' Disabled', '').Replace('CD/DVD Drive', 'CD/DVD Drive Disabled').Replace('USB Floppy/CD', 'USB Floppy/CD Disabled').Replace('USB Hard Drive', 'USB Hard Drive Disabled')
$NewFile | Set-Content -Path '.\bios.txt'

.\BiosConfigUtility.exe /cpwdfile:cur.bin /setconfig:bios.txt
