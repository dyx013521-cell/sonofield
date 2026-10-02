`timescale 1ns/1ps
module sync_button #(parameter integer STABLE_CYCLES=250000)(
 input wire clk,rst_n,button_n,output reg pressed);
 (* ASYNC_REG="TRUE" *) reg [1:0] samples;
 reg stable;
 localparam integer WIDTH=(STABLE_CYCLES<2)?1:$clog2(STABLE_CYCLES);
 reg [WIDTH-1:0] count;
 always @(posedge clk) begin
  if(!rst_n) begin samples<=2'b11;stable<=1;count<=0;pressed<=0;end
  else begin
   samples<={samples[0],button_n};pressed<=0;
   if(samples[1]==stable) count<=0;
   else if(count==STABLE_CYCLES-1) begin stable<=samples[1];count<=0;pressed<=!samples[1];end
   else count<=count+1'b1;
  end
 end
endmodule
