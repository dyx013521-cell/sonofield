# EBAZ4205 PS7 hardware facts / TASK-001C

Date: 2026-10-02. Baseline commit: c3147d9aa8287bea0be876ad127237d53042619b.
Sources: core schematic `references/4205.pdf`, page 1, visually reviewed again;
`EBAZ4205_硬件说明.md`; current RTL/XDC; the user's two-phase task.
Schematic labels establish wiring and intended component options, not actual
population or measured activity. No PS initialization or board reset was run.

## Release-critical clock finding

U31B dedicated **PS_CLK = E7**, net **CLK**, is separate from PL N18/X5.
The drawing shows X8 marked 33.333 MHz, but **R2340 between X8 and CLK is NC**;
X8 enable option resistors R2389/R2391 are also NC. The supplied hardware note
explicitly describes X8 as unpopulated. This is an optional source description,
not evidence of a live 33.333 MHz PS clock on either connected board.
Neither PL DONE nor successful JTAG enumeration measures PS_CLK.
No other established live source for CLK is identified in the supplied drawing.

**PS_CLK_SOURCE = REQUIRES_PHYSICAL_CONFIRMATION; PS_CLK_FREQUENCY_HZ = null.**
**BLOCKED_PS_CLOCK_FACT / STOP_BEFORE_BITSTREAM.** Do not put 33.333 or N18's
50 MHz into a PS7 profile to bypass this finding. Confirm both actual boards'
E7/CLK clock and source/population before creating the release configuration.

## Fact table

| Item | Finding | Classification |
|---|---|---|
| FPGA | U31 XC7Z010-1CLG400I; Vivado xc7z010clg400-1 | CONFIRMED_SCHEMATIC |
| PS_CLK input | U31B E7 / CLK; separate dedicated PS input | CONFIRMED_SCHEMATIC |
| PS_CLK actual source / frequency | Optional X8 33.333 MHz via NC R2340; no verified live source | REQUIRES_PHYSICAL_CONFIRMATION |
| PL reference | N18/X5 50 MHz, 20 ns; used by current Master and Slave watchdog | CONFIRMED_HARDWARE (USER_CONFIRMED) |
| PS_POR_B | C7 / RESET.0; 100k pull-up R2432; U65 reset supervisor outputs RESET.0/RESET.1 | CONFIRMED_SCHEMATIC |
| PS_SRST_B | B10 / R2430 100k to VCC | CONFIRMED_SCHEMATIC |
| Boot straps | MIO[8:2]; NAND-related 20k pull options R2577..R2590; multiple alternatives NC | CONFIRMED_SCHEMATIC |
| Current sampled PS boot mode | Not exposed by current Hardware Manager properties; actual population unconfirmed | REQUIRES_PHYSICAL_CONFIRMATION |
| MIO wiring | U31A dedicated PS MIO; NAND plus optional TF/other connector nets; not PL array IO | CONFIRMED_SCHEMATIC |
| DDR device / wiring | U66 EM6GD16EWKG-12H; x16 DQ0..15, two byte strobes, dedicated PS DDR; upper DQ16..31 unconnected in drawing | CONFIRMED_SCHEMATIC |
| DDR physical population / initialization | Drawing alone does not prove either actual board population or running firmware | REQUIRES_PHYSICAL_CONFIRMATION |
| SonoField DDR access | No PS/AXI/DDR path in current PL RTL | NOT_USED |
| NAND | U12 W29N01HVSINA, 8-bit IO[7:0], CE/RE/WE/ALE/CLE/RB wired to MIO | CONFIRMED_SCHEMATIC |
| Existing NAND content | No media read or write performed; firmware existence/content unknown | REQUIRES_PHYSICAL_CONFIRMATION |
| QSPI | No dedicated populated QSPI device established by supplied schematic | NOT_AVAILABLE (IN SUPPLIED SCHEMATIC) |
| SD / TF | U7 socket and several pulls/capacitors marked NC; MIO connector wiring exists | CONFIRMED_SCHEMATIC (OPTIONAL) |
| eMMC | No eMMC device established by supplied schematic | NOT_AVAILABLE (IN SUPPLIED SCHEMATIC) |
| Ethernet | U24 IP101GA, Y3 25 MHz, RJ45; MII signals use PL balls, e.g. U14/U15/U18, not evidence of a direct PS MIO Ethernet interface | CONFIRMED_SCHEMATIC / NOT_USED |
| USB | No USB PHY/connector path established by supplied core schematic; host USB-JTAG is separate | NOT_AVAILABLE (IN SUPPLIED SCHEMATIC) |
| UART | Board1 COM7 user-confirmed; expansion UART/header path is PL networking, not proof of enabled PS UART | CONFIRMED_HARDWARE (HOST PORT) / NOT_USED (PS UART) |
| PS power | Dedicated VCCPINT/VCCPAUX/VCCPLL/MIO supply pins shown on U31D; board rails require individual tracing, not Bank35 extrapolation | CONFIRMED_SCHEMATIC (PINS) / REQUIRES_PHYSICAL_CONFIRMATION (LIVE RAILS) |
| DDR power | VCC-DDR, U27/L32/TP2 VDD_1V5; dedicated VREF resistor networks | CONFIRMED_SCHEMATIC |
| PL Bank35 power | C19/H14/J17/K20/M16/N19 -> VCCB -> R2460 0R -> VCC -> U22/L7/TP1 3V3 | CONFIRMED_SCHEMATIC |
| Bank35 actual voltage | 3.3 V measurement confirmed by user; applies only to unchanged 19 Bank35 array balls | CONFIRMED_HARDWARE (USER_CONFIRMED) |
| Ground | Two EBAZ and future PCB common ground user-confirmed; actual P5/1 seating still needs first-use check | CONFIRMED_HARDWARE (USER_CONFIRMED) |
| Parallel modules | VGA and Camera removed by user; hardwired LED/resistor/parallel traces remain | CONFIRMED_HARDWARE (USER_CONFIRMED) |
| PS / PL reset relationship | Dedicated PS reset is distinct from PL rst_n/G19; current PL RUN derives local reset/MMCM/link reset, never FCLK_RESET | CONFIRMED_SCHEMATIC / NOT_USED (PS RESET TO SONOFIELD) |
| PS / PL level shifters | Hard device boundary; most controlled by SLCR LVL_SHFTR_EN, some by PL power; live register state not read | REQUIRES_PHYSICAL_CONFIRMATION (LIVE STATE) |
| PL configuration relationship | PS must be powered for PL programming; boot firmware can use PCAP; previous DONE does not identify firmware/source | REQUIRES_PHYSICAL_CONFIRMATION (CURRENT PS BEHAVIOR) |

## Required AMD interpretation

The exact-part database read from both existing routed checkpoints confirms
E7=PS_CLK_500, C7=PS_POR_B_500, B10=PS_SRST_B_501. It maps boot pins as:

| MIO | Ball | Schematic net | UG585 meaning |
|---:|---|---|---|
| 2 | B8 | ALE; NC pull options | BOOT_MODE[3], chain selection |
| 3 | D6 | NAND WE; R2587 20k down, R2579 NC up | BOOT_MODE[1] |
| 4 | B7 | NAND IO2; R2578 20k up, R2589 NC down | BOOT_MODE[2] |
| 5 | A6 | NAND IO0; R2584 20k down, R2577 NC up | BOOT_MODE[0] |
| 6 | A5 | NAND IO1; R2588 20k down, R2581 NC up | PLL_BYPASS |
| 7 | D8 | NAND CLE | VMODE[0] |
| 8 | D5 | NAND RE | VMODE[1] |

With the drawn resistor population, MIO[5:3]=010 is a **schematic NAND boot
candidate** under UG585. This is not the current sampled mode of either board:
actual resistor population, optional NCs and the PS BOOT_MODE register were
not established. Two chain devices per cable (Arm DAP and FPGA TAP) establish
current cascade-chain visibility, not the boot device or existing firmware.

[UG585 Boot Mode Pin Settings](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Boot-Mode-Pin-Settings)
maps MIO[8:2] to VMODE and BOOT_MODE, sampled after PS_POR_B.
[UG585 BOOT_MODE register](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Register-BOOT_MODE-Details)
is the PS sampled mode register; Hardware Manager's PL BOOT_STATUS and
CONFIG_STATUS MODE_PIN_M fields cannot substitute for it.
[UG585 PS–PL Level Shifter Enables](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/PS-PL-Voltage-Level-Shifter-Enables)
describes the boundary and PS power requirement. No SLCR writes are authorized
or necessary for this preflight. Current existing firmware is UNKNOWN.

## Configuration plan, not an implemented IP

After the clock fact is established, create processing_system7_0 explicitly
with Vivado IP properties, no board preset. Audit every disabled GP/HP/ACP,
IRQ, EMIO, FCLK/reset and project peripheral against the actual installed IP.
Retain an independent existing PL core and N18/P5 clock path. Dedicated MIO,
DDR, E7/C7/B10 must not receive PL PACKAGE_PIN/IOSTANDARD assignments.
DDR interface disable/support must be established from Vivado and AMD rules,
not fabricated memory timing. No PS software, initialization, FSBL or boot
media write is part of this task. As of this preflight no PS7 IP is created,
no wrapper interface changes are made, and ZPS7-1 is not closed.
