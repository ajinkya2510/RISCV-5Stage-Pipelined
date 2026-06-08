module hazard_unit (
    input wire id_ex_mem_read, // 1 if instruction in EX is a load
    input wire [4:0] id_ex_rd, // destination register of EX instruction
 
    input wire [4:0] if_id_rs1, // source reg 1 of instruction in ID
    input wire [4:0] if_id_rs2, // source reg 2 of instruction in ID

    input wire branch_taken, // branch condition was true
    input wire jump, // unconditional jump (JAL / JALR)

    output wire stall, // 1 → freeze PC + IF/ID register
    output wire flush // 1 → squash IF and ID stages (branch/jump)
);
    // Load-Use Hazard Detectio
    // Conditions (ALL must be true):
    //   (a) The instruction currently in EX is a load  (id_ex_mem_read == 1)
    //   (b) The load's destination register is not x0  (id_ex_rd != 0)
    //   (c) The load's rd matches rs1 OR rs2 of the instruction now in ID
    //
    // Condition (c) covers:
    //   - LW x1, …  followed immediately by  ADD x3, x1, x2  (rs1 match)
    //   - LW x1, …  followed immediately by  ADD x3, x2, x1  (rs2 match)
    //   - LW x1, …  followed immediately by  SW  x1, …       (rs2 match for store)
    wire load_use_hazard = id_ex_mem_read              // EX stage is a load
                        && (id_ex_rd != 5'b0)          // load writes to a real register
                        && ( (id_ex_rd == if_id_rs1)   // ID stage reads that register
                           ||(id_ex_rd == if_id_rs2) );

    assign stall = load_use_hazard;

    // Flush Signal — kill instructions fetched after a branch/jump
    // When a branch is taken or a jump executes we need to cancel:
    //   - The instruction currently in IF  (wrong-path fetch)
    //   - The instruction currently in ID  (wrong-path decode)
    //
    // Note: we do NOT flush on a stall cycle — the stall takes priority.
    assign flush = branch_taken && !stall;

endmodule