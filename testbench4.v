module tb_TinyMIPS_Test4;

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
    $dumpfile("dump_test4.vcd");
    $dumpvars(0, tb_TinyMIPS_Test4);

    rst = 1'b1;
    repeat (10) @(posedge clk); 
    rst = 1'b0;
    repeat (200) @(posedge clk); 
    $finish;
  end

  initial begin
    #2100;
    uut2.mem[0] = 16'b0111001000000101; // CPi R1 5
    uut2.mem[1] = 16'b0111010000000000; // CPi R2 0
    uut2.mem[2] = 16'b0110011010000000; // CP R3 R2
    uut2.mem[3] = 16'b0111100000000010; // CPi R4 2
    uut2.mem[4] = 16'b0100101001001110; // LD R5 R1 14
    uut2.mem[5] = 16'b1000101011000100; // BEQ R5 R3 4
    uut2.mem[6] = 16'b0001101101000101; // ADDi R5 R5 5
    uut2.mem[7] = 16'b0011101101100000; // SRL R5 R5 R4
    uut2.mem[8] = 16'b0101101001001110; // ST R5 R1 14
    uut2.mem[9] = 16'b0001001001111111; // ADDi R1 R1 -1
    uut2.mem[10] = 16'b1010001010111010; // BGT R1 R2 -6
    uut2.mem[15] = 16'b0000000000000101; // Data: 5
    uut2.mem[16] = 16'b0000000000000000; // Data: 0
    uut2.mem[17] = 16'b0000000000001111; // Data: 15
    uut2.mem[18] = 16'b0000000000010001; // Data: 17
    uut2.mem[19] = 16'b0000000000010110; // Data: 22
  end

  // Monitor
  initial begin
    expected_result = uut2.mem[14]; // Expecting an updated value at address 14
    #2700;
    if (uut2.mem[14] != 16'b0000000000000101 && uut2.mem[14] != expected_result) begin
      $display("Test 4 Passed. Memory updated successfully.");
    end else begin
      $display("Test 4 Failed. Memory not updated as expected.");
    end
  end

  // Debug Monitor
  initial begin
    $monitor("Time = %d, PC = %d, State = %d, RF[1] = %d, RF[2] = %d, RF[3] = %d, RF[4] = %d, RF[5] = %d", $time, uut1.PC, uut1.st, uut1.RF[1], uut1.RF[2], uut1.RF[3], uut1.RF[4], uut1.RF[5]);
  end

endmodule
