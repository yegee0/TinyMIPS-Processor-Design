module TinyMIPS(
    input wire clk,
    input wire rst,
    input wire [15:0] data_fromRAM,
    output reg wrEn,
    output reg [7:0] addr_toRAM,
    output reg [15:0] data_toRAM
);

    reg [2:0] st, stN;
    reg [7:0] PC, PCN;
    reg [15:0] IW, IWN;
    reg [15:0] T1, T1N, T2, T2N;
    reg [15:0] RF [7:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            st <= 3'd0;
            PC <= 8'd0;
            IW <= 16'd0;
            T1 <= 16'd0;
            T2 <= 16'd0;
            addr_toRAM <= 8'd0;
            data_toRAM <= 16'd0;
            wrEn <= 1'b0;
        end else begin
            st <= stN;
            PC <= PCN;
            IW <= IWN;
            T1 <= T1N;
            T2 <= T2N;
            addr_toRAM <= addr_toRAM;
            data_toRAM <= data_toRAM;
            wrEn <= wrEn;
        end
    end

    // Combinational logic
    always @* begin
        wrEn = 1'b0;
        PCN = PC;
        IWN = IW;
        stN = st;
        addr_toRAM = 8'd0;
        data_toRAM = 16'd0;
        T1N = T1;
        T2N = T2;

        case (st)
            3'd0: begin // S0: Fetch State
                addr_toRAM = PC;
                stN = 3'd1;
            end
            3'd1: begin // S1: Decode State
                IWN = data_fromRAM;
                case (data_fromRAM[15:12])
                    4'b0000: begin // ADD
                        T1N = RF[data_fromRAM[8:6]];
                        stN = 3'd2;
                    end
                    4'b0001: begin // ADDi
                        T1N = RF[data_fromRAM[8:6]];
                        stN = 3'd2;
                    end
                    4'b0010: begin // MUL
                        T1N = RF[data_fromRAM[8:6]];
                        stN = 3'd2;
                    end
                    4'b0011: begin // SRL
                        T1N = RF[data_fromRAM[8:6]];
                        stN = 3'd2;
                    end
                    4'b0100: begin // LD
                        T1N = RF[data_fromRAM[8:6]];
                        stN = 3'd2;
                    end
                    4'b0101: begin // ST
                        T1N = RF[data_fromRAM[8:6]];
                        stN = 3'd2;
                    end
                    4'b0110: begin // CP
                        RF[data_fromRAM[11:9]] = RF[data_fromRAM[8:6]];
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b0111: begin // CPi
                        RF[data_fromRAM[11:9]] = {7'd0, data_fromRAM[8:0]};
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b1000: begin // BEQ
                        T1N = RF[data_fromRAM[11:9]];
                        stN = 3'd2;
                    end
                    4'b1001: begin // BLT
                        T1N = RF[data_fromRAM[11:9]];
                        stN = 3'd2;
                    end
                    4'b1010: begin // BGT
                        T1N = RF[data_fromRAM[11:9]];
                        stN = 3'd2;
                    end
                    default: stN = 3'd0;
                endcase
            end
            3'd2: begin // S2 State
                case (IW[15:12])
                    4'b0000: begin // ADD
                        T1N = T1;
                        T2N = RF[IW[5:3]];
                        stN = 3'd3;
                    end
                    4'b0001: begin // ADDi
                        RF[IW[11:9]] = T1 + {{2{IW[5]}}, IW[5:0]};
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b0010: begin // MUL
                        T1N = T1;
                        T2N = RF[IW[5:3]];
                        stN = 3'd3;
                    end
                    4'b0011: begin // SRL
                        T1N = T1;
                        T2N = RF[IW[5:3]];
                        stN = 3'd3;
                    end
                    4'b0100: begin // LD
                        addr_toRAM = T1 + IW[5:0];
                        stN = 3'd3;
                    end
                    4'b0101: begin // ST
                        addr_toRAM = T1 + IW[5:0];
                        data_toRAM = RF[IW[11:9]];
                        wrEn = 1'b1;
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b1000: begin // BEQ
                        T2N = RF[IW[8:6]];
                        stN = 3'd3;
                    end
                    4'b1001: begin // BLT
                        T2N = RF[IW[8:6]];
                        stN = 3'd3;
                    end
                    4'b1010: begin // BGT
                        T2N = RF[IW[8:6]];
                        stN = 3'd3;
                    end
                    default: stN = 3'd0;
                endcase
            end
            3'd3: begin // S3 State
                case (IW[15:12])
                    4'b0000: begin // ADD
                        RF[IW[11:9]] = T1 + T2;
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b0010: begin // MUL
                        RF[IW[11:9]] = T1 * T2;
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b0011: begin // SRL
                        RF[IW[11:9]] = (T2 < 32) ? (T1 >> T2) : (T1 << (T2 - 32));
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b0100: begin // LD
                        RF[IW[11:9]] = data_fromRAM;
                        PCN = PC + 8'd1;
                        stN = 3'd0;
                    end
                    4'b1000: begin // BEQ
                        PCN = (T1 == T2) ? (PC + {{2{IW[5]}}, IW[5:0]}) : (PC + 8'd1);
                        stN = 3'd0;
                    end
                    4'b1001: begin // BLT
                        PCN = (T1 < T2) ? (PC + {{2{IW[5]}}, IW[5:0]}) : (PC + 8'd1);
                        stN = 3'd0;
                    end
                    4'b1010: begin // BGT
                        PCN = (T1 > T2) ? (PC + {{2{IW[5]}}, IW[5:0]}) : (PC + 8'd1);
                        stN = 3'd0;
                    end
                    default: stN = 3'd0;
                endcase
            end
            default: stN = 3'd0;
        endcase
    end
endmodule



module blram #(parameter SIZE = 8, parameter DEPTH = 2**SIZE) (
  input wire clk,
  input wire rst,
  input wire we,
  input wire [SIZE-1:0] addr,
  input wire [15:0] din,
  output reg [15:0] dout
);

  reg [15:0] mem [0:DEPTH-1];

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      dout <= 16'b0;
    end else begin
      dout <= mem[addr];
      if (we)
        mem[addr] <= din;
    end
  end
endmodule

