`default_nettype none
/* *****************************************
// Hub75(e) interface and logic
// The Hub75 interface is basically 3 or 6 chains of  
// shift registers that mux a column of leds together. 
// 
// This is expected to run at 40 MHz with the output  
// interface running at 20 MHz.
***************************************** */

module hub75 #(
    parameter FIFO_WIDTH = 64,
    parameter OUT_REG = 6,
    parameter CLK_SPEED = 40_000_000
) (
    input wire clk,
    input wire s_axi_valid,
    output logic s_axi_ready,
    input wire reset_n,
    input wire [FIFO_WIDTH - 1 : 0] r0_in,
    input wire [FIFO_WIDTH - 1 : 0] g0_in,
    input wire [FIFO_WIDTH - 1 : 0] b0_in,
    input wire [FIFO_WIDTH - 1 : 0] r1_in,
    input wire [FIFO_WIDTH - 1 : 0] g1_in,
    input wire [FIFO_WIDTH - 1 : 0] b1_in,
    output logic r0_out,
    output logic g0_out,
    output logic b0_out,
    output logic r1_out,
    output logic g1_out,
    output logic b1_out,
    output logic [5 - 1 : 0] addr_out,
    output logic blank,
    output logic latch_out,
    output logic clk_out

);

  logic [FIFO_WIDTH - 1 : 0] piso [6]; // parallel in, serial out array
  logic [2 : 0 ] addr_cnt;
  int shift_cnt; 
  int timer;
  logic valid_data;
  int bcm_arr[8]; // hard-coded for now
  typedef enum {
    S0, // data in on PISO
    S1, // shift data out, set clk_out high
    S2, // set clk_out low, inc shift_cnt
    S3, // wait if addr_cnt == 7 && timer > 0; go to S4 if true, go to S5 if addr_cnt < 7
    S4, // set blank to 1, increment addr
    S5, // latch data if timer == 0
    S6, // set blank to 0, set timer to new value, addr_cnt++
    S7,
    RST
  } state_t;
  state_t c_state, n_state;

  initial begin
    bcm_arr[0] = 10418;
    bcm_arr[1] = 5210;
    bcm_arr[2] = 2604;
    bcm_arr[3] = 1302;
    bcm_arr[4] = 651;
    bcm_arr[5] = 325;
    bcm_arr[6] = 163;
    bcm_arr[7] = 82;
  end

  always_comb begin
    unique case (c_state)
      S0: begin
        if (s_axi_valid == 1'b1) begin
          n_state = S1;
        end else begin
          n_state = S0;
        end
      end

      S1: n_state = S2;

      S2: begin
        if (shift_cnt < 63) begin
          n_state = S1;
        end else begin
          n_state = S3;
        end
      end

      S3: begin
        if (addr_cnt == 7) begin
          if (timer > 0) begin
            n_state = S3;
          end else begin
            n_state = S4;
          end
        end else begin
          n_state = S5;
        end
      end

      S4: begin
        n_state = S5;
      end

      S5: begin
        if (timer > 0) begin
          n_state = S5;
        end else begin
          n_state = S6;
        end
      end

      S6: begin
        n_state = S0;
      end

      RST: begin
        if (reset_n == 1'b0) begin
          n_state = RST;
        end else begin
          n_state = S0;
        end
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset_n == 0) begin
      c_state <= RST;
      timer <= 0;
      clk_out <= 1'b0;
      latch_out <= 1'b0;
      blank <= 1'b1;
      s_axi_ready <= 1'b0;
      addr_cnt <= '0;
      timer <= '0;
    end else begin
      c_state <= n_state;
      clk_out <= 1'b0;
      latch_out <= 1'b0;
      blank <= 1'b1;
      s_axi_ready <= 1'b0;
    end

    if (c_state == S0) begin
      s_axi_ready <= 1'b1;
      if (valid_data) begin
        blank <= 1'b0; 
      end
      if (s_axi_valid == 1'b1) begin
        piso[0] <= r0_in;
        piso[1] <= g0_in;
        piso[2] <= b0_in;
        piso[3] <= r1_in;
        piso[4] <= g1_in;
        piso[5] <= b1_in;
      end
    end

    if (c_state == S1) begin
      clk_out <= 1'b1;
      if (valid_data) begin
        blank <= 1'b0;
      end

      for (int i = 0; i < 5; i++) begin
        for (int k = 1; k < 63; k++) begin
          piso[i][k - 1] <= piso[i][k + 1];
        end
      end
    end

    if (c_state == S2) begin
      if (valid_data) begin
        blank <= 1'b0;
      end
    end

    if (c_state == S3) begin
      if (valid_data) begin
        blank <= 1'b0;
      end

      if (timer > 0) begin
        timer = timer - 1;
      end 
    end

    if (c_state == S4) begin
      addr_out <= addr_out + 1;
    end

    if (c_state == S5) begin
      latch_out <= 1'b1;
    end

    if (c_state == S6) begin
      if (valid_data == 0) begin
        valid_data <= 1'b1;
        addr_cnt <= '0;
      end else begin
        addr_cnt <= addr_cnt + 1;
        valid_data <= 1'b1;
      end

      unique case (addr_cnt)
        3'b000 : timer <= bcm_arr[0];
        3'b001 : timer <= bcm_arr[1];
        3'b010 : timer <= bcm_arr[2];
        3'b011 : timer <= bcm_arr[3];
        3'b100 : timer <= bcm_arr[4];
        3'b101 : timer <= bcm_arr[5];
        3'b110 : timer <= bcm_arr[6];
        3'b111 : timer <= bcm_arr[7];
      endcase
    end
  end

  always_comb begin
    r0_out = piso[0][0];
    g0_out = piso[1][0];
    b0_out = piso[2][0];
    r1_out = piso[3][0];
    g1_out = piso[4][0];
    b1_out = piso[5][0];
    
  end

endmodule
