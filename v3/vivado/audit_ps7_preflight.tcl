# Read existing routed TASK-001B artifacts; no IP generation, implementation,
# hardware programming, PS register access, board reset or PS initialization.
set root [file normalize [file join [file dirname [info script]] ..]]
set dest [file join $root evidence task001c_ps7]
file mkdir $dest
set expected [dict create {serial_data[0]} A20 {serial_data[1]} H16 {serial_data[2]} B19 {serial_data[3]} B20 {serial_data[4]} C20 {serial_data[5]} H17 {serial_data[6]} D20 {serial_data[7]} D18 {serial_data[8]} H18 {serial_data[9]} D19 {serial_data[10]} F20 {serial_data[11]} E19 {serial_data[12]} F19 {serial_data[13]} K17 {serial_data[14]} G20 {serial_data[15]} J18 shift_clock H20 latch_clock J20 output_disable L19]
set f [open [file join $dest current-pin-audit.tsv] w]
puts $f "role\tport\tball\tbank\tpin_func\tiostandard\tdrive\tslew\tresult"
foreach role {master slave} {
 open_checkpoint [file join $root evidence task001b $role routed.dcp]
 if {[get_property PART [current_design]] ne "xc7z010clg400-1"} {error "Wrong part"}
 foreach port [dict keys $expected] {
  set obj [get_ports $port]
  set ball [get_property PACKAGE_PIN $obj]
  set pin [get_package_pins $ball]
  set bank [get_property BANK $pin]
  set std [get_property IOSTANDARD $obj]
  set drive [get_property DRIVE $obj]
  set slew [get_property SLEW $obj]
  if {$ball ne [dict get $expected $port] || $bank!=35 || $std ne "LVCMOS33" || $drive!=4 || $slew ne "SLOW"} {error "Array pin changed: $role $port"}
  puts $f "$role\t$port\t$ball\t$bank\t[get_property PIN_FUNC $pin]\t$std\t$drive\t$slew\tPASS"
 }
 if {[llength [get_ports {serial_data[*] shift_clock latch_clock output_disable}]]!=19} {error "Array count !=19"}
 set p [open [file join $dest ${role}-fixed-pin-database.tsv] w]
 puts $p "ball\tbank\tpin_func"
 foreach pin [get_package_pins *] {
  set func [get_property PIN_FUNC $pin]
  if {[regexp {PS_|DDR|MIO|TCK|TDI|TDO|TMS} $func] || $pin eq "N18"} {
   puts $p "$pin\t[get_property BANK $pin]\t$func"
  }
 }
 close $p
 set info [open [file join $dest ${role}-preflight.txt] w]
 puts $info "SOURCE=EXISTING_TASK001B_ROUTED_CHECKPOINT_NOT_NEW_IMPLEMENTATION"
 puts $info "PART=[get_property PART [current_design]]"
 puts $info "PS7_CELL_COUNT=[llength [get_cells -hier -filter {REF_NAME == PS7}]]"
 puts $info "OUTPUT_DISABLE_NET=[get_nets -of_objects [get_ports output_disable]]"
 puts $info "N18=[get_property PACKAGE_PIN [get_ports clk50]]"
 foreach port {sync_clk sync_data sync_valid sync_reset sync_lock sync_echo trigger_out waveform_out} {
  puts $info "PIN_$port=[get_property PACKAGE_PIN [get_ports $port]]"
 }
 close $info
 close_design
}
close $f
puts "CURRENT_19_ARRAY_GPIO_ALL_BANK35_PASS"
exit
