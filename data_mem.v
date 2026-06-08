// Simple byte-addressable RAM, 1 KB (256 words).
// Supports word (LW/SW), halfword (LH/LHU/SH), and byte (LB/LBU/SB) access.
//
// Write: synchronous (on posedge clk)
// Read : asynchronous (combinational) — MEM stage reads in same cycle
//
// funct3 encoding for load/store width:
//   000 — byte  (LB / SB)
//   001 — half  (LH / SH)
//   010 — word  (LW / SW)
//   100 — byte unsigned  (LBU)
//   101 — half unsigned  (LHU)

module data_mem (
    input  wire clk,
    input  wire mem_write,
    input  wire mem_read,
    input  wire [2:0] funct3,         // access width selector
    input  wire [31:0] addr,           // byte address
    input  wire [31:0] write_data,
    output reg [31:0] read_data
);

    reg [7:0] mem [0:1023]; 	 // byte-addressable, 1 KB
    
	 integer j;
    initial begin
        for (j = 0; j < 1024; j = j + 1) mem[j] = 8'h00;
    end


    // Synchronous write — byte/half/word granularity
 
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[addr] <= write_data[7:0]; // SB
                3'b001: begin // SH
									mem[addr] <= write_data[7:0];
									mem[addr+1] <= write_data[15:8];
                end
                3'b010: begin // SW
                    mem[addr] <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                    mem[addr+3] <= write_data[31:24];
                end
                default: mem[addr] <= write_data[7:0];
            endcase
        end
    end


    // Asynchronous read — sign/zero extension based on funct3
    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: read_data = {{24{mem[addr][7]}}, mem[addr]}; // LB  (sign-extend)
                3'b001: read_data = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]}; // LH  (sign-extend)
                3'b010: read_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}; // LW
                3'b100: read_data = {24'b0, mem[addr]}; // LBU (zero-extend)
                3'b101: read_data = {16'b0, mem[addr+1], mem[addr]}; // LHU (zero-extend)
                default: read_data = 32'b0;
            endcase
        end
        else
            read_data = 32'b0;
    end
endmodule

