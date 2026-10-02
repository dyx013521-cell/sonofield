`timescale 1ns/1ps
module dual_sync_tb;
 import sync_defs::*;
 reg clk=0;always #10 clk=~clk;
 reg rst_n=0,start=0,reset_cmd=0,trigger_cmd=0;
 reg [63:0] command_time=0;
 wire [63:0] master_timestamp;
 wire tx,valid,ready,tx_event,cmd_error,reset_due,trigger_due,wrap;
 reg master_pulse;
 timestamp_counter master_counter(.clk(clk),.rst_n(rst_n),.sync_clear(reset_due),.load(1'b0),
  .load_value(64'd0),.timestamp(master_timestamp),.wrap_pulse(wrap));
 sync_master master(.clk(clk),.rst_n(rst_n),.timestamp(master_timestamp),.sync_start(start),
  .sync_reset(reset_cmd),.sync_trigger(trigger_cmd),.command_time(command_time),
  .sync_tx(tx),.sync_valid(valid),.command_ready(ready),.tx_event(tx_event),
  .command_error(cmd_error),.reset_due(reset_due),.trigger_due(trigger_due));
 always @(posedge clk) master_pulse<=rst_n && trigger_due;
 reg manual=0,manual_data=0,manual_valid=0,corrupt=0,drop=0;
 integer wire_bit=0;
 always @(negedge clk) if(!valid) wire_bit<=0;else wire_bit<=wire_bit+1;
 wire channel_data=manual?manual_data:(tx ^ (corrupt && wire_bit==37));
 wire channel_valid=manual?manual_valid:(valid && !drop);
 reg [2:0] data_delay=0,valid_delay=0;
 always @(negedge clk) begin data_delay<={data_delay[1:0],channel_data};valid_delay<={valid_delay[1:0],channel_valid};end
 wire slave_clk;assign #3 slave_clk=clk;
 wire [3:0] locks,pulses,echos;
 wire [63:0] stamps[0:3];wire signed [63:0] offsets[0:3];
 wire [31:0] crc_errors[0:3],seq_errors[0:3],timeouts[0:3],seqs[0:3];
 real flight_ns=2.0;
 genvar g;
 generate for(g=0;g<4;g=g+1) begin:slaves
  wire d,v;
  if(g==0) begin assign #(flight_ns) d=channel_data;assign #(flight_ns) v=channel_valid;end
  else begin assign #(flight_ns) d=data_delay[g-1];assign #(flight_ns) v=valid_delay[g-1];end
  sync_slave #(.LINK_CYCLES(g)) rx(.clk(slave_clk),.rst_n(rst_n),.sync_data(d),.sync_valid(v),
   .sync_locked(locks[g]),.slave_timestamp(stamps[g]),.offset_value(offsets[g]),.trigger_pulse(pulses[g]),
   .echo_toggle(echos[g]),.crc_errors(crc_errors[g]),.sequence_errors(seq_errors[g]),
   .timeout_errors(timeouts[g]),.received_sequence(seqs[g]));
 end endgenerate
 integer checks=0,aligned_cycles=0;integer k;
 reg check_alignment=1;
 always @(posedge clk) begin
  #8;
  if(rst_n && check_alignment) for(integer n=0;n<4;n=n+1) if(locks[n]) begin
   if(stamps[n]!==master_timestamp) $fatal(1,"TIMESTAMP drift lane%0d master=%0d slave=%0d offset=%0d",n,master_timestamp,stamps[n],offsets[n]);
   aligned_cycles=aligned_cycles+1;
  end
 end
 task automatic check(input bit condition,input string label);
  begin if(!condition)$fatal(1,"FAIL %s",label);checks++;$display("PASS %s",label);end
 endtask
 task automatic request(input [7:0] cmd,input [63:0] at_time);
  begin
   wait(ready);@(posedge clk);#1;
   flight_ns=$urandom_range(0,7)+0.25;
   command_time=at_time;start=cmd==CMD_SYNC;reset_cmd=cmd==CMD_RESET_AT;trigger_cmd=cmd==CMD_TRIGGER_AT;
   @(posedge clk);#1;start=0;reset_cmd=0;trigger_cmd=0;
   if(!cmd_error) begin wait(!ready);wait(ready);end
   repeat(12)@(posedge clk);#8;
  end
 endtask
 task automatic acquire;
  begin repeat(8) request(CMD_SYNC,0);check(&locks,"all delay profiles lock");end
 endtask
 task automatic raw_frame(input [31:0] seq,input [7:0] cmd,input [63:0] stamp,input integer extra);
  reg [127:0] p;reg [143:0] bits;reg [15:0] c;
  begin
   p={HEADER,BOARD_ID,cmd,seq,stamp};c=16'hffff;
   for(integer b=127;b>=0;b=b-1)c=crc_step(c,p[b]);
   bits={p,c};manual=1;
   for(integer b=143;b>=0;b=b-1) begin @(negedge clk);#1;manual_valid=1;manual_data=bits[b];end
   repeat(extra) begin @(negedge clk);#1;manual_valid=1;end
   @(negedge clk);#1;manual_valid=0;
   repeat(12)@(posedge clk);#8;manual=0;
  end
 endtask
 // Existing production counter tested at exact large-value and rollover boundaries.
 reg creset=0,cload=0,cclear=0;reg [63:0] cvalue=0;wire [63:0] cstamp;wire cwrap;
 timestamp_counter boundary(.clk(clk),.rst_n(creset),.sync_clear(cclear),.load(cload),.load_value(cvalue),.timestamp(cstamp),.wrap_pulse(cwrap));
 reg dreset=0,dtx=0,decho=0;wire [31:0] dcount,drtt;wire dvalid,dtimeout;
 delay_measure #(.TURNAROUND_CYCLES(10),.TIMEOUT_CYCLES(128)) dm(.clk(clk),.rst_n(dreset),.tx_event(dtx),.echo_toggle(decho),
  .timestamp(master_timestamp),.delay_count(dcount),.round_trip_count(drtt),.delay_valid(dvalid),.measurement_timeout(dtimeout));
 initial begin
  repeat(8)@(posedge clk);#1;rst_n=1;
  acquire();check(crc_errors[0]==0,"clean link no CRC errors");
  request(CMD_TRIGGER_AT,master_timestamp+400);
  wait(master_pulse);#8;check(&pulses,"scheduled trigger same logical tick across four delays");
  @(posedge clk);#8;check(!(|pulses),"trigger is one cycle");
  begin reg [63:0] reset_target;reset_target=master_timestamp+400;
   request(CMD_RESET_AT,reset_target);
   wait(master_timestamp==reset_target-60);
   request(CMD_SYNC,0); // Must be rejected while reset is pending: no old-epoch frame in flight.
   wait(master_timestamp==0);#8;check(stamps[0]==0 && stamps[1]==0 && stamps[2]==0 && stamps[3]==0,"scheduled reset same epoch with straddling snapshot suppressed");
  end
  acquire();
  corrupt=1;request(CMD_SYNC,0);corrupt=0;
  check(locks==0 && crc_errors[0]>0,"CRC corruption rejected and unlocks");acquire();
  raw_frame(seqs[0],CMD_SYNC,master_timestamp,0);
  check(locks==0 && seq_errors[0]>0,"duplicate frame rejected");acquire();
  drop=1;request(CMD_SYNC,0);drop=0;request(CMD_SYNC,0);
  check(locks==0,"missing frame sequence gap rejected");acquire();
  raw_frame(seqs[0]-1,CMD_SYNC,master_timestamp,0);
  check(locks==0,"older replay rejected");acquire();
  begin reg [31:0] last_seq;last_seq=seqs[0];
   raw_frame(last_seq+1,CMD_SYNC,master_timestamp,4);
   check(locks==0 && seqs[0]==last_seq,"overlong frame rejects valid CRC prefix without sequence update");
  end
  acquire();
  request(CMD_TRIGGER_AT,master_timestamp+10);
  check(locks==4'b1111,"late command rejected at master without corrupting link");
  repeat(4200)@(posedge clk);#8;check(locks==0 && timeouts[0]>0,"missing link heartbeat timeout");acquire();
  for(k=0;k<300;k=k+1) begin
   repeat($urandom_range(0,40))@(posedge clk);
   request(CMD_SYNC,0);
  end
  check(&locks,"continuous shared-clock no-drift run with random frame gaps");
  // CRC known vector independent of TX/RX state-machine implementation.
  begin reg [15:0] crc;reg [71:0] text;crc=16'hffff;text="123456789";
   for(k=71;k>=0;k=k-1)crc=crc_step(crc,text[k]);check(crc==16'h29b1,"CRC16 CCITT golden vector");end
  @(negedge clk);creset=1;cload=1;cvalue=64'd180000000000-64'd256;
  @(posedge clk);#1;cload=0;
  repeat(512)@(posedge clk);#1;check(cstamp==64'd180000000256,"one-hour 50MHz counter boundary (accelerated load, not elapsed hour)");
  @(negedge clk);cload=1;cvalue=64'hfffffffffffffffe;
  @(posedge clk);#1;cload=0;
  @(posedge clk);#1;check(cstamp==64'hffffffffffffffff && cwrap,"rollover announces wrap");
  @(posedge clk);#1;check(cstamp==0,"64bit modulo wrap");
  @(negedge clk);cclear=1;@(posedge clk);#1;check(cstamp==0,"explicit synchronous clear");cclear=0;
  // Randomized RTT with known turnaround and return synchronizer. Arithmetic remains conditional.
  for(k=0;k<8;k=k+1) begin
   integer pause_cycles;
   @(negedge clk);dreset=0;dtx=0;decho=0;
   repeat(4)@(negedge clk);dreset=1;dtx=1;
   @(negedge clk);dtx=0;pause_cycles=$urandom_range(12,35);
   repeat(pause_cycles)@(negedge clk);decho=1;
   wait(dvalid);#1;check(drtt==pause_cycles+3 && dcount==((drtt-10)>>1),"RTT timestamp golden latency and symmetric-delay estimate");
  end
  @(negedge clk);dtx=1;@(negedge clk);dtx=0;
  repeat(140)@(posedge clk);#1;check(dtimeout && !dvalid,"delay measurement timeout");
  $display("DUAL_SYNC_TB PASS checks=%0d aligned_samples=%0d hour_test=BOUNDARY_ONLY",checks,aligned_cycles);
  $finish;
 end
 initial begin #10000000;$fatal(1,"testbench watchdog");end
endmodule
