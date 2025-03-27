
module hub75_tb;

  // Parameters
  localparam  DATA_WIDTH = 0;
  localparam  OUT_REG = 0;
  localparam  CLK_SPEED = 0;

  //Ports
  reg  clk;
  reg  s_axi_valid;
  wire s_axi_ready;
  reg  reset_n;
  reg [DATA_WIDTH - 1 : 0] r0_in;
  reg [DATA_WIDTH - 1 : 0] g0_in;
  reg [DATA_WIDTH - 1 : 0] b0_in;
  reg [DATA_WIDTH - 1 : 0] r1_in;
  reg [DATA_WIDTH - 1 : 0] g1_in;
  reg [DATA_WIDTH - 1 : 0] b1_in;
  wire r0_out;
  wire g0_out;
  wire b0_out;
  wire r1_out;
  wire g1_out;
  wire b1_out;
  wire [5 - 1 : 0] addr_out;
  wire blank;
  wire latch_out;
  wire clk_out;

  hub75 # (
    .DATA_WIDTH(DATA_WIDTH),
    .OUT_REG(OUT_REG),
    .CLK_SPEED(CLK_SPEED)
  )
  hub75_inst (
    .clk(clk),
    .s_axi_valid(s_axi_valid),
    .s_axi_ready(s_axi_ready),
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

//always #5  clk = ! clk ;

endmodule