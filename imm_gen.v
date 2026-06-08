module imm_gen (
    input  wire [31:0] inst, // full 32-bit instruction
    output reg  [31:0] imm_out // sign-extended 32-bit immediate
);
   
    wire [6:0] opcode = inst[6:0]; //tells us which format to use

    localparam I_ALU   = 7'b0010011;
    localparam I_LOAD  = 7'b0000011;
    localparam I_JALR  = 7'b1100111;
    localparam S_TYPE  = 7'b0100011;
    localparam B_TYPE  = 7'b1100011;
    localparam U_LUI   = 7'b0110111;
    localparam U_AUIPC = 7'b0010111;
    localparam J_JAL   = 7'b1101111;

    always @(*) begin
        case (opcode)

           
            // I-type immediate: bits [31:20], sign-extended from bit 31
            //  31        20 19      12 11   7 6     0
            //  [  imm[11:0] ][  ----  ][ rd  ][ op  ]
            I_ALU, I_LOAD, I_JALR:
                imm_out = {{20{inst[31]}}, inst[31:20]};

            // S-type: split immediate, reassembled as imm[11:5] | imm[4:0]
            //  31      25 24   20  19  15  14   12 11      7 6   0
            //  [imm[11:5]][  rs2 ][  rs1 ][funct3][imm[4:0]][ op ]
            S_TYPE:
                imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};

            // B-type: scrambled bits for hardware reasons (minimise mux depth)
            // Bit 0 is always 0 — branches must be 2-byte aligned
            //
            //  inst[31]   = imm[12]
            //  inst[7]    = imm[11]
            //  inst[30:25]= imm[10:5]
            //  inst[11:8] = imm[4:1]
            //  imm[0]     = 0 (implicit)
            B_TYPE:
                imm_out = {{19{inst[31]}}, inst[31], inst[7],
                           inst[30:25], inst[11:8], 1'b0};

            // U-type: upper 20 bits form imm[31:12], lower 12 bits are 0
            // LUI  result = imm (ALU passes through)
            // AUIPC result = PC + imm
            U_LUI, U_AUIPC:
                imm_out = {inst[31:12], 12'b0};

            // J-type (JAL): also scrambled, bit 0 always 0
            //
            //  inst[31]   = imm[20]
            //  inst[19:12]= imm[19:12]
            //  inst[20]   = imm[11]
            //  inst[30:21]= imm[10:1]
            //  imm[0]     = 0 (implicit)
            J_JAL:
                imm_out = {{11{inst[31]}}, inst[31], inst[19:12],
                           inst[20], inst[30:21], 1'b0};

            // R-type has no immediate
            default:
                imm_out = 32'b0;

        endcase
    end

endmodule