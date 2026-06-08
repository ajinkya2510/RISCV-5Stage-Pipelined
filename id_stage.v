module id_stage (
	input  wire clk,
	input  wire rst,
	input  wire [31:0] if_id_inst, // instruction bits
	input  wire [31:0] if_id_pc, // PC of this instruction
	input  wire wb_reg_write,
	input  wire [4:0] wb_rd,
	input  wire [31:0] wb_data,
	input  wire flush, // insert NOP into ID/EX (branch taken)
	input  wire stall, // freeze ID/EX (load-use hazard)

	output reg  [31:0] id_ex_pc,
	output reg  [31:0] id_ex_rs1_data,
	output reg  [31:0] id_ex_rs2_data,
	output reg  [31:0] id_ex_imm,
	output reg  [4:0] id_ex_rs1, // source reg addresses (for forwarding unit)
	output reg  [4:0] id_ex_rs2,
	output reg  [4:0] id_ex_rd,
	output reg  [2:0] id_ex_funct3,
	output reg id_ex_funct7_5,

	output reg id_ex_is_jalr,
	output reg id_ex_reg_write,
	output reg id_ex_alu_src,
	output reg id_ex_mem_write,
	output reg id_ex_mem_read,
	output reg id_ex_mem_to_reg,
	output reg id_ex_branch,
	output reg id_ex_jump,
	output reg [1:0] id_ex_alu_op
);

	wire [6:0] opcode = if_id_inst[6:0];
	wire [4:0] rd = if_id_inst[11:7];
	wire [2:0] funct3 = if_id_inst[14:12];
	wire [4:0] rs1 = if_id_inst[19:15];
	wire [4:0] rs2 = if_id_inst[24:20];
	wire funct7_5 = if_id_inst[30];
	wire is_jalr = (opcode == 7'b1100111); // I_JALR opcode
	wire [31:0] rs1_data, rs2_data;

	regfile u_regfile (
		.clk(clk),
		.rs1_addr(rs1),
		.rs1_data(rs1_data),
		.rs2_addr(rs2),
		.rs2_data(rs2_data),
		.we(wb_reg_write),
		.rd_addr(wb_rd),
		.rd_data(wb_data)
	);

	// Immediate generator
	wire [31:0] imm;
	
	imm_gen u_imm_gen (
		.inst(if_id_inst),
		.imm_out(imm)
	);

	wire ctrl_reg_write, ctrl_alu_src, ctrl_mem_write, ctrl_mem_read;
	wire ctrl_mem_to_reg, ctrl_branch, ctrl_jump;
	wire [1:0] ctrl_alu_op;

	control u_control (
		.opcode(opcode),
		.reg_write(ctrl_reg_write),
		.alu_src(ctrl_alu_src),
		.mem_write(ctrl_mem_write),
		.mem_read(ctrl_mem_read),
		.mem_to_reg(ctrl_mem_to_reg),
		.branch(ctrl_branch),
		.jump(ctrl_jump),
		.alu_op(ctrl_alu_op)
	);


	// On flush or stall: insert bubble (all control signals = 0) to prevent the instruction from having any side-effects downstream.

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// Async reset — zero everything
			id_ex_pc <= 32'b0;
			id_ex_rs1_data <= 32'b0;
			id_ex_rs2_data <= 32'b0;
			id_ex_imm <= 32'b0;
			id_ex_rs1 <= 5'b0;
			id_ex_rs2 <= 5'b0;
			id_ex_rd <= 5'b0;
			id_ex_funct3 <= 3'b0;
			id_ex_funct7_5 <= 1'b0;
			id_ex_reg_write <= 0;
			id_ex_alu_src <= 0;
			id_ex_mem_write <= 0;
			id_ex_mem_read <= 0;
			id_ex_mem_to_reg <= 0;
			id_ex_branch <= 0;
			id_ex_jump <= 0;
			id_ex_alu_op <= 2'b00;
			id_ex_is_jalr <= 0;
		end
		else if (flush || stall) begin
			// Synchronous bubble injection:
			// flush = branch/jump taken(squash this instruction)
			// stall = load-use hazard(squash this instruction (PC/IF frozen))
			// Data fields zeroed so downstream stages see a NOP
			id_ex_pc <= 32'b0;
			id_ex_rs1_data <= 32'b0;
			id_ex_rs2_data <= 32'b0;
			id_ex_imm <= 32'b0;
			id_ex_rs1 <= 5'b0;
			id_ex_rs2 <= 5'b0;
			id_ex_rd <= 5'b0;
			id_ex_funct3 <= 3'b0;
			id_ex_funct7_5 <= 1'b0;
		  
			id_ex_reg_write <= 0;
			id_ex_alu_src <= 0;
			id_ex_mem_write <= 0;
			id_ex_mem_read <= 0;
			id_ex_mem_to_reg <= 0;
			id_ex_branch <= 0;
			id_ex_jump <= 0;
			id_ex_alu_op <= 2'b00;
			id_ex_is_jalr <= 0;
		end
		else begin
			// Normal operation — latch decoded instruction into ID/EX register
			id_ex_pc <= if_id_pc;
			id_ex_rs1_data <= rs1_data;
			id_ex_rs2_data <= rs2_data;
			id_ex_imm <= imm;
			id_ex_rs1 <= rs1;
			id_ex_rs2 <= rs2;
			id_ex_rd <= rd;
			id_ex_funct3 <= funct3;
			id_ex_funct7_5 <= (opcode == 7'b0110011) || ((opcode == 7'b0010011) && ((funct3 == 3'b001) || (funct3 == 3'b101))) ? funct7_5 : 1'b0;
			id_ex_reg_write <= ctrl_reg_write;
			id_ex_alu_src <= ctrl_alu_src;
			id_ex_mem_write <= ctrl_mem_write;
			id_ex_mem_read <= ctrl_mem_read;
			id_ex_mem_to_reg <= ctrl_mem_to_reg;
			id_ex_branch <= ctrl_branch;
			id_ex_jump <= ctrl_jump;
			id_ex_alu_op <= ctrl_alu_op;
			id_ex_is_jalr <= is_jalr;
		end
	end
endmodule