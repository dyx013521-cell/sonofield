`timescale 1ns/1ps
module sync_master(input wire clk,rst_n,input wire [63:0] timestamp,
 input wire sync_start,sync_reset,sync_trigger,input wire [63:0] command_time,
 output reg sync_tx,sync_valid,output wire command_ready,
 output reg tx_event,command_error,output wire reset_due,trigger_due);
 import sync_defs::*;
 reg [127:0] payload;
 reg [15:0] crc;
 reg [7:0] index;
 reg [31:0] sequence_id;
 reg busy,reset_pending,trigger_pending;
 reg [63:0] reset_at,trigger_at;
 wire [63:0] lead=command_time-timestamp;
 wire [7:0] cmd=sync_reset?CMD_RESET_AT:(sync_trigger?CMD_TRIGGER_AT:CMD_SYNC);
 wire [127:0] first_payload={HEADER,BOARD_ID,cmd,sequence_id,(cmd==CMD_SYNC?timestamp:command_time)};
 assign command_ready=!busy;
 assign reset_due=reset_pending && timestamp==reset_at-64'd1;
 assign trigger_due=trigger_pending && timestamp==trigger_at-64'd1;
 // Falling-edge launch gives a half cycle to the rising-edge receiver.
 always @(negedge clk) begin
  if(!rst_n) begin
   sync_tx<=0;sync_valid<=0;tx_event<=0;command_error<=0;busy<=0;index<=0;
   sequence_id<=0;payload<=0;crc<=16'hffff;reset_pending<=0;trigger_pending<=0;
   reset_at<=0;trigger_at<=0;
  end else begin
   tx_event<=0;command_error<=0;
   if(reset_pending && timestamp==0) reset_pending<=0;
   if(trigger_pending && (timestamp==trigger_at || timestamp==0)) trigger_pending<=0;
   if(!busy) begin
    sync_valid<=0;sync_tx<=0;
    if(sync_start || sync_reset || sync_trigger) begin
     // No snapshot may straddle an epoch reset. Bound the scheduling horizon so
     // suppressed SYNC heartbeats cannot exceed the receiver timeout.
     if((sync_start && reset_pending) ||
        ((sync_reset || sync_trigger) && (lead<FRAME_BITS+32 || lead>2048 || lead[63] || reset_pending || trigger_pending)))
      command_error<=1;
     else begin
      payload<=first_payload<<1;crc<=crc_step(16'hffff,first_payload[127]);
      sync_tx<=first_payload[127];sync_valid<=1;busy<=1;index<=1;tx_event<=1;
      sequence_id<=sequence_id+1'b1;
      if(sync_reset) begin reset_pending<=1;reset_at<=command_time;end
      if(sync_trigger) begin trigger_pending<=1;trigger_at<=command_time;end
     end
    end
   end else if(index<PAYLOAD_BITS) begin
    sync_tx<=payload[127];payload<=payload<<1;crc<=crc_step(crc,payload[127]);index<=index+1'b1;
   end else if(index<FRAME_BITS) begin
    sync_tx<=crc[15];crc<=crc<<1;index<=index+1'b1;
   end else begin busy<=0;sync_valid<=0;end
  end
 end
endmodule
