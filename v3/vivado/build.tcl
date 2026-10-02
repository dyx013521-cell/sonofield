set root [file normalize [file join [file dirname [info script]] ..]]
set evidence [file join $root evidence task001]
set_param general.maxThreads 4
set result [open [file join $evidence build-results.tsv] w]
puts $result "role\tsynthesis\timplementation\tsetup_slack_ns\thold_slack_ns\tcdc_critical_count\tstatus"
set sources {}
foreach rel {rtl/sync/sync_protocol.sv rtl/sync/timestamp_counter.sv rtl/sync/sync_master.sv rtl/sync/sync_slave.sv rtl/sync/sync_button.sv rtl/sync/delay_measure.sv rtl/clock/clk_manager.sv rtl/top/dual_sync_top.sv} {
 lappend sources [file join $root $rel]
}
foreach role {master slave} {
 set top ebaz_$role
 set dest [file join $evidence $top];file mkdir $dest
 set syn NOT_RUN;set impl NOT_RUN;set setup NA;set hold NA;set critical NA;set status ERROR
 if {[catch {
  create_project $top [file join $root vivado build $top] -part xc7z010clg400-1 -force
  set_property target_language Verilog [current_project]
  add_files -norecurse $sources
  add_files -fileset constrs_1 -norecurse [file join $root constraints $top.xdc]
  set_property top $top [current_fileset]
  update_compile_order -fileset sources_1
  synth_design -top $top -part xc7z010clg400-1
  # Primary-clock user uncertainty is not inherited by automatic MMCM clocks.
  # Apply the stated 0.2ns budget to every resolved clock before implementation.
  set_clock_uncertainty 0.200 [get_clocks *]
  if {$role eq "master" && [llength [get_clocks -quiet forwarded50]]!=1} {error "Forwarded clock constraint missing"}
  set syn SYNTHESIZED
  write_checkpoint -force [file join $dest synthesized.dcp]
  report_utilization -file [file join $dest synthesis_utilization.rpt]
  report_timing_summary -delay_type min_max -report_unconstrained -file [file join $dest synthesis_timing.rpt]
  report_property -all -file [file join $dest N20_package_pin.rpt] [get_package_pins N20]
  if {![regexp {P_T.*(MRCC|SRCC)} [get_property PIN_FUNC [get_package_pins N20]]]} {error "N20 is not a P-side clock-capable pin"}
  report_io -file [file join $dest io.rpt]
  opt_design
  place_design
  phys_opt_design
  route_design
  set impl IMPLEMENTED
  write_checkpoint -force [file join $dest routed.dcp]
  report_utilization -file [file join $dest utilization.rpt]
  report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file [file join $dest timing.rpt]
  report_timing -delay_type max -max_paths 10 -file [file join $dest setup_paths.rpt]
  report_timing -delay_type min -max_paths 10 -file [file join $dest hold_paths.rpt]
  report_clock_interaction -file [file join $dest clock_interaction.rpt]
  report_cdc -details -file [file join $dest cdc.rpt]
  set cf [open [file join $dest cdc.rpt] r];set cdc_text [read $cf];close $cf
  set critical 0
  foreach {row number} [regexp -all -inline -line {^CDC-[0-9]+\s+Critical\s+([0-9]+)} $cdc_text] {incr critical $number}
  report_drc -file [file join $dest drc.rpt]
  report_methodology -file [file join $dest methodology.rpt]
  report_clocks -file [file join $dest clocks.rpt]
  set sp [get_timing_paths -delay_type max -max_paths 1]
  set hp [get_timing_paths -delay_type min -max_paths 1]
  if {[llength $sp]} {set setup [get_property SLACK [lindex $sp 0]]}
  if {[llength $hp]} {set hold [get_property SLACK [lindex $hp 0]]}
  set status TIMING_FAIL
  if {$setup ne "NA" && $hold ne "NA" && $setup>=0 && $hold>=0} {set status TIMING_BUDGET_MET_NOT_HARDWARE_VERIFIED}
  if {$critical>0} {set status CDC_FAIL}
 } msg opts]} {
  set errorfile [open [file join $dest failure.txt] w];puts $errorfile $msg;puts $errorfile [dict get $opts -errorinfo];close $errorfile
  puts "BUILD_ERROR $top $msg"
 }
 puts $result "$role\t$syn\t$impl\t$setup\t$hold\t$critical\t$status";flush $result
 catch {close_project}
}
close $result
exit
