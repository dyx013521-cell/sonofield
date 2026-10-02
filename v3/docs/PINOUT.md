# EBAZ4205 expansion V1.1 synchronization harness

Source: EBAZ4205_EXBOARD_20200313.pdf, page1, P5 symbol visually reviewed.
This corrects the attached summary: the drawing labels P4 Header9x2 (18 pins), NOT 10x2.
P5 is14x2 (28 pins). Confirm board revision, continuity and Bank3.3V before wiring.

| Net | Package ball | P5 pin | Master | Slave |
|---|---|---|---|---|
| SYNC_CLK | N20 | 7 | out | P-side SRCC clock input |
| SYNC_DATA | M18 | 3 | out | in |
| SYNC_VALID | M20 | 5 | out | in |
| SYNC_RESET (high=run) | L17 | 6 | out | in |
| SYNC_LOCK | M17 | 9 | in | out |
| SYNC_ECHO (added RTT return) | M19 | 8 | in | out |
| Scope scheduled trigger | P20 | 11 | out, scope only | out, scope only |
| Scope counter waveform | R19 | 13 | out, scope only | out, scope only |
| Ground | GND | 1 | common ground | common ground |

Never join the two boards' scope outputs to each other. P5/2 is3.3V, NOT GND.
N18 is each board's oscillator input, never driven by the other board. Forwarded clock uses N20.
Vivado's exact-part database identifies N20 as IO_L14P_T2_SRCC_34. L17 is
IO_L11N_T1_SRCC_35 (N-side), which failed single-ended input-buffer DRC PLIO-9 in the first attempt.
The design moved the clock to N20; no DRC severity or dedicated-clock routing override was used.
S1/G19 resets local logic. Master S2/J19 schedules a common counter clear; S3/K19 schedules a one-cycle trigger.
S2/S3 use two-flop synchronization and 5ms stable-level debounce; each press schedules one future event.
Core watchdog consumes slave N18 but timestamps consume only forwarded clock. Do not install a VGA/peripheral
module on reused pins. Extra return wire is necessary for RTT observations. Wire length, impedance,
source termination, skew and connector delay must be measured; current timing budget assumes bounded short wiring.

The XDCs are for this documented expansion mapping and exact xc7z010clg400-1 part; not generic Zynq XDCs.
No physical board has been programmed or electrically verified by TASK-001.
