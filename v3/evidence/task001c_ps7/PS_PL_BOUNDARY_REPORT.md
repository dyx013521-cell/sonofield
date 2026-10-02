# Current PL boundary / not a PS7 implementation

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
