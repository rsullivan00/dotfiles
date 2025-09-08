<#
 Permanently remap CapsLock to Escape via registry scancode map.
 Must be run in elevated PowerShell (Run as Administrator), then reboot.
#>

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$name = 'Scancode Map'
# Binary data for: 1 mapping entry + null terminator
$data = [byte[]](0,0,0,0,0,0,0,0, 2,0,0,0, 1,0,0x3a,0, 0,0,0,0)

New-Item -Path $regPath -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $regPath -Name $name -PropertyType Binary -Value $data -Force | Out-Null
Write-Host 'CapsLock -> Escape mapping applied. Reboot required.' -ForegroundColor Green
