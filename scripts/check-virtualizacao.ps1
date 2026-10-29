# Diagnostico de virtualizacao para WSL2 / Docker Desktop.
# Rode como Administrador:  powershell -ExecutionPolicy Bypass -File scripts\check-virtualizacao.ps1
# Com -Fix, ajusta o boot para carregar o hypervisor (precisa reiniciar depois).
param([switch]$Fix)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Warning "Rode como Administrador para ver a configuracao de boot."; }

Write-Host "`n== CPU / firmware ==" -ForegroundColor Cyan
Get-CimInstance Win32_Processor | Select-Object Name, VirtualizationFirmwareEnabled, SecondLevelAddressTranslationExtensions | Format-List

Write-Host "== DEP / NX no Windows (SupportPolicy: 0=AlwaysOff 1=AlwaysOn 2=OptIn 3=OptOut) ==" -ForegroundColor Cyan
Get-CimInstance Win32_OperatingSystem | Select-Object DataExecutionPrevention_Available, DataExecutionPrevention_SupportPolicy | Format-List

Write-Host "== Hypervisor carregado agora? ==" -ForegroundColor Cyan
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent

Write-Host "`n== Recursos do Windows ==" -ForegroundColor Cyan
Get-CimInstance Win32_OptionalFeature |
  Where-Object { $_.Name -in 'VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux','Microsoft-Hyper-V-Hypervisor','HypervisorPlatform' } |
  Select-Object Name, @{n='Habilitado';e={$_.InstallState -eq 1}} | Format-Table -AutoSize

if ($isAdmin) {
  Write-Host "== Boot (procure hypervisorlaunchtype e nx) ==" -ForegroundColor Cyan
  bcdedit /enum "{current}" | Select-String -Pattern 'hypervisor|nx'
}

Write-Host "`n== Ultimas falhas do hypervisor (evento 44 = falha ao iniciar) ==" -ForegroundColor Cyan
Get-WinEvent -ProviderName Microsoft-Windows-Hyper-V-Hypervisor -MaxEvents 5 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, Message | Format-List

if ($Fix) {
  if (-not $isAdmin) { throw "-Fix precisa de Administrador." }
  bcdedit /set "{current}" hypervisorlaunchtype auto
  bcdedit /set "{current}" nx OptIn
  Write-Host "Pronto. Reinicie o PC e rode este script de novo (sem -Fix)." -ForegroundColor Green
}
