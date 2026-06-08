module inst_mem (
    input  wire [31:0] addr,
    output wire [31:0] inst
);

    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for(i=0;i<256;i=i+1)
            mem[i] = 32'h00000013;
    end

	 // Instruction fetch
    // Instructions are 4 bytes wide, so use addr[9:2]
    // to convert byte address into word index
    assign inst = mem[addr[9:2]];
endmodule