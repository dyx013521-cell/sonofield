set root [file normalize [file join [file dirname [info script]] ..]]
set build [file join $root build prepcb]
set evidence [file join $root evidence task001b]
file mkdir $evidence
set_param general.maxThreads 4
set roles {master slave}
if {[llength $argv]>0} {set roles $argv}
set result_name build-results.tsv
if {[llength $roles]==1} {set result_name [lindex $roles 0]-build-results.tsv}
set results [open [file join $evidence $result_name] w]
puts $results "role\tsynthesis\timplementation\tsetup_ns\thold_ns\tcdc_critical\tdrc_errors\tstatus"
foreach role $roles {
 if {$role ni {master slave}} {error "Unknown role $role"}
 set top ebaz_${role}_serializer_prepcb
 set dest [file join $evidence $role];file mkdir $dest
 set syn NOT_RUN;set impl NOT_RUN;set setup NA;set hold NA;set cdc NA;set drc NA;set status ERROR
 if {[catch {
  create_project $top [file join $build $role] -part xc7z010clg400-1 -force
  set_property target_language Verilog [current_project]
  foreach rel {rtl/sync/sync_protocol.sv rtl/sync/timestamp_counter.sv rtl/sync/sync_master.sv rtl/sync/sync_slave.sv rtl/sync/sync_button.sv rtl/sync/delay_measure.sv rtl/clock/clk_manager.sv rtl/top/dual_sync_top.sv rtl/array/serializer64.sv rtl/array/array_output_guard.sv rtl/array/array_test_endpoint.sv rtl/top/serializer_prepcb_top.sv} {
   add_files -norecurse [file join $root $rel]
  }
  create_ip -name ila -vendor xilinx.com -library ip -module_name ila_prepcb
  set_property -dict [list CONFIG.C_NUM_OF_PROBES {1} CONFIG.C_PROBE0_WIDTH {64} CONFIG.C_DATA_DEPTH {1024} CONFIG.C_INPUT_PIPE_STAGES {0}] [get_ips ila_prepcb]
  generate_target all [get_ips ila_prepcb]
  set_property generate_synth_checkpoint false [get_files ila_prepcb.xci]
  add_files -fileset constrs_1 -norecurse [file join $root constraints ebaz_${role}_prepcb_sync.xdc]
  add_files -fileset constrs_1 -norecurse [file join $root constraints ebaz_${role}_array.xdc]
  set_property top $top [current_fileset]
  update_compile_order -fileset sources_1
  synth_design -top $top -part xc7z010clg400-1
  set syn SYNTHESIZED
  set_clock_uncertainty 0.200 [get_clocks *]
  set array_ports [get_ports {serial_data[*] shift_clock latch_clock output_disable}]
  if {[llength $array_ports]!=19} {error "ARRAY GPIO != 19"}
  set balls {};set p5 {M18 L20 M20 L17 N20 M19 M17 P18 P20 N17 R19 R18 T20 P19 T19 U20 U19 V20}
  set audit [open [file join $dest pin-audit.tsv] w]
  puts $audit "port\tball\tbank\tstandard\tstatus"
  foreach port [get_ports *] {
   set ball [get_property PACKAGE_PIN $port]
   if {$ball eq "" || $ball in $balls} {error "missing/duplicate package ball $port $ball"}
   lappend balls $ball
  }
  foreach port $array_ports {
   set ball [get_property PACKAGE_PIN $port];set bank [get_property BANK [get_package_pins $ball]]
   if {$ball in $p5 || $ball eq "N18" || $bank!=35 || [get_property IOSTANDARD $port] ne "LVCMOS33"} {error "ARRAY GPIO conflict $port $ball bank=$bank"}
   puts $audit "$port\t$ball\t$bank\tLVCMOS33\tPASS_SCHEMA_NOMINAL_3V3"
  }
  close $audit
  write_checkpoint -force [file join $dest synthesized.dcp]
  report_utilization -file [file join $dest synthesis-utilization.rpt]
  opt_design;place_design;phys_opt_design;route_design
  set impl IMPLEMENTED
  write_checkpoint -force [file join $dest routed.dcp]
  write_debug_probes -force [file join $build $top.ltx]
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
  # Never convert a routed design directly to a downloadable image. Review the
  # PS7/default configuration, unconstrained paths and physical facts first.
 } msg opts]} {
  set f [open [file join $dest failure.txt] w];puts $f $msg;puts $f [dict get $opts -errorinfo];close $f
  puts "BUILD_ERROR $role $msg"
 }
 puts $results "$role\t$syn\t$impl\t$setup\t$hold\t$cdc\t$drc\t$status";flush $results
 catch {close_project}
}
close $results
exit
