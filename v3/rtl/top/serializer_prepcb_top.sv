`timescale 1ns/1ps
module serializer_prepcb_core #(parameter bit MASTER=1)(
 input wire clk50,rst_n,sync_clk_in,sync_data_in,sync_valid_in,sync_reset_in,
 sync_lock_in,sync_echo_in,reset_request_n,trigger_request_n,
 output wire sync_clk_out,sync_data_out,sync_valid_out,sync_reset_out,
 sync_lock_out,sync_echo_out,trigger_out,waveform_out,led_sync_n,
 output wire [15:0] serial_data,output wire shift_clock,latch_clock,output_disable);
 wire clk,locked,run,alive,fault,apply_valid,link_lock,array_lock,watchdog_alive;
 wire [63:0] timestamp,apply_at,active;
 wire start,busy,done,overrun;
 dual_sync_top #(.MASTER(MASTER)) core(
  .clk50(clk50),.rst_n(rst_n),.sync_clk_in(sync_clk_in),.sync_data_in(sync_data_in),
  .sync_valid_in(sync_valid_in),.sync_reset_in(sync_reset_in),.sync_lock_in(sync_lock_in),.sync_echo_in(sync_echo_in),
  .reset_request_n(reset_request_n),.trigger_request_n(trigger_request_n),
  .sync_clk_out(sync_clk_out),.sync_data_out(sync_data_out),.sync_valid_out(sync_valid_out),.sync_reset_out(sync_reset_out),
  .sync_lock_out(link_lock),.sync_echo_out(sync_echo_out),.trigger_out(trigger_out),.waveform_out(waveform_out),.led_n(),
  .array_clk(clk),.array_locked(locked),.array_run(run),.array_alive(alive),.array_fault(fault),
  .array_sync_locked(array_lock),.array_watchdog_alive(watchdog_alive),
  .array_timestamp(timestamp),.scheduled_apply_valid(apply_valid),.scheduled_apply_at(apply_at));
 assign sync_lock_out=link_lock;assign led_sync_n=!link_lock;
 array_test_endpoint endpoint(.clk(clk),.rst_n(rst_n),.mmcm_locked(locked),.run(run),.sync_locked(array_lock),.alive(alive),.fault(fault),.watchdog_alive(watchdog_alive),
  .timestamp(timestamp),.scheduled_apply_valid(apply_valid),.scheduled_apply_at(apply_at),.serial_data(serial_data),
  .shift_clock(shift_clock),.latch_clock(latch_clock),.output_disable(output_disable),
  .serializer_start(start),.serializer_busy(busy),.serializer_frame_done(done),.serializer_overrun(overrun),.waveform_active(active));
 // probe0: [31:0] timestamp,32 lock,33 alive,34 MMCM,35 RUN,36 fault,
 // 37 start,38 busy,39 done,40 overrun,[56:41] data,57 shift,58 latch,
 // 59 disable,60 accepted APPLY, [63:61] reserved zero.
 wire [63:0] debug_probe={3'd0,apply_valid,output_disable,latch_clock,shift_clock,serial_data,
  overrun,done,busy,start,fault,run,locked,alive,array_lock,timestamp[31:0]};
 ila_prepcb debug_ila(.clk(clk),.probe0(debug_probe));
endmodule

module ebaz_master_serializer_prepcb(
 input wire clk50,rst_n,sync_lock,sync_echo,reset_request_n,trigger_request_n,
 output wire sync_clk,sync_data,sync_valid,sync_reset,trigger_out,waveform_out,led_sync_n,
 output wire [15:0] serial_data,output wire shift_clock,latch_clock,output_disable);
 serializer_prepcb_core #(.MASTER(1)) core(
  .clk50(clk50),.rst_n(rst_n),.sync_clk_in(1'b0),.sync_data_in(1'b0),.sync_valid_in(1'b0),.sync_reset_in(1'b0),
  .sync_lock_in(sync_lock),.sync_echo_in(sync_echo),.reset_request_n(reset_request_n),.trigger_request_n(trigger_request_n),
  .sync_clk_out(sync_clk),.sync_data_out(sync_data),.sync_valid_out(sync_valid),.sync_reset_out(sync_reset),
  .sync_lock_out(),.sync_echo_out(),.trigger_out(trigger_out),.waveform_out(waveform_out),.led_sync_n(led_sync_n),
  .serial_data(serial_data),.shift_clock(shift_clock),.latch_clock(latch_clock),.output_disable(output_disable));
endmodule
module ebaz_slave_serializer_prepcb(
 input wire clk50,rst_n,sync_clk,sync_data,sync_valid,sync_reset,
 output wire sync_lock,sync_echo,trigger_out,waveform_out,led_sync_n,
 output wire [15:0] serial_data,output wire shift_clock,latch_clock,output_disable);
 serializer_prepcb_core #(.MASTER(0)) core(
  .clk50(clk50),.rst_n(rst_n),.sync_clk_in(sync_clk),.sync_data_in(sync_data),.sync_valid_in(sync_valid),.sync_reset_in(sync_reset),
  .sync_lock_in(1'b0),.sync_echo_in(1'b0),.reset_request_n(1'b1),.trigger_request_n(1'b1),
  .sync_clk_out(),.sync_data_out(),.sync_valid_out(),.sync_reset_out(),.sync_lock_out(sync_lock),.sync_echo_out(sync_echo),
  .trigger_out(trigger_out),.waveform_out(waveform_out),.led_sync_n(led_sync_n),
  .serial_data(serial_data),.shift_clock(shift_clock),.latch_clock(latch_clock),.output_disable(output_disable));
endmodule
