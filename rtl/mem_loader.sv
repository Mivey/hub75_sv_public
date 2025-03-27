`timescale 1ns / 1ns `default_nettype none
// `include "mem_if.sv"

//need to add reset state to SM.
module mem_loader #(
    parameter FIFO_WIDTH = 64,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8 ,
    parameter OUT_REG    = 6
) (
    input  wire                   clk,
    input  wire                   s_axi_valid,
    output logic                  s_axi_ready,
    input  wire  [DATA_WIDTH-1:0] s_axi_data,
    output logic                  m_axi_valid,
    input  wire                   m_axi_ready,
    output logic [FIFO_WIDTH-1:0] bram_red_0,
    output logic [FIFO_WIDTH-1:0] bram_green_0,
    output logic [FIFO_WIDTH-1:0] bram_blue_0,
    output logic [FIFO_WIDTH-1:0] bram_red_1,
    output logic [FIFO_WIDTH-1:0] bram_green_1,
    output logic [FIFO_WIDTH-1:0] bram_blue_1
);

  logic [OUT_REG-1:0] i_we;  // array of logic values to individually control each BRAM
  logic [ADDR_WIDTH-1:0] addr;
  logic i_re;
  logic [DATA_WIDTH - 1 : 0] mem_fifo[FIFO_WIDTH];
  bit [6 - 1 : 0] fifo_wptr, fifo_rptr;
  typedef enum {
    S0,
    S1,
    S2,
    S3,
    S4,
    S5,
    S6,
    S7,
    E0
  } state_t;
  state_t c_state, n_state;  // c_state is output of D_ff, n_state is input
  int row_cnt;
  bit [ADDR_WIDTH-1:0] bram_wptr[3];
  bit [ADDR_WIDTH-1:0] bram_rptr;
  bit ul_half;
  logic [FIFO_WIDTH - 1 : 0] fifo_mux_out;

  bram #(
      .DATA_WIDTH(FIFO_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) bram_r0 (
      .clk   (clk),
      .i_we  (i_we[0]),
      .i_re  (i_re),
      .i_data(fifo_mux_out),
      .addr  (addr),
      .o_data(bram_red_0)
  );

  bram #(
      .DATA_WIDTH(FIFO_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) bram_g0 (
      .clk   (clk),
      .i_we  (i_we[1]),
      .i_re  (i_re),
      .i_data(fifo_mux_out),
      .addr  (addr),
      .o_data(bram_green_0)
  );

  bram #(
      .DATA_WIDTH(FIFO_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) bram_b0 (
      .clk   (clk),
      .i_we  (i_we[2]),
      .i_re  (i_re),
      .i_data(fifo_mux_out),
      .addr  (addr),
      .o_data(bram_blue_0)
  );

  //////////////////////////////////////////////////
  // generate statement for if OUT_REG is 6 instead of 3
  //////////////////////////////////////////////////

  generate
    if (OUT_REG == 6) begin : alt_config

      bram #(
          .DATA_WIDTH(FIFO_WIDTH),
          .ADDR_WIDTH(ADDR_WIDTH)
      ) bram_r0 (
          .clk(clk),
          .i_we(i_we[3]),
          .i_re(i_re),
          .i_data(fifo_mux_out),
          .addr(addr),
          .o_data(bram_red_1)
      );

      bram #(
          .DATA_WIDTH(FIFO_WIDTH),
          .ADDR_WIDTH(ADDR_WIDTH)
      ) bram_g0 (
          .clk   (clk),
          .i_we  (i_we[4]),
          .i_re  (i_re),
          .i_data(fifo_mux_out),
          .addr  (addr),
          .o_data(bram_green_1)
      );

      bram #(
          .DATA_WIDTH(FIFO_WIDTH),
          .ADDR_WIDTH(ADDR_WIDTH)
      ) bram_b0 (
          .clk   (clk),
          .i_we  (i_we[5]),
          .i_re  (i_re),
          .i_data(fifo_mux_out),
          .addr  (addr),
          .o_data(bram_blue_1)
      );

    end
  endgenerate

  always_comb begin
    for (int k = 0; k < FIFO_WIDTH; k++) begin
      fifo_mux_out[k] = mem_fifo[k][fifo_rptr];
    end

    ul_half = (row_cnt < 32) ? 1'b0 : 1'b1;

    case (c_state)
      S1: begin
        i_we = (~ul_half) ? 6'o01 : 6'o10;  //octal
        addr = bram_wptr[0];
        i_re = 1'b0;
      end
      S2: begin
        i_we = (~ul_half) ? 6'o02 : 6'o20;  //octal
        addr = bram_wptr[1];
        i_re = 1'b0;
      end
      S3: begin
        i_we = (~ul_half) ? 6'o04 : 6'o40;  //octal
        addr = bram_wptr[2];
        i_re = 1'b0;
      end
      S5: begin
        i_we = '0;
        addr = bram_rptr;
        i_re = 1'b1;
      end
      S6: begin
        i_we = '0;
        addr = bram_rptr;
        i_re = 1'b1;
      end
      default: begin
        i_we = '0;
        addr = '0;
        i_re = 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    c_state     <= n_state;
    s_axi_ready <= 1'b0;
    m_axi_valid <= 1'b0;

    if (c_state == S0) begin
      if (s_axi_valid == 1'b1) begin
        fifo_wptr <= fifo_wptr + 1;
        mem_fifo[fifo_wptr] <= s_axi_data;
        if (fifo_wptr < 63) begin
          s_axi_ready <= 1'b1;
        end
      end
    end

    if ((c_state == S1) || (c_state == S2) || (c_state == S3)) begin
      fifo_rptr <= fifo_rptr + 1;
      if (fifo_rptr == 23) begin
        fifo_rptr <= 0;
      end
      unique case (c_state)
        S1: begin
          bram_wptr[0] <= bram_wptr[0] + 1;
        end
        S2: begin
          bram_wptr[1] <= bram_wptr[1] + 1;
        end
        S3: begin
          bram_wptr[2] <= bram_wptr[2] + 1;
        end
      endcase
    end


    if (c_state == S4) begin
      fifo_wptr <= 0;
      if (row_cnt < 63) begin
        if (s_axi_valid == 1'b1) begin
          row_cnt <= row_cnt + 1;
        end
      end
      bram_rptr <= '0;
    end

    if (c_state == S5) begin
      m_axi_valid <= 1'b1;
      row_cnt <= 0;
    end
    if (c_state == S6) begin
      m_axi_valid <= 1'b1;
    end

    if (c_state == S7) begin
      bram_rptr <= bram_rptr + 1;
    end
  end

  always_comb begin
    unique case (c_state)
      S0: begin  //idle state
        if (fifo_wptr < 63) begin
          n_state = S0;
        end else begin
          n_state = S1;
        end
      end
      S1: begin
        if (fifo_rptr < 7) begin
          n_state = S1;
        end else begin
          n_state = S2;
        end
      end
      S2: begin
        if ((fifo_rptr >= 8) && (fifo_rptr < 15)) begin
          n_state = S2;
        end else begin
          n_state = S3;
        end
      end
      S3: begin
        if ((fifo_rptr >= 16) && (fifo_rptr < 23)) begin
          n_state = S3;
        end else begin
          n_state = S4;
        end
      end
      S4: begin
        if ((s_axi_valid == 1'b1) && (row_cnt == 63)) begin  //11
          n_state = E0;  // shouldn't happen, Error state
        end else if ((s_axi_valid == 1'b1) && (row_cnt <= 62)) begin  // 10
          n_state = S0;  // next row of pixels
        end else if ((s_axi_valid == 1'b0) && (row_cnt == 63)) begin  // 10
          n_state = S5;  // got all the pixels 
        end else begin  // (s_axi_valid == 1'b0) && (row_cnt <= 62) // 00
          n_state = S4;  // valid not ready yet? keep waiting
        end
      end
      S5: begin
        if (s_axi_valid == 1'b1) begin
          n_state = S4;
        end else if (m_axi_ready == 1'b0) begin
          n_state = S5;
        end else begin
          n_state = S6;
        end
      end
      S6: begin
        if (m_axi_ready == 1) begin
          n_state = S6;
        end else begin
          n_state = S7;
        end
      end
      S7: begin
        n_state = S5;
      end
      E0: begin
        if ((s_axi_valid == 1'b1)) begin  //11
          n_state = E0;  // shouldn't happen, Error state, wait for it to resolve
        end else begin  // 10
          n_state = S4;  // next row of pixels
        end
      end
    endcase
  end

endmodule
