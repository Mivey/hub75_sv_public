`include "input_packet.sv"
class output_packet;
  bit [64-1:0] data_out, expected_dout;
  input_packet my_packets[64];
  int sig_fig;
  local static int err_cnt;
  string color  ;
  local bit [1:0] color_id;
  int    row_num;
  virtual mem_if mif;
  int foo;

  function new(input_packet p[64], int a, int r_num, virtual mem_if mi);
    my_packets = p;
    sig_fig = a;
    row_num = r_num;
    mif = mi;
    expected_dout = 0;
    data_out = 0;

    unique case (a) inside
      [0 : 7]:   color = "Red";
      [8 : 15]:  color = "Green";
      [16 : 23]: color = "Blue";
    endcase
    unique case (a) inside
      [0 : 7]:   color_id = 2'b00;
      [8 : 15]:  color_id = 2'b01;
      [16 : 23]: color_id = 2'b10;
    endcase
  endfunction


  task automatic create_dout();
    for (int i = 0; i < 64; i++) begin
      expected_dout[i] = my_packets[i].sendbit(sig_fig);
    end
  endtask  //automatic

  function my_assert(bit i = 0);
    int temp = row_num * 8 + (sig_fig % 8);
    if (i) begin
      $display("Expected data: %0h \t Actual Data: %0h \t %0s  %0d", expected_dout, data_out,
               color, temp);
    end

    assert (data_out === expected_dout)
    else begin
      $warning("NOPE!!");
      err_cnt++;
    end

  endfunction

  task automatic collect_data(bit i);

    unique case ({
      i, color_id
    })
      3'b000: data_out <= mif.r0_reg;
      3'b001: data_out <= mif.g0_reg;
      3'b010: data_out <= mif.b0_reg;
      3'b100: data_out <= mif.r1_reg;
      3'b101: data_out <= mif.g1_reg;
      3'b110: data_out <= mif.b1_reg;
    endcase
  endtask  //automatic

  function void reset_err();
    err_cnt = 0;
  endfunction

  task printf();
    $display("expected dout \t\t%0h", this.expected_dout);

    if (mif == null) begin
      $display("WHY IS THIS NULL!!");
    end
    if (mif.m_axi_ready === 1'b0) begin
      $display("THIS WORKS \t\t\t\t\t\ this works!!");
    end
    if (mif.m_axi_ready === 1'b1) begin
      $display("THIS ALSO WORKS WORKS \t\t\t\t\t\ this works!!");
    end
    $display("dout_is: %0d", data_out);
  endtask  //
endclass  //output_packet
