`default_nettype none
`timescale 1ns/1ns

module bram #(
    parameter DATA_WIDTH = 24,
    parameter ADDR_WIDTH = 10
  ) (
    input wire clk,
    input wire i_we,
    input wire i_re,
    input wire [DATA_WIDTH - 1 : 0] i_data,
    input wire [ADDR_WIDTH - 1 : 0] addr,
    output logic [DATA_WIDTH - 1 : 0] o_data
  );

  localparam MEM_DEPTH = 2 ** ADDR_WIDTH;
  var logic [DATA_WIDTH - 1 : 0] mem [0 : MEM_DEPTH - 1];

  always_ff @ (posedge clk)
  begin
    if (i_we)
      mem[addr] <= i_data;

    if (i_re)
      o_data <= mem[addr];
  end
endmodule
