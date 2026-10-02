#requires -Version 7
param([string]$VivadoBin='D:\amd2025_2\2025.2\Vivado\bin')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$taskBuild=Join-Path $taskRoot 'build/prepcb/xsim';New-Item -ItemType Directory -Force $taskBuild|Out-Null
$taskEvidence=Join-Path $taskRoot 'evidence/task001b/simulation';New-Item -ItemType Directory -Force $taskEvidence|Out-Null
$taskSources=@('rtl/sync/sync_protocol.sv','rtl/sync/timestamp_counter.sv','rtl/sync/sync_master.sv','rtl/sync/sync_slave.sv','rtl/sync/sync_button.sv','rtl/sync/delay_measure.sv','rtl/clock/clk_manager.sv','rtl/top/dual_sync_top.sv','rtl/array/serializer64.sv','rtl/array/array_output_guard.sv','rtl/array/array_test_endpoint.sv','tb/dual_sync_tb.sv','tb/top_clock_tb.sv','tb/serializer64_tb.sv','tb/dual_serializer_sync_tb.sv')|ForEach-Object{Join-Path $taskRoot $_}
Push-Location $taskBuild
try{
 & (Join-Path $VivadoBin 'xvlog.bat') -sv @taskSources *> (Join-Path $taskEvidence 'xvlog.log')
 if($LASTEXITCODE){throw 'xvlog failed'}
 foreach($tb in @('dual_sync_tb','top_clock_tb','serializer64_tb','dual_serializer_sync_tb')){
  & (Join-Path $VivadoBin 'xelab.bat') $tb -s ($tb+'_snapshot') -debug typical *> (Join-Path $taskEvidence ($tb+'-xelab.log'))
  if($LASTEXITCODE){throw "$tb elaboration failed"}
  & (Join-Path $VivadoBin 'xsim.bat') ($tb+'_snapshot') -runall *> (Join-Path $taskEvidence ($tb+'.log'))
  if($LASTEXITCODE -or !(Select-String -LiteralPath (Join-Path $taskEvidence ($tb+'.log')) -Pattern ($tb.ToUpper()+' PASS') -Quiet)){throw "$tb did not pass"}
  Get-Content -LiteralPath (Join-Path $taskEvidence ($tb+'.log')) -Tail 5
 }
}finally{Pop-Location}
