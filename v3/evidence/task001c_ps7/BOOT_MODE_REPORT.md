# Boot mode read-only report / TASK-001C

Capture: 2026-10-02T21:53:40+0800; Vivado 2025.2; both exact serial targets opened.
2 targets / 2 XC7Z010 / 4 chain devices / 0 probe errors. No refresh, reset,
programming, ARM control, register write, boot-media read/write or PS init.

| Board | Cable | FPGA IDCODE | Existing DONE | EOS | CRC_ERROR | PL MODE M2:M0 | PS boot mode |
|---|---|---|---:|---:|---:|---|---|
| Master | 210299245711 | 13722093 | 1 | 1 | 0 | 111 | UNKNOWN |
| Slave | 210299835073 | 13722093 | 1 | 1 | 0 | 111 | UNKNOWN |

Both existing PL CONFIG_STATUS = 0x46107FFC;
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
