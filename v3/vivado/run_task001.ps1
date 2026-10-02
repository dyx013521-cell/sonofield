param([string]$VivadoBin='D:\amd2025_2\2025.2\Vivado\bin',[switch]$SkipSimulation)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 required'}
$Root=Split-Path $PSScriptRoot -Parent
if(-not $SkipSimulation){& (Join-Path $Root 'simulation/run_xsim.ps1') -VivadoBin $VivadoBin}
$Out=Join-Path $Root 'evidence/task001'
Push-Location $Out
try {
 & (Join-Path $VivadoBin 'vivado.bat') -mode batch -source (Join-Path $PSScriptRoot 'build.tcl') -log vivado-build.log -journal vivado-build.jou *> vivado-console.log
 if($LASTEXITCODE){throw 'Vivado process failed'}
 Get-Content build-results.tsv
 $Rows=Import-Csv build-results.tsv -Delimiter "`t"
 if($Rows.Count -ne 2 -or @($Rows|Where-Object {$_.status -ne 'TIMING_BUDGET_MET_NOT_HARDWARE_VERIFIED'}).Count){throw 'Build/timing has unresolved results; review original reports'}
} finally {Pop-Location}
