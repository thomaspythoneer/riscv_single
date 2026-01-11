
# RV32I Single-Cycle RISC-V CPU

This repository contains a 32‑bit single-cycle RISC‑V CPU implementing the RV32I base integer instruction set, written in Verilog and targeted for FPGA and simulator-based evaluation.

## Features

- Single-cycle RV32I core (RV32I base integer ISA, no M/A/F/C extensions).  
- Full support for R/I/S/B/U/J instruction formats, including loads, stores, branches, jumps, and upper immediates.  
- Modular hierarchy with separate controller, datapath, register file, ALU, instruction memory, and data memory.  
- Verilog RTL suitable for FPGA synthesis (Quartus) and simulation (ModelSim, etc.).

***

## Architecture Overview

The CPU is a **single‑cycle** implementation: every instruction (fetch, decode, execute, memory, writeback) completes in one clock cycle.

Top-level structural organization:

```text
t1c_riscv_cpu (Top-level wrapper)
├── riscv_cpu (Core CPU)
│   ├── controller (Control Unit)
│   │   ├── main_decoder
│   │   └── alu_decoder
│   └── datapath
│       ├── Program Counter (PC)
│       ├── Register File (32 registers)
│       ├── ALU
│       ├── Immediate Extender
│       └── Multiplexers
├── instr_mem (Instruction Memory)
└── data_mem (Data Memory)
```

Key properties:

- 32‑bit data path and 32‑bit program counter.  
- 1 CPI (one instruction retired per clock).  
- Separate instruction and data memories (Harvard-style), both modeled as simple Verilog memories.

***

## Supported Instruction Set

The core implements the full RV32I base integer instruction set excluding system/CSR instructions.

**R‑type (register‑register):**

- ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND  

**I‑type (immediate ALU):**

- ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI  

**Loads (I‑type):**

- LB, LH, LW, LBU, LHU  

**Stores (S‑type):**

- SB, SH, SW  

**Branches (B‑type):**

- BEQ, BNE, BLT, BGE, BLTU, BGEU  

**Upper immediates (U‑type):**

- LUI, AUIPC  

**Jumps:**

- JAL (J‑type), JALR (I‑type)  

These instructions are sufficient to compile and run standard RV32I C/assembly programs that do not rely on CSR/privileged instructions.

***

## Microarchitecture Details

### Datapath

The datapath follows the standard single‑cycle RISC‑V structure.

- Instruction Fetch:  
  - PC feeds `instr_mem`, which outputs a 32‑bit instruction (combinational read).  
- Register File:  
  - 32 general‑purpose registers (x0–x31), each 32 bits wide.  
  - x0 is hardwired to zero and ignores writes.  
  - Two combinational read ports (rs1, rs2), one synchronous write port (rd).  
- Immediate Generation:  
  - Immediate extender supports I, S, B, U, and J formats with proper sign/zero extension and left shifts.  
- ALU:  
  - 32‑bit ALU with operations selected by a 4‑bit `ALUControl`.  
  - Outputs: `alu_out`, `zero`, `less` (signed), `lessu` (unsigned).  
  - Shift operations use the lower 5 bits of operand B and support logical/arithmetic right shifts.  
- Result Mux:  
  - Selects one of: ALU result, memory read data, PC+4, or immediate, before writing back to rd.

### Control Unit

The control path is split into a **main decoder** and an **ALU decoder**, similar to common textbook RV32I single‑cycle designs.

- Main Decoder:
  - Inputs: opcode (`instr[6:0]`).  
  - Outputs: `RegWrite`, `ImmSrc[2:0]`, `ALUSrc`, `MemWrite`, `ResultSrc[1:0]`, `Branch`, `ALUOp[1:0]`, `Jump`, `UsePC`.  
- ALU Decoder:
  - Inputs: `funct3`, `funct7`, `ALUOp`.  
  - Outputs: `ALUControl[3:0]`, `ShiftArith`.  
- Branch Logic:
  - Uses `zero`, `less`, and `lessu` to evaluate branch conditions for all six branch types.

### Program Counter (PC)

- 32‑bit register with synchronous reset to `0x00000000`.  
- Next PC selection:
  1. For JALR: `PC_next = (rs1 + imm) & ~1`.  
  2. For taken branch or JAL: `PC_next = PC + ImmExt`.  
  3. Otherwise: `PC_next = PC + 4`.

***

## Memory System

Two simple on-chip memories are modeled to ease simulation and FPGA integration.

### Instruction Memory

- 512 words (2048 bytes) of 32‑bit instructions.  
- Word-aligned addressing using `PC[31:2]`.  
- Combinational read.  
- Initialized from `rv32i_test.hex` (or another hex file) using `$readmemh`.

### Data Memory

- 64 words (256 bytes), organized as a byte‑addressable array.  
- 32‑bit data bus for load/store operations.  
- Supports:
  - Loads: LB, LH, LW, LBU, LHU with correct sign/zero extension.  
  - Stores: SB, SH, SW with byte‑enable style behavior.  
- Reads are combinational; writes are synchronous on clock edge.

***

## Top-Level Interface

The top-level module `t1c_riscv_cpu` exposes a compact set of I/O ports for simulation and FPGA integration.

**Clock and Reset**

- `input clk` – system clock.  
- `input reset` – synchronous reset for PC and internal state.

**External Memory Passthrough (optional)**

- `input Ext_MemWrite`  
- `input [31:0] Ext_WriteData`  
- `input [31:0] Ext_DataAdr`  

These signals can be used during reset or debug to pre-load data memory or inspect behavior without modifying the core RTL.

**CPU Visibility / Probes**

- `output [31:0] PC` – current program counter.  
- `output [31:0] Result` – writeback result to the register file.  
- `output MemWrite` – data memory write enable.  
- `output [31:0] WriteData` – data written to memory.  
- `output [31:0] DataAdr` – data memory address.  
- `output [31:0] ReadData` – data memory read value.

These outputs are primarily for testbench observation and waveform debugging.

***

## Test Program and Verification

A test program `rv32i_test.s` plus its hex image `rv32i_test.hex` is included to validate functional correctness of the entire instruction set.

The test program covers:

- All I‑type ALU instructions.  
- All R‑type ALU operations.  
- U‑type (LUI, AUIPC).  
- Load/store sequences (LB/LH/LW/LBU/LHU, SB/SH/SW).  
- All branch instructions (BEQ/BNE/BLT/BGE/BLTU/BGEU).  
- Control flow using JAL and JALR.

The standard flow is:

1. Assemble the program:
   - Use an RV32I toolchain to assemble `rv32i_test.s` into an ELF.
   - Convert the ELF into a Verilog‑compatible hex (`rv32i_test.hex`) using `objcopy` or a custom script.  
2. Simulate:
   - Launch your Verilog simulator (ModelSim, Icarus, etc.
   - Compile the RTL and the provided top‑level testbench.  
   - Run simulation and inspect:
     - `PC`, `Instr`, `Result` signals.  
     - Data memory contents for expected results.  
3. (Optional) Synthesize to FPGA:
   - Add the RTL files into a Quartus (or other FPGA) project.  
   - Set `t1c_riscv_cpu` as the top module.  
   - Provide board clock/reset and connect any LEDs or UARTs as needed.

***

## File Organization

A typical directory layout for this project is:

```text
.
├── rtl/
│   ├── riscv_cpu.v
│   ├── controller.v
│   ├── main_decoder.v
│   ├── alu_decoder.v
│   ├── datapath.v
│   ├── alu.v
│   ├── regfile.v
│   ├── imm_ext.v
│   ├── instr_mem.v
│   ├── data_mem.v
│   └── t1c_riscv_cpu.v
├── sim/
│   ├── tb_riscv_cpu.v
│   └── rv32i_test.hex
├── sw/
│   ├── rv32i_test.s
│   └── Makefile
├── fpga/
│   └── quartus_project_files...
└── README.md
```

You can adapt these names to your actual repository; keeping a clean separation between **RTL**, **simulation**, and **software** files is recommended.

***

## How to Run (Quick Start)

1. Clone the repo and move into it.  
2. Assemble the test program:
   - `cd sw`  
   - `make` (or run the provided build script) to generate `rv32i_test.hex`.  
3. Run simulation:
   - `cd sim`  
   - Compile and run `tb_riscv_cpu.v` with your Verilog simulator.  
   - Open the waveform and monitor PC, instruction, and memory signals.  
4. Check pass criteria:
   - Final data memory/register file contents should match the expected results documented in the testbench comments.

***

## Future Work

- Add support for RV32M extension (MUL/DIV) and basic CSR instructions.
- Explore multi-cycle or pipelined versions of the core for improved frequency.  
- Integrate simple I/O peripherals (timer, UART, GPIO) for bare‑metal software demos.

***
