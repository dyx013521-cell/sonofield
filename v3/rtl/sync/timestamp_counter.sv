`timescale 1ns/1ps
// Counter is modulo 2^64. Monotonic within an epoch; only explicit reset/load changes epoch.
module timestamp_counter(input wire clk,rst_n,input wire sync_clear,load,
 input wire [63:0] load_value,output reg [63:0] timestamp,output wire wrap_pulse);
 assign wrap_pulse=rst_n && !sync_clear && !load && (&timestamp);
 always @(posedge clk) begin
  if(!rst_n || sync_clear) timestamp<=64'd0;
  else if(load) timestamp<=load_value;
  else timestamp<=timestamp+64'd1;
 end
endmodule
