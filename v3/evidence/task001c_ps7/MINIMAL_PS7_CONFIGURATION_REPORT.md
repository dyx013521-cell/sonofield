# Minimal safe PS7 configuration / STOP_BEFORE_BITSTREAM

Date: 2026-10-02T22:07:40.765188+08:00. Input baseline: `c3147d9aa8287bea0be876ad127237d53042619b`.
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
