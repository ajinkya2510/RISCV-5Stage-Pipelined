module regfile (
    input  wire        clk,

    //rs1
    input  wire [4:0]  rs1_addr,    // rs1 address (5 bits, 32 regs)
    output wire [31:0] rs1_data,    // value of x[rs1_addr]

    //rs2
    input  wire [4:0]  rs2_addr,    // rs2 address
    output wire [31:0] rs2_data,    // value of x[rs2_addr]

    //Write port (rd) 
    input  wire        we,          // write-enable (from WB stage)
    input  wire [4:0]  rd_addr,     // destination register address
    input  wire [31:0] rd_data      // data to write
);

    reg [31:0] regs [0:31]; //32 registers × 32 bits

    // Initialise all registers to 0 
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Synchronous write - rising edge, x0 protected
    always @(posedge clk) begin
        if (we && (rd_addr != 5'b0))   // never write x0
            regs[rd_addr] <= rd_data;
    end

    // WB-ID forwarding(If the WB stage is writing to the same register we are trying to read,forward the new value instead of the (stale) stored value)
    // This eliminates one class of data hazard without a stall.
    assign rs1_data = (we && (rd_addr != 0) && (rd_addr == rs1_addr))
                      ? rd_data          // forward from WB
                      : regs[rs1_addr];  // normal read

    assign rs2_data = (we && (rd_addr != 0) && (rd_addr == rs2_addr))
                      ? rd_data          // forward from WB
                      : regs[rs2_addr];  // normal read

endmodule