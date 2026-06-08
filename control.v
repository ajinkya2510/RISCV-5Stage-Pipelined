module control (
    input  wire [6:0] opcode, // inst[6:0]

    output reg reg_write, // 1 = write result to register file
    output reg alu_src, // 0 = rs2,  1 = sign-extended immediate
    output reg mem_write, // 1 = write to data memory
    output reg mem_read, // 1 = read  from data memory
    output reg mem_to_reg, // 0 = ALU result -> rd,  1 = mem data -> rd (ResultSrc)
    output reg branch, // 1 = conditional branch instruction
    output reg jump, // 1 = unconditional jump (JAL / JALR)
    output reg [1:0] alu_op // to ALU control decoder 
);

    localparam R_TYPE = 7'b0110011;
    localparam I_ALU = 7'b0010011; // ADDI, ANDI, ORI …
    localparam I_LOAD = 7'b0000011; // LW, LH, LB …
    localparam S_TYPE = 7'b0100011; // SW, SH, SB
    localparam B_TYPE = 7'b1100011; // BEQ, BNE, BLT …
    localparam U_LUI = 7'b0110111; // LUI
    localparam U_AUIPC = 7'b0010111; // AUIPC
    localparam J_JAL = 7'b1101111; // JAL
    localparam I_JALR = 7'b1100111; // JALR

   
    always @(*) begin
        case (opcode)

            // R-TYPE:  ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
            // Both operands come from the register file(alu_src = 0)
            // Result written back to rd(reg_write = 1)
            //No memory access
            // alu_op = 10: alu_control will decode funct3/funct7
            R_TYPE: begin
                reg_write = 1;
                alu_src = 0; // operand B = rs2
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0; // write ALU result to rd
                branch = 0;
                jump = 0;
                alu_op = 2'b10;
            end

            // I-TYPE ALU:  ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
            // Operand B is sign-extended immediate(alu_src = 1)
            // Result written to rd(reg_write = 1)
            // Same alu_op as R-type so funct3 still selects the operation
            I_ALU: begin
                reg_write = 1;
                alu_src = 1; // operand B = immediate
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                branch = 0;
                jump = 0;
                alu_op = 2'b10;
            end

            // I-TYPE LOAD: LW LH LB LHU LBU
            // ALU adds rs1 + imm12 to form memory address(alu_src = 1)
            // Data from memory written to rd(mem_to_reg = 1)
            // mem_read = 1 lets the hazard unit detect load-use hazards
            // alu_op = 00: always ADD for address calculation
            I_LOAD: begin
                reg_write = 1;
                alu_src = 1; // address = rs1 + imm
                mem_write = 0;
                mem_read = 1; // trigger load-use hazard detection
                mem_to_reg = 1; // rd <- memory data
                branch = 0;
                jump = 0;
                alu_op = 2'b00;
            end

            // S-TYPE: SW SH SB
            // ALU adds rs1 + imm12 for address(alu_src = 1)
            // rs2 value written to memory(mem_write = 1)
            // No register writeback(reg_write = 0)
            // alu_op = 00: always ADD
            S_TYPE: begin
                reg_write = 0; // stores don't write to registers
                alu_src = 1; // address = rs1 + imm
                mem_write = 1; // write to data memory
                mem_read = 0;
                mem_to_reg = 0; // don't care (reg_write=0)
                branch = 0;
                jump = 0;
                alu_op = 2'b00;
            end

            // B-TYPE:  BEQ BNE BLT BGE BLTU BGEU
            // ALU subtracts rs1 - rs2 to set flags(alu_src = 0)
            // No writeback, no memory(reg_write = 0)
            // branch = 1: EX stage will check condition & compute target
            // alu_op = 01: always SUB so zero/sign flags are meaningful
            // Actual branch condition (funct3) handled in EX stage
            B_TYPE: begin
                reg_write = 0;
                alu_src = 0; // compare rs1 vs rs2
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0; // don't care
                branch = 1; // signal to EX: check branch condition
                jump = 0;
                alu_op = 2'b01;
            end

            // U-TYPE LUI:  Load Upper Immediate
            // ALU passes 20-bit immediate (shifted left 12) (alu_op = 11)
            // alu_src = 1: immediate is operand B
            // Result written to rd(reg_write = 1)
            // rs1 is not used (EX stage will force A = 0)
            U_LUI: begin
                reg_write = 1;
                alu_src = 1; // immediate is B operand
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                branch = 0;
                jump = 0;
                alu_op = 2'b11; // LUI: pass immediate through ALU
            end

            // U-TYPE AUIPC:  Add Upper Immediate to PC
            // ALU computes PC + (imm << 12)
            // EX stage must use PC as operand A, not rs1
            // alu_op = 00 (ADD), alu_src = 1 (immediate)
            U_AUIPC: begin
                reg_write = 1;
                alu_src = 1; // immediate is B operand
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                branch = 0;
                jump = 0;
                alu_op = 2'b00; // ADD: PC + imm
            end

            // J-TYPE JAL: Jump And Link
            // PC + 4 saved to rd(reg_write = 1)
            // jump = 1: EX stage computes PC + imm20 target
            // mem_to_reg handled separately (rd = PC+4, not ALU/mem)
            // alu_op = 00: ADD used to compute jump target (PC + imm)
            J_JAL: begin
                reg_write = 1; // rd = PC + 4 (return address)
                alu_src = 1;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0; // WB mux will select PC+4 for jumps
                branch = 0;
                jump = 1; // unconditional jump
                alu_op = 2'b00;
            end

            // I-TYPE JALR: Jump And Link Register
            // Target = (rs1 + imm12) & ~1   (clear LSB)
            // rd = PC + 4
            // alu_src = 1: immediate offset added to rs1
            I_JALR: begin
                reg_write = 1;
                alu_src = 1; // target = rs1 + imm
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                branch = 0;
                jump = 1;
                alu_op = 2'b00;
            end
				
            default: begin
                reg_write = 0;
                alu_src = 0;
                mem_write = 0;
                mem_read = 0;
                mem_to_reg = 0;
                branch = 0;
                jump = 0;
                alu_op = 2'b00;
            end
        endcase
    end
endmodule