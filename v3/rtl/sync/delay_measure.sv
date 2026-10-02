`timescale 1ns/1ps
// Measures round-trip cycles. One-way estimate ONLY under a stated symmetric-link assumption.
// Includes receiver turnaround and return synchronizer latency, supplied as an explicit profile.
module delay_measure #(parameter integer TURNAROUND_CYCLES=148,TIMEOUT_CYCLES=4096)(
 input wire clk,rst_n,tx_event,echo_toggle,input wire [63:0] timestamp,
 output reg [31:0] delay_count,round_trip_count,output reg delay_valid,measurement_timeout);
 (* ASYNC_REG="TRUE" *) reg echo_meta,echo_sync;
 reg echo_previous,tx_previous,pending;
 reg [63:0] tx_time;
 reg [31:0] age;
 wire [63:0] elapsed=timestamp-tx_time;
 always @(posedge clk) begin
  if(!rst_n) begin
   echo_meta<=0;echo_sync<=0;echo_previous<=0;tx_previous<=0;pending<=0;tx_time<=0;age<=0;
   delay_count<=0;round_trip_count<=0;delay_valid<=0;measurement_timeout<=0;
  end else begin
   echo_meta<=echo_toggle;echo_sync<=echo_meta;echo_previous<=echo_sync;tx_previous<=tx_event;
   if(tx_event && !tx_previous) begin
    tx_time<=timestamp;pending<=1;age<=0;delay_valid<=0;measurement_timeout<=0;
   end else if(pending) begin
    age<=age+1'b1;
    if(echo_sync!=echo_previous) begin
     pending<=0;round_trip_count<=elapsed[31:0];
     if(elapsed>=TURNAROUND_CYCLES && elapsed<32'h80000000) begin
      delay_count<=(elapsed-TURNAROUND_CYCLES)>>1;delay_valid<=1;
     end
    end else if(age==TIMEOUT_CYCLES-1) begin pending<=0;measurement_timeout<=1;end
   end
  end
 end
endmodule
