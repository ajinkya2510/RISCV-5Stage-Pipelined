module ex_stage (
    input wire clk,
    input wire rst,

    input wire [31:0] id_ex_pc,
    input wire [31:0] id_ex_rs1_data,
    input wire [31:0] id_ex_rs2_data,
    input wire [31:0] id_ex_imm,

    input wire [4:0] id_ex_rs1,
    input wire [4:0] id_ex_rs2,
    input wire [4:0] id_ex_rd,

    input wire [2:0] id_ex_funct3,
    input wire id_ex_funct7_5,

    input wire id_ex_reg_write,
    input wire id_ex_alu_src,
    input wire id_ex_mem_write,
    input wire id_ex_mem_read,
    input wire id_ex_mem_to_reg,
    input wire id_ex_branch,
    input wire id_ex_jump,
    input wire [1:0] id_ex_alu_op,
    input wire id_ex_is_jalr,

    input wire [1:0] fwd_a,
    input wire [1:0] fwd_b,

    input wire [31:0] ex_mem_alu_result,
    input wire [31:0] wb_data,

    output wire branch_taken,
    output wire jump_out,
    output wire [31:0] pc_target,

    output reg [31:0] ex_mem_alu_out,
    output reg [31:0] ex_mem_rs2_data,
    output reg [4:0] ex_mem_rd,
    output reg [2:0] ex_mem_funct3,

    output reg ex_mem_reg_write,
    output reg ex_mem_mem_write,
    output reg ex_mem_mem_read,
    output reg ex_mem_mem_to_reg,

    output reg ex_mem_jump,
    output reg [31:0] ex_mem_pc_plus4
);

    wire [31:0] rs1_forwarded;
    wire [31:0] rs2_forwarded;
	 
    //resolve RAW hazards
	 // 10 -> take latest result from EX/MEM stage
	 // 01 -> take result from WB stage
    // 00 -> use value read from register file
    assign rs1_forwarded = (fwd_a == 2'b10) ? ex_mem_alu_result : (fwd_a == 2'b01) ? wb_data : id_ex_rs1_data;
    assign rs2_forwarded = (fwd_b == 2'b10) ? ex_mem_alu_result : (fwd_b == 2'b01) ? wb_data : id_ex_rs2_data;
	 
    wire use_pc;
    
	 // Use PC as ALU operand A for PC-relative operations (JAL/AUIPC).
	 // Otherwise, use the forwarded rs1 value.
	 // Exclude loads/stores (base address = rs1 + imm) and JALR (target = rs1 + imm).
    assign use_pc = id_ex_jump || ((id_ex_alu_op == 2'b00) && id_ex_alu_src && !id_ex_mem_read && !id_ex_mem_write && !id_ex_is_jalr);
	
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    
	 //use_pc = 1  -> ALU operand A = PC
	 //use_pc = 0  -> ALU operand A = rs1
    assign alu_operand_a = use_pc ? id_ex_pc : rs1_forwarded;
    assign alu_operand_b = id_ex_alu_src ? id_ex_imm : rs2_forwarded;

    wire [3:0] alu_ctrl;

    alu_control u_alu_ctrl (
        .alu_op(id_ex_alu_op),
        .funct3(id_ex_funct3),
        .funct7_5(id_ex_funct7_5),
        .alu_ctrl(alu_ctrl)
    );

    wire [31:0] alu_result;
    wire alu_zero;

    alu u_alu (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );

    reg branch_cond;

    always @(*) begin
        case(id_ex_funct3)

            3'b000: branch_cond = (alu_operand_a == rs2_forwarded); //BEQ
            3'b001: branch_cond = (alu_operand_a != rs2_forwarded); //BNE
            3'b100: branch_cond = ($signed(alu_operand_a) < $signed(rs2_forwarded)); //BLT
            3'b101: branch_cond = ($signed(alu_operand_a) >= $signed(rs2_forwarded)); //BGE
            3'b110: branch_cond = (alu_operand_a < rs2_forwarded); //BLTU
            3'b111: branch_cond = (alu_operand_a >= rs2_forwarded); //BGEU
            default: branch_cond = 1'b0;
        endcase
    end

    assign branch_taken = id_ex_branch & branch_cond;
    assign jump_out = id_ex_jump;
    assign pc_target = id_ex_is_jalr ? ((rs1_forwarded + id_ex_imm) & ~32'd1) : (id_ex_pc + id_ex_imm);
	 
    wire [31:0] pc_plus4;

    assign pc_plus4 = id_ex_pc + 32'd4;

    always @(posedge clk or posedge rst) begin

        if(rst) begin
            ex_mem_alu_out <= 32'b0;
            ex_mem_rs2_data <= 32'b0;
            ex_mem_rd <= 5'b0;
            ex_mem_funct3 <= 3'b0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_jump <= 1'b0;
            ex_mem_pc_plus4 <= 32'b0;

        end
        else begin

            ex_mem_alu_out <= alu_result;
            ex_mem_rs2_data <= rs2_forwarded;
            ex_mem_rd <= id_ex_rd;
            ex_mem_funct3 <= id_ex_funct3;

            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_jump <= id_ex_jump;

            ex_mem_pc_plus4 <= pc_plus4;
        end
    end
endmodule