`timescale 1ns/1ps
module clk_manager #(parameter bit SIMULATION=0)(input wire clk_in,rst_n,
 output wire clk,locked);
 generate if(SIMULATION) begin:g_sim
  assign clk=clk_in;assign locked=rst_n;
 end else begin:g_hw
  wire ibuf_clk,feedback,feedback_buf,mmcm_clk;
  IBUF input_buffer(.I(clk_in),.O(ibuf_clk));
  MMCME2_BASE #(.CLKIN1_PERIOD(20.0),.DIVCLK_DIVIDE(1),.CLKFBOUT_MULT_F(20.0),
   .CLKOUT0_DIVIDE_F(20.0),.STARTUP_WAIT("FALSE")) mmcm(
   .CLKIN1(ibuf_clk),.CLKFBIN(feedback_buf),.RST(!rst_n),.PWRDWN(1'b0),
   .CLKFBOUT(feedback),.CLKOUT0(mmcm_clk),.LOCKED(locked));
  BUFG feedback_buffer(.I(feedback),.O(feedback_buf));
  BUFG output_buffer(.I(mmcm_clk),.O(clk));
 end endgenerate
endmodule
