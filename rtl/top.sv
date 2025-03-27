`default_nettype none
`include "mem_loader.sv"
`include "hub75.sv"

module top #(
  parameter FIFO_WIDTH = 64,
  parameter DATA_WIDTH = 32,
  parameter OUT_REG = 6,
  parameter ADDR_WIDTH = 8,
  parameter CLK_SPEED = 40_000_000
) (
  input wire clk,
  input wire s_axi_valid, 
  output logic s_axi_ready,
  input wire [DATA_WIDTH - 1 : 0] s_axi_data,

  input wire slow_clk,
  input wire reset_n,
  output logic r0_out,
  output logic g0_out,
  output logic b0_out,
  output logic r1_out,
  output logic g1_out,
  output logic b1_out,
  output logic [5 - 1 : 0 ] addr_out,
  output logic blank,
  output logic latch_out,
  output logic clk_out
);

wire [FIFO_WIDTH - 1 : 0] r0_in;
wire [FIFO_WIDTH - 1 : 0] g0_in;
wire [FIFO_WIDTH - 1 : 0] b0_in;
wire [FIFO_WIDTH - 1 : 0] r1_in;
wire [FIFO_WIDTH - 1 : 0] g1_in;
wire [FIFO_WIDTH - 1 : 0] b1_in;

wire axi_valid;
wire axi_ready;

mem_loader # (
    .FIFO_WIDTH(FIFO_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .OUT_REG(OUT_REG)
  )
  mem_loader_inst (
    .clk(clk),
    .s_axi_valid(s_axi_valid),
    .s_axi_ready(s_axi_ready),
    .s_axi_data(s_axi_data),
    .m_axi_valid(axi_valid),
    .m_axi_ready(axi_ready),
    .bram_red_0(r0_in),
    .bram_green_0(g0_in),
    .bram_blue_0(b0_in),
    .bram_red_1(r1_in),
    .bram_green_1(g1_in),
    .bram_blue_1(b1_in)
  );

  hub75 # (
    .FIFO_WIDTH(FIFO_WIDTH),
    .OUT_REG(OUT_REG),
    .CLK_SPEED(CLK_SPEED)
  )
  hub75_inst (
    .clk(slow_clk),
    .s_axi_valid(axi_valid),
    .s_axi_ready(axi_ready),
    .reset_n(reset_n),
    .r0_in(r0_in),
    .g0_in(g0_in),
    .b0_in(b0_in),
    .r1_in(r1_in),
    .g1_in(g1_in),
    .b1_in(b1_in),
    .r0_out(r0_out),
    .g0_out(g0_out),
    .b0_out(b0_out),
    .r1_out(r1_out),
    .g1_out(g1_out),
    .b1_out(b1_out),
    .addr_out(addr_out),
    .blank(blank),
    .latch_out(latch_out),
    .clk_out(clk_out)
  );
  
endmodule