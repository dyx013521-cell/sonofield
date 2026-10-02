param([string]$VivadoBin='D:\amd2025_2\2025.2\Vivado\bin')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 required'}
$Root=Split-Path $PSScriptRoot -Parent
$Build=Join-Path $PSScriptRoot 'build';New-Item -ItemType Directory -Force $Build|Out-Null
$Evidence=Join-Path $Root 'evidence/task001';New-Item -ItemType Directory -Force $Evidence|Out-Null
$Sources=@('rtl/sync/sync_protocol.sv','rtl/sync/timestamp_counter.sv','rtl/sync/sync_master.sv','rtl/sync/sync_slave.sv','rtl/sync/sync_button.sv','rtl/sync/delay_measure.sv','rtl/clock/clk_manager.sv','rtl/top/dual_sync_top.sv','tb/dual_sync_tb.sv','tb/top_clock_tb.sv') | ForEach-Object {Join-Path $Root $_}
Push-Location $Build
try {
 & (Join-Path $VivadoBin 'xvlog.bat') -sv @Sources *> (Join-Path $Evidence 'xvlog.log')
 if($LASTEXITCODE){throw 'xvlog failed'}
 & (Join-Path $VivadoBin 'xelab.bat') dual_sync_tb -s dual_sync_tb_snapshot -debug typical *> (Join-Path $Evidence 'xelab.log')
 if($LASTEXITCODE){throw 'xelab failed'}
 & (Join-Path $VivadoBin 'xsim.bat') dual_sync_tb_snapshot -runall *> (Join-Path $Evidence 'xsim.log')
 if($LASTEXITCODE -or -not (Select-String -Path (Join-Path $Evidence 'xsim.log') -Pattern 'DUAL_SYNC_TB PASS' -Quiet)){throw 'xsim did not pass'}
 Get-Content (Join-Path $Evidence 'xsim.log') -Tail 8
 & (Join-Path $VivadoBin 'xelab.bat') top_clock_tb -s top_clock_snapshot -debug typical *> (Join-Path $Evidence 'xelab-top.log')
 if($LASTEXITCODE){throw 'top xelab failed'}
 & (Join-Path $VivadoBin 'xsim.bat') top_clock_snapshot -runall *> (Join-Path $Evidence 'xsim-top.log')
 if($LASTEXITCODE -or -not (Select-String -Path (Join-Path $Evidence 'xsim-top.log') -Pattern 'TOP_CLOCK_TB PASS' -Quiet)){throw 'top xsim did not pass'}
 Get-Content (Join-Path $Evidence 'xsim-top.log') -Tail 8
} finally {Pop-Location}
