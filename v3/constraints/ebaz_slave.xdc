# EBAZ4205 expansion V1.1 source: docs/hardware_sources.json; see docs/PINOUT.md.
# Pin2 of P5 is POWER. This file is not permission to connect unknown board revisions.
set_property PACKAGE_PIN N18 [get_ports clk50]
set_property PACKAGE_PIN G19 [get_ports rst_n]
set_property PACKAGE_PIN N20 [get_ports sync_clk]
set_property PACKAGE_PIN M18 [get_ports sync_data]
set_property PACKAGE_PIN M20 [get_ports sync_valid]
set_property PACKAGE_PIN L17 [get_ports sync_reset]
set_property PACKAGE_PIN M17 [get_ports sync_lock]
set_property PACKAGE_PIN M19 [get_ports sync_echo]
set_property PACKAGE_PIN P20 [get_ports trigger_out]
set_property PACKAGE_PIN R19 [get_ports waveform_out]
set_property PACKAGE_PIN H20 [get_ports {led_n[0]}]
set_property PACKAGE_PIN K18 [get_ports {led_n[1]}]
set_property PACKAGE_PIN J20 [get_ports {led_n[2]}]
set_property PACKAGE_PIN L19 [get_ports {led_n[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports *]
set_property DRIVE 8 [get_ports -filter {DIRECTION == OUT}]
set_property SLEW SLOW [get_ports -filter {DIRECTION == OUT}]
create_clock -name local50 -period 20.000 [get_ports clk50]
set_input_jitter [get_clocks local50] 0.100
# 0.2ns uncertainty and IO values below are analysis budgets, NOT measurements.
set_clock_uncertainty 0.200 [get_clocks local50]
set_input_delay -clock local50 -max 5.000 [get_ports rst_n]
set_input_delay -clock local50 -min 0.500 [get_ports rst_n]

create_clock -name received50 -period 20.000 [get_ports sync_clk]
set_input_jitter [get_clocks received50] 0.100
set_clock_uncertainty 0.200 [get_clocks received50]
set_input_delay -clock received50 -clock_fall -max 4.000 [get_ports {sync_data sync_valid}]
set_input_delay -clock received50 -clock_fall -min 0.500 [get_ports {sync_data sync_valid}]
set_input_delay -clock received50 -max 4.000 [get_ports sync_reset]
set_input_delay -clock received50 -min 0.500 [get_ports sync_reset]
set_output_delay -clock received50 -max 5.000 [get_ports {sync_lock sync_echo trigger_out waveform_out led_n[*]}]
set_output_delay -clock received50 -min 0.500 [get_ports {sync_lock sync_echo trigger_out waveform_out led_n[*]}]
# local50 and received50 are physically asynchronous. No false_path or clock-group exception is applied.
# Cross-domain watchdog synchronizers are reported in CDC; STA alone cannot verify metastability.
set_clock_uncertainty 0.200 [get_clocks *]
