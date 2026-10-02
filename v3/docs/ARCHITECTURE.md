# TASK-001 execution contract
Active v3; 2026-09-29; source repository initial commit cbd7cb46870db27c3fe07f203d98e8841978f552.
Scope: timing synchronization only. No acoustic, ADC, phase, trajectory or driver modules.

## Clock and epoch
The master uses X5/N18 50MHz. A dedicated ODDR forwards 50MHz to the slave P5/7 N20 P-side SRCC input.
Both use MMCME2_BASE at 1GHz VCO /20 =50MHz; no independent slave-crystal timestamp domain.
Slave N18 remains an independent clock-loss watchdog only. This is essential: periodic timestamp correction
between independent crystals cannot make one frequency domain. Master and slave edges still have physical
flight/MMCM skew, to be measured; no zero-skew claim is made.
Reset asserts/release synchronization, reacquisition and link timeouts are explicit. The dedicated SYNC_RESET
wire flushes link state on a master reset; it is not evidence of simultaneous asynchronous reset edges.
Scheduled RESET_AT frames provide a common logical epoch at a future count while locked.
64bit counters wrap modulo2^64, never saturate; normal counts increase by one each clock.
Initial/unlocked acquisition may load a counter; a locked counter is never continuously rewritten.

## Wire protocol
144 bits MSB first: header16=0x5346, board_id8=1, command8, sequence32, timestamp64, CRC16.
CRC16-CCITT: polynomial0x1021, init0xffff, no reflect/final xor; computed incrementally.
Launch at falling edges, sample at rising edges; VALID high for exactly144 samples, low between frames.
Commands1 SYNC(snapshot at first-bit launch),2 RESET_AT(future epoch),3 TRIGGER_AT(future pulse).
Frame serialization+decoder latency=146 rising edges from snapshot; LINK_CYCLES is an explicit integer
pipeline compensation, defaults0 for direct source-synchronous wires. CRC, header, board ID, framing,
duplicate/gapped sequence, unknown commands and late commands invalidate lock. Three consecutive
zero-offset SYNC frames acquire lock. Watchdog4096 cycles fails closed; schedules cancelled on error.
SYNC_LOCK is a reverse level. Additional SYNC_ECHO on P5/8 is required for round-trip observation;
without a return path, one-way delay and clock offset cannot be distinguished.

## Delay boundary
delay_measure reports actual local TX-to-echo round-trip cycles, minus a documented receiver/synchronizer
turnaround profile (148 cycles in default RTL). Integer one-way delay=(RTT-turnaround)/2 is meaningful
ONLY under symmetric routes and that latency profile, with clock-quantization uncertainty. It is NOT
an absolute cable-delay or sub-cycle phase measurement, and is not fed back automatically to the counter.
Scope/ILA measurement must determine clock/data skew and asymmetry; no guessed compensation is persisted.

## Physical outputs and command integration
ebaz_master and ebaz_slave are independently routed tops. Autonomous heartbeat is one frame/1024 clocks.
Both expose timestamp bit20 (50MHz/2^21 = approximately23.842Hz) as the initial scope waveform after lock.
Master S2 schedules RESET_AT and S3 schedules TRIGGER_AT, at timestamp+1024 (20.48us) after admission.
Buttons pass a two-flop synchronizer and 250000-cycle (5ms) debounce. Only one event may be pending.
Core command lead is bounded to176..2048 cycles. SYNC snapshots are suppressed until a pending reset executes
so that a serialized snapshot cannot span two epochs. Normal periodic SYNC resumes afterward.
Scheduled events require intact delivery; this baseline does not implement acknowledged distributed commit.
An error cancels slave pending commands and invalidates lock; it cannot undo a master event already scheduled.
Slave local crystal watchdog detects absent forwarded clock within approximately20.5us plus sampling latency.
Heartbeat and alive status cross only through ASYNC_REG synchronizers. During this detection interval,
the output lock may still reflect the previous valid state. The asynchronous output safety gate deasserts it
after detection, even when the forwarded clock is stopped. Reset sources have separate assertion/release chains.
No bitstream is generated or hardware programmed in this baseline.

## Electrical assumptions
P5 mapping is read from EBAZ4205 expansion V1.1 2020/3/13 original PDF, not copied from another board:
CLK N20 pin7; DATA M18 pin3; VALID M20 pin5; RESET L17 pin6; reverse LOCK M17 pin9;
reverse ECHO M19 pin8; each board local scope TRIGGER P20 pin11; GND pin1. Pin2=3.3V, do not use as GND.
Reset key G19 active-low; LEDs H20/K18/J20/L19 active-low. Disconnect VGA/other peripherals on those nets.
LVCMOS33 is schematic-derived, remains subject to checking the actual board revision/VCCO before wiring.
IO budgets and uncertainty in XDC are explicit engineering assumptions, not measured cable values.
No false-path/clock-route overrides. Board acceptance needs real link waveforms and >1hour stability.

## Evidence boundary
Behavioral top simulation bypasses MMCM/ODDR primitives and therefore does not validate analog MMCM phase,
lock acquisition, jitter or a routed netlist with SDF. Integer logical alignment is asserted after each
forwarded edge; physical edge coincidence below20ns must be measured at the two scope outputs.
The fast hour test loads a counter near180000000000 ticks and crosses the one-hour boundary. It does not
execute180 billion clock edges, nor establish one-hour link stability. Full-duration board evidence is pending.
Preserve implementation warnings and CDC reports: modeled IO budgets are assumptions until measured.
# TASK-001B extension (2026-10-02)

Board1 is Master (JTAG 210299245711, UART COM7); Board2 is Slave
(JTAG 210299835073, UART optional and not blocking).
Each board has 64 logical bits, 16 independent serial lanes and four bits per
lane. P5 remains reserved. P1 has 14 GPIO; P2 G20/J18 provide the last two data
lanes. P2 H20/J20/L19 replace three LED indicators with shift/latch/disable;
their existing 2 kohm LED loads remain, and are documented, not ignored.
TASK-001 wrappers and original tests retain their interfaces. New PRE-PCB
wrappers expose timing/status and early accepted TRIGGER_AT announcements
through explicit new optional outputs of dual_sync_top/sync_slave. A frame is
loaded into shadow storage on that announcement, shifted before the deadline,
then published at APPLY_AT. Missed deadlines and overlap latch a fault.
The serializer shifts bit3,2,1,0 at 2.5 MHz using the existing 50 MHz clock:
200 ns setup, 200 ns high/hold per bit, then a common latch. A real eight-bit
595 model verifies Q[3:0] after four shifts; actual PCB Q wiring is unknown.
Independent guard asserts disable asynchronously on loss of any permissive.
Diagnostic PRE-PCB wrappers hold physical output_disable high permanently;
diagnostic shift/latch frames require a manual Master S3 press. No automatic
frames, PCB, acoustics or permanent programming are introduced.
Receiver error counters include fragments during initial clock/watchdog startup.
The array consumes explicit error events, and latches fatal errors only after
the first sync lock. Training stays disabled; historical startup counters cannot
prevent all later diagnostics. After lock, faults require local RUN reset.
Array logic/ILA use receiver-clock synchronized alive and lock, separately
from the raw independent watchdog used by the physical P5 interlock. Reset,
MMCM lock and watchdog each assert their own three-stage reset synchronizer
without combinational logic before its asynchronous input. Their released
states combine only inside the array clock domain. No raw local-domain status
gates serializer data or ILA probes. Watchdog loss still clears all three stages
asynchronously, even if the received clock has stopped.
The array endpoint reuses the core RUN reset release instead of independently
resynchronizing the same raw reset into a second chain. Independent reset
chains could release on different cycles and reconverge (CDC-11). RUN already
includes the core reset, MMCM and link-reset synchronizers; the endpoint adds
only the separate local-watchdog assertion/release chain.
CRC acceptance is evaluated on VALID falling, using the fully registered
16-bit received CRC and payload. The final serial input is captured first;
it does not feed a half-cycle-wide CRC/header comparison. This preserves
the existing frame_valid cycle and 146-cycle decoder compensation, while
giving the registered CRC comparison a full system cycle. Raw sync_data
still has the same source-synchronous input setup/hold budget.

# TASK-001C preflight (2026-10-02)

The latest two-phase user task authorizes volatile PL JTAG only after its
minimal PS7 release gate. That gate is currently false: dedicated PS_CLK
E7/CLK has no established live source/frequency; optional X8 33.333 MHz uses
NC R2340. N18/X5 remains a separate confirmed 50 MHz PL clock. No PS7 wrapper,
functional interface or RTL/XDC change is made before this fact is resolved.
No new simulations or implementations are claimed. All existing 19 array
balls are freshly rechecked as Bank35; user-confirmed measured 3.3 V,
common ground and removed VGA/Camera apply to current unchanged mapping.
The current state lives in evidence/task001c_ps7, with Phase-B explicitly
NOT_STARTED in evidence/task001d_first_board. ARM/boot firmware behavior
is unobserved and must not be inferred from PL JTAG configuration registers.
