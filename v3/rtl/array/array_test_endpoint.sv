`timescale 1ns/1ps
module array_test_endpoint(input wire clk,rst_n,mmcm_locked,run,sync_locked,alive,fault,watchdog_alive,
 input wire scheduled_apply_valid,input wire [63:0] timestamp,scheduled_apply_at,
 output wire [15:0] serial_data,output wire shift_clock,latch_clock,output_disable,
 output wire serializer_start,serializer_busy,serializer_frame_done,serializer_overrun,
 output wire [63:0] waveform_active);
 reg had_lock=0,fatal_latched=0;
 always @(posedge clk) begin
  if(!run) begin had_lock<=0;fatal_latched<=0;end
  else begin
   if(sync_locked) had_lock<=1;
   if(had_lock && (fault || serializer_overrun)) fatal_latched<=1;
  end
 end
 // RUN already contains the core's reset/MMCM/link release. Reuse that
 // common release instead of reconverging independent raw-reset chains.
 (* ASYNC_REG="TRUE" *) reg [2:0] watchdog_pipe=0;
 always @(posedge clk or negedge watchdog_alive)
  if(!watchdog_alive) watchdog_pipe<=0;else watchdog_pipe<={watchdog_pipe[1:0],1'b1};
 wire serial_reset=watchdog_pipe[2] &&
  run && sync_locked && alive && !fault && !fatal_latched;
 reg [5:0] test_index=0;
 reg [63:0] waveform;
 always @* begin
  case(test_index)
   0: waveform=0;
   1: waveform=64'd1;
   2: waveform=64'haaaaaaaaaaaaaaaa;
   3: waveform=64'hffffffffffffffff;
   4: waveform=64'h5555555555555555;
   5: waveform=~64'd1;
   default: waveform={58'd0,test_index};
  endcase
 end
 // Pattern index resets with local RUN, not temporary sync loss. Both boards
 // advance only on an accepted scheduled command; reset both before new tests.
 always @(posedge clk) if(!run) test_index<=0;
  else if(serializer_start) test_index<=test_index+1'b1;
 assign serializer_start=scheduled_apply_valid && serial_reset && !serializer_overrun;
 wire [15:0] raw_data;wire raw_shift,raw_latch;
 serializer64 sender(.clk(clk),.rst_n(serial_reset),.start(serializer_start),.waveform(waveform),
  .scheduled(1'b1),.timestamp(timestamp),.apply_at(scheduled_apply_at),
  .serial_data(raw_data),.shift_clock(raw_shift),.latch_clock(raw_latch),
  .busy(serializer_busy),.frame_done(serializer_frame_done),.overrun(serializer_overrun),
  .waveform_active(waveform_active));
 assign serial_data=!serializer_overrun ? raw_data:16'd0;
 assign shift_clock=!serializer_overrun && raw_shift;
 assign latch_clock=!serializer_overrun && raw_latch;
 // PRE-PCB diagnostics can shift while physical outputs stay disabled. Enabling
 // real outputs requires a later reviewed PCB /OE contract and explicit arm.
 array_output_guard guard(.clk(clk),.rst_n(rst_n),.mmcm_locked(mmcm_locked),.run(run),
  .sync_locked(sync_locked),.array_test_arm(1'b0),.fatal_fault(fault),
  .watchdog_timeout(!alive),.frame_error(1'b0),.sequence_error(1'b0),
  .serializer_overrun(serializer_overrun),.output_disable(output_disable));
endmodule
