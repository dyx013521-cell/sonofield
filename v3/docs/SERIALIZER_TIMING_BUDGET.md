# Serializer timing budget — PRE_PCB_TIMING_ESTIMATE

50MHz PL clock, period20ns; HALF_CYCLES=10, data changes only on capture or
falling shift edges. SRCLK is 2.5MHz during the four-bit burst. Data setup and
hold launch spacing are each 200ns; clock high/low widths 200ns. Four lanes
bits are sent in parallel across 16 lanes: 64 bits in 1.6us of shifting.
Unscheduled frame: capture to rising latch81cycles/1.62us, latch high10cycles,
frame_done92cycles/1.84us, next accepted start93cycles/1.86us. Maximum
back-to-back update rate50MHz/93 = 537634 frames/s. Scheduled mode holds the
four shifted bits until APPLY_AT and has no fixed maximum latency. A future
desired update rate U needs at least4U serial edges/s, plus latch and guard
overhead. No future acoustic update-rate requirement has been specified.

For a candidate 3.3V ±0.3V 595 supply, TI SCES998A specifies 2.5ns SER setup,
1.5ns SER hold, 2.5ns SRCLK-to-RCLK setup and 4.5ns SRCLK/RCLK pulse width.
Source: https://www.ti.com/lit/ds/symlink/sn74lvc595a.pdf (table6.6).
These values apply only at the specified rail/temperature/load; an actual
PCB-side rail remains unknown and requires a new budget if different.

| Element | Provisional bound / status |
|---|---|
| FPGA data/clock pin skew | budget10ns; routed path comparison still required |
| AXC data/clock mismatch | budget20ns, conservative placeholder; actual rails/group/load unknown |
| PCB/cable skew | budget10ns; no physical length or scope measurement |
| SER setup margin | 200 -10 -20 -10 -2.5 =157.5ns estimate |
| SER hold margin | 200 -10 -20 -10 -1.5 =158.5ns estimate |
| Last SRCLK rising to earliest latch | 220ns nominal; minus40ns skew and2.5ns setup =>177.5ns estimate |
| Clock/latch high width | 200ns nominal; minus40ns mismatch and4.5ns requirement =>155.5ns estimate |

The20ns AXC bound is an assumption for early design exploration, not a quoted
guarantee or actual delay. TI switching table5.13 must be applied to actual
VCCA/VCCB, capacitance and temperature before PCB use. Default DRIVE4/SLOW,
22ohm core series resistors and2kohm LED control-line loads affect pin edges;
STA is not signal-integrity validation. No clock-only LVC244 path is assumed.
595 Q4..Q7 retain earlier bits and must not drive channels. Actual Q0..Q3
wiring, physical /OE polarity, external disable pulls and any extra buffers
require the PCB schematic. FPGA config-time pins are high impedance; safe RTL
after DONE does not replace an external default-disable pull.

Measure serial_data[0]/[15], shift_clock, latch_clock and output_disable for
amplitude, frequency, edge quality, setup/hold and latch position at the FPGA
headers first, then at the farthest 595 after a separate PCB review.
State: REQUIRES_PHYSICAL_MEASUREMENT. No translator/595 physical timing pass.
