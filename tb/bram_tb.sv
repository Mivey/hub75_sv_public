
module bram_tb;

  // Parameters
  localparam  DATA_WIDTH = 8;
  localparam  MEM_DEPTH = 256;
  localparam ADDR_WIDTH = $clog2(MEM_DEPTH);
  //localparam  INIT_FILE = 0;

  //Ports
  reg  clk;
  reg  w_en;
  reg  r_en;
  reg [DATA_WIDTH - 1 : 0] w_data;
  reg [ADDR_WIDTH - 1 : 0] w_addr;
  reg [ADDR_WIDTH - 1 : 0] r_addr;
  wire [DATA_WIDTH - 1 : 0] r_data;

  bram # (
         .DATA_WIDTH(DATA_WIDTH),
         .MEM_DEPTH(MEM_DEPTH)
         //.INIT_FILE(INIT_FILE)
       )
       bram_inst (
         .clk(clk),
         .w_en(w_en),
         .r_en(r_en),
         .w_data(w_data),
         .w_addr(w_addr),
         .r_addr(r_addr),
         .r_data(r_data)
       );

  always #5  clk = ! clk ;
  integer i;

  initial
  begin
    clk = 1'b0;
    $dumpfile("bram_tb.vcd");
    $dumpvars(0, bram_tb);

    #300

    $display("done");
    $finish;
    end

    initial begin
      w_en = 1'b0;
      r_en = 1'b0;

      #10
      r_addr = {(ADDR_WIDTH ) {1'b0}};
      #2
      r_en = 1'b1;
      for (i = 0; i < 4; i = i + 1) begin
        #10
        r_addr = r_addr + 1;
      end

      #10
      r_en = 1'b0;
      w_addr = {(ADDR_WIDTH ){1'b0}};
      w_data = 8'hDE;
      #10
      
      w_en = 1'b1; 

      #10
      w_addr = w_addr + 1;
      w_data = 8'hAD;
      #10
      w_addr = w_addr + 1;
      w_data = 8'hBE;
      #10
      w_addr = w_addr + 1;
      w_data = 8'hEF;
      #10
      w_addr = w_addr + 1;
      w_data = 8'hb0;
      #10
      w_addr = w_addr + 1;
      w_data = 8'h0B;
      #10
      w_en = 1'b0;
      r_en = 1'b0;

      #10
      r_addr = {(ADDR_WIDTH) {1'b0}};
      r_en = 1'b1;
      for (i = 0; i < 6; i++) begin
        #10
        r_addr = r_addr + 1;
      end


    end

  endmodule

