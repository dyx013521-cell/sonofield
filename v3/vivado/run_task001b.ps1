#requires -Version 7
[CmdletBinding()]
param([string]$VivadoBin='D:\amd2025_2\2025.2\Vivado\bin')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$taskEvidence=Join-Path $taskRoot 'evidence/task001b'
$taskBuild=Join-Path $taskRoot 'build/prepcb'
New-Item -ItemType Directory -Force $taskBuild,$taskEvidence|Out-Null
function Source-Hashes {
 $taskFiles=@(Get-ChildItem (Join-Path $taskRoot 'rtl'),(Join-Path $taskRoot 'tb'),(Join-Path $taskRoot 'constraints'),(Join-Path $taskRoot 'vivado'),(Join-Path $taskRoot 'simulation') -File -Recurse|Where-Object{$_.Extension -in @('.sv','.xdc','.tcl','.ps1','.py') -and $_.FullName -notmatch '\\build\\'})
 $taskHash=[ordered]@{}
 foreach($file in $taskFiles|Sort-Object FullName){$taskHash[[IO.Path]::GetRelativePath($taskRoot,$file.FullName).Replace('\','/')]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower()}
 return $taskHash
}
$taskBefore=Source-Hashes
$taskBefore|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $taskEvidence 'source-sha256.json') -Encoding utf8
& (Join-Path $taskRoot 'simulation/run_task001b_xsim.ps1') -VivadoBin $VivadoBin
& (Join-Path $VivadoBin 'vivado.bat') -mode batch -notrace -source (Join-Path $PSScriptRoot 'build_task001b.tcl') -log (Join-Path $taskBuild 'final-build.log') -journal (Join-Path $taskBuild 'final-build.jou') *> (Join-Path $taskEvidence 'vivado-build-console.log')
if($LASTEXITCODE){throw 'Vivado build process failed'}
$taskAfter=Source-Hashes
if(($taskBefore|ConvertTo-Json -Compress) -ne ($taskAfter|ConvertTo-Json -Compress)){throw 'Sources changed during build; evidence does not describe final sources'}
Get-Content -LiteralPath (Join-Path $taskEvidence 'build-results.tsv')
# This orchestration intentionally ends at reviewed implementation. Bitstream
# generation/programming requires the distinct physical + PS7 + timing gates.
