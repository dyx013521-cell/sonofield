# TASK-001 synthesis and implementation

Source commit: `e0cc3a6412ea2559e698ffe13aa403de790279f1`. Vivado2025.2 build6299465. PowerShell7.6.5.

Both `ebaz_master` and `ebaz_slave` were synthesized, optimized, placed, physically optimized and routed for
`xc7z010clg400-1`. Separate `.xpr` projects exist under `v3/vivado/build/`. Original synthesis and route
checkpoints, IO mapping, utilization, clocks, DRC, CDC and timing reports are retained in each evidence folder.

The batch flow uses direct Tcl design commands; GUI run-manager entries may remain unlaunched. Open each
`routed.dcp` to inspect the actual completed implementation, or rerun `v3/vivado/run_task001.ps1`.

DRC warnings are preserved: ZPS7-1 reports that PS7 is absent from the PL-only baseline. The slave may also
report IOSR-1 for IOB set/reset packing. These are not waived. Resolve PS7/default configuration and board boot
requirements before bitstream release. The current task generated no bitstreams and programmed no FPGA.

Earlier attempts and corrections are archived: wrong N-side clock pin (PLIO-9) was replaced with N20 P-side
SRCC; missing forwarded-clock query corrected; watchdog-to-receiver reset crossing synchronized; reset sources
split into separate assertion/release chains; raw reset-to-output path removed; all derived clock uncertainty
budgets explicitly applied. Source-synchronous data timing was not hidden with false-path constraints.
