`timescale 1ns/1ps
module array_output_guard(input wire clk,rst_n,mmcm_locked,run,sync_locked,
 array_test_arm,fatal_fault,watchdog_timeout,frame_error,sequence_error,serializer_overrun,
 output wire output_disable);
 wire permissive=rst_n && mmcm_locked && run && sync_locked && array_test_arm &&
  !(fatal_fault || watchdog_timeout || frame_error || sequence_error || serializer_overrun);
 // Assertion is independent of serializer state/clock; release takes three clocks.
 (* ASYNC_REG="TRUE" *) reg [2:0] enable_pipe=0;
 always @(posedge clk or negedge permissive)
  if(!permissive) enable_pipe<=0;else enable_pipe<={enable_pipe[1:0],1'b1};
 assign output_disable=!permissive || !enable_pipe[2];
endmodule
