# Serializer pin map — both Board1/Master and Board2/Slave

19 outputs: 14 data on P1, 2 data plus 3 control outputs on P2; P3 unused,
P5_ARRAY_GPIO_COUNT=0. All are Bank35, schematic nominal 3.3V, not measured.
H20/J20/L19 replace three original LED outputs in the PRE-PCB wrappers only.
Their LEDs/resistors remain electrically connected. Physical board revision,
module absence and voltage confirmation are pending. Keep PCB disconnected.

| Logical signal | Connector | Physical pin | FPGA ball | Bank | IOSTANDARD |
|---|---|---:|---|---:|---|
| serial_data[0] | P1 | 5 | A20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[1] | P1 | 6 | H16 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[2] | P1 | 7 | B19 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[3] | P1 | 8 | B20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[4] | P1 | 9 | C20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[5] | P1 | 11 | H17 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[6] | P1 | 13 | D20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[7] | P1 | 14 | D18 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[8] | P1 | 15 | H18 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[9] | P1 | 16 | D19 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[10] | P1 | 17 | F20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[11] | P1 | 18 | E19 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[12] | P1 | 19 | F19 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[13] | P1 | 20 | K17 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[14] | P2 | 5 | G20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| serial_data[15] | P2 | 6 | J18 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| shift_clock | P2 | 8 | H20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| latch_clock | P2 | 14 | J20 | 35 | LVCMOS33 / DRIVE4 / SLOW |
| output_disable | P2 | 16 | L19 | 35 | LVCMOS33 / DRIVE4 / SLOW |

Each lane N sends CH[4N+3], CH[4N+2], CH[4N+1], CH[4N] on four rising
SRCLK edges. An actual 8-bit shift register then has CH[4N+i] in Qi (i=0..3),
with the preceding four values still in Q4..Q7. These upper outputs must be
unused. This is a behavioral-model mapping; actual PCB Q pin/channel wiring
and /OE polarity remain unconfirmed. No 595 SRCLR wire is assigned; the first
four-bit frame replaces Q0..Q3 even from an unknown prior shift register.
Pin numbers are schematic numbers; connector viewing orientation requires
silkscreen/continuity confirmation before physical wiring.
