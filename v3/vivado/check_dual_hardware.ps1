#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$VivadoBin = 'D:\amd2025_2\2025.2\Vivado\bin',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../evidence/task001/hardware_check')
)
$ErrorActionPreference = 'Stop'
$outdir = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outdir -Force | Out-Null
if (Test-Path -LiteralPath (Join-Path $outdir 'hardware-check-summary.json')) {
    throw 'Evidence already exists; use -OutputDirectory with a new directory for a new scan.'
}
$errors = [Collections.Generic.List[string]]::new()
function Capture-Query([string]$Name, [scriptblock]$Query) {
    try { $items = @(& $Query); return ,$items }
    catch { $errors.Add("$Name : $($_.Exception.Message)"); return ,@() }
}
function Save-Text([string]$Name, $Value) {
    $Value | Out-String -Width 4096 | Set-Content -LiteralPath (Join-Path $outdir $Name) -Encoding utf8
}
function Save-Json([string]$Name, $Value) {
    ConvertTo-Json -InputObject $Value -Depth 15 | Set-Content -LiteralPath (Join-Path $outdir $Name) -Encoding utf8
}
$started = [DateTimeOffset]::Now
$present = Capture-Query 'Get-PnpDevice -PresentOnly' { Get-PnpDevice -PresentOnly }
$entities = Capture-Query 'Win32_PnPEntity' { Get-CimInstance Win32_PnPEntity |
    Where-Object { $_.Name -match 'Xilinx|AMD|FTDI|JTAG|USB Serial|UART|COM[0-9]+' } }
$controllers = Capture-Query 'Win32_USBControllerDevice' { Get-CimInstance Win32_USBControllerDevice }
$serial = Capture-Query 'Win32_SerialPort' { Get-CimInstance Win32_SerialPort }
$drivers = Capture-Query 'Win32_PnPSignedDriver' { Get-CimInstance Win32_PnPSignedDriver |
    Where-Object { $_.DeviceID -match '^(USB|FTDIBUS)\\' -or $_.DeviceName -match 'Xilinx|FTDI|JTAG' } }
$usb = @($present | Where-Object { $_.InstanceId -match '^(USB|FTDIBUS)\\' })
$ports = @($present | Where-Object { $_.Class -eq 'Ports' })
$uart = @($ports | Where-Object { $_.InstanceId -match '^(USB|FTDIBUS)\\' })
$jtagCandidates = @($present | Where-Object { $_.FriendlyName -match 'Xilinx|Digilent|JTAG|Platform Cable|FT2232|FT232H' -or
    $_.InstanceId -match 'VID_03FD|VID_0403&PID_(6010|6014)|VID_1443' })
$propertyRows = [Collections.Generic.List[object]]::new()
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($device in @($usb + $ports + $jtagCandidates)) {
    $next = $device.InstanceId
    for ($depth=0; $depth -lt 12 -and $next; $depth++) {
        if (-not $seen.Add($next)) { break }
        try {
            $properties = @(Get-PnpDeviceProperty -InstanceId $next)
            $map = [ordered]@{}
            foreach ($property in $properties) {
                if ($property.KeyName -match 'Parent|Location|HardwareIds|BusReported|FriendlyName|Manufacturer|ContainerId|SerialNumber|Service|Driver|ProblemCode') {
                    $map[$property.KeyName] = $property.Data
                }
            }
            $propertyRows.Add([ordered]@{InstanceId=$next;Properties=$map})
            $next = $map['DEVPKEY_Device_Parent']
        } catch { $errors.Add("PnP properties $next : $($_.Exception.Message)"); break }
    }
}
Save-Text 'windows-device-inventory.txt' ($present | Select-Object Status,Class,FriendlyName,InstanceId | Format-Table -Wrap)
Save-Json 'windows-device-inventory.json' @($present | Select-Object Status,Class,FriendlyName,InstanceId)
Save-Text 'matching-pnp-entities.txt' ($entities | Select-Object Name,PNPDeviceID,Status,ConfigManagerErrorCode | Format-List)
Save-Text 'usb-controller-associations.txt' ($controllers | Select-Object Antecedent,Dependent | Format-List)
Save-Json 'usb-properties.json' @($propertyRows)
Save-Text 'usb-device-tree.txt' ($propertyRows | ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 10 })
Save-Text 'serial-ports.txt' ($serial | Select-Object DeviceID,Name,PNPDeviceID,Status | Format-List)
Save-Text 'uart-devices.txt' ($uart | Select-Object Status,Class,FriendlyName,InstanceId | Format-List)
Save-Text 'jtag-usb-devices.txt' ($jtagCandidates | Select-Object Status,Class,FriendlyName,InstanceId | Format-List)
Save-Text 'usb-drivers.txt' ($drivers | Select-Object DeviceName,DeviceID,DriverProviderName,DriverVersion,InfName,IsSigned | Format-List)
Save-Text 'hw-server-before.txt' @(Get-CimInstance Win32_Process | Where-Object Name -Match '^(hw_server|vivado)\.exe$' |
    Select-Object Name,ProcessId,ExecutablePath,CommandLine | Format-List)
$vivado = Join-Path $VivadoBin 'vivado.bat'
if (-not (Test-Path -LiteralPath $vivado)) { throw "Vivado executable missing: $vivado" }
Push-Location $outdir
try {
    & $vivado -mode batch -notrace -source (Join-Path $PSScriptRoot 'check_dual_hardware.tcl') `
        -log (Join-Path $outdir 'vivado-hardware.log') -journal (Join-Path $outdir 'vivado-hardware.jou') -tclargs $outdir 2>&1 |
        Tee-Object -FilePath (Join-Path $outdir 'vivado-hardware-console.log')
    $vivadoExit = $LASTEXITCODE
} finally { Pop-Location }
$probe = [ordered]@{}
$probeStatus = Join-Path $outdir 'vivado-probe-status.tsv'
if (Test-Path -LiteralPath $probeStatus) {
    Import-Csv -LiteralPath $probeStatus -Delimiter "`t" | ForEach-Object { $probe[$_.key] = $_.value }
}
$devices = @()
$propertyFile = Join-Path $outdir 'hw-properties.txt'
if (Test-Path -LiteralPath $propertyFile) {
    $text = [IO.File]::ReadAllText($propertyFile)
    $devices = @([regex]::Matches($text, '(?ms)^OBJECT=([^\r\n]+)\r?\n(.*?)(?=^OBJECT=|\z)') | ForEach-Object {
        $values = [ordered]@{object=$_.Groups[1].Value}
        foreach ($line in ($_.Groups[2].Value -split '\r?\n')) {
            if ($line -match '^([A-Z][A-Z0-9_.()\[\]-]*)=(.*)$') { $values[$Matches[1]]=$Matches[2] }
        }
        if ($values['CLASS'] -eq 'hw_device') { $values }
    })
}
$fpgas = @($devices | Where-Object { $_['PART'] -match '^(xc|xa|xq)' })
Save-Text 'hw-server-after.txt' @(Get-CimInstance Win32_Process | Where-Object Name -eq 'hw_server.exe' |
    Select-Object Name,ProcessId,ExecutablePath,CommandLine | Format-List)
$summary = [ordered]@{
    started_at=$started.ToString('o'); completed_at=[DateTimeOffset]::Now.ToString('o')
    powershell_version=$PSVersionTable.PSVersion.ToString(); shell=(Get-Process -Id $PID).Path
    source_commit=(git -C (Join-Path $PSScriptRoot '../..') rev-parse HEAD)
    user_reported_topology=[ordered]@{jtag='Both PC-native USB direct';uart='Both USB dock'}
    present_device_count=$present.Count; usb_device_count=$usb.Count
    all_port_device_count=$ports.Count; usb_uart_device_count=$uart.Count
    jtag_usb_candidate_count=$jtagCandidates.Count
    uart_devices=@($uart | Select-Object Status,FriendlyName,InstanceId)
    jtag_usb_candidates=@($jtagCandidates | Select-Object Status,FriendlyName,InstanceId)
    vivado_exit_code=$vivadoExit; vivado_probe=$probe; query_errors=@($errors)
    hardware_devices=$devices; fpga_devices=$fpgas; fpga_device_count=$fpgas.Count
    expected_device_match=($fpgas.Count -eq 2 -and @($fpgas | Where-Object { $_['PART'] -ne 'xc7z010' }).Count -eq 0)
    full_package_speed_grade='REQUIRES_PHYSICAL_MEASUREMENT'
    jtag_uart_board_mapping='JTAG_AND_UART_BOARD_MAPPING_UNCONFIRMED'
    usb_physical_port_mapping='USB_PHYSICAL_PORT_MAPPING_REQUIRES_MANUAL_CONFIRMATION'
    readiness='NOT_READY_FOR_BITSTREAM'; programmed=$false; board_tested=$false; hardware_verified=$false
}
Save-Json 'hardware-check-summary.json' $summary
Save-Text 'query-errors.txt' @($errors)
Write-Output ('EVIDENCE_DIRECTORY='+$outdir)
Write-Output ('USB_UART_DEVICE_COUNT='+$uart.Count)
Write-Output ('VIVADO_EXIT_CODE='+$vivadoExit)
if ($vivadoExit -ne 0) { Write-Warning 'Probe incomplete; inspect errors. No programming was attempted.' }
