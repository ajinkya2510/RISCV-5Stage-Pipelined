module alu (
    input  wire [31:0] a,           // operand A  (rs1 or PC)
    input  wire [31:0] b,           // operand B  (rs2 or immediate)
    input  wire [3:0]  alu_ctrl,    // operation select

    output reg  [31:0] result,      // computed result
    output wire        zero         // 1 when result == 0  (used for branches)
);

    assign zero = (result == 32'b0); // zero flag(used by branch logic in EX stage)
	 
    wire [4:0] shamt = b[4:0]; //RISC-V only uses the lower 5 bits of rs2 for shifts

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b; // ADD
            4'b0001: result = a - b; // SUB
            4'b0010: result = a << shamt; // SLL
            4'b0011: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b0100: result = (a < b) ? 32'd1 : 32'd0;  // SLTU
            4'b0101: result = a ^ b; // XOR
            4'b0110: result = a >> shamt; // SRL (logical)
            4'b0111: result = $signed(a) >>> shamt; // SRA (arithmetic)
            4'b1000: result = a | b; // OR
            4'b1001: result = a & b; // AND
            4'b1010: result = b; // LUI  (pass B)
            default: result = 32'b0;                          
        endcase
    end

endmodule

