# Reproducible post-route refinement of TASK-001B. No RTL/XDC changes.
set here [file dirname [file normalize [info script]]]
set root [file normalize [file join $here ../..]]
set build [file join $root build prepcb]
set_param general.maxThreads 4
set results [open [file join $here refinement-build-results.tsv] w]
puts $results "role\tsynthesis\timplementation\tsetup_ns\thold_ns\tcdc_critical\tdrc_errors\tstatus"
foreach role {master slave} {
 open_checkpoint [file join $here $role routed.dcp]
 if {$role eq "slave"} {
  phys_opt_design -directive AggressiveExplore
  route_design
  write_checkpoint -force [file join $here $role routed.dcp]
  write_debug_probes -force [file join $build ebaz_${role}_serializer_prepcb.ltx]
 }
 set dest [file join $here $role]
 report_utilization -file [file join $dest utilization.rpt]
 report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file [file join $dest timing.rpt]
 report_timing -delay_type max -max_paths 10 -file [file join $dest setup.rpt]
 report_timing -delay_type min -max_paths 10 -file [file join $dest hold.rpt]
 report_bus_skew -file [file join $dest bus-skew.rpt]
 report_cdc -details -file [file join $dest cdc.rpt]
 report_drc -file [file join $dest drc.rpt]
 report_methodology -file [file join $dest methodology.rpt]
 report_io -file [file join $dest io.rpt]
 report_clocks -file [file join $dest clocks.rpt]
 report_clock_interaction -file [file join $dest clock-interaction.rpt]
 set setup [get_property SLACK [lindex [get_timing_paths -delay_type max -max_paths 1] 0]]
 set hold [get_property SLACK [lindex [get_timing_paths -delay_type min -max_paths 1] 0]]
 set f [open [file join $dest cdc.rpt] r];set text [read $f];close $f
 set cdc 0;foreach {row count} [regexp -all -inline -line {^CDC-[0-9]+\s+Critical\s+([0-9]+)} $text] {incr cdc $count}
 set drc [llength [get_drc_violations -filter {SEVERITY == Error}]]
 set status REVIEW_REQUIRED
 if {$setup<0 || $hold<0} {set status TIMING_FAIL}
 if {$cdc>0} {set status CDC_FAIL}
 if {$drc>0} {set status DRC_FAIL}
 puts $results "$role\tSYNTHESIZED\tIMPLEMENTED\t$setup\t$hold\t$cdc\t$drc\t$status";flush $results
 close_design
}
close $results
file copy -force [file join $here refinement-build-results.tsv] [file join $here build-results.tsv]
exit
