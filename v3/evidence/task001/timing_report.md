# TASK-001 timing analysis

Vivado2025.2; exact part xc7z010clg400-1; routed designs. Source commit `e0cc3a6412ea2559e698ffe13aa403de790279f1`.

| Role | Setup WNS (ns) | Hold WHS (ns) | CDC critical |
|---|---:|---:|---:|
| master | 0.936 | 0.006 | 0 |
| slave | 0.199 | 0.052 | 0 |

These slacks meet the current analysis budgets. They are not proof of board-level phase/skew or asynchronous
clock phase alignment. IO delays remain engineering assumptions; no cable measurement has been substituted.

## Constraint coverage and clocks

- N18/local50 and slave N20/received50 are20ns clocks. MMCM uses1GHz VCO /20; master ODDR forwards50MHz.
- Input jitter0.100ns. User uncertainty0.200ns explicitly applied to all resolved clocks including automatic
  MMCM clocks; raw setup reports show User Uncertainty. Primary uncertainty alone was insufficient.
- Input/output min and max delays are explicit. Slave DATA/VALID launch on the falling edge and capture on
  the rising edge; the model is SDR. No DDR rising-edge data is generated.
- Both check_timing reports show zero unclocked registers, unconstrained internal endpoints, missing input
  delays, partial IO delays or combinational loops. Master sync_clk has a propagated generated clock;
  it is the sole no_output_delay category entry, with zero unconstrained ordinary data output ports.
- No false_path, clock-group cut, DRC severity reduction or non-dedicated clock-route override is used.
- CDC: both have0 critical crossings. Slave reports2 recognized ASYNC_REG data synchronizers and1 recognized
  asynchronous reset synchronizer. Independent local watchdog and received clocks remain physically asynchronous.

## Remaining methodology review items

| Role | Rule | Severity | Count |
|---|---|---|---:|
| master | TIMING-18 | Warning | 2 |
| master | TIMING-28 | Warning | 4 |
| slave | TIMING-6 | Critical Warning | 3 |
| slave | TIMING-7 | Critical Warning | 3 |
| slave | TIMING-18 | Warning | 7 |
| slave | TIMING-28 | Warning | 4 |

TIMING-6/7 remain because physically unrelated watchdog/received clocks are analyzed without timing cuts.
Positive STA slack between them assumes a phase relationship that hardware does not have; CDC synchronizers,
not this slack, handle metastability. Direct asynchronous output gates deliberately suppress lock/waveform
after watchdog loss; there is no claim of synchronous placement of that fault transition.

TIMING-18 includes edge/clock coverage suggestions: DATA/VALID use one specified launch/capture edge; async
reset and fault-gated output/status paths involve more than one clock. These warnings are retained rather
than adding fictitious DDR edges or claiming all methodology checks passed. Before board release, review the
external timing contract against measured clock/data skew and qualify asynchronous status/fault paths.

TIMING-28 warns that uncertainty constraints reference automatic MMCM clocks. This is intentional for this
baseline and is applied after clock resolution; the raw reports verify0.200ns user uncertainty. Preserve the
post-synthesis application when rebuilding. Master hold margin is only0.006ns with these budgets, so there is
little margin for any change to external assumptions; a positive number is not a board sign-off.

## Hardware-dependent limits

Trigger skew<20ns, jitter, MMCM phase repeatability, VCCO, trace/cable skew and reset startup behavior are
unmeasured. Physical Level0–3 acceptance and literal>1hour endurance remain pending. No bitstream is released.
