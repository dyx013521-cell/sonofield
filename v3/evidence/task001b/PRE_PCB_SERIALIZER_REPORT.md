# TASK-001B PRE-PCB Serializer report

Generated 2026-10-02T20:53:19.242792+08:00. **READY_FOR_PCB_CONNECTION=false**.
No FPGA programming, flash/boot changes or PCB connection were performed.
Tool simulation/synthesis/routing evidence below is separate from real P5,
array-header voltage, external translation and 595 physical timing evidence.

## Fixed architecture and identity

Board1/Master=210299245711, UART COM7; Board2/Slave=210299835073.
Board2 UART is OPTIONAL_DEBUG/NOT_BLOCKING. A new read-only scan opened both
exact serial targets and found one xc7z010 each, two FPGAs/four chain devices,
zero probe errors. Existing configured-device DONE/EOS/CRC properties do not
prove these new sources were programmed. Full package/speed-grade confirmation
still comes from physical marking; the build uses xc7z010clg400-1.

Each board:64 logical channels ->16 parallel lanes ->4 used outputs of each
of16 SN74LVC595A ->64 channels; two boards total128. No64-GPIO redesign,
cascaded single serial chain, acoustics, ADC, phase solver, trajectory or v4.
19 control signals need at least3 AXC8T245 per board by capacity (six total),
but actual PCB grouping is unconfirmed. AXC rail/OE/DIR review is in
[BANK_VCCO_REPORT.md](BANK_VCCO_REPORT.md).

## GPIO / XDC

[Complete pool](../../docs/ARRAY_GPIO_POOL.md),
[19-signal pin map](../../docs/SERIALIZER_PINMAP.md),
[machine mapping](../../docs/array_gpio_mapping.json).
P1 has14 usable GPIO; P2 supplies2 additional data pins plus3 known LED-loaded
outputs. H20/J20/L19 replace LED0/2/3 in the new wrappers;2kohm loads remain.
LED1/K18 displays sync lock. Original TASK-001 wrappers retain their four LED
interface and are regression tested. No button pin is driven as array output.
All19 selected pins are Bank35/LVCMOS33/DRIVE4/SLOW; nominal VCCB=3.3V is
traced through core R2460 to VCC/U22/L7/TP1. Vivado confirms bank/function,
not actual voltage. P1/P2 supply pins1/2 are VCC_IN, never array data.
Duplicate selected balls/connectors, array-to-P5 conflicts and bank mismatches
are all0. All P5-connected aliases on P2/P3 are excluded. P3 adds no GPIO
outside P5. P5 remains only sync and original scope outputs.

## Serializer / 595 model / scheduled commit

Serializer captures all64 bits in shadow, sends bit3/2/1/0 on four SRCLK rises,
then publishes once on the common latch. Each full8-bit virtual595 shifts
all eight bits; Q0..Q3 reconstruct the current frame, while Q4..Q7 hold older
shifted data and are not counted as current-frame channels. Actual PCB Q
mapping, unused-output wiring and physical /OE polarity are not established.
Active waveform updates only with latch. APPLY_AT waits after shifting and
rejects a deadline with less than82 cycles lead or overlap. Fault disable is
independent of the serializer FSM. PRE-PCB wrappers keep output_disable=1;
manual Master S3 is the only diagnostic single-frame request, default idle.
Startup receiver fragments remain counted; array fatal events become sticky
after first lock and require RUN reset, rather than treating all historical
training counts as an irrevocable error.

50MHz FSM,2.5MHz shift burst,200ns data setup/hold and pulse widths. Untimed
frame to latch81 cycles, done92, next start93:1.86us /537634frames/s.
Future required rate U requires at least4U shift edges/s plus overhead.
No acoustic update-rate requirement or physical timing pass is inferred.
[Timing budget](../../docs/SERIALIZER_TIMING_BUDGET.md) remains
PRE_PCB_TIMING_ESTIMATE with explicit translator/PCB mismatch assumptions.

## Simulation

- `DUAL_SYNC_TB PASS checks=34 aligned_samples=264138 hour_test=BOUNDARY_ONLY`
- `TOP_CLOCK_TB PASS checks=6 aligned=9405`
- `SERIALIZER64_TB PASS checks=6995 reconstructed_frames=388 virtual_595=16 bits_per_595=8 used_Q=0..3`
- `DUAL_SERIALIZER_SYNC_TB PASS checks=18 common_latches=7 output_disable=1`

The serializer includes388 reconstructed frames,64 walking-one/zero pairs,
256 random words, immutable capture, four-pulse/latch timing, mid-frame reset,
overrun/deadline rejection and independent guard faults while a frame is busy.
Guard checks include sync loss, MMCM unlock, watchdog, CRC/frame, sequence,
fatal and disarm, asserting disable without waiting for completion. Dual test
uses actual sync protocol/wrappers,100ppm local-crystal mismatch and a3ns
forwarded-clock delay; seven common logical-timestamp latches pass. Clock loss
during the next frame produces no partial latch and clears slave pins through
the independent watchdog. These are simulation observations, not scope data.
The original long-duration test remains accelerated BOUNDARY_ONLY, not1hour.

## Synthesis, implementation and release gates

| Board | Synthesis | Implementation | Setup WNS ns | Hold WHS ns | CDC Critical | DRC Error |
|---|---|---|---:|---:|---:|---:|
| master | SYNTHESIZED | IMPLEMENTED | 0.494 | 0.007 | 0 | 0 |
| slave | SYNTHESIZED | IMPLEMENTED | 0.430 | 0.015 | 0 | 0 |

Full synthesis/opt/place/phys_opt/route includes a64-bit,1024-sample ILA per
board. Reports include utilization/IOB, setup/hold, CDC, DRC, methodology,
IO/clocks/clock interaction and unconstrained endpoints. Routed checkpoints
and .ltx exist for GUI inspection. Source hashes are in source-sha256.json;
run_task001b.ps1 checks that sources did not change across simulation/build.
Vendor debug bus-skew constraints are also reported. Initial routing had
Slave setup -0.099ns from sync_data to good_crc (attempt03); additional physical
optimization did not improve it (attempt04). Current RTL compares the fully
registered CRC on the original VALID-fall commit cycle, avoiding the long raw
serial-input comparison path without changing protocol latency or IO budgets.
Final reports come from a complete simulation/synthesis/route of this revision.
Initial failed reports in attempt01 are explicitly superseded. The first
Master failure was a falling-edge fault-to-pin half-cycle path; first Slave
CDC failures came from raw watchdog/reset status entering array/ILA logic.
Current architecture separates synchronized logic from asynchronous assertion.
The intermediate two CDC-11 reports in attempt02 came from two independent
raw-reset release chains. The endpoint now shares core RUN release; a dual
mid-frame reset regression verifies immediate clamp without a partial latch.

No user false_path, clock-group exclusion, non-dedicated clock routing or DRC
severity downgrade was added. ILA/debug-hub vendor constraints contain their
own synchronizer exceptions; these do not exempt the inter-board link. Review
the actual methodology and clock interaction reports before release, including
independent local/received clocks, asynchronous safety resets and generated
clock-reference notices. A positive STA number for independent clocks does
not prove a physical phase relationship.
The rule-by-rule dispositions and still-open work are recorded in
[IMPLEMENTATION_REVIEW.md](IMPLEMENTATION_REVIEW.md); this is not release
sign-off. The status keeps METHODOLOGY_REVIEW_COMPLETE=false.

Resource counts (LUT / FF / BRAM tiles / total bonded IOB):
- master: 2125 / 2751 / 2 / 32.
- slave: 2121 / 2750 / 2 / 30.

Array IOB count is19 per board; bonded IOB totals also include clocks, keys,
P5 and the remaining LED. Critical unconstrained internal endpoint and missing
clock/input-delay counts are recorded in the status JSON. Master's forwarded
sync_clk is the one LOW clock-output notice; it is not a data endpoint.

The ZPS7-1 default-configuration warning remains a blocking release review;
[ZYNQ_CONFIGURATION_REVIEW.md](ZYNQ_CONFIGURATION_REVIEW.md) explains it.
DRC Error=0 does not close that review. No unreviewed generic PS7 preset was
inserted simply to suppress the warning. Therefore neither requested .bit
was generated or programmed. .ltx files are not a downloadable bitstream.

## Actual hardware state / remaining work

Real P5 lock and ILA serializer frames: NOT_BOARD_TESTED. Physical P1/P2
module absence, board revision, VCCO and exact P5 wiring remain unconfirmed.
PCB expected disconnected for this task; actual connection cannot be read
from JTAG, so PCB_CONNECTED is null rather than an invented observation.
Scope/logic-analyzer amplitude, edge, setup/hold and latch measurements remain
REQUIRES_PHYSICAL_MEASUREMENT. No PCB/AXC/595/channel/acoustic/levitation pass.

Before continuation: close PS7/default/isolation review; resolve any failing
CDC/STA in the recorded final reports; confirm actual boards/rails, no camera
or VGA devices on reused nets, PCB absent, and P5 six signals/common ground.
Then generate bitstreams under all gates, match JTAG serial/part again.
The latest engineering contract says No automatic programming; programming
is a separate authorized/manual stage, restricted to volatile PL. Verify new
DONE/EOS/CRC/MMCM/RUN/real P5 lock. After
lock, capture manual ALL_ZERO/WALKING_ONE/1010 single frames with disable=1,
resetting both boards before a new test sequence. Keep resulting GUI pages
open. Do not connect the PCB until every readiness gate actually passes.
