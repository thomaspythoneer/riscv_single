// t1c_riscv_cpu.v - Top-level wrapper

module t1c_riscv_cpu (
    input         clk,
    input         reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData,
    input  [31:0] Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData,
    output [31:0] DataAdr,
    output [31:0] ReadData,
    output [31:0] PC,
    output [31:0] Result
);

    // Internal wires
    wire [31:0] Instr;
    wire [31:0] DataAdr_rv32, WriteData_rv32;
    wire        MemWrite_rv32;
    wire [31:0] ReadData_rv32;
    wire [2:0]  Mem_Funct3_rv32;  // ✅ added funct3 wire from CPU core

    // --------------------------
    // Core RISC-V CPU instance
    // --------------------------
    riscv_cpu rvcpu (
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Instr(Instr),
        .MemWrite(MemWrite_rv32),
        .Mem_WrAddr(DataAdr_rv32),
        .Mem_WrData(WriteData_rv32),
        .Mem_Funct3(Mem_Funct3_rv32), // ✅ added connection
        .ReadData(ReadData_rv32),
        .Result(Result)
    );

    // --------------------------
    // Instruction memory
    // --------------------------
    instr_mem imem (
        .instr_addr(PC),
        .instr(Instr)
    );

    // --------------------------
    // Data memory
    // --------------------------
    data_mem dmem (
        .clk(clk),
        .wr_en(MemWrite_rv32),
        .wr_addr(DataAdr_rv32),
        .wr_data(WriteData_rv32),
        .funct3(Mem_Funct3_rv32),     // ✅ use funct3 from core
        .rd_data_mem(ReadData_rv32)
    );

    // --------------------------
    // External passthrough logic
    // --------------------------
    assign MemWrite  = (Ext_MemWrite && reset) ? 1'b1 : MemWrite_rv32;
    assign WriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;
    assign DataAdr   = (reset) ? Ext_DataAdr : DataAdr_rv32;
    assign ReadData  = ReadData_rv32;

endmodule
