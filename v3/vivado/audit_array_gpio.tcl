set root [file normalize [file join [file dirname [info script]] ..]]
set dest [file join $root evidence task001b gpio_audit]
file mkdir $dest
create_project -in_memory -part xc7z010clg400-1
read_verilog [file join $root rtl sync timestamp_counter.sv]
synth_design -top timestamp_counter -part xc7z010clg400-1
set f [open [file join $dest package-pins.tsv] w]
puts $f "ball\tbank\tpin_func"
foreach ball {A20 H16 B19 B20 C20 H17 D20 D18 H18 D19 F20 E19 F19 K17 G20 J18 G19 H20 J19 K18 K19 J20 L16 L19 M18 L20 M20 L17 M19 N20 P18 M17 N17 P20 R19 R18 T20 P19 T19 U20 U19 V20 N18 F9 G6 F6 J6} {
 set p [get_package_pins $ball]
 if {[llength $p]!=1} {error "Invalid ball $ball"}
 puts $f "$ball\t[get_property BANK $p]\t[get_property PIN_FUNC $p]"
}
close $f
set f [open [file join $dest bank-properties.txt] w]
foreach bank [get_iobanks] {puts $f [report_property -all -return_string $bank]}
close $f
set f [open [file join $dest tool-version.txt] w]
puts $f [version];puts $f "PART=xc7z010clg400-1"
close $f
exit
