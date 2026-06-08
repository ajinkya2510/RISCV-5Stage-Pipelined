module RISC_V (
    input wire clk,
    input wire rst
);

wire [31:0] pc_out;
wire [31:0] if_id_pc;
wire [31:0] if_id_inst;
wire [31:0] inst_mem_out;

wire [31:0] id_ex_pc;
wire [31:0] id_ex_rs1_data;
wire [31:0] id_ex_rs2_data;
wire [31:0] id_ex_imm;
wire [4:0] id_ex_rs1;
wire [4:0] id_ex_rs2;
wire [4:0] id_ex_rd;
wire [2:0] id_ex_funct3;
wire id_ex_funct7_5;

wire id_ex_reg_write;
wire id_ex_alu_src;
wire id_ex_mem_write;
wire id_ex_mem_read;
wire id_ex_mem_to_reg;
wire id_ex_branch;
wire id_ex_jump;
wire [1:0] id_ex_alu_op;
wire id_ex_is_jalr;

wire branch_taken;
wire jump_out;
wire [31:0] pc_target;

wire [31:0] ex_mem_alu_out;
wire [31:0] ex_mem_rs2_data;
wire [4:0] ex_mem_rd;
wire [2:0] ex_mem_funct3;
wire ex_mem_reg_write;
wire ex_mem_mem_write;
wire ex_mem_mem_read;
wire ex_mem_mem_to_reg;
wire ex_mem_jump;
wire [31:0] ex_mem_pc_plus4;

wire [31:0] mem_addr;
wire [31:0] mem_write_data;
wire mem_write_en;
wire mem_read_en;
wire [31:0] mem_read_data;

wire [31:0] mem_wb_alu_result;
wire [31:0] mem_wb_mem_data;
wire [4:0] mem_wb_rd;
wire mem_wb_reg_write;
wire mem_wb_mem_to_reg;
wire mem_wb_jump;
wire [31:0] mem_wb_pc_plus4;

wire [31:0] wb_data;
wire [4:0] wb_rd;
wire wb_reg_write;

wire stall;
wire flush;
wire [1:0] fwd_a;
wire [1:0] fwd_b;

inst_mem u_inst_mem (
    .addr(pc_out),
    .inst(inst_mem_out)
);

if_stage u_if (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),
    .branch_taken(branch_taken),
    .jump(jump_out),
    .pc_target(pc_target),
    .inst_in(inst_mem_out),
    .pc_out(pc_out),
    .if_id_pc(if_id_pc),
    .if_id_inst(if_id_inst)
);

id_stage u_id (
    .clk(clk),
    .rst(rst),
    .if_id_inst(if_id_inst),
    .if_id_pc(if_id_pc),
    .wb_reg_write(wb_reg_write),
    .wb_rd(wb_rd),
    .wb_data(wb_data),
    .flush(flush),
    .stall(stall),

    .id_ex_pc(id_ex_pc),
    .id_ex_rs1_data(id_ex_rs1_data),
    .id_ex_rs2_data(id_ex_rs2_data),
    .id_ex_imm(id_ex_imm),
    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),
    .id_ex_rd(id_ex_rd),
    .id_ex_funct3(id_ex_funct3),
    .id_ex_funct7_5(id_ex_funct7_5),

    .id_ex_reg_write(id_ex_reg_write),
    .id_ex_alu_src(id_ex_alu_src),
    .id_ex_mem_write(id_ex_mem_write),
    .id_ex_mem_read(id_ex_mem_read),
    .id_ex_mem_to_reg(id_ex_mem_to_reg),
    .id_ex_branch(id_ex_branch),
    .id_ex_jump(id_ex_jump),
    .id_ex_alu_op(id_ex_alu_op),
    .id_ex_is_jalr(id_ex_is_jalr)
);

ex_stage u_ex (
    .clk(clk),
    .rst(rst),

    .id_ex_pc(id_ex_pc),
    .id_ex_rs1_data(id_ex_rs1_data),
    .id_ex_rs2_data(id_ex_rs2_data),
    .id_ex_imm(id_ex_imm),

    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),
    .id_ex_rd(id_ex_rd),

    .id_ex_funct3(id_ex_funct3),
    .id_ex_funct7_5(id_ex_funct7_5),

    .id_ex_reg_write(id_ex_reg_write),
    .id_ex_alu_src(id_ex_alu_src),
    .id_ex_mem_write(id_ex_mem_write),
    .id_ex_mem_read(id_ex_mem_read),
    .id_ex_mem_to_reg(id_ex_mem_to_reg),
    .id_ex_branch(id_ex_branch),
    .id_ex_jump(id_ex_jump),
    .id_ex_alu_op(id_ex_alu_op),
    .id_ex_is_jalr(id_ex_is_jalr),

    .fwd_a(fwd_a),
    .fwd_b(fwd_b),

    .ex_mem_alu_result(ex_mem_alu_out),
    .wb_data(wb_data),

    .branch_taken(branch_taken),
    .jump_out(jump_out),
    .pc_target(pc_target),

    .ex_mem_alu_out(ex_mem_alu_out),
    .ex_mem_rs2_data(ex_mem_rs2_data),
    .ex_mem_rd(ex_mem_rd),
    .ex_mem_funct3(ex_mem_funct3),

    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_mem_write(ex_mem_mem_write),
    .ex_mem_mem_read(ex_mem_mem_read),
    .ex_mem_mem_to_reg(ex_mem_mem_to_reg),

    .ex_mem_jump(ex_mem_jump),
    .ex_mem_pc_plus4(ex_mem_pc_plus4)
);

mem_stage u_mem (
    .clk (clk),
    .rst(rst),

    .ex_mem_alu_out(ex_mem_alu_out),
    .ex_mem_rs2_data(ex_mem_rs2_data),
    .ex_mem_rd(ex_mem_rd),
    .ex_mem_funct3(ex_mem_funct3),

    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_mem_write(ex_mem_mem_write),
    .ex_mem_mem_read(ex_mem_mem_read),
    .ex_mem_mem_to_reg(ex_mem_mem_to_reg),

    .ex_mem_jump(ex_mem_jump),
    .ex_mem_pc_plus4(ex_mem_pc_plus4),

    .mem_addr(mem_addr),
    .mem_write_data(mem_write_data),
    .mem_write_en(mem_write_en),
    .mem_read_en(mem_read_en),
    .mem_read_data(mem_read_data),

    .mem_wb_alu_result(mem_wb_alu_result),
    .mem_wb_mem_data(mem_wb_mem_data),
    .mem_wb_rd(mem_wb_rd),
    .mem_wb_reg_write(mem_wb_reg_write),
    .mem_wb_mem_to_reg(mem_wb_mem_to_reg),

    .mem_wb_jump(mem_wb_jump),
    .mem_wb_pc_plus4(mem_wb_pc_plus4)
);

data_mem u_data_mem (
    .clk(clk),
    .mem_write(mem_write_en),
    .mem_read(mem_read_en),
    .funct3(ex_mem_funct3),
    .addr(mem_addr),
    .write_data(mem_write_data),
    .read_data(mem_read_data)
);

wb_stage u_wb (
    .mem_wb_alu_result(mem_wb_alu_result),
    .mem_wb_mem_data(mem_wb_mem_data),
    .mem_wb_rd(mem_wb_rd),
    .mem_wb_reg_write(mem_wb_reg_write),
    .mem_wb_mem_to_reg(mem_wb_mem_to_reg),

    .mem_wb_jump(mem_wb_jump),
    .mem_wb_pc_plus4(mem_wb_pc_plus4),

    .wb_data(wb_data),
    .wb_rd(wb_rd),
    .wb_reg_write(wb_reg_write)
);

hazard_unit u_hazard (
    .id_ex_mem_read(id_ex_mem_read),
    .id_ex_rd(id_ex_rd),
    .if_id_rs1(if_id_inst[19:15]),
    .if_id_rs2(if_id_inst[24:20]),
    .branch_taken(branch_taken),
    .jump(jump_out),
    .stall(stall),
    .flush(flush)
);

forward_unit u_fwd (
    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),

    .ex_mem_reg_write(ex_mem_reg_write),
    .ex_mem_rd(ex_mem_rd),

    .mem_wb_reg_write(mem_wb_reg_write),
    .mem_wb_rd(mem_wb_rd),

    .fwd_a(fwd_a),
    .fwd_b(fwd_b)
);

endmodule