"""Document the completed read-only preflight, never fabricate PS7 release.

Run only after check_dual_hardware.tcl and audit_ps7_preflight.tcl.
PS clock remains unknown in the supplied sources; no Vivado IP was created.
"""
import csv
import hashlib
import json
import re
from datetime import datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]
dest = root / 'evidence/task001c_ps7'
first = root / 'evidence/task001d_first_board'
dest.mkdir(parents=True, exist_ok=True)
first.mkdir(parents=True, exist_ok=True)
stamp = datetime.now().astimezone().isoformat()
base = 'c3147d9aa8287bea0be876ad127237d53042619b'

def save(folder, name, value):
    if not isinstance(value, str):
        value = json.dumps(value, ensure_ascii=False, indent=2) + '\n'
    (folder / name).write_text(value, encoding='utf-8')

rows = list(csv.DictReader((dest / 'current-pin-audit.tsv').open(), delimiter='\t'))
assert len(rows) == 38
mapping = json.loads((root / 'docs/array_gpio_mapping.json').read_text(encoding='utf-8'))
for role in ('master', 'slave'):
    selected = [r for r in rows if r['role'] == role]
    assert len(selected) == 19
    assert {r['port']: r['ball'] for r in selected} == {r[0]: r[3] for r in mapping['selected']}
    assert all(r['bank'] == '35' and r['iostandard'] == 'LVCMOS33' and
               r['drive'] == '4' and r['slew'] == 'SLOW' and r['result'] == 'PASS'
               for r in selected)
    text = (dest / f'{role}-preflight.txt').read_text()
    assert 'PS7_CELL_COUNT=0' in text and 'N18=N18' in text
    for port, ball in {'sync_clk':'N20','sync_data':'M18','sync_valid':'M20','sync_reset':'L17',
                       'sync_lock':'M17','sync_echo':'M19','trigger_out':'P20','waveform_out':'R19'}.items():
        assert f'PIN_{port}={ball}\n' in text

probe = dict((r['key'], r['value']) for r in csv.DictReader(
    (dest / 'hardware_check/vivado-probe-status.tsv').open(), delimiter='\t'))
assert probe['hw_target_count'] == '2' and probe['expected_xc7z010_count'] == '2'
assert probe['probe_error_count'] == '0' and probe['programmed'] == 'false'
devices = (dest / 'hardware_check/hw-devices.txt').read_text()
props = (dest / 'hardware_check/hw-properties.txt').read_text()
boards = []
for serial, role in [('210299245711','MASTER'),('210299835073','SLAVE')]:
    match = re.search(rf'^TARGET=([^\n]*{serial}) INDEX=1 DEVICE=([^ ]+) PART=xc7z010$', devices, re.M)
    assert match
    device = match[2]
    block = re.search(rf'^OBJECT={re.escape(device)}\n(.*?)(?=^OBJECT=|\Z)', props, re.M | re.S)[1]
    parsed = dict(line.split('=', 1) for line in block.splitlines()
                  if re.match(r'^[A-Z][A-Z0-9_.()\[\]-]*=', line))
    boards.append(dict(role=role,jtag=serial,device=device,part=parsed['PART'],
        idcode_hex=parsed['IDCODE_HEX'],config_status_binary=parsed['REGISTER.CONFIG_STATUS'],
        boot_status_binary=parsed['REGISTER.BOOT_STATUS'],
        done=int(parsed['REGISTER.CONFIG_STATUS.BIT14_DONE_PIN']),
        eos=int(parsed['REGISTER.CONFIG_STATUS.BIT04_END_OF_STARTUP_(EOS)_STATUS']),
        crc_error=int(parsed['REGISTER.CONFIG_STATUS.BIT00_CRC_ERROR']),
        pl_mode_m2_m1_m0=''.join(parsed[f'REGISTER.CONFIG_STATUS.BIT{10-i:02d}_MODE_PIN_M[{2-i}]'] for i in range(3)),
        ps_boot_mode='UNKNOWN',ps_boot_mode_register_available=False,
        observation_scope='EXISTING_CONFIGURATION_NOT_SONOFIELD_PROGRAM_RESULT'))

facts = dict(CAPTURED_AT=stamp, SOURCE='USER_CONFIRMED_TWO_PHASE_TASK',
    BOARD1_ROLE='MASTER',BOARD2_ROLE='SLAVE',BOARD1_JTAG='210299245711',BOARD2_JTAG='210299835073',
    BOARD1_UART='COM7',BOARD2_UART='OPTIONAL_DEBUG_NOT_BLOCKING',
    BANK35_VCCO_VOLTS=3.3,BANK_VCCO_MEASURED=True,BANK_VCCO_PASS=True,
    BANK_VCCO_EVIDENCE='USER_CONFIRMED_MEASUREMENT_PLUS_CURRENT_19_PIN_DEVICE_DATABASE_AUDIT',
    ARRAY_GPIO_COUNT_PER_BOARD=19,ALL_ARRAY_GPIO_BANK35=True,
    COMMON_GROUND_CONFIRMED=True,VGA_MODULE_ATTACHED=False,CAMERA_MODULE_ATTACHED=False,
    N18_FREQUENCY_HZ=50000000,PS_CLK_FREQUENCY_HZ=None,
    PS_CLK_SOURCE='REQUIRES_PHYSICAL_CONFIRMATION',PS_CLOCK_FACT_ESTABLISHED=False,
    PCB_CONNECTED=None,PCB_CONNECTION_STATUS='PCB_CONNECTION_REQUIRES_USER_CONFIRMATION',
    ACTUAL_P5_GND_SEATING_CHECKED=False)
save(dest,'CONFIRMED_HARDWARE_FACTS.json',facts)
save(dest,'board-read-only-status.json',dict(CAPTURED_AT=probe['captured_at'],PROGRAMMED=False,
    DEVICE_REFRESH=False,BOARD_RESET=False,BOARDS=boards))

configuration = dict(STATUS='NOT_CREATED_BLOCKED_PS_CLOCK_FACT',PART='xc7z010clg400-1',
    PROCESSING_SYSTEM7_0_EXISTS=False,FOREIGN_PRESET_USED=False,PS_CLK_FREQUENCY_HZ=None,
    ACTUAL_IP_PROPERTIES=None,CONFIGURATION_SHA256=None,
    PL_CLOCK_SOURCE='MASTER_N18_X5_50MHZ_SLAVE_P5_FORWARDED_CLOCK',
    PROPOSED_PS_INTERFACES='GP_HP_ACP_IRQ_EMIO_FCLK_FCLK_RESET_UNUSED_BY_SONOFIELD',
    DDR_INTERFACE_CONFIGURATION='NOT_DECIDED_NO_IP_CREATED',
    NO_SONOFIELD_DDR_DEPENDENCY=True,NO_PS_TO_PL_FUNCTIONAL_DEPENDENCY=True,
    PL_ARRAY_ARM_RTL=0,PL_OUTPUT_DISABLE_RTL=1,
    PS7_INIT_RUN=False,PS7_POST_CONFIG_RUN=False,FSBL_CREATED=False,BOOT_MEDIA_WRITTEN=False,
    NOTE='Proposed disabled interfaces are not claimed as applied IP properties.')
save(dest,'PS7_CONFIGURATION.json',configuration)
release = dict(TASK='TASK-001C / MINIMAL_SAFE_PS7_CONFIGURATION',CAPTURED_AT=stamp,
    BASELINE_COMMIT=base,STATUS='MINIMAL_PS7_NOT_READY',STOP_STATE='STOP_BEFORE_BITSTREAM',
    BLOCKERS=['BLOCKED_PS_CLOCK_FACT','PS7_NOT_CREATED','PS_BOOT_MODE_AND_FIRMWARE_UNKNOWN'],
    PHASE_A_RELEASED=False,READY_FOR_FIRST_VOLATILE_JTAG_BITSTREAM=False,
    PS_CLOCK_FACT_ESTABLISHED=False,PS_CLK_FREQUENCY_HZ=None,
    PROCESSING_SYSTEM7_0_EXISTS=False,PS7_IMPLEMENTED=False,ZPS7_1_CLOSED=False,
    ARRAY_GPIO_CHANGED=False,P5_CHANGED=False,N18_CHANGED=False,
    BANK_VCCO_MEASURED=True,BANK_VCCO_PASS=True,COMMON_GROUND_CONFIRMED=True,
    VGA_MODULE_ATTACHED=False,CAMERA_MODULE_ATTACHED=False,
    BOARD1_BOOT_MODE='UNKNOWN',BOARD2_BOOT_MODE='UNKNOWN',
    BOOT_MODE_SOURCE='READ_ONLY_REGISTER',PS_BOOT_MODE_REGISTER_AVAILABLE=False,
    EXISTING_PS_FIRMWARE='UNKNOWN',EXISTING_FIRMWARE_INITIALIZES_MIO='POSSIBLE',
    EXISTING_FIRMWARE_INITIALIZES_DDR='POSSIBLE',EXISTING_FIRMWARE_INITIALIZES_SLCR='POSSIBLE',
    EXISTING_FIRMWARE_BEHAVIOR_OBSERVED=False,
    PHASE_A_SIMULATIONS='NOT_RUN',PHASE_A_SYNTHESIS='NOT_RUN',PHASE_A_IMPLEMENTATION='NOT_RUN',
    PHASE_A_DRC_ERRORS=None,PHASE_A_CDC_CRITICAL=None,PHASE_A_TIMING=None,
    BASELINE_RESULTS_SOURCE='task001b/PRE_PCB_SERIALIZER_STATUS.json',
    NOTE='No new implementation exists. Prior TASK-001B PASS results do not satisfy Phase-A gates.')
save(dest,'PS7_RELEASE_STATUS.json',release)
save(dest,'BOOT_MODE_REPORT.md',f'''# Boot mode read-only report / TASK-001C

Capture: {probe['captured_at']}; Vivado 2025.2; both exact serial targets opened.
2 targets / 2 XC7Z010 / 4 chain devices / 0 probe errors. No refresh, reset,
programming, ARM control, register write, boot-media read/write or PS init.

| Board | Cable | FPGA IDCODE | Existing DONE | EOS | CRC_ERROR | PL MODE M2:M0 | PS boot mode |
|---|---|---|---:|---:|---:|---|---|
| Master | {boards[0]['jtag']} | {boards[0]['idcode_hex']} | {boards[0]['done']} | {boards[0]['eos']} | {boards[0]['crc_error']} | 111 | UNKNOWN |
| Slave | {boards[1]['jtag']} | {boards[1]['idcode_hex']} | {boards[1]['done']} | {boards[1]['eos']} | {boards[1]['crc_error']} | 111 | UNKNOWN |

Both existing PL CONFIG_STATUS = 0x{int(boards[0]['config_status_binary'],2):08X};
PL BOOT_STATUS = 0x00000001. These are existing configuration observations;
they neither prove SonoField was programmed nor identify the PS boot device.
Raw properties are in hardware_check/hw-properties.txt; structured extraction
is in board-read-only-status.json.

BOOT_MODE_SOURCE=READ_ONLY_REGISTER describes the attempted inspection.
The actual PS sampled BOOT_MODE register is **not exposed** in these Hardware
Manager properties. BOARD1_BOOT_MODE=UNKNOWN; BOARD2_BOOT_MODE=UNKNOWN.
Do not interpret PL M[2:0]=111 as the PS boot mode, or PL BOOT_STATUS as PS
boot mode. [UG585 boot straps](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Boot-Mode-Pin-Settings)
use MIO[8:2], and the [PS BOOT_MODE register](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Register-BOOT_MODE-Details)
holds the PS sampled fields. Schematic drawn MIO[5:3]=010 suggests NAND only
if the resistor population is as drawn; actual mode remains unconfirmed.

U12 W29N01HVSINA NAND and U66 x16 DDR are drawn. Optional TF socket U7 is
NC; no populated QSPI/eMMC is established. No boot content was inspected:
EXISTING_PS_FIRMWARE=UNKNOWN, not NONE. MIO/DDR/SLCR initialization remains
POSSIBLE / NOT_OBSERVED under a possible boot flow, not confirmed.
[UG585 JTAG boot](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/JTAG-Slave-Boot)
describes minimal BootROM setup in JTAG mode; it does not establish that these
boards currently boot in that mode. [UG585 PL configuration](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/PL-Configuration-Considerations)
permits PS software PCAP configuration; unknown running firmware therefore
requires review before a volatile PL release. No assertion of active PCAP
interference or firmware execution is made.
''')
save(dest,'PS_PL_BOUNDARY_REPORT.md','''# Current PL boundary / not a PS7 implementation

Current RTL has no PS7 instance, AXI GP/HP/ACP, PS IRQ/EMIO/DMA requests,
PS FCLK or FCLK_RESET connection. NO_PS_TO_PL_FUNCTIONAL_DEPENDENCY=true
and NO_SONOFIELD_DDR_DEPENDENCY=true describe the existing PL datapath.
The physical SoC still contains hard ARM/DDR/DMA/peripheral hardware; this
does not claim those modules are globally disabled or that existing firmware
is absent. No live SLCR or PS isolation register state was read.

Master N18 -> MMCM -> PL -> ODDR -> P5/N20; Slave uses P5/N20 for MMCM/time
and N18 for independent watchdog. Local G19 reset and P5 link reset form RUN.
PS resets are not wired into the current functional datapath. Arm remains
constant 0, output_disable constant 1 in the PRE-PCB RTL. This describes RTL,
not a measured pin voltage on a newly programmed device.

Both existing routed checkpoints were opened read-only. current-pin-audit.tsv
contains 19 Bank35/LVCMOS33/DRIVE4/SLOW rows per board. Both fixed-pin database
reports identify PS_CLK E7, PS_POR_B C7, PS_SRST_B B10, MIO Bank500/501 and
dedicated DDR Bank502; none is a selected array ball. Both preflight files
confirm current N18/P5 mapping and PS7_CELL_COUNT=0. No physical pins changed.

[UG585 level-shifter boundary](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/PS-PL-Voltage-Level-Shifter-Enables)
requires PS power for PL programming and describes SLCR/PL-power control.
Functional independence alone does not prove current firmware cannot control
PL configuration or power. PS clock and boot behavior remain release gates.
No dummy PS7 primitive or unknown preset was inserted to hide ZPS7-1.
''')
save(dest,'PS7_DRC_REPORT.md','''# PS7 DRC gate / NOT_RUN

No PS7 IP/configuration or new implementation exists because PS_CLK is
unknown. No fresh Phase-A DRC result or write_bitstream DRC is available.
ZPS7-1 remains unclosed; neither severity downgrade nor rule suppression was
used. Both existing routed checkpoints contain zero PS7 cells.

Historical TASK-001B DRC Error=0 is documented in the prior reports, whose
ZPS7-1 warning remains a release blocker. That result is not a Phase-A PASS.
''')
save(dest,'PS7_TIMING_REPORT.md','''# PS7 timing gate / NOT_RUN

No new synthesis/opt/place/phys_opt/route exists. No Phase-A setup/hold value,
timing delta or effect attributable to PS7 can be reported.

| Historical TASK-001B baseline | Setup ns | Hold ns |
|---|---:|---:|
| Master | 0.494 | 0.007 |
| Slave | 0.430 | 0.015 |

These are prior implementation values, not rerun results. The PL RTL and
XDC are unchanged. Actual N18 remains 50 MHz; PS clock remains separate and
unknown. No false paths, clock groups, routing overrides or FCLK replacement
were introduced. Four fresh simulations and both fresh implementations are
still required after a justified PS7 profile is created.
''')
save(dest,'PS7_CDC_REPORT.md','''# PS7 CDC gate / NOT_RUN

No new PS7 implementation or fresh CDC report exists. Historical TASK-001B
CDC Critical=0 is not a Phase-A gate result. The current functional design
has no PS/PL crossing because no PS functional interface exists in RTL.
Slave N18 watchdog/received clock relationship remains independently reviewed
under prior TIMING-6/7 dispositions; no new exception hides those notices.
''')
save(dest,'MINIMAL_PS7_CONFIGURATION_REPORT.md',f'''# Minimal safe PS7 configuration / STOP_BEFORE_BITSTREAM

Date: {stamp}. Input baseline: `{base}`.
**STATUS=MINIMAL_PS7_NOT_READY; PHASE_A_RELEASED=false.**
**Blocking fact: actual PS_CLK source/frequency is not established.**

The task's A12 and stop rule require stopping release when PS_CLK is unknown.
The source review found dedicated E7/CLK, an optional X8 33.333 MHz path via
NC R2340, and a hardware note describing X8 as unpopulated. N18/X5 50 MHz is
an independently confirmed PL clock and cannot substitute for PS_CLK.
[Complete hardware facts](../../docs/EBAZ4205_PS7_FACTS.md).

## Completed independent preflight

- Read current project documents, RTL, constraints and Vivado scripts; confirmed baseline HEAD.
- Re-read/rendered core schematic and inspected PS clock/reset, boot/NAND, MIO, DDR, TF and PHY regions.
- Read AMD UG585 boot straps, sampled register, JTAG boot, level shifters and PL configuration rules.
- Opened both exact JTAG targets read-only: 2 XC7Z010, FPGA IDCODE 13722093, zero probe errors.
- Recorded existing DONE/EOS=1, CRC_ERROR=0; these are not new-program results.
- Reopened both existing routed checkpoints read-only; checked all 38 board/signal assignments.
- Each board's 19 array GPIO still Bank35/LVCMOS33/DRIVE4/SLOW; N18/P5 mapping unchanged.
- Recorded user-confirmed measured Bank35 3.3 V, common ground, removed VGA/Camera and roles/cables/UART.

## Configuration and release gates

processing_system7_0 was **not created**. No foreign-board preset, guessed PS
frequency, dummy primitive or severity change was used. Actual enabled/disabled
IP properties, DDR interface mode and configuration hash are unavailable.
The proposed profile has all SonoField GP/HP/ACP/IRQ/EMIO/FCLK dependencies
absent, but proposed settings are not claimed as implemented settings.

Existing PL continues its N18/P5 architecture; no PS software/AXI/DDR/reset
dependency appears in RTL. PRE-PCB arm=0, output_disable=1 remains the RTL
default. No PS initialization/post_config, FSBL, CPU executable, register
write, boot-media write, bitstream generation or programming occurred.
ARRAY_GPIO_CHANGED=false; P5_CHANGED=false; N18_CHANGED=false.

Four Phase-A simulations, both syntheses and implementations, and fresh
DRC/STA/CDC/methodology gates are **NOT_RUN**. Historical TASK-001B PASS values
remain separately documented; no old report was relabeled as Phase-A.
ZPS7-1 has not been eliminated. Read [DRC](PS7_DRC_REPORT.md),
[timing](PS7_TIMING_REPORT.md), [CDC](PS7_CDC_REPORT.md),
[boundary](PS_PL_BOUNDARY_REPORT.md), [boot review](BOOT_MODE_REPORT.md) and
[machine gate](PS7_RELEASE_STATUS.json).

## Resume requirement

Establish each actual board's E7/CLK source/frequency and the relevant X8/R2340
population or alternative wiring; do not infer it from JTAG/DONE/N18.
Then create a reproducible minimal board-specific PS7 profile, audit its
dedicated boundaries, run all fresh software gates and assess unknown boot
firmware's ability to affect volatile PL configuration. Phase-B is authorized
only after READY_FOR_FIRST_VOLATILE_JTAG_BITSTREAM is explicitly achieved.
No further programming approval is requested; the missing item is hardware
evidence required by the user's task. Board2 UART is not a blocker.
''')

bstatus = dict(TASK='TASK-001D / FIRST_VOLATILE_JTAG_PRE_PCB_BRINGUP',CAPTURED_AT=stamp,
    STATUS='NOT_STARTED_PHASE_A_RELEASE_BLOCKED',MINIMAL_PS7_RELEASED=False,
    BOARD1_ROLE='MASTER',BOARD2_ROLE='SLAVE',BOARD1_JTAG='210299245711',BOARD2_JTAG='210299835073',
    BANK35_VCCO_CONFIRMED=True,COMMON_GROUND_CONFIRMED=True,VGA_MODULE_ATTACHED=False,
    CAMERA_MODULE_ATTACHED=False,N18_FREQUENCY_HZ=50000000,
    PS7_CONFIGURATION_SHA256=None,MASTER_BITSTREAM_SHA256=None,SLAVE_BITSTREAM_SHA256=None,
    MASTER_BITSTREAM_GENERATED=False,SLAVE_BITSTREAM_GENERATED=False,
    MASTER_PROGRAMMED=False,SLAVE_PROGRAMMED=False,
    MASTER_DONE=None,SLAVE_DONE=None,MASTER_MMCM_LOCKED=None,SLAVE_MMCM_LOCKED=None,
    P5_SYNC_LOCK=None,TASK001_LEVEL0='NOT_TESTED',LOGICAL_TIMESTAMP_ALIGNMENT=None,
    SERIALIZER_ALL_ZERO_PASS=None,SERIALIZER_WALKING_ONE_PASS=None,SERIALIZER_1010_PASS=None,
    OUTPUT_DISABLE_DEFAULT_SAFE=None,OUTPUT_DISABLE_DEFAULT_SAFE_RTL=True,
    P1_P2_OUTPUT_MEASURED=False,SHIFT_CLOCK_MEASURED=False,LATCH_CLOCK_MEASURED=False,
    SERIAL_DATA_MEASURED=False,PCB_CONNECTED=None,
    PCB_CONNECTION_STATUS='PCB_CONNECTION_REQUIRES_USER_CONFIRMATION',
    FPGA_PRE_PCB_HARDWARE_VERIFIED=False,READY_FOR_PCB_CONNECTION=False,
    PCB_TESTED=False,CHANNEL128_PHYSICAL_VERIFIED=False,ACOUSTIC_VERIFIED=False,LEVITATION_VERIFIED=False,
    BLOCKERS=['PHASE_A_NOT_RELEASED','BLOCKED_PS_CLOCK_FACT'],
    NOTE='null hardware result means NOT_OBSERVED, not a measured failure. Prior DONE is reported only in Phase-A boot report.')
save(first,'FIRST_VOLATILE_JTAG_STATUS.json',bstatus)
save(first,'FIRST_VOLATILE_JTAG_REPORT.md','''# First volatile JTAG bringup / NOT_STARTED

Phase-A is MINIMAL_PS7_NOT_READY / BLOCKED_PS_CLOCK_FACT. Its strict release
gate is false, so Phase-B was not entered. No .bit or new .ltx, configuration
hash, program result, MMCM capture, P5 synchronization capture or serializer
ILA frame exists for this phase. No board reset or PS initialization was run.
Existing configured-device DONE/EOS/CRC properties appear only in the Phase-A
read-only boot report and are not new SonoField program results.

Bank35 measured 3.3 V, common ground, removed VGA/Camera and N18 50 MHz are
USER_CONFIRMED. Current 19 GPIO per board remain device-database verified
Bank35. Board2 UART remains optional and does not block this task.
Arm=0/output_disable=1 remains the RTL default, with no newly programmed pin
measurement. P1/P2 shift/latch/data/disable measurements, 2.5 MHz burst pulse
width/levels/edges/setup/hold, common logical APPLY and physical latch skew,
P5 GND seating and manual loss/recovery tests remain unperformed.

PCB_CONNECTED=null because software cannot establish actual connection;
PCB_CONNECTION_REQUIRES_USER_CONFIRMATION. The intended test leaves the PCB
disconnected. READY_FOR_PCB_CONNECTION=false; no AXC/595/physical channel,
PCB, acoustic or levitation verification is claimed.

Resume only after the [Phase-A gate](../task001c_ps7/PS7_RELEASE_STATUS.json)
becomes READY_FOR_FIRST_VOLATILE_JTAG_BITSTREAM. The user already authorized
volatile PL JTAG with identity and release gates; no new approval is needed
for that same scope. Permanent boot media and PS software remain excluded.
''')

manifest = {}
for p in sorted(dest.rglob('*')):
    if p.is_file() and p.name != 'evidence-sha256.json':
        manifest[p.relative_to(dest).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
save(dest,'evidence-sha256.json',manifest)
print(json.dumps(dict(STATUS=release['STATUS'],ARRAY_PIN_ROWS=len(rows),BOARDS=boards),ensure_ascii=False))
