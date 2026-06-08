module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,

    output reg  [3:0] alu_ctrl
);

always @(*) begin

    case(alu_op)
        2'b00: alu_ctrl = 4'b0000; // Load/store/AUIPC use ADD
        2'b01: alu_ctrl = 4'b0001; // Branch instructions use SUB/comparison
        2'b11: alu_ctrl = 4'b1010; // LUI: pass immediate through ALU
        2'b10: begin
						case(funct3)  // Decode R-type and I-type ALU operations
							3'b000: begin  // ADD/ADDI or SUB
										if(funct7_5) alu_ctrl = 4'b0001; // SUB
										else alu_ctrl = 4'b0000; // ADD
									  end
							3'b001: alu_ctrl = 4'b0010; // Shift left logical
							3'b010: alu_ctrl = 4'b0011; // Signed less-than compare
							3'b011: alu_ctrl = 4'b0100; // Unsigned less-than compare
							3'b100: alu_ctrl = 4'b0101; // XOR
							3'b101: begin // SRL or SRA
										if(funct7_5) alu_ctrl = 4'b0111; // SRA
										else alu_ctrl = 4'b0110; // SRL
									  end
							3'b110: alu_ctrl = 4'b1000; // OR
							3'b111: alu_ctrl = 4'b1001; // AND

                default: alu_ctrl = 4'b0000;
            endcase
        end
        default: alu_ctrl = 4'b0000;
    endcase
end

endmodule