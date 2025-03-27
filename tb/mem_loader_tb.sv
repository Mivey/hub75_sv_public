`timescale 1ns / 1ns

`include "../include/output_packet.sv"
`include "../include/mem_if.sv"

module mem_loader_tb;

  localparam DATA_WIDTH = 32;
  localparam FIFO_WIDTH = 64;
  localparam ADDR_WIDTH = 8;
  localparam OUT_REG = 6;

  bit clk = 0;
  always #5 clk = ~clk;
  mem_if my_mem (clk);
  bit [DATA_WIDTH - 1 : 0] temp;

  mem_loader #(
      .FIFO_WIDTH(FIFO_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH),
      .OUT_REG(OUT_REG)
  ) mem_loader_inst (
      .clk(my_mem.clk),
      .s_axi_valid(my_mem.s_axi_valid),
      .s_axi_ready(my_mem.s_axi_ready),
      .rst_ptr(my_mem.rst_ptr),
      .s_axi_data(my_mem.s_axi_data),
      .m_axi_valid(my_mem.m_axi_valid),
      .m_axi_ready(my_mem.m_axi_ready),
      .o_addr(my_mem.o_addr),
      .bram_red_0(my_mem.r0_reg),
      .bram_green_0(my_mem.g0_reg),
      .bram_blue_0(my_mem.b0_reg),
      .bram_red_1(my_mem.r1_reg),
      .bram_green_1(my_mem.g1_reg),
      .bram_blue_1(my_mem.b1_reg)
  );

  initial begin
    $dumpfile("mem_loader.vcd");
    $dumpvars(2, mem_loader_tb);
    $dumpvars(2, mem_loader);
    #200000;
    $finish;
  end


  initial begin

    input_packet tx_data[64];
    output_packet r0_data[256], g0_data[256], b0_data[256];
    output_packet r1_data[256], g1_data[256], b1_data[256];

    my_mem.cb.s_axi_valid <= 1'b0;
    my_mem.cb.rst_ptr <= 1'b1;
    my_mem.cb.m_axi_ready <= 1'b0;
    my_mem.cb.s_axi_data <= '0;

    WRONG_PROPERTY_IDIOT :
    assert ((OUT_REG == 3) || (OUT_REG == 6))
    else $error("boop");

    repeat (2) @my_mem.cb;
    my_mem.cb.rst_ptr <= 1'b0;
    @my_mem.cb;
    foreach (tx_data[i]) tx_data[i] = new();

    for (int k = 0; k < 32; k++) begin
      ///////////////Generate random data and parse it//////////////
      for (int y = 0; y < 64; y++) begin
        tx_data[y].randomize();
      end

      for (int h = 0; h < 8; h++) begin
        r0_data[h+k*8] = new(.p(tx_data), .a(h + 0), .r_num(k), .mi(my_mem));
        g0_data[h+k*8] = new(.p(tx_data), .a(h + 8), .r_num(k), .mi(my_mem));
        b0_data[h+k*8] = new(.p(tx_data), .a(h + 16), .r_num(k), .mi(my_mem));

        r0_data[h+k*8].create_dout();
        g0_data[h+k*8].create_dout();
        b0_data[h+k*8].create_dout();

      end
      ////////////send randomized data to DUT/////////////////
      for (int j = 0; j < 64; j++) begin
        my_mem.cb.s_axi_valid <= 1'b1;
        my_mem.cb.s_axi_data  <= tx_data[j].data_in;
        @my_mem.cb;

        if (!my_mem.s_axi_ready) @(my_mem.s_axi_ready);
      end
      repeat (2) @my_mem.cb;
      my_mem.cb.s_axi_valid <= 1'b0;
      repeat (2) @my_mem.cb;

      assert (my_mem.cb.s_axi_ready == 0)
      else $error("ready after 64 data packets? hmm. %0d", k);
      //TODO: Use Implication construct instead of faking it.

    end
    for (int k = 0; k < 32; k++) begin

      for (int y = 0; y < 64; y++) begin
        tx_data[y].randomize();
      end

      for (int h = 0; h < 8; h++) begin
        r1_data[h+k*8] = new(.p(tx_data), .a(h + 0), .r_num(k), .mi(my_mem));
        g1_data[h+k*8] = new(.p(tx_data), .a(h + 8), .r_num(k), .mi(my_mem));
        b1_data[h+k*8] = new(.p(tx_data), .a(h + 16), .r_num(k), .mi(my_mem));

        r1_data[h+k*8].create_dout();
        g1_data[h+k*8].create_dout();
        b1_data[h+k*8].create_dout();

      end

      for (int j = 0; j < 64; j++) begin
        my_mem.cb.s_axi_valid <= 1'b1;
        my_mem.cb.s_axi_data  <= tx_data[j].data_in;
        @my_mem.cb;

        if (!my_mem.s_axi_ready) @(my_mem.s_axi_ready);
      end
      my_mem.cb.s_axi_valid <= 1'b0;
      repeat (2) @my_mem.cb;

      assert (my_mem.cb.s_axi_ready == 0)
      else $error("ready after 64 data packets? hmm. %0d", k);
      //TODO: Use Implication construct instead of faking it.

    end

    @(my_mem.cb.m_axi_valid) @my_mem.cb;
    for (int k = 0; k < 256; k++) begin
      // r0_data[k].printf;
      my_mem.cb.m_axi_ready <= 1'b0;
      repeat (8) @my_mem.cb;  // simulates 10x clock domain crossing to 20 MHz driver
      my_mem.cb.m_axi_ready <= 1'b1;
      @my_mem.cb;

      //////////////////////Store data in output packet object//////////////////
      r0_data[k].collect_data(0);
      g0_data[k].collect_data(0);
      b0_data[k].collect_data(0);
      r1_data[k].collect_data(1);
      g1_data[k].collect_data(1);
      b1_data[k].collect_data(1);
      $display("time: %0t \t\t\t\t\t round %0d ", $time, k);
      @my_mem.cb;

    end
    @my_mem.cb;
    ///////////////////////CHECK ASSERTS//////////////////////////
    for (int yo = 0; yo < 256; yo++) begin
      r0_data[yo].my_assert(1);
      g0_data[yo].my_assert(1);
      b0_data[yo].my_assert(1);
      r1_data[yo].my_assert(1);
      g1_data[yo].my_assert(1);
      b1_data[yo].my_assert(1);
    end
  end

endmodule
