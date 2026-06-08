module forward_unit ( 
    input wire [4:0] id_ex_rs1, // rs1 address
    input wire [4:0] id_ex_rs2, // rs2 address
  
    input wire ex_mem_reg_write, // 1 if EX/MEM instruction writes a reg
    input wire [4:0] ex_mem_rd, // destination register of EX/MEM inst

    input  wire mem_wb_reg_write, // 1 if MEM/WB instruction writes a reg
    input  wire [4:0] mem_wb_rd, // destination register of MEM/WB inst

    output reg  [1:0]  fwd_a, // select for operand A (rs1)
    output reg  [1:0]  fwd_b // select for operand B (rs2)
);


    always @(*) begin
        // Default: no forwarding — use register file value from ID/EX
        fwd_a = 2'b00;

        // EX/MEM path — higher priority, checked last so it overwrites MEM/WB
        // Conditions:
        //   (a) EX/MEM instruction actually writes a register
        //   (b) It's not writing x0 (x0 is always 0, forwarding it is wrong)
        //   (c) Its destination matches the rs1 we need
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1))
		    begin
				fwd_a = 2'b10; // forward from EX/MEM
        end
        // MEM/WB path — lower priority
        // Same three conditions but for the MEM/WB register
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1)) 
			 begin
            fwd_a = 2'b01; // forward from MEM/WB
        end
    end

    always @(*) begin
        fwd_b = 2'b00;

        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) 
		    begin
            fwd_b = 2'b10; // forward from EX/MEM
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2)) 
		    begin
            fwd_b = 2'b01; // forward from MEM/WB
        end
    end

endmodule