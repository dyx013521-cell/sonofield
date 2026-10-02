`timescale 1ns/1ps
// One parameterized implementation, two physical wrappers with correct IO direction.
module dual_sync_top #(parameter bit MASTER=1,SIMULATION=0,parameter integer WAVEFORM_BIT=20,KEY_DEBOUNCE_CYCLES=250000)(
 input wire clk50,rst_n,sync_clk_in,sync_data_in,sync_valid_in,sync_reset_in,
 input wire sync_lock_in,sync_echo_in,reset_request_n,trigger_request_n,
 output wire sync_clk_out,sync_data_out,sync_valid_out,sync_reset_out,
 output wire sync_lock_out,sync_echo_out,trigger_out,waveform_out,output wire [3:0] led_n,
 output wire array_clk,array_locked,array_run,array_alive,array_fault,array_sync_locked,array_watchdog_alive,
 output wire [63:0] array_timestamp,scheduled_apply_at,output wire scheduled_apply_valid);
 wire clk,locked;
 clk_manager #(.SIMULATION(SIMULATION)) clocks(.clk_in(MASTER?clk50:sync_clk_in),.rst_n(rst_n),.clk(clk),.locked(locked));
 (* ASYNC_REG="TRUE" *) reg [2:0] reset_release=0;
 (* ASYNC_REG="TRUE" *) reg [2:0] mmcm_release=0;
 // Independent assertion paths avoid combinational logic before reset synchronizers.
 always @(posedge clk or negedge rst_n)
  if(!rst_n) reset_release<=0;else reset_release<={reset_release[1:0],1'b1};
 always @(posedge clk or negedge locked)
  if(!locked) mmcm_release<=0;else mmcm_release<={mmcm_release[1:0],1'b1};
 wire link_run;
 generate if(MASTER) assign link_run=1'b1;
 else begin:g_link_reset
  (* ASYNC_REG="TRUE" *) reg [2:0] release_pipe=0;
  always @(posedge clk or negedge sync_reset_in)
   if(!sync_reset_in) release_pipe<=0;else release_pipe<={release_pipe[1:0],1'b1};
  assign link_run=release_pipe[2];
 end endgenerate
 wire run=reset_release[2] && mmcm_release[2] && link_run;
 wire [63:0] stamp;
 assign array_clk=clk;assign array_locked=locked;assign array_run=run;
 assign array_timestamp=stamp;
 wire [31:0] measured_delay,measured_roundtrip;
 wire measured_valid,measure_timeout;
 generate if(MASTER) begin:g_master
  (* MARK_DEBUG="TRUE" *) wire [31:0] debug_delay=measured_delay,debug_roundtrip=measured_roundtrip;
  wire ready,tx_event,command_error,reset_due,trigger_due,wrap_pulse;
  reg array_command_error;
  // The transmitter reports errors on the falling edge. Capture them in the
  // rising-edge array domain before gating data pins; /OE remains independent.
  always @(posedge clk) if(!run) array_command_error<=0;else array_command_error<=command_error;
  assign array_alive=run;assign array_fault=array_command_error || measure_timeout;
  assign array_sync_locked=lock_pipe[1];assign array_watchdog_alive=run;
  // TX accepts on the falling edge; ready is already low at the following
  // rising edge where the array captures this accepted command.
  assign scheduled_apply_valid=trigger_request && !command_error;
  assign scheduled_apply_at=event_at;
  reg [9:0] cadence;
  reg request,reset_request,trigger_request,want_reset,want_trigger;
  reg [63:0] event_at;
  reg master_trigger;
  wire reset_pressed,trigger_pressed;
  sync_button #(.STABLE_CYCLES(KEY_DEBOUNCE_CYCLES)) reset_button(.clk(clk),.rst_n(run),.button_n(reset_request_n),.pressed(reset_pressed));
  sync_button #(.STABLE_CYCLES(KEY_DEBOUNCE_CYCLES)) trigger_button(.clk(clk),.rst_n(run),.button_n(trigger_request_n),.pressed(trigger_pressed));
  always @(posedge clk) begin
   if(!run) begin
    cadence<=0;request<=0;reset_request<=0;trigger_request<=0;want_reset<=0;want_trigger<=0;
    event_at<=0;master_trigger<=0;
   end else begin
    if(reset_pressed) want_reset<=1;
    if(trigger_pressed) want_trigger<=1;
    cadence<=cadence+1'b1;request<=0;reset_request<=0;trigger_request<=0;
    master_trigger<=trigger_due;
    if(ready) begin
     if(lock_pipe[1] && want_reset) begin reset_request<=1;event_at<=stamp+1024;want_reset<=0;end
     else if(lock_pipe[1] && want_trigger) begin trigger_request<=1;event_at<=stamp+1024;want_trigger<=0;end
     else if(cadence==0) request<=1;
    end
   end
  end
  timestamp_counter timer(.clk(clk),.rst_n(run),.sync_clear(reset_due),.load(1'b0),.load_value(64'd0),.timestamp(stamp),.wrap_pulse(wrap_pulse));
  sync_master tx(.clk(clk),.rst_n(run),.timestamp(stamp),.sync_start(request),.sync_reset(reset_request),
   .sync_trigger(trigger_request),.command_time(event_at),.sync_tx(sync_data_out),.sync_valid(sync_valid_out),
   .command_ready(ready),.tx_event(tx_event),.command_error(command_error),.reset_due(reset_due),.trigger_due(trigger_due));
  delay_measure delay_meter(.clk(clk),.rst_n(run),.tx_event(tx_event),.echo_toggle(sync_echo_in),
   .timestamp(stamp),.delay_count(measured_delay),.round_trip_count(measured_roundtrip),
   .delay_valid(measured_valid),.measurement_timeout(measure_timeout));
  (* ASYNC_REG="TRUE" *) reg [1:0] lock_pipe;
  always @(posedge clk) if(!run) lock_pipe<=0;else lock_pipe<={lock_pipe[0],sync_lock_in};
  assign sync_lock_out=lock_pipe[1];
  assign trigger_out=lock_pipe[1] && master_trigger;
  assign waveform_out=lock_pipe[1] && stamp[WAVEFORM_BIT];
  assign sync_echo_out=1'b0;
  assign sync_reset_out=run;
  if(SIMULATION) assign sync_clk_out=clk;
  else ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) forward_clock(.C(clk),.CE(1'b1),.D1(1'b1),.D2(1'b0),.R(1'b0),.S(1'b0),.Q(sync_clk_out));
  assign led_n=~{measure_timeout,measured_valid,lock_pipe[1],run};
 end else begin:g_slave
  reg alive=0;
  (* ASYNC_REG="TRUE" *) reg [1:0] alive_pipe=0;
  always @(posedge clk) if(!run) alive_pipe<=0;else alive_pipe<={alive_pipe[0],alive};
  wire slave_lock,slave_trigger,echo;
  wire signed [63:0] offset;
  wire [31:0] crc_errors,sequence_errors,timeout_errors,received_sequence;
  assign array_alive=alive_pipe[1];assign array_watchdog_alive=alive;
  assign array_sync_locked=slave_lock && alive_pipe[1] && run;
  wire receiver_error_event;
  reg array_receiver_error;
  always @(posedge clk) if(!run) array_receiver_error<=0;else array_receiver_error<=receiver_error_event;
  assign array_fault=array_receiver_error;
  sync_slave receiver(.clk(clk),.rst_n(run && alive_pipe[1]),.sync_data(sync_data_in),.sync_valid(sync_valid_in),
   .sync_locked(slave_lock),.slave_timestamp(stamp),.offset_value(offset),.trigger_pulse(slave_trigger),
   .echo_toggle(echo),.crc_errors(crc_errors),.sequence_errors(sequence_errors),.timeout_errors(timeout_errors),.received_sequence(received_sequence),
   .scheduled_apply_valid(scheduled_apply_valid),.scheduled_apply_at(scheduled_apply_at),.fatal_error_event(receiver_error_event));
  // Free-running local N18 clock supervises forwarded-clock loss. Not used for global time.
  (* ASYNC_REG="TRUE" *) reg [1:0] heartbeat_pipe;
  reg heartbeat_previous;
  reg [9:0] silence=0;
  reg [4:0] clock_heartbeat=0;
  always @(posedge clk) if(!run) clock_heartbeat<=0;else clock_heartbeat<=clock_heartbeat+1'b1;
  always @(posedge clk50) begin
   if(!rst_n) begin heartbeat_pipe<=0;heartbeat_previous<=0;silence<=0;alive<=0;end
   else begin
    heartbeat_pipe<={heartbeat_pipe[0],clock_heartbeat[4]};heartbeat_previous<=heartbeat_pipe[1];
    if(heartbeat_pipe[1]!=heartbeat_previous) begin silence<=0;alive<=1;end
    else if(!(&silence)) silence<=silence+1'b1;
    else alive<=0;
   end
  end
  // reset_release asserts asynchronously, releases only on the received clock.
  // Do not add a raw pushbutton-to-output combinational timing path.
  assign sync_lock_out=slave_lock && alive && locked && reset_release[2];
  assign trigger_out=sync_lock_out && slave_trigger;
  assign waveform_out=sync_lock_out && stamp[WAVEFORM_BIT];
  // Return echo/status are sampled through synchronizers at the master.
  assign sync_echo_out=echo;
  assign sync_clk_out=0;assign sync_data_out=0;assign sync_valid_out=0;assign sync_reset_out=0;
  assign led_n=~{|crc_errors,|sequence_errors,sync_lock_out,run};
 end endgenerate
endmodule

module ebaz_master(input wire clk50,rst_n,sync_lock,sync_echo,reset_request_n,trigger_request_n,
 output wire sync_clk,sync_data,sync_valid,sync_reset,trigger_out,waveform_out,output wire [3:0] led_n);
 dual_sync_top #(.MASTER(1)) core(.clk50(clk50),.rst_n(rst_n),.sync_clk_in(1'b0),.sync_data_in(1'b0),
  .sync_valid_in(1'b0),.sync_reset_in(1'b0),.sync_lock_in(sync_lock),.sync_echo_in(sync_echo),
  .sync_clk_out(sync_clk),.sync_data_out(sync_data),.sync_valid_out(sync_valid),.sync_reset_out(sync_reset),
  .reset_request_n(reset_request_n),.trigger_request_n(trigger_request_n),
  .sync_lock_out(),.sync_echo_out(),.trigger_out(trigger_out),.waveform_out(waveform_out),.led_n(led_n));
endmodule
module ebaz_slave(input wire clk50,rst_n,sync_clk,sync_data,sync_valid,sync_reset,
 output wire sync_lock,sync_echo,trigger_out,waveform_out,output wire [3:0] led_n);
 dual_sync_top #(.MASTER(0)) core(.clk50(clk50),.rst_n(rst_n),.sync_clk_in(sync_clk),.sync_data_in(sync_data),
  .sync_valid_in(sync_valid),.sync_reset_in(sync_reset),.sync_lock_in(1'b0),.sync_echo_in(1'b0),
  .sync_clk_out(),.sync_data_out(),.sync_valid_out(),.sync_reset_out(),.sync_lock_out(sync_lock),
  .sync_echo_out(sync_echo),.trigger_out(trigger_out),.waveform_out(waveform_out),
  .reset_request_n(1'b1),.trigger_request_n(1'b1),.led_n(led_n));
endmodule
