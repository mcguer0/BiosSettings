$online = Get-Content .\cp\online_utf8.txt

function Get-OnlineComputers {
    Remove-Item '.\cp\cp_online.txt'
    Remove-Item '.\cp\cp_offline.txt'

    $names = Get-Content '.\cp\cc.txt'
    foreach ($name in $names){
        if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
            Write-Host $name -ForegroundColor Green
            Write-Output $Name | Out-File -Encoding utf8 -Append -FilePath '.\cp\cp_online.txt'
        }
        else{
            Write-Host $name -ForegroundColor Red
            Write-Output $Name | Out-File -Encoding utf8 -Append -FilePath '.\cp\cp_offline.txt'
        }
    }
    $filename = 'M:\ASU\Soft\BiosSettings\cp\online_utf8.txt'
    $content = Get-Content '.\cp\cp_online.txt'
    [IO.File]::WriteAllLines($filename, $content)
}

function Start-WinRM {
    .\Script\Start_WinRM.bat
}

function Stop-WinRM {
    .\Script\Stop_WinRM.bat
}

function Set-WorkDirectory {
    Invoke-Command -ScriptBlock { New-Item -Path 'C:\Audit' -ItemType Directory -Force } -ComputerName ($online)
}

function Remove-WorkDirectory {
    Invoke-Command -ScriptBlock { Remove-Item -Path 'C:\Audit' -Force -Recurse } -ComputerName ($online)
}
function Start-Script {
    Invoke-Command -ScriptBlock { 
        

        Get-WmiObject -Namespace root\HP\InstrumentedBIOS -Class HP_BIOSSetting | Select-Object name, value | Select-String 'Uefi boot sources', 'Legacy boot sources' | Out-File -Width 200 -FilePath C:\Audit\$env:COMPUTERNAME.txt
        
    } -ComputerName ($online)

    foreach ($cp in $online) {
        Copy-Item \\$cp\c$\Audit\*.txt .\Result -Recurse -Force
    }
}

function Move-Result {
    Set-Location -Path '.\Result'
    
    $result = Select-String -Path '.\*.txt' -SimpleMatch 'cd/dvd drive disabled', 'usb floppy/cd disabled', 'usb floppy/cd disabled', 'usb hard drive disabled', 'atapi cd/dvd drive disabled' | Select-Object -ExpandProperty Filename -Unique
    foreach ($ok in $result) {
        Move-Item -Path $ok -Destination '.\OK' -Force
    }
    Move-Item -Path '*.txt' -Destination '.\Not_OK' -Force

    Set-Location -Path '..\'
}

function Set-BootOrder {
    Get-ChildItem -Path .\Result\Not_Ok\ -Name '*.txt' | Out-File .\cp\bad.txt
    (Get-Content -Path .\cp\bad.txt) |
    ForEach-Object {$_ -replace '.txt', ''} |
        Set-Content -Path .\cp\bad.txt
        
    $bad_cp = Get-Content .\cp\bad.txt

    foreach ($cp in $bad_cp) {
        Copy-Item '.\FixBootOrder\*' \\$cp\c$\Audit\ -Recurse -Force
        PsExec.exe -s \\$cp powershell /c "Get-Content C:\Audit\SetBoot.ps1 | PowerShell.exe -noprofile -"
    }
}


while($true)
{
Write-Host
Write-Host 'HpBiosSettings' -BackgroundColor White -ForegroundColor Black 
Write-Host
Write-Host '1. Обновить список компьютеров' -ForegroundColor Green
Write-Host '2. Создание рабочего каталога' -ForegroundColor Green
Write-Host '3. Служба WinRM' -ForegroundColor Green
Write-Host '4. Запуск скрипта.' -ForegroundColor Green
Write-Host '5. Отсортировать результат' -ForegroundColor Green
Write-Host '6. Выставить параметры загрузки' -ForegroundColor Green
Write-Host '7. Удаление рабочего каталога' -ForegroundColor Green
Write-Host '8. Выход' -ForegroundColor Green
Write-Host
$choice = Read-Host 'Выберите параметр'

Switch($choice){
1{Get-OnlineComputers}
2{Set-WorkDirectory}
3{  
    Write-Host
    Write-Host 'Управление службой WinRM для удаленного администрирования PowerShell' -BackgroundColor White -ForegroundColor Black 
    Write-Host
    Write-Host '1. Запустить службу WinRM' -ForegroundColor Green
    Write-Host '2. Остановить службу WinRM' -ForegroundColor Green
    Write-Host
    $rm_choice = Read-Host 'Выберите параметр'
    switch ($rm_choice) {
        1{Start-WinRM}
        2{Stop-WinRM}
        Default {Write-Host 'Неверный параметр.'}
    }
}
4{Start-Script}
5{Move-Result}
6{Set-BootOrder}
7{Remove-WorkDirectory}
8{Write-Host 'Выход'; exit}
default {Write-Host 'Неверный параметр' -ForegroundColor Red}
}
}