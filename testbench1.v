module tb_TinyMIPS_Test1;

  parameter SIZE = 8, DEPTH = 2**SIZE;

  reg clk, rst;
  wire wrEn;
  wire [SIZE-1:0] addr_toRAM;
  wire [15:0] data_toRAM, data_fromRAM;
  reg [15:0] expected_result;

  TinyMIPS uut1 (
    .clk(clk), 
    .rst(rst), 
    .data_fromRAM(data_fromRAM), 
    .wrEn(wrEn), 
    .addr_toRAM(addr_toRAM), 
    .data_toRAM(data_toRAM)
  );

  blram #(SIZE, DEPTH) uut2 (
    .clk(clk), 
    .rst(rst), 
    .we(wrEn), 
    .addr(addr_toRAM), 
    .din(data_toRAM), 
    .dout(data_fromRAM)
  );

  initial begin
    clk = 1'b1;
    forever #5 clk = ~clk; 
  end

  initial begin
    $dumpfile("dump_test1.vcd");
    $dumpvars(0, tb_TinyMIPS_Test1);

    rst = 1'b1;
    repeat (10) @(posedge clk); 
    rst = 1'b0;
    repeat (200) @(posedge clk); 
    $finish;
  end

  initial begin
    @(negedge rst);
    uut2.mem[0] = 16'b0111001000000001; // CPi R1 1
    uut2.mem[1] = 16'b0111010000000000; // CPi R2 0
    uut2.mem[2] = 16'b0111011000000110; // CPi R3 6
    uut2.mem[3] = 16'b0000010010001000; // ADD R2 R2 R1
    uut2.mem[4] = 16'b0001001001000001; // ADDi R1 R1 1
    uut2.mem[5] = 16'b1001001011111110; // BLT R1 R3 -2
  end

  // Monitor
  initial begin
    expected_result = 15; // Sum of 1 to 5
    #600;
    if (uut1.RF[2] == expected_result) begin
      $display("Test 1 Passed. Sum is %d", uut1.RF[2]);
    end else begin
      $display("Test 1 Failed. Sum is %d", uut1.RF[2]);
    end
  end

  // Debug Monitor
  initial begin
    $monitor("Time = %d, PC = %d, State = %d, RF[1] = %d, RF[2] = %d", $time, uut1.PC, uut1.st, uut1.RF[1], uut1.RF[2]);
  end
endmodule
