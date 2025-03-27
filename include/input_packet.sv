class input_packet;
  rand bit [32 - 1 : 0] data_in;

  constraint data {data_in[31 -: 8] == '0;}
  function new();
  endfunction

  function bit sendbit (int i);
    return data_in[i];
  endfunction

endclass //data_packet_in