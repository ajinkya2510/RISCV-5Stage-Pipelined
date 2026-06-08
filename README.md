# 5-Stage Pipelined RISC-V Processor (RV32I)

## Overview

This project implements a 32-bit RV32I 5-stage pipelined RISC-V processor in Verilog. The processor follows the classical pipeline organization consisting of Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB) stages.

The design supports arithmetic, logical, memory, branch, and jump instructions from the RV32I base integer instruction set. To ensure correct execution in a pipelined environment, the processor incorporates forwarding logic, hazard detection, pipeline stalling, branch flushing, and jump redirection mechanisms.

Unlike a single-cycle processor where an instruction completes within one clock cycle, this implementation allows multiple instructions to execute simultaneously in different pipeline stages, significantly improving instruction throughput.

### Supported Instruction Categories

**R-Type Instructions**

* ADD
* SUB
* SLL
* SLT
* SLTU
* XOR
* SRL
* SRA
* OR
* AND

**I-Type ALU Instructions**

* ADDI
* SLTI
* SLTIU
* XORI
* ORI
* ANDI
* SLLI
* SRLI
* SRAI

**Load Instructions**

* LB
* LH
* LW
* LBU
* LHU

**Store Instructions**

* SB
* SH
* SW

**Branch Instructions**

* BEQ
* BNE
* BLT
* BGE
* BLTU
* BGEU

**Jump Instructions**

* JAL
* JALR

**Upper Immediate Instructions**

* LUI
* AUIPC

---

# Processor Architecture

The processor is divided into five stages:

| Stage | Function                                    |
| ----- | ------------------------------------------- |
| IF    | Fetch instruction from instruction memory   |
| ID    | Decode instruction and read operands        |
| EX    | Execute ALU operations and resolve branches |
| MEM   | Access data memory                          |
| WB    | Write results back to register file         |

Pipeline registers implemented:

* IF/ID
* ID/EX
* EX/MEM
* MEM/WB

Key inter-stage signals include:

* `if_id_pc`
* `if_id_inst`
* `id_ex_pc`
* `id_ex_rs1_data`
* `id_ex_rs2_data`
* `id_ex_imm`
* `ex_mem_alu_out`
* `mem_wb_alu_result`
* `mem_wb_mem_data`

---

# Module Descriptions

## RISC_V.v — Top-Level Processor

`RISC_V.v` is the top-level module that integrates all processor stages, memories, forwarding logic, and hazard handling logic.

It instantiates:

* inst_mem
* if_stage
* id_stage
* ex_stage
* mem_stage
* data_mem
* wb_stage
* forward_unit
* hazard_unit

The module connects all pipeline registers and control paths between stages.

Key control signals:

| Signal       | Purpose                              |
| ------------ | ------------------------------------ |
| branch_taken | Indicates a successful branch        |
| jump_out     | Indicates JAL/JALR execution         |
| pc_target    | Branch/jump destination address      |
| stall        | Pipeline stall signal                |
| flush        | Pipeline flush signal                |
| fwd_a        | Forwarding control for ALU operand A |
| fwd_b        | Forwarding control for ALU operand B |

---

## if_stage.v — Instruction Fetch Stage

The IF stage maintains the Program Counter (PC) and fetches instructions from instruction memory.

Responsibilities:

* Maintain PC register
* Generate sequential PC (`PC + 4`)
* Redirect PC on branches and jumps
* Populate IF/ID pipeline register

Important signals:

* `pc`
* `pc_out`
* `if_id_pc`
* `if_id_inst`
* `pc_target`

Operation:

Normal execution:

PC ← PC + 4

Taken branch:

PC ← pc_target

JAL/JALR:

PC ← pc_target

The stage supports:

### Pipeline Stall

When:

```verilog
stall = 1
```

the PC and IF/ID register contents are frozen.

### Pipeline Flush

When:

```verilog
flush = 1
```

the fetched instruction is replaced by:

```verilog
32'h00000013
```

which corresponds to:

```assembly
ADDI x0, x0, 0
```

(the RV32I NOP instruction).

---

## id_stage.v — Instruction Decode Stage

The ID stage performs instruction decoding, register access, immediate generation, and control signal generation.

Instruction fields extracted:

* opcode
* rd
* rs1
* rs2
* funct3
* funct7[5]

### Register File Access

Instantiates:

```text
u_regfile
```

Provides:

* rs1_data
* rs2_data

Receives:

* wb_reg_write
* wb_rd
* wb_data

for write-back.

### Immediate Generation

Instantiates:

```text
u_imm_gen
```

Generates correctly formatted immediates for all RV32I instruction formats.

### Control Generation

Instantiates:

```text
u_control
```

Produces:

* ctrl_reg_write
* ctrl_alu_src
* ctrl_mem_write
* ctrl_mem_read
* ctrl_mem_to_reg
* ctrl_branch
* ctrl_jump
* ctrl_alu_op

### JALR Detection

The signal:

```verilog
id_ex_is_jalr
```

is generated separately and propagated to EX stage to simplify JALR target computation.

### ID/EX Pipeline Register

Stores:

* id_ex_pc
* id_ex_rs1_data
* id_ex_rs2_data
* id_ex_imm
* id_ex_rs1
* id_ex_rs2
* id_ex_rd
* id_ex_funct3
* id_ex_funct7_5

Control signals stored:

* id_ex_reg_write
* id_ex_alu_src
* id_ex_mem_write
* id_ex_mem_read
* id_ex_mem_to_reg
* id_ex_branch
* id_ex_jump
* id_ex_alu_op
* id_ex_is_jalr

### Bubble Insertion

When:

```verilog
flush = 1
```

or

```verilog
stall = 1
```

all control signals entering EX stage are cleared, effectively inserting a NOP into the pipeline.

---

## ex_stage.v — Execute Stage

The EX stage performs ALU execution, forwarding resolution, branch evaluation, jump target generation, and EX/MEM pipeline register generation.

### Data Forwarding

Forwarded operands:

* rs1_forwarded
* rs2_forwarded

Selected using:

* fwd_a
* fwd_b

Forwarding priority:

1. EX/MEM stage
2. MEM/WB stage
3. Register file

This eliminates most RAW hazards without stalling.

### ALU Operand Selection

Operand A:

* PC
* rs1_forwarded

Operand B:

* Immediate
* rs2_forwarded

Signal:

```verilog
use_pc
```

selects PC as operand A for:

* JAL
* AUIPC

while loads, stores, and JALR continue using rs1.

### ALU Control

Instantiates:

```text
u_alu_ctrl
```

which converts:

* id_ex_alu_op
* id_ex_funct3
* id_ex_funct7_5

into:

```verilog
alu_ctrl
```

used by the ALU.

### Branch Evaluation

Unlike simple implementations that rely solely on the ALU zero flag, this design explicitly evaluates branch conditions.

Supported branches:

* BEQ
* BNE
* BLT
* BGE
* BLTU
* BGEU

Output:

```verilog
branch_taken
```

is generated entirely within EX stage.

### Jump Handling

JAL target:

```verilog
pc_target = id_ex_pc + id_ex_imm
```

JALR target:

```verilog
pc_target =
(rs1_forwarded + id_ex_imm) & ~32'd1
```

Outputs:

* jump_out
* pc_target

are fed back to IF stage.

### PC+4 Generation

The EX stage computes:

```verilog
pc_plus4 = id_ex_pc + 4
```

which is later written back for JAL/JALR instructions.

### EX/MEM Pipeline Register

Stores:

* ex_mem_alu_out
* ex_mem_rs2_data
* ex_mem_rd
* ex_mem_funct3
* ex_mem_reg_write
* ex_mem_mem_write
* ex_mem_mem_read
* ex_mem_mem_to_reg
* ex_mem_jump
* ex_mem_pc_plus4

---

## mem_stage.v — Memory Access Stage

The MEM stage interfaces between EX stage and data memory.

Generated memory interface signals:

```verilog
mem_addr = ex_mem_alu_out
mem_write_data = ex_mem_rs2_data
mem_write_en = ex_mem_mem_write
mem_read_en = ex_mem_mem_read
```

The stage forwards memory responses and control signals into the MEM/WB pipeline register.

Stored signals:

* mem_wb_alu_result
* mem_wb_mem_data
* mem_wb_rd
* mem_wb_reg_write
* mem_wb_mem_to_reg
* mem_wb_jump
* mem_wb_pc_plus4

---

## wb_stage.v — Write Back Stage

The WB stage selects the final value written back to the register file.

Priority:

1. JAL/JALR → PC + 4
2. Load → Memory Data
3. Other Instructions → ALU Result

Implemented using:

```verilog
wb_data =
mem_wb_jump ? mem_wb_pc_plus4 :
mem_wb_mem_to_reg ? mem_wb_mem_data :
mem_wb_alu_result;
```

Outputs:

* wb_data
* wb_rd
* wb_reg_write

which are connected back to the register file in ID stage.

---

## regfile.v — Register File

32 × 32-bit register file.

Features:

* Two asynchronous read ports
* One synchronous write port
* x0 protection
* Write-back forwarding

Registers:

```verilog
reg [31:0] regs [0:31];
```

The design includes WB→ID forwarding:

```verilog
assign rs1_data =
(we && rd_addr == rs1_addr)
? rd_data
: regs[rs1_addr];
```

which eliminates one class of data hazards without stalling.

---

## alu.v — Arithmetic Logic Unit

32-bit combinational ALU.

Supported operations:

* ADD
* SUB
* SLL
* SLT
* SLTU
* XOR
* SRL
* SRA
* OR
* AND
* LUI

Outputs:

* result
* zero

The zero flag is generated as:

```verilog
zero = (result == 0)
```

---

## alu_control.v — ALU Control Unit

Decodes:

* alu_op
* funct3
* funct7[5]

into:

```verilog
alu_ctrl
```

Supported instruction classes:

* R-Type
* I-Type ALU
* Branches
* Loads
* Stores
* LUI
* AUIPC

---

## control.v — Main Control Unit

Primary instruction decoder.

Generates:

* reg_write
* alu_src
* mem_write
* mem_read
* mem_to_reg
* branch
* jump
* alu_op

Supports:

* R-Type
* I-Type
* Load
* Store
* Branch
* LUI
* AUIPC
* JAL
* JALR

---

## imm_gen.v — Immediate Generator

Generates correctly sign-extended 32-bit immediates.

Supports:

* I-Type
* S-Type
* B-Type
* U-Type
* J-Type

The module reconstructs scrambled branch and jump immediates according to the RV32I specification.

---

## inst_mem.v — Instruction Memory

Instruction memory containing:

```verilog
reg [31:0] mem [0:255];
```

Features:

* 256 instruction locations
* Word-addressed fetch
* NOP initialization

Address conversion:

```verilog
inst = mem[addr[9:2]]
```

---

## data_mem.v — Data Memory

Byte-addressable 1 KB memory.

Storage:

```verilog
reg [7:0] mem [0:1023];
```

Supported loads:

* LB
* LH
* LW
* LBU
* LHU

Supported stores:

* SB
* SH
* SW

Provides proper sign-extension and zero-extension behavior.

---

## forward_unit.v — Data Forwarding Unit

Generates:

* fwd_a
* fwd_b

Used by EX stage to resolve RAW hazards.

Forwarding sources:

| Code | Source        |
| ---- | ------------- |
| 00   | Register File |
| 01   | MEM/WB        |
| 10   | EX/MEM        |

Priority:

EX/MEM > MEM/WB

This eliminates most pipeline stalls caused by data dependencies.

---

## hazard_unit.v — Hazard Detection Unit

Detects load-use hazards and generates stall/flush signals.

Inputs:

* id_ex_mem_read
* id_ex_rd
* if_id_rs1
* if_id_rs2
* branch_taken

Outputs:

* stall
* flush

---

# Hazard Handling

## Register File Forwarding

The register file forwards WB results directly into the decode stage whenever the same register is simultaneously being written and read.

This eliminates WB → ID hazards.

---

## Data Forwarding

The processor implements operand forwarding from:

* EX/MEM stage
* MEM/WB stage

Forwarding is performed through:

* fwd_a
* fwd_b

and allows dependent ALU instructions to execute without stalls.

Example:

```assembly
ADD x5, x1, x2
SUB x6, x5, x3
```

executes without pipeline stalls.

---

## Load-Use Hazard Detection

Example:

```assembly
LW x5, 0(x1)
ADD x6, x5, x2
```

The load result is unavailable until MEM stage.

The hazard unit detects the dependency and:

* Freezes PC
* Freezes IF/ID register
* Inserts bubble into ID/EX

This introduces a single-cycle stall.

---

## Branch Hazards

Branches are resolved in EX stage.

Supported:

* BEQ
* BNE
* BLT
* BGE
* BLTU
* BGEU

When a branch is taken:

```verilog
branch_taken = 1
```

the IF stage receives:

```verilog
flush = 1
```

and inserts a NOP instruction to remove wrong-path instructions.

---

## Jump Handling

The processor supports:

* JAL
* JALR

EX stage computes:

* pc_target
* jump_out

The IF stage immediately redirects execution to the new target address.

For JALR:

```verilog
pc_target =
(rs1_forwarded + id_ex_imm) & ~1
```

ensuring RV32I-compliant alignment.

---

# Future Improvements

* Branch prediction
* Instruction cache
* Data cache
* CSR support
* RV32M extension
* External memory initialization files
* Performance counters

---
# Author

**Ajinkya Tembhurne**<br>
Electrical Engineering<br>
Indian Institute of Technology Goa
