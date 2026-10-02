`timescale 1ns/1ps
module sync_slave #(parameter integer LINK_CYCLES=0,LOCK_FRAMES=3,TIMEOUT_CYCLES=4096)(
 input wire clk,rst_n,sync_data,sync_valid,
 output reg sync_locked,output wire [63:0] slave_timestamp,
 output reg signed [63:0] offset_value,output reg trigger_pulse,echo_toggle,
 output reg [31:0] crc_errors,sequence_errors,timeout_errors,
 output wire [31:0] received_sequence,
 output wire scheduled_apply_valid,output wire [63:0] scheduled_apply_at,
 output wire fatal_error_event);
 import sync_defs::*;
 wire frame_valid,frame_error;
 wire [127:0] payload;
 sync_protocol decoder(.*);
 wire [7:0] cmd=payload[103:96];
 wire [31:0] seq=payload[95:64];
 wire [63:0] sent_time=payload[63:0];
 reg have_sequence;
 reg [31:0] last_sequence;
 reg [31:0] age;
 reg [7:0] good_frames;
 reg reset_pending,trigger_pending;
 reg [63:0] reset_at,trigger_at;
 wire sequential=!have_sequence || seq==last_sequence+32'd1;
 wire duplicate=have_sequence && seq==last_sequence;
 wire [31:0] sequence_delta=seq-last_sequence;
 wire forward_gap=!sequence_delta[31] && sequence_delta>1;
 wire known_cmd=cmd==CMD_SYNC || cmd==CMD_RESET_AT || cmd==CMD_TRIGGER_AT;
 wire accepted=frame_valid && sequential && known_cmd;
 // Last bit at +144, VALID boundary at +145, decoder valid consumed at +146.
 wire [63:0] target=sent_time+64'(FRAME_BITS+2+LINK_CYCLES);
 wire [63:0] expected_next=slave_timestamp+64'd1;
 wire [63:0] delta=target-expected_next;
 wire [63:0] event_lead=sent_time-slave_timestamp;
 assign fatal_error_event=frame_error || age==TIMEOUT_CYCLES-1 ||
  (frame_valid && (!sequential || !known_cmd ||
   (cmd!=CMD_SYNC && !(sync_locked && event_lead>2 && !event_lead[63] && !reset_pending && !trigger_pending))));
 assign scheduled_apply_valid=accepted && cmd==CMD_TRIGGER_AT && sync_locked &&
  event_lead>2 && !event_lead[63] && !reset_pending && !trigger_pending;
 assign scheduled_apply_at=sent_time;
 wire load=accepted && cmd==CMD_SYNC && !sync_locked;
 wire sync_clear=reset_pending && slave_timestamp==reset_at-64'd1;
 wire wrap_pulse;
 timestamp_counter counter(.clk(clk),.rst_n(rst_n),.sync_clear(sync_clear),.load(load),
  .load_value(target),.timestamp(slave_timestamp),.wrap_pulse(wrap_pulse));
 assign received_sequence=last_sequence;
 always @(posedge clk) begin
  if(!rst_n) begin
   sync_locked<=0;offset_value<=0;trigger_pulse<=0;echo_toggle<=0;
   crc_errors<=0;sequence_errors<=0;timeout_errors<=0;have_sequence<=0;
   last_sequence<=0;age<=0;good_frames<=0;reset_pending<=0;trigger_pending<=0;
   reset_at<=0;trigger_at<=0;
  end else begin
   trigger_pulse<=0;
   if(age<TIMEOUT_CYCLES) age<=age+1'b1;
   if(age==TIMEOUT_CYCLES-1) begin
    timeout_errors<=timeout_errors+1'b1;sync_locked<=0;good_frames<=0;
    have_sequence<=0;reset_pending<=0;trigger_pending<=0;
   end
   if(sync_clear) begin reset_pending<=0;trigger_pending<=0;end
   if(trigger_pending && slave_timestamp==trigger_at-64'd1) begin
    trigger_pulse<=sync_locked;trigger_pending<=0;
   end
   if(frame_error) begin
    crc_errors<=crc_errors+1'b1;sync_locked<=0;good_frames<=0;reset_pending<=0;trigger_pending<=0;
   end
   if(frame_valid) begin
    echo_toggle<=~echo_toggle;
    if(!sequential || !known_cmd) begin
     sequence_errors<=sequence_errors+1'b1;sync_locked<=0;good_frames<=0;
     reset_pending<=0;trigger_pending<=0;
     // Duplicate rejected; a forward gap establishes a new sequence checkpoint only.
     if(have_sequence && forward_gap) begin last_sequence<=seq;have_sequence<=1;end
    end else begin
     age<=0;last_sequence<=seq;have_sequence<=1;
     if(cmd==CMD_SYNC) begin
      offset_value<=delta;
      if(delta==0) begin
       if(good_frames<LOCK_FRAMES) good_frames<=good_frames+1'b1;
       if(good_frames>=LOCK_FRAMES-1) sync_locked<=1;
      end else begin sync_locked<=0;good_frames<=0;end
     end else if(sync_locked && event_lead>2 && !event_lead[63] && !reset_pending && !trigger_pending) begin
      if(cmd==CMD_RESET_AT) begin reset_pending<=1;reset_at<=sent_time;end
      if(cmd==CMD_TRIGGER_AT) begin trigger_pending<=1;trigger_at<=sent_time;end
     end else begin sequence_errors<=sequence_errors+1'b1;sync_locked<=0;good_frames<=0;end
    end
   end
  end
 end
endmodule
