# Read-only hardware enumeration. Never programs or resets an FPGA.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [open [file join $root evidence task001 hardware_probe.txt] w]
puts $out "READ_ONLY_PROBE [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S %z}]"
puts $out "Vivado [version -short]"
if {[catch {
 open_hw_manager
 connect_hw_server -url localhost:3121 -allow_non_jtag
 set targets [get_hw_targets -quiet]
 puts $out "TARGET_COUNT [llength $targets]"
 foreach target $targets {
  puts $out "TARGET $target"
  current_hw_target $target
  if {[catch {open_hw_target;puts $out "DEVICES [get_hw_devices -quiet]";close_hw_target} problem]} {
   puts $out "TARGET_ERROR $problem"
  }
 }
} problem]} {puts $out "PROBE_ERROR $problem"}
puts $out "PROGRAMMING NOT_PERFORMED"
close $out
catch {close_hw_manager}
exit
