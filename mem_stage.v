module mem_stage (
    input  wire clk,
    input  wire rst,

    input  wire [31:0] ex_mem_alu_out,
    input  wire [31:0] ex_mem_rs2_data,
    input  wire [4:0] ex_mem_rd,
    input  wire [2:0] ex_mem_funct3,
    input  wire ex_mem_reg_write,
    input  wire ex_mem_mem_write,
    input  wire ex_mem_mem_read,
    input  wire ex_mem_mem_to_reg,

    input  wire ex_mem_jump,
    input  wire [31:0] ex_mem_pc_plus4,

    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire mem_write_en,
    output wire mem_read_en,
    input  wire [31:0] mem_read_data,

    output reg [31:0] mem_wb_alu_result,
    output reg [31:0] mem_wb_mem_data,
    output reg [4:0]  mem_wb_rd,
    output reg mem_wb_reg_write,
    output reg mem_wb_mem_to_reg,

    output reg mem_wb_jump,
    output reg [31:0] mem_wb_pc_plus4
);

    // Memory access signals
    assign mem_addr = ex_mem_alu_out;
    assign mem_write_data = ex_mem_rs2_data;
    assign mem_write_en = ex_mem_mem_write;
    assign mem_read_en = ex_mem_mem_read;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            mem_wb_alu_result <= 32'b0;
            mem_wb_mem_data <= 32'b0;
            mem_wb_rd <= 5'b0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;

            mem_wb_jump <= 1'b0;
            mem_wb_pc_plus4 <= 32'b0;

        end
        else begin
		      // Pass results and control signals to WB stage
            mem_wb_alu_result <= ex_mem_alu_out;
            mem_wb_mem_data <= mem_read_data;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;

				// Preserve jump information for JAL/JALR write-back
            mem_wb_jump <= ex_mem_jump;
            mem_wb_pc_plus4 <= ex_mem_pc_plus4;

        end
    end

endmodule