module riscv_tb;

reg clk;
reg rst;

integer pass_count;
integer fail_count;

RISC_V dut (
    .clk(clk),
    .rst(rst)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 0;

    pass_count = 0;
    fail_count = 0;

    test_rtype("ADD" ,32'h002081B3, 32'd15);
    test_rtype("SUB" ,32'h402081B3, 32'd4294967291);
    test_rtype("SLL" ,32'h002091B3, 32'd5120);
    test_rtype("SLT" ,32'h0020A1B3, 32'd1);
    test_rtype("SLTU",32'h0020B1B3, 32'd1);
    test_rtype("XOR" ,32'h0020C1B3, 32'd15);
    test_rtype("SRL" ,32'h0020D1B3, 32'd0);
    test_rtype("SRA" ,32'h4020D1B3, 32'd0);
    test_rtype("OR"  ,32'h0020E1B3, 32'd15);
    test_rtype("AND" ,32'h0020F1B3, 32'd0);

    test_itype("ADDI" ,32'h00A08193, 32'd15);
    test_itype("SLTI" ,32'h00A0A193, 32'd1);
    test_itype("SLTIU",32'h00A0B193, 32'd1);
    test_itype("XORI" ,32'h00F0C193, 32'd10);
    test_itype("ORI"  ,32'h00A0E193, 32'd15);
    test_itype("ANDI" ,32'h00F0F193, 32'd5);

    test_itype("SLLI" ,32'h00209193, 32'd20);
    test_itype("SRLI" ,32'h0010D193, 32'd2);
    test_itype("SRAI" ,32'h4010D193, 32'd2);

    test_store_load;
	 test_lui;
	 test_auipc;
	 test_jal;
	test_jalr;

	test_beq;
	test_bne;
	test_blt;
	test_bge;
	test_bltu;
	test_bgeu;

	test_sb_lb;
	test_sh_lh;
	test_lbu;
	test_lhu;

    $display("PASS = %0d", pass_count);
    $display("FAIL = %0d", fail_count);

    $stop;

end

task clear_mem;

integer i;

begin

    for(i=0;i<256;i=i+1)
        dut.u_inst_mem.mem[i] = 32'h00000013;

    for(i=0;i<256;i=i+1)
        dut.u_data_mem.mem[i] = 8'b0;

end
endtask

task test_rtype;

input [127:0] name;
input [31:0] instr;
input [31:0] expected;

begin

    clear_mem;

    dut.u_inst_mem.mem[0] = instr;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd5;
    dut.u_id.u_regfile.regs[2] = 32'd10;

    rst = 0;

    repeat(12) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == expected) begin
        $display("%s PASS", name);
        pass_count = pass_count + 1;
    end
    else begin
        $display("%s FAIL expected=%0d got=%0d",
                 name,
                 expected,
                 dut.u_id.u_regfile.regs[3]);
        fail_count = fail_count + 1;
    end

end
endtask

task test_itype;

input [127:0] name;
input [31:0] instr;
input [31:0] expected;

begin

    clear_mem;

    dut.u_inst_mem.mem[0] = instr;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd5;

    rst = 0;

    repeat(12) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == expected) begin
        $display("%s PASS", name);
        pass_count = pass_count + 1;
    end
    else begin
        $display("%s FAIL expected=%0d got=%0d",
                 name,
                 expected,
                 dut.u_id.u_regfile.regs[3]);
        fail_count = fail_count + 1;
    end

end
endtask

task test_store_load;

begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h02A00093;
    dut.u_inst_mem.mem[1] = 32'h00102023;
    dut.u_inst_mem.mem[2] = 32'h00002183;

    rst = 1;
    repeat(4) @(posedge clk);

    rst = 0;

    repeat(16) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd42) begin
        $display("LOAD_STORE PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("LOAD_STORE FAIL expected=42 got=%0d",
                 dut.u_id.u_regfile.regs[3]);
        fail_count = fail_count + 1;
    end

end
endtask

task test_lui;

begin

    clear_mem;

    // lui x3,0x12345
    dut.u_inst_mem.mem[0] = 32'h123451B7;

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(12) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'h12345000) begin
        $display("LUI PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("LUI FAIL expected=%h got=%h",
                 32'h12345000,
                 dut.u_id.u_regfile.regs[3]);
        fail_count = fail_count + 1;
    end

end

endtask


task test_auipc;

begin

    clear_mem;

    // auipc x3,0x12345
    dut.u_inst_mem.mem[0] = 32'h12345197;

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(12) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'h12345000) begin
        $display("AUIPC PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("AUIPC FAIL expected=%h got=%h",
                 32'h12345000,
                 dut.u_id.u_regfile.regs[3]);
        fail_count = fail_count + 1;
    end

end

endtask

task test_jal;
begin

    clear_mem;

    // jal x1,+8
    dut.u_inst_mem.mem[0] = 32'h008000EF;

    // addi x3,x0,0  (should be skipped)
    dut.u_inst_mem.mem[1] = 32'h00000193;

    // addi x3,x0,42
    dut.u_inst_mem.mem[2] = 32'h02A00193;

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if ((dut.u_id.u_regfile.regs[1] == 32'd4) &&
        (dut.u_id.u_regfile.regs[3] == 32'd42)) begin
        $display("JAL PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("JAL FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_jalr;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h00800093; // addi x1,x0,8
    dut.u_inst_mem.mem[1] = 32'h000082E7; // jalr x5,x1,0
    dut.u_inst_mem.mem[2] = 32'h00000193; // skipped
    dut.u_inst_mem.mem[3] = 32'h02A00193; // addi x3,x0,42

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(25) @(posedge clk);
    #1;

    if ((dut.u_id.u_regfile.regs[5] == 32'd8) &&
        (dut.u_id.u_regfile.regs[3] == 32'd42)) begin
        $display("JALR PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("JALR FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_beq;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h00208463; // beq x1,x2,+8
    dut.u_inst_mem.mem[1] = 32'h00000193; // skipped
    dut.u_inst_mem.mem[2] = 32'h02A00193; // target

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd5;
    dut.u_id.u_regfile.regs[2] = 32'd5;

    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd42) begin
        $display("BEQ PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("BEQ FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_bne;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h00209463; // bne x1,x2,+8
    dut.u_inst_mem.mem[1] = 32'h00000193;
    dut.u_inst_mem.mem[2] = 32'h02A00193;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd5;
    dut.u_id.u_regfile.regs[2] = 32'd10;

    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd42) begin
        $display("BNE PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("BNE FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_blt;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h0020C463;
    dut.u_inst_mem.mem[1] = 32'h00000193;
    dut.u_inst_mem.mem[2] = 32'h02A00193;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd5;
    dut.u_id.u_regfile.regs[2] = 32'd10;

    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd42) begin
        $display("BLT PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("BLT FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_bge;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h0020D463;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd10;
    dut.u_id.u_regfile.regs[2] = 32'd5;

    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd42)
        pass_count = pass_count + 1;
    else
        fail_count = fail_count + 1;

end
endtask

task test_bltu;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h0020E463;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd5;
    dut.u_id.u_regfile.regs[2] = 32'd10;

    rst = 0;

    repeat(20) @(posedge clk);

end
endtask

task test_bgeu;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h0020F463;

    rst = 1;
    repeat(4) @(posedge clk);

    dut.u_id.u_regfile.regs[1] = 32'd10;
    dut.u_id.u_regfile.regs[2] = 32'd5;

    rst = 0;

    repeat(20) @(posedge clk);

end
endtask

task test_sb_lb;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'h0FF00093; // addi x1,x0,255
    dut.u_inst_mem.mem[1] = 32'h00100023; // sb x1,0(x0)
    dut.u_inst_mem.mem[2] = 32'h00000183; // lb x3,0(x0)

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(25) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'hFFFFFFFF) begin
        $display("SB_LB PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("SB_LB FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_sh_lh;
begin

    clear_mem;

    dut.u_inst_mem.mem[0] = 32'hFFF00093;
    dut.u_inst_mem.mem[1] = 32'h00101023;
    dut.u_inst_mem.mem[2] = 32'h00001183;

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(25) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'hFFFFFFFF) begin
        $display("SH_LH PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("SH_LH FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_lbu;
begin

    clear_mem;

    dut.u_data_mem.mem[0] = 8'hFF;

    dut.u_inst_mem.mem[0] = 32'h00004183;

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd255) begin
        $display("LBU PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("LBU FAIL");
        fail_count = fail_count + 1;
    end

end
endtask

task test_lhu;
begin

    clear_mem;

    dut.u_data_mem.mem[0] = 8'hFF;
    dut.u_data_mem.mem[1] = 8'hFF;

    dut.u_inst_mem.mem[0] = 32'h00005183;

    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;

    repeat(20) @(posedge clk);
    #1;

    if(dut.u_id.u_regfile.regs[3] == 32'd65535) begin
        $display("LHU PASS");
        pass_count = pass_count + 1;
    end
    else begin
        $display("LHU FAIL");
        fail_count = fail_count + 1;
    end

end
endtask



endmodule