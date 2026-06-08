
//  top
//  ├── inst_mem          instruction memory (ROM)
//  ├── data_mem          data memory (RAM)
//  ├── if_stage          PC register + IF/ID pipeline register
//  ├── id_stage          decode + regfile + imm_gen + control + ID/EX register
//  ├── ex_stage          forwarding muxes + ALU + branch + EX/MEM register
//  ├── mem_stage         memory access + MEM/WB register
//  ├── wb_stage          writeback mux (no register — purely combinational)
//  ├── hazard_unit       load-use stall + branch/jump flush
//  └── forward_unit      EX/MEM and MEM/WB operand forwarding
//

// PIPELINE REGISTER NAMING CONVENTION

//  if_id_*   : wires between IF stage and ID stage
//  id_ex_*   : wires between ID stage and EX stage
//  ex_mem_*  : wires between EX stage and MEM stage
//  mem_wb_*  : wires between MEM stage and WB stage
//

// HAZARD HANDLING SUMMARY

//
//  Load-use hazard  → hazard_unit asserts stall
//                     · IF stage and IF/ID register freeze
//                     · ID/EX register gets NOP bubble
//
//  Branch taken     → hazard_unit asserts flush
//  Unconditional    → (branch_taken || jump) && !stall
//  jump             · IF/ID register gets NOP
//                   · ID/EX register gets NOP
//                   · PC redirected to pc_target from EX stage
//
//  ALU data hazard  → forward_unit asserts fwd_a / fwd_b
//                     · EX/MEM → EX  (one-cycle-old result)
//                     · MEM/WB → EX  (two-cycle-old result or loaded value)
//


module RISC_V (
    input  wire clk,
    input  wire rst
);

  
    // IF STAGE wires

    wire [31:0] pc_out;           // PC → instruction memory address
    wire [31:0] if_id_pc;         // IF/ID: PC of fetched instruction
    wire [31:0] if_id_inst;       // IF/ID: raw instruction bits

   
    // ID STAGE wires

    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm;
    wire [4:0]  id_ex_rs1;
    wire [4:0]  id_ex_rs2;
    wire [4:0]  id_ex_rd;
    wire [2:0]  id_ex_funct3;
    wire        id_ex_funct7_5;
    // Control signals travelling with the instruction
    wire        id_ex_reg_write;
    wire        id_ex_alu_src;
    wire        id_ex_mem_write;
    wire        id_ex_mem_read;
    wire        id_ex_mem_to_reg;
    wire        id_ex_branch;
    wire        id_ex_jump;
    wire [1:0]  id_ex_alu_op;

 
    // EX STAGE wires

    wire        branch_taken;     // resolved branch condition → IF + hazard_unit
    wire        jump_out;         // jump asserted → IF + hazard_unit
    wire [31:0] pc_target;        // computed branch/jump target → IF stage

    wire [31:0] ex_mem_alu_out;
    wire [31:0] ex_mem_rs2_data;
    wire [4:0]  ex_mem_rd;
    wire [2:0]  ex_mem_funct3;
    wire        ex_mem_reg_write;
    wire        ex_mem_mem_write;
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_to_reg;
    wire [31:0] ex_mem_pc_plus4;  // return address for JAL/JALR


    // MEM STAGE wires

    wire [31:0] mem_addr;         // data memory address
    wire [31:0] mem_write_data;   // data memory write data
    wire        mem_write_en;     // data memory write enable
    wire        mem_read_en;      // data memory read enable
    wire [31:0] mem_read_data;    // data memory read result

    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_reg_write;
    wire        mem_wb_mem_to_reg;


    // WB STAGE wires
 
    wire [31:0] wb_data;          // value written back to register file
    wire [4:0]  wb_rd;            // destination register
    wire        wb_reg_write;     // register file write enable


    // HAZARD / FORWARD control wires
  
    wire        stall;            // hazard_unit → IF stage + ID stage
    wire        flush;            // hazard_unit → IF stage + ID stage
    wire [1:0]  fwd_a;            // forward_unit → EX stage mux A
    wire [1:0]  fwd_b;            // forward_unit → EX stage mux B

    // INSTRUCTION MEMORY
 
    // Combinational read: inst = mem[pc >> 2]
    // Populated from "program.hex" at simulation start.
  
    inst_mem u_inst_mem (
        .addr (pc_out),
        .inst (if_id_inst)   // NOTE: wired directly into IF/ID latch input
    );

    // IF STAGE — Program Counter + IF/ID pipeline register

    if_stage u_if (
        .clk          (clk),
        .rst          (rst),
        .stall        (stall),
        .flush        (flush),
        .branch_taken (branch_taken),
        .jump         (jump_out),
        .pc_target    (pc_target),
        .pc_out       (pc_out),
        .if_id_pc     (if_id_pc),
        .if_id_inst   (if_id_inst)
    );

    
    // ID STAGE — Decode + Register File + Imm Gen + Control + ID/EX register
    
    id_stage u_id (
        .clk            (clk),
        .rst            (rst),
        // From IF/ID
        .if_id_inst     (if_id_inst),
        .if_id_pc       (if_id_pc),
        // Writeback port (from WB stage)
        .wb_reg_write   (wb_reg_write),
        .wb_rd          (wb_rd),
        .wb_data        (wb_data),
        // Hazard control
        .flush          (flush),
        .stall          (stall),
        // ID/EX outputs — data
        .id_ex_pc       (id_ex_pc),
        .id_ex_rs1_data (id_ex_rs1_data),
        .id_ex_rs2_data (id_ex_rs2_data),
        .id_ex_imm      (id_ex_imm),
        .id_ex_rs1      (id_ex_rs1),
        .id_ex_rs2      (id_ex_rs2),
        .id_ex_rd       (id_ex_rd),
        .id_ex_funct3   (id_ex_funct3),
        .id_ex_funct7_5 (id_ex_funct7_5),
        // ID/EX outputs — control
        .id_ex_reg_write  (id_ex_reg_write),
        .id_ex_alu_src    (id_ex_alu_src),
        .id_ex_mem_write  (id_ex_mem_write),
        .id_ex_mem_read   (id_ex_mem_read),
        .id_ex_mem_to_reg (id_ex_mem_to_reg),
        .id_ex_branch     (id_ex_branch),
        .id_ex_jump       (id_ex_jump),
        .id_ex_alu_op     (id_ex_alu_op)
    );

   
    // EX STAGE — Forwarding Muxes + ALU + Branch Resolution + EX/MEM register
 
    ex_stage u_ex (
        .clk                (clk),
        .rst                (rst),
        // From ID/EX — data
        .id_ex_pc           (id_ex_pc),
        .id_ex_rs1_data     (id_ex_rs1_data),
        .id_ex_rs2_data     (id_ex_rs2_data),
        .id_ex_imm          (id_ex_imm),
        .id_ex_rs1          (id_ex_rs1),
        .id_ex_rs2          (id_ex_rs2),
        .id_ex_rd           (id_ex_rd),
        .id_ex_funct3       (id_ex_funct3),
        .id_ex_funct7_5     (id_ex_funct7_5),
        // From ID/EX — control
        .id_ex_reg_write    (id_ex_reg_write),
        .id_ex_alu_src      (id_ex_alu_src),
        .id_ex_mem_write    (id_ex_mem_write),
        .id_ex_mem_read     (id_ex_mem_read),
        .id_ex_mem_to_reg   (id_ex_mem_to_reg),
        .id_ex_branch       (id_ex_branch),
        .id_ex_jump         (id_ex_jump),
        .id_ex_alu_op       (id_ex_alu_op),
        // Forwarding inputs
        .fwd_a              (fwd_a),
        .fwd_b              (fwd_b),
        .ex_mem_alu_result  (ex_mem_alu_out),
        .wb_data            (wb_data),
        // Branch/jump resolution → IF stage
        .branch_taken       (branch_taken),
        .jump_out           (jump_out),
        .pc_target          (pc_target),
        // EX/MEM outputs — data
        .ex_mem_alu_out     (ex_mem_alu_out),
        .ex_mem_rs2_data    (ex_mem_rs2_data),
        .ex_mem_rd          (ex_mem_rd),
        .ex_mem_funct3      (ex_mem_funct3),
        // EX/MEM outputs — control
        .ex_mem_reg_write   (ex_mem_reg_write),
        .ex_mem_mem_write   (ex_mem_mem_write),
        .ex_mem_mem_read    (ex_mem_mem_read),
        .ex_mem_mem_to_reg  (ex_mem_mem_to_reg),
        .ex_mem_pc_plus4    (ex_mem_pc_plus4)
    );

   
    // MEM STAGE — Data Memory Access + MEM/WB register
  
    mem_stage u_mem (
        .clk                (clk),
        .rst                (rst),
        // From EX/MEM — data
        .ex_mem_alu_out     (ex_mem_alu_out),
        .ex_mem_rs2_data    (ex_mem_rs2_data),
        .ex_mem_rd          (ex_mem_rd),
        .ex_mem_funct3      (ex_mem_funct3),
        // From EX/MEM — control
        .ex_mem_reg_write   (ex_mem_reg_write),
        .ex_mem_mem_write   (ex_mem_mem_write),
        .ex_mem_mem_read    (ex_mem_mem_read),
        .ex_mem_mem_to_reg  (ex_mem_mem_to_reg),
        // Data memory interface
        .mem_addr           (mem_addr),
        .mem_write_data     (mem_write_data),
        .mem_write_en       (mem_write_en),
        .mem_read_en        (mem_read_en),
        .mem_read_data      (mem_read_data),
        // MEM/WB outputs
        .mem_wb_alu_result  (mem_wb_alu_result),
        .mem_wb_mem_data    (mem_wb_mem_data),
        .mem_wb_rd          (mem_wb_rd),
        .mem_wb_reg_write   (mem_wb_reg_write),
        .mem_wb_mem_to_reg  (mem_wb_mem_to_reg)
    );

  
    // DATA MEMORY — byte-addressable 1 KB RAM

    data_mem u_data_mem (
        .clk        (clk),
        .mem_write  (mem_write_en),
        .mem_read   (mem_read_en),
        .funct3     (ex_mem_funct3),
        .addr       (mem_addr),
        .write_data (mem_write_data),
        .read_data  (mem_read_data)
    );

  
    // WB STAGE — Writeback Mux (combinational only)
   
    wb_stage u_wb (
        .mem_wb_alu_result  (mem_wb_alu_result),
        .mem_wb_mem_data    (mem_wb_mem_data),
        .mem_wb_rd          (mem_wb_rd),
        .mem_wb_reg_write   (mem_wb_reg_write),
        .mem_wb_mem_to_reg  (mem_wb_mem_to_reg),
        .wb_data            (wb_data),
        .wb_rd              (wb_rd),
        .wb_reg_write       (wb_reg_write)
    );

 
    // HAZARD DETECTION UNIT

    hazard_unit u_hazard (
        // Load-use detection: watch EX stage destination vs ID stage sources
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (if_id_inst[19:15]),   // rs1 field of instruction in ID
        .if_id_rs2      (if_id_inst[24:20]),   // rs2 field of instruction in ID
        // Branch/jump flush
        .branch_taken   (branch_taken),
        .jump           (jump_out),
        // Outputs
        .stall          (stall),
        .flush          (flush)
    );

   
    // FORWARDING UNIT
 
    forward_unit u_fwd (
        // Source registers of instruction in EX
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        // EX/MEM stage info
        .ex_mem_reg_write (ex_mem_reg_write),
        .ex_mem_rd        (ex_mem_rd),
        // MEM/WB stage info
        .mem_wb_reg_write (mem_wb_reg_write),
        .mem_wb_rd        (mem_wb_rd),
        // Forwarding select outputs → EX stage muxes
        .fwd_a            (fwd_a),
        .fwd_b            (fwd_b)
    );

endmodule