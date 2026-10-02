`timescale 1ns/1ps
package sync_defs;
  localparam integer PAYLOAD_BITS=128, FRAME_BITS=144;
  localparam logic [15:0] HEADER=16'h5346;
  localparam logic [7:0] BOARD_ID=8'h01;
  localparam logic [7:0] CMD_SYNC=8'h01, CMD_RESET_AT=8'h02, CMD_TRIGGER_AT=8'h03;
  function automatic [15:0] crc_step(input [15:0] crc,input bit data_bit);
    crc_step={crc[14:0],1'b0} ^ ((crc[15]^data_bit)?16'h1021:16'h0000);
  endfunction
endpackage

// 128 payload bits followed by CRC16-CCITT, MSB first. VALID must fall after 144 bits.
module sync_protocol(input wire clk,rst_n,sync_data,sync_valid,
 output reg frame_valid,frame_error,output reg [127:0] payload);
 import sync_defs::*;
 reg [7:0] count;
 reg [127:0] shift_payload;
 reg [15:0] crc,rx_crc;
 reg complete,overlong;
 wire [15:0] next_crc={rx_crc[14:0],sync_data};
 always @(posedge clk) begin
  if(!rst_n) begin
   count<=0;crc<=16'hffff;rx_crc<=0;shift_payload<=0;payload<=0;
   complete<=0;overlong<=0;frame_valid<=0;frame_error<=0;
  end else begin
   frame_valid<=0;frame_error<=0;
   if(!sync_valid) begin
    if(count!=0) begin
     // Final CRC bit was captured on the previous edge. Compare registered
     // words here, retaining the original VALID-fall commit cycle and avoiding
     // a long half-cycle path from the raw serial input through CRC equality.
     if(complete && rx_crc==crc && shift_payload[127:112]==HEADER &&
        shift_payload[111:104]==BOARD_ID && !overlong) frame_valid<=1;
     else frame_error<=1;
    end
    count<=0;crc<=16'hffff;rx_crc<=0;complete<=0;overlong<=0;
   end else if(complete) begin
    overlong<=1; // Reject the whole overlong frame, including its valid CRC prefix.
   end else begin
    count<=count+1'b1;
    if(count<PAYLOAD_BITS) begin
     shift_payload<={shift_payload[126:0],sync_data};
     crc<=crc_step(crc,sync_data);
    end else begin
     rx_crc<=next_crc;
     if(count==FRAME_BITS-1) begin
      complete<=1;payload<=shift_payload;
     end
    end
   end
  end
 end
endmodule
