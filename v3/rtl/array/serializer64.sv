`timescale 1ns/1ps
module serializer64 #(
 parameter integer CHANNELS=64, LANES=16, BITS_PER_LANE=4,
 parameter integer HALF_CYCLES=10
)(input wire clk,rst_n,start,input wire [CHANNELS-1:0] waveform,
 input wire scheduled,input wire [63:0] timestamp,apply_at,
 output reg [LANES-1:0] serial_data,
 output reg shift_clock,latch_clock,busy,frame_done,overrun,
 output reg [CHANNELS-1:0] waveform_active);
 localparam IDLE=0,SETUP=1,HIGH=2,WAIT_APPLY=3,LATCH=4,FINISH=5;
 reg [2:0] state;
 reg [CHANNELS-1:0] waveform_shadow;
 reg [63:0] deadline;
 reg timed;
 integer count,bit_index,lane;
 wire [63:0] remaining=apply_at-timestamp;
 initial begin
  if(CHANNELS!=LANES*BITS_PER_LANE || HALF_CYCLES<2)
   $fatal(1,"invalid serializer parameters");
 end
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   serial_data<=0;shift_clock<=0;latch_clock<=0;busy<=0;frame_done<=0;
   overrun<=0;state<=IDLE;count<=0;bit_index<=0;waveform_shadow<=0;
   waveform_active<=0;deadline<=0;timed<=0;
  end else begin
   frame_done<=0;
   if(start && busy) overrun<=1;
   case(state)
    IDLE: if(start && !overrun) begin
     if(scheduled && (remaining[63] || remaining<2*HALF_CYCLES*BITS_PER_LANE+2)) overrun<=1;
     else begin
      waveform_shadow<=waveform;deadline<=apply_at;timed<=scheduled;
      for(lane=0;lane<LANES;lane=lane+1)
       serial_data[lane]<=waveform[lane*BITS_PER_LANE+BITS_PER_LANE-1];
      bit_index<=BITS_PER_LANE-1;count<=HALF_CYCLES-1;busy<=1;state<=SETUP;
     end
    end
    SETUP: if(count==0) begin shift_clock<=1;count<=HALF_CYCLES-1;state<=HIGH;end
           else count<=count-1;
    HIGH: if(count==0) begin
     shift_clock<=0;
     if(bit_index==0) begin state<=WAIT_APPLY;end
     else begin
      bit_index<=bit_index-1;count<=HALF_CYCLES-1;state<=SETUP;
      for(lane=0;lane<LANES;lane=lane+1)
       serial_data[lane]<=waveform_shadow[lane*BITS_PER_LANE+bit_index-1];
     end
    end else count<=count-1;
    WAIT_APPLY: begin
     if(!timed || timestamp==deadline-1) begin
      latch_clock<=1;waveform_active<=waveform_shadow;count<=HALF_CYCLES-1;state<=LATCH;
     end else if((timestamp-deadline)<64'h8000000000000000) begin
      overrun<=1;busy<=0;serial_data<=0;state<=IDLE;
     end
    end
    LATCH: if(count==0) begin latch_clock<=0;serial_data<=0;state<=FINISH;end
           else count<=count-1;
    FINISH: begin busy<=0;frame_done<=1;state<=IDLE;end
    default: begin overrun<=1;busy<=0;serial_data<=0;shift_clock<=0;latch_clock<=0;state<=IDLE;end
   endcase
  end
 end
endmodule
