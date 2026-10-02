`timescale 1ns/1ps
module serializer64_tb;
 reg clk=0;always #10 clk=~clk;
 reg rst_n=0,start=0,scheduled=0;
 reg [63:0] waveform=0,timestamp=0,apply_at=0;
 always @(posedge clk) if(!rst_n)timestamp<=0;else timestamp<=timestamp+1;
 wire [15:0] serial_data;wire shift_clock,latch_clock,busy,frame_done,overrun;
 wire [63:0] waveform_active;
 serializer64 dut(.*);
 reg [7:0] shift_model[0:15],latched_model[0:15];
 integer pulses=0,frames=0,checks=0,i;
 reg [63:0] expected;
 always @(posedge shift_clock) begin
  pulses++;
  for(integer n=0;n<16;n++) shift_model[n]={shift_model[n][6:0],serial_data[n]};
 end
 always @(posedge latch_clock) begin
  if(pulses!=4)$fatal(1,"shift pulse count %0d",pulses);
  for(integer n=0;n<16;n++) begin
   latched_model[n]=shift_model[n];
   if(latched_model[n][3:0]!==expected[4*n+:4])$fatal(1,"595 Q[3:0] lane %0d",n);
  end
  if(scheduled && timestamp!==apply_at)$fatal(1,"deadline got=%0d expected=%0d",timestamp,apply_at);
  frames++;checks+=17;
 end
 task automatic frame(input reg [63:0] bits,input bit timed);
  @(negedge clk);pulses=0;expected=bits;waveform=bits;scheduled=timed;apply_at=timestamp+150;start=1;
  @(negedge clk);start=0;waveform=~bits; // capture must isolate subsequent input changes
  wait(frame_done);#1;
  if(busy || waveform_active!==bits)$fatal(1,"busy/active capture");
  checks++;repeat(2)@(negedge clk);
 endtask
 reg mmcm_locked=1,run=1,sync_locked=1,array_test_arm=1,fatal_fault=0;
 reg watchdog_timeout=0,frame_error=0,sequence_error=0,serializer_overrun=0;
 wire output_disable;
 array_output_guard guard(.*);
 task automatic safe_check(input string why);
  #1;if(!output_disable)$fatal(1,"unsafe guard: %s",why);checks++;
 endtask
 initial begin
  for(i=0;i<16;i++)begin shift_model[i]=8'hd3;latched_model[i]=0;end
  repeat(4)@(negedge clk);rst_n=1;
  frame(0,0);frame('1,0);frame(64'h5555555555555555,0);frame(64'haaaaaaaaaaaaaaaa,1);
  for(i=0;i<64;i++)begin frame(64'd1<<i,0);frame(~(64'd1<<i),1);end
  for(i=0;i<256;i++)frame({$urandom,$urandom},i%2);
  // Mid-frame reset cannot publish a partial payload.
  @(negedge clk);start=1;scheduled=0;waveform=64'hbeef;
  @(negedge clk);start=0;wait(shift_clock);#3;rst_n=0;safe_check("reset");
  if(shift_clock || latch_clock || serial_data || busy)$fatal(1,"reset outputs");
  repeat(4)@(negedge clk);rst_n=1;
  @(negedge clk);pulses=0;expected=64'h1234567890abcdef;waveform=expected;start=1;
  @(negedge clk);start=0;repeat(3)@(negedge clk);start=1;
  @(negedge clk);start=0;#1;if(!overrun)$fatal(1,"no overrun");
  serializer_overrun=overrun;safe_check("overrun during shift");
  rst_n=0;repeat(3)@(negedge clk);rst_n=1;serializer_overrun=0;
  repeat(5)@(negedge clk);if(output_disable)$fatal(1,"guard release");
  // Hold a scheduled frame in flight while injecting each independent fault.
  @(negedge clk);pulses=0;expected=64'h5a5a12345678cdef;waveform=expected;
  scheduled=1;apply_at=timestamp+500;start=1;
  @(negedge clk);start=0;wait(shift_clock);#1;
  if(!busy)$fatal(1,"fault tests must be mid-frame");
  sync_locked=0;safe_check("sync lost");sync_locked=1;repeat(5)@(negedge clk);
  mmcm_locked=0;safe_check("MMCM unlock");mmcm_locked=1;repeat(5)@(negedge clk);
  watchdog_timeout=1;safe_check("watchdog");watchdog_timeout=0;repeat(5)@(negedge clk);
  frame_error=1;safe_check("CRC/frame error");frame_error=0;repeat(5)@(negedge clk);
  sequence_error=1;safe_check("sequence error");sequence_error=0;repeat(5)@(negedge clk);
  fatal_fault=1;safe_check("fatal");fatal_fault=0;repeat(5)@(negedge clk);
  array_test_arm=0;safe_check("disarm");array_test_arm=1;repeat(5)@(negedge clk);
  if(!busy)$fatal(1,"serializer completed before mid-frame fault tests");checks++;
  rst_n=0;repeat(3)@(negedge clk);rst_n=1;
  // Deadline too short is rejected without a shift edge.
  @(negedge clk);scheduled=1;apply_at=timestamp+5;start=1;
  @(negedge clk);start=0;#1;if(!overrun || busy || shift_clock)$fatal(1,"late command accepted");checks++;
  $display("SERIALIZER64_TB PASS checks=%0d reconstructed_frames=%0d virtual_595=16 bits_per_595=8 used_Q=0..3",checks,frames);$finish;
 end
 initial begin #2000000;$fatal(1,"serializer timeout");end
endmodule
