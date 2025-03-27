`default_nettype none
// `timescale 1ns/1ns

module axi_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ELEMENTS   = 64
) (
    input wire clk,
    input wire areset_n,
    input wire s_axi_valid,
    input wire [DATA_WIDTH - 1 : 0] s_axi_data,
    output logic s_axi_ready,
    output logic [ELEMENTS - 1 : 0] o_fifo_data,
    output logic m_axi_valid,
    input wire m_axi_ready
);

  int wptr, rptr;
  logic [DATA_WIDTH - 1 : 0] fifo_array[0 : ELEMENTS - 1];
  typedef enum {
    RST,
    IDLE,
    DATA_IN,
    DATA_OUT,
    WAITING
  } state_t;
  state_t curr_state;
  state_t n_state;

  wire s_axi_rv_ok, m_axi_rv_ok;
  assign s_axi_rv_ok = (s_axi_valid && s_axi_ready) ? 1'b1 : 1'b0;
  assign m_axi_rv_ok = (m_axi_valid && m_axi_ready) ? 1'b1 : 1'b0;


  always_ff @(posedge clk) begin
    if (!areset_n) begin
      curr_state <= RST;
    end else begin
      curr_state <= n_state;
    end

    if (curr_state == RST) begin
      wptr <= 0;
      rptr <= 0;
      s_axi_ready <= 1'b0;
      m_axi_valid <= 1'b0;
    end

    if (curr_state == DATA_IN) begin
      s_axi_ready <= 1'b1;
      m_axi_valid <= 1'b0;
      if (s_axi_rv_ok) begin
        wptr <= wptr + 1;
        fifo_array[wptr] <= s_axi_data;
      end
    end

    if (curr_state == IDLE) begin
      s_axi_ready <= 1'b1;
      m_axi_valid <= 1'b0;
    end

    if (curr_state == WAITING) begin
      s_axi_ready <= 1'b0;
      m_axi_valid <= 1'b1;

    end

    if (curr_state == DATA_OUT) begin
      if (m_axi_rv_ok) begin
        rptr <= rptr + 1;
        for (int i = 0; i < ELEMENTS; i++) begin
          o_fifo_data[i] <= fifo_array[i][rptr];
        end
      end

    end

  end

  always_comb begin
    unique case (curr_state)
      RST: begin
        if (areset_n != 1'b0) n_state = RST;
        else n_state = IDLE;
      end

      IDLE: begin
        if (s_axi_valid) n_state = DATA_IN;
        else n_state = IDLE;
      end

      DATA_IN: begin
        if (s_axi_valid) begin
          if (wptr < ELEMENTS - 1) n_state = DATA_IN;
          else n_state = DATA_OUT;
        end else n_state = IDLE;
      end

      DATA_OUT: begin
        if (m_axi_ready) begin
          if (rptr < (DATA_WIDTH - 1)) n_state = DATA_OUT;
          else n_state = IDLE;
        end else n_state = WAITING;
      end

      WAITING: begin
        if (m_axi_ready) begin
          n_state = DATA_OUT;
        end else begin
          n_state = WAITING;
        end
      end
    endcase
  end

endmodule

// will be three modules
// 1st will be this to take in data to its internal fifo
//    need to add signals to tell data storage input is full
// 2nd data storage intefaces with both axi input and hub75 output
//    needs signals to tell hub75 to WAITING, and signal to tell mem storage
//    to send more data.


