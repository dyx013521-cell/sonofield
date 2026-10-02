`timescale 1ns/1ps
module dual_serializer_sync_tb;
 reg master_ref=0,slave_ref=0,rst_n=0,link_enable=1,key_trigger=1;
 always #10 master_ref=~master_ref;always #10.001 slave_ref=~slave_ref;
 wire ac,ad,av,ar,bl,be,at,bt,aw,bw,bc,bd,bv,br;
 assign #3 bc=ac && link_enable;assign #2 bd=ad;assign #2 bv=av;assign #2 br=ar;
 wire aclk,alocked,arun,aalive,afault,alock,avalid;
 wire bclk,blocked,brun,balive,bfault,bvalid;
 wire array_alock,array_block,awd,bwd;
 wire [63:0] ats,bts,aapply,bapply;
 dual_sync_top #(.MASTER(1),.SIMULATION(1),.KEY_DEBOUNCE_CYCLES(16)) a(
  .clk50(master_ref),.rst_n(rst_n),.sync_clk_in(1'b0),.sync_data_in(1'b0),.sync_valid_in(1'b0),.sync_reset_in(1'b0),
  .sync_lock_in(bl),.sync_echo_in(be),.reset_request_n(1'b1),.trigger_request_n(key_trigger),
  .sync_clk_out(ac),.sync_data_out(ad),.sync_valid_out(av),.sync_reset_out(ar),.sync_lock_out(alock),.sync_echo_out(),
  .trigger_out(at),.waveform_out(aw),.led_n(),.array_clk(aclk),.array_locked(alocked),.array_run(arun),
  .array_alive(aalive),.array_fault(afault),.array_sync_locked(array_alock),.array_watchdog_alive(awd),.array_timestamp(ats),.scheduled_apply_valid(avalid),.scheduled_apply_at(aapply));
 dual_sync_top #(.MASTER(0),.SIMULATION(1)) b(
  .clk50(slave_ref),.rst_n(rst_n),.sync_clk_in(bc),.sync_data_in(bd),.sync_valid_in(bv),.sync_reset_in(br),
  .sync_lock_in(1'b0),.sync_echo_in(1'b0),.reset_request_n(1'b1),.trigger_request_n(1'b1),
  .sync_clk_out(),.sync_data_out(),.sync_valid_out(),.sync_reset_out(),.sync_lock_out(bl),.sync_echo_out(be),
  .trigger_out(bt),.waveform_out(bw),.led_n(),.array_clk(bclk),.array_locked(blocked),.array_run(brun),
  .array_alive(balive),.array_fault(bfault),.array_sync_locked(array_block),.array_watchdog_alive(bwd),.array_timestamp(bts),.scheduled_apply_valid(bvalid),.scheduled_apply_at(bapply));
 wire [15:0] asd,bsd;wire ash,ashl,adis,bs,blat,bdis;
 wire ast,ab,adone,ao,bst,bb,bdone,bo;wire [63:0] wa,wb;
 array_test_endpoint ea(.clk(aclk),.rst_n(rst_n),.mmcm_locked(alocked),.run(arun),.sync_locked(array_alock),.alive(aalive),.fault(afault),.watchdog_alive(awd),
  .timestamp(ats),.scheduled_apply_valid(avalid),.scheduled_apply_at(aapply),.serial_data(asd),.shift_clock(ash),.latch_clock(ashl),.output_disable(adis),
  .serializer_start(ast),.serializer_busy(ab),.serializer_frame_done(adone),.serializer_overrun(ao),.waveform_active(wa));
 array_test_endpoint eb(.clk(bclk),.rst_n(rst_n),.mmcm_locked(blocked),.run(brun),.sync_locked(array_block),.alive(balive),.fault(bfault),.watchdog_alive(bwd),
  .timestamp(bts),.scheduled_apply_valid(bvalid),.scheduled_apply_at(bapply),.serial_data(bsd),.shift_clock(bs),.latch_clock(blat),.output_disable(bdis),
  .serializer_start(bst),.serializer_busy(bb),.serializer_frame_done(bdone),.serializer_overrun(bo),.waveform_active(wb));
 integer af=0,bf=0,ap=0,bp=0,checks=0;
 reg [63:0] last_a;
 always @(posedge ash)ap++;
 always @(posedge bs)bp++;
 always @(posedge ashl) begin
  if(ap!=4)$fatal(1,"Master shift count");last_a=ats;ap=0;af++;
 end
 always @(posedge blat) begin
  if(bp!=4 || bts!==last_a || wa!==wb)$fatal(1,"dual latch mismatch at=%0d bt=%0d",last_a,bts);
  bp=0;bf++;checks++;
 end
 initial begin
  repeat(10)@(negedge master_ref);rst_n=1;wait(bl && alock);repeat(100)@(negedge master_ref);
  if(ash || ashl || bs || blat || !adis || !bdis || af || bf)$fatal(1,"unsolicited frame / output enabled");checks++;
  repeat(7)begin
   @(negedge master_ref);key_trigger=0;repeat(30)@(negedge master_ref);key_trigger=1;
   wait(adone);wait(bdone);repeat(100)@(negedge master_ref);
   if(ao || bo || !adis || !bdis)$fatal(1,"fault / unsafe diagnostic");checks++;
  end
  // Raw reset mid-frame must assert through shared RUN immediately. Independent
  // endpoint/core reset-release chains are deliberately absent.
  @(negedge master_ref);key_trigger=0;repeat(30)@(negedge master_ref);key_trigger=1;
  wait(bs);#1;rst_n=0;#1;
  if(asd || bsd || ash || bs || ashl || blat || !adis || !bdis)
   $fatal(1,"shared RUN reset did not clamp both serializers");checks++;
  ap=0;bp=0;repeat(10)@(negedge master_ref);rst_n=1;
  wait(bl && alock);repeat(100)@(negedge master_ref);
  // Lose the forwarded clock during the next shift. No partial latch may occur.
  @(negedge master_ref);key_trigger=0;repeat(30)@(negedge master_ref);key_trigger=1;
  wait(bs);@(negedge master_ref);link_enable=0;
  repeat(1300)@(posedge slave_ref);#1;
  if(bl || bs || blat || bsd || !bdis)$fatal(1,"watchdog array clamp");checks++;
  if(bf!=7)$fatal(1,"partial frame latched after clock loss");checks++;
  $display("DUAL_SERIALIZER_SYNC_TB PASS checks=%0d common_latches=%0d output_disable=1",checks,bf);$finish;
 end
 initial begin #2000000;$fatal(1,"dual serializer timeout af=%0d bf=%0d ao=%b bo=%b fault=%b/%b lock=%b/%b",af,bf,ao,bo,afault,bfault,alock,bl);end
endmodule
