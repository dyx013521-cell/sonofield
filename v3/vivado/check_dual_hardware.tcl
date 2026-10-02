# Detection only: enumerate targets/devices and cached properties.
# Never program, refresh a device, reset a board, write registers, or write Flash.
set outdir [file normalize [file join [file dirname [info script]] .. evidence task001 hardware_check]]
if {[llength $argv] > 0} {set outdir [file normalize [lindex $argv 0]]}
file mkdir $outdir
set targets_out [open [file join $outdir hw-targets.txt] w]
set devices_out [open [file join $outdir hw-devices.txt] w]
set properties_out [open [file join $outdir hw-properties.txt] w]
set status_out [open [file join $outdir vivado-probe-status.tsv] w]
puts $status_out "key\tvalue"
puts $status_out "captured_at\t[clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
puts $status_out "vivado_version\t[version -short]"
puts $status_out "programmed\tfalse"
puts $status_out "board_reset\tfalse"
puts $status_out "device_refresh\tfalse"
set target_count -1
set device_count 0
set fpga_count 0
set expected_match_count 0
set opened_count 0
set errors 0
proc record_properties {handle object} {
 puts $handle "OBJECT=$object"
 if {[catch {report_property -return_string $object} result]} {
  puts $handle "REPORT_PROPERTY_ERROR=$result"
 } else {puts $handle $result}
 foreach property [list_property $object] {
  if {[catch {get_property $property $object} value]} {set value "PROPERTY_READ_ERROR=$value"}
  puts $handle "$property=$value"
 }
 flush $handle
}
if {[catch {
 open_hw_manager
 connect_hw_server -url localhost:3121 -allow_non_jtag
 set targets [get_hw_targets -quiet]
 set target_count [llength $targets]
 puts "HW_TARGET_COUNT=$target_count"
 puts $targets_out "HW_TARGET_COUNT=$target_count"
 foreach target $targets {
  puts $targets_out "TARGET=$target"
  record_properties $properties_out $target
  current_hw_target $target
  if {[catch {open_hw_target} problem]} {
   incr errors
   puts $targets_out "TARGET_OPEN_ERROR=$problem"
   puts "TARGET_OPEN_ERROR=$problem"
   continue
  }
  incr opened_count
  puts $properties_out "TARGET_PROPERTIES_AFTER_OPEN"
  record_properties $properties_out $target
  set devices [get_hw_devices -quiet]
  puts $devices_out "TARGET=$target DEVICE_COUNT=[llength $devices]"
  set index 0
  foreach device $devices {
   incr device_count
   set part [get_property PART $device]
   if {[regexp -nocase {^(xc|xa|xq)} $part]} {incr fpga_count}
   if {$part eq "xc7z010"} {incr expected_match_count}
   puts $devices_out "TARGET=$target INDEX=$index DEVICE=$device PART=$part"
   record_properties $properties_out $device
   incr index
  }
  catch {close_hw_target}
 }
} problem]} {
 incr errors
 puts $targets_out "PROBE_ERROR=$problem"
 puts "PROBE_ERROR=$problem"
}
puts $devices_out "HARDWARE_DEVICE_COUNT=$device_count"
puts $devices_out "FPGA_DEVICE_COUNT=$fpga_count"
puts $status_out "hw_target_count\t$target_count"
puts $status_out "opened_target_count\t$opened_count"
puts $status_out "hardware_device_count\t$device_count"
puts $status_out "fpga_device_count\t$fpga_count"
puts $status_out "expected_xc7z010_count\t$expected_match_count"
puts $status_out "probe_error_count\t$errors"
puts "HARDWARE_DEVICE_COUNT=$device_count"
puts "FPGA_DEVICE_COUNT=$fpga_count"
puts "PROGRAMMING=NOT_PERFORMED"
foreach handle [list $targets_out $devices_out $properties_out $status_out] {close $handle}
catch {disconnect_hw_server}
catch {close_hw_manager}
if {$errors > 0} {exit 1}
exit 0
