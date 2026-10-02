`timescale 1ns/1ps
module top_clock_tb;
 reg master_ref=0,slave_ref=0,rst_n=0,link_enable=1;
 always #10 master_ref=~master_ref;
 // Deliberate 100 ppm crystal mismatch; slave timestamp MUST ignore this clock.
 always #10.001 slave_ref=~slave_ref;
 reg key_reset=1,key_trigger=1;
 wire ac,ad,av,ar,bl,be,at,bt,aw,bw;
 wire bc,bd,bv,br;
 assign #3 bc=ac && link_enable;
 assign #2 bd=ad;
 assign #2 bv=av;
 assign #2 br=ar;
 dual_sync_top #(.MASTER(1),.SIMULATION(1),.WAVEFORM_BIT(8),.KEY_DEBOUNCE_CYCLES(16)) a(
  .clk50(master_ref),.rst_n(rst_n),.sync_clk_in(1'b0),.sync_data_in(1'b0),.sync_valid_in(1'b0),.sync_reset_in(1'b0),
  .sync_lock_in(bl),.sync_echo_in(be),.reset_request_n(key_reset),.trigger_request_n(key_trigger),
  .sync_clk_out(ac),.sync_data_out(ad),.sync_valid_out(av),.sync_reset_out(ar),.sync_lock_out(),.sync_echo_out(),
  .trigger_out(at),.waveform_out(aw),.led_n());
 dual_sync_top #(.MASTER(0),.SIMULATION(1),.WAVEFORM_BIT(8)) b(
  .clk50(slave_ref),.rst_n(rst_n),.sync_clk_in(bc),.sync_data_in(bd),.sync_valid_in(bv),.sync_reset_in(br),
  .sync_lock_in(1'b0),.sync_echo_in(1'b0),.reset_request_n(1'b1),.trigger_request_n(1'b1),
  .sync_clk_out(),.sync_data_out(),.sync_valid_out(),.sync_reset_out(),.sync_lock_out(bl),.sync_echo_out(be),
  .trigger_out(bt),.waveform_out(bw),.led_n());
 integer aligned=0,checks=0;
 task automatic check(input bit yes,input string what);
  if(!yes)$fatal(1,"FAIL %s",what);else begin checks++;$display("PASS %s",what);end
 endtask
 always @(posedge master_ref) begin
  #8;
  if(link_enable && bl && a.sync_lock_out) begin
   if(a.stamp!==b.stamp)$fatal(1,"stale lock after clock loss or crystal drift A=%0d B=%0d",a.stamp,b.stamp);
   aligned++;
  end
 end
 initial begin
  repeat(10)@(posedge master_ref);#1;rst_n=1;
  wait(bl && a.sync_lock_out);
  repeat(4000)@(posedge master_ref);#8;check(aw==bw,"timestamp waveform matches with independent 100ppm local crystal");
  // delay_valid is cleared while each new measurement is in flight.
  wait(a.measured_valid);#1;
  $display("TOP_RTT roundtrip=%0d delay=%0d valid=%0d",a.measured_roundtrip,a.measured_delay,a.measured_valid);
  check(a.measured_valid && a.measured_roundtrip==148 && a.measured_delay==0,"default RTT turnaround profile matches physical-wrapper simulation");
  @(negedge master_ref);key_trigger=0;repeat(30)@(negedge master_ref);key_trigger=1;
  wait(at);#8;check(bt,"physical wrapper scheduled trigger");
  repeat(20)@(posedge master_ref);
  @(negedge master_ref);key_reset=0;repeat(30)@(negedge master_ref);key_reset=1;
  wait(a.stamp==0);#8;check(b.stamp==0,"physical wrapper scheduled reset");
  repeat(200)@(posedge master_ref);
  @(negedge master_ref);link_enable=0;
  repeat(1300)@(posedge slave_ref);#1;check(!bl && !bw && !bt,"local crystal watchdog fails closed on absent forwarded clock");
  @(negedge master_ref);link_enable=1;
  wait(bl && a.sync_lock_out);
  repeat(3000)@(posedge master_ref);#8;check(a.stamp==b.stamp,"fresh lock and equal epoch after clock resumes");
  $display("TOP_CLOCK_TB PASS checks=%0d aligned=%0d",checks,aligned);$finish;
 end
 initial begin #1000000;$fatal(1,"top test watchdog");end
endmodule
