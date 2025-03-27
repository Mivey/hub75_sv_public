package my_frame;


  `include "output_packet.sv"

  task automatic tx_random(input_packet p[], output_packet r[], g[], b[], int row,
                           virtual mem_if mi);

    for (int k = 0; k < 8; k++) begin
      r[k+row*8] = new(.p(p), .a(k + 0), .r_num(row), .mi(mi));
      g[k+row*8] = new(.p(p), .a(k + 8), .r_num(row), .mi(mi));
      b[k+row*8] = new(.p(p), .a(k + 16), .r_num(row), .mi(mi));

      r[k+row*8].create_dout();
      g[k+row*8].create_dout();
      b[k+row*8].create_dout();

    end
  endtask  //automatic
endpackage
