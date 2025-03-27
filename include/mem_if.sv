`timescale 1ns / 1ns

interface mem_if #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 8
) (
    input wire clk
);
  logic                  s_axi_ready;
  logic                  s_axi_valid;
  logic                  rst_ptr;
  logic [DATA_WIDTH-1:0] s_axi_data;
  logic                  m_axi_valid;
  logic                  m_axi_ready;
  logic [ADDR_WIDTH-1:0] o_addr;
  logic [DATA_WIDTH-1:0] r0_reg;
  logic [DATA_WIDTH-1:0] g0_reg;
  logic [DATA_WIDTH-1:0] b0_reg;
  logic [DATA_WIDTH-1:0] r1_reg;
  logic [DATA_WIDTH-1:0] g1_reg;
  logic [DATA_WIDTH-1:0] b1_reg;

  default clocking cb @(posedge clk);
    default input #1 output #3;
    input #1 s_axi_ready, o_addr, r0_reg, g0_reg, b0_reg, clk, r1_reg, g1_reg, b1_reg, m_axi_valid;
    output #3 s_axi_valid, rst_ptr, m_axi_ready, s_axi_data;
  endclocking

endinterface  //my_axi(input clk)
