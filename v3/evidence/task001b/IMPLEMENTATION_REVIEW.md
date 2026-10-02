# TASK-001B implementation warnings — release review remains open

Read this with each board's final `drc.rpt`, `methodology.rpt`, `timing.rpt`,
`clock-interaction.rpt` and `cdc.rpt`. Zero DRC Errors and zero CDC Critical
counts are separate from closing methodology warnings. No warning severity,
clock routing rule or inter-board timing exception was suppressed.

| Rule | Current interpretation and remaining action |
|---|---|
| ZPS7-1 | Both PL-only tops lack an established board-specific default PS configuration. Release blocked; see ZYNQ_CONFIGURATION_REVIEW.md. |
| TIMING-6 / TIMING-7 | Slave local N18 watchdog and received/MMCM clocks are physically independent. Current STA times them without pretending a measured phase relationship. Review synchronized status, reset assertion and return-status paths; positive STA cannot establish metastability probability or hardware alignment. No clock group/false path was added. |
| TIMING-18 | Master sync DATA/VALID and Slave sync/control paths have edge/reference notices. Explicit IO budgets exist, and check_timing reports no unconstrained internal endpoints or data ports missing delays. Nevertheless source/capture edge conventions and every notice still require reviewed reconciliation with the physical link. Do not mark the warning closed merely because WNS is positive. |
| TIMING-28 | MMCM clocks receive explicit 0.2 ns uncertainty after synthesis by derived clock name. Periods are reported, but references should be made stable by pin-based queries during constraint review. No physical jitter measurement exists. |
| LUTAR-1 | User safety/reset combinations and vendor debug logic drive async clears. Intended asynchronous clamp is useful when a clock stops, but the report flags possible combinational glitches. The PRE-PCB arm is fixed low; outputs cannot be enabled. Physical reset recovery and any future armed PCB implementation need a dedicated release review. |
| IOSR-1 | Slave input-related flops have differing set/reset controls; this affects optimal IOB packing. It is retained in DRC and is not resolved by declaring simulation successful. |
| PDCN-1569 / RTSTAT-10 | Current reports locate LUT unused-input/no-routable-load notices inside vendor dbg_hub, including BSCAN TDO infrastructure. Generated IP and final routed design are preserved; verify actual JTAG/ILA operation before claiming debug hardware passed. |
| XDCB-5 | Vendor ILA pin queries are inefficient; retain vendor constraints and report. These vendor constraints do not waive the external sync interface. |

Automatic timing/CDC/DRC summaries are in PRE_PCB_SERIALIZER_STATUS.json and
build-results.tsv. METHODOLOGY_REVIEW_COMPLETE remains false. This review
records dispositions and work still required; it is not bitstream sign-off.
