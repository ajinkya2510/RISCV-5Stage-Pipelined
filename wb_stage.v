module wb_stage (

    input wire [31:0] mem_wb_alu_result, // ALU result from EX/MEM path
    input wire [31:0] mem_wb_mem_data, // Data loaded from memory
    input wire [4:0] mem_wb_rd, // Destination register
    input wire mem_wb_reg_write, // Register write enable
    input wire mem_wb_mem_to_reg, // Select memory data over ALU result

    input wire mem_wb_jump, // JAL/JALR instruction
    input wire [31:0] mem_wb_pc_plus4, //PC + 4

    output wire [31:0] wb_data, // Data to be written back
    output wire [4:0] wb_rd, 
    output wire wb_reg_write
);

   // Write-back data selection:
    // JAL/JALR -> write PC+4
    // Load     -> write memory data
    // Others   -> write ALU resul
	assign wb_data = mem_wb_jump ? mem_wb_pc_plus4 : mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;
	assign wb_rd = mem_wb_rd;
	assign wb_reg_write = mem_wb_reg_write;

endmodule