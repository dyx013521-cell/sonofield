# TASK-001 RTL simulation

Tool: XSim 2025.2, build6299465. Entry: `v3/simulation/run_xsim.ps1`, PowerShell7.

## Executed results

| Test | Result | Coverage |
|---|---|---|
| dual_sync_tb | PASS,34 checks | 264138 aligned timestamp observations over four link-delay profiles |
| top_clock_tb | PASS,6 checks | 9405 aligned observations; physical top integration with behavioral clocks |

Original outputs: `xvlog.log`, `xelab.log`, `xsim.log`, `xelab-top.log`, `xsim-top.log`.

`dual_sync_tb` covers initial acquisition, randomized fractional flight0.25..7.25ns, integer pipelines0..3cycles,
common scheduled trigger/clear, snapshot suppression across reset, CRC corruption, duplicate/missing/backward frames,
overlong valid-CRC prefix rejection, timeout and recovery, random heartbeat gaps, independent CRC golden vector,
one-hour count boundary, full64bit rollover and randomized round-trip measurement/timeout.

`top_clock_tb` deliberately differs local crystals by100ppm. Slave time is driven by the forwarded master clock.
It checks waveform equality, default148-cycle RTT turnaround profile, debounced command integration, loss of
forwarded clock and reacquisition after restoration. The two-flop alive crossing and independent reset-release
chains are exercised. Lock can remain stale during the documented watchdog detection window; the monitor does
not treat that latency as instantaneous fault detection.

## Boundaries, not hardware claims

- The main test executes approximately1.395ms of modeled time; the top test approximately0.370ms.
- One-hour test uses the real counter RTL loaded near180000000000, then crosses that value. It is explicitly
  `BOUNDARY_ONLY`, not an elapsed-hour simulation and not a one-hour drift/lock-loss endurance test.
- MMCM/ODDR are bypassed in behavioral top simulation. Analog MMCM phase, jitter, clock IO electrical behavior
  and post-route SDF are not covered.
- Integer timestamp equality does not establish sub20ns physical skew at board outputs.
- Single-way delay estimate assumes symmetric routes and known turnaround; fractional phase remains unmeasured.
- No FPGA has been programmed by this task. `BOARD_TESTED` and `HARDWARE_VERIFIED` remain pending.

Earlier failed attempts are retained in `attempt01/` and `attempt02/` to record actual issues and corrections;
they are not the current result. In particular, the RTT test now waits for measurement validity rather than
sampling while a subsequent measurement is in flight.
