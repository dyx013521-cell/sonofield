# Read-only GUI review. Source this in an existing Vivado Tcl Console.
# Deliberately no exit, close_project, bitstream generation or programming.
set taskEvidence [file dirname [file normalize [info script]]]
catch {close_design}
open_checkpoint [file join $taskEvidence master routed.dcp]
report_utilization -name TASK001B_master_UTILIZATION
report_cdc -details -name TASK001B_master_CDC
report_bus_skew -file [file join $taskEvidence master gui-bus-skew.rpt]
report_drc -name TASK001B_master_DRC
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -name TASK001B_master_TIMING
puts {TASK-001B review only: READY_FOR_PCB_CONNECTION=false; PS7/default configuration and physical validation pending. No programming performed.}
