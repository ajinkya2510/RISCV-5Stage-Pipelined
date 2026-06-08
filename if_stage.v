module if_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall, // 1 = freeze PC and IF/ID register
    input  wire        flush, // 1 = squash instruction in IF/ID (branch taken)
    input  wire        branch_taken, // 1 = a branch was resolved as taken in EX
    input  wire        jump, // 1 = unconditional jump in EX
    input  wire [31:0] pc_target, // branch/jump destination address
    input  wire [31:0] inst_in, // instruction from inst_mem (combinational)
    output wire [31:0] pc_out, // address sent to inst memory
    output reg  [31:0] if_id_pc, // PC of fetched instruction
    output reg  [31:0] if_id_inst // fetched instruction bits
);

   
    reg [31:0] pc; // Program Counter register

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0000_0000; // boot from address 0
       else if ((branch_taken === 1'b1) || (jump === 1'b1))
            pc <= pc_target; // redirect: branch/jump wins
        else if (!stall)
            pc <= pc + 4;  // normal advance
        // else: stall,hold pc (no assignment)
    end

    assign pc_out = pc; // drives instruction memory address port

    localparam NOP = 32'h0000_0013;     // ADDI x0, x0, 0 - the canonical RV32I NOP (does nothing)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc   <= 32'b0;
            if_id_inst <= NOP;
        end
        else if (flush) begin // branch taken → kill instruction in flight
            if_id_pc   <= 32'b0;
            if_id_inst <= NOP;
        end
        else if (!stall) begin // normal: latch PC and instruction
            if_id_pc   <= pc;
            if_id_inst <= inst_in; // inst memory is combinational: inst = mem[pc]
        end
        // else stall: hold current if_id values
    end

endmodule