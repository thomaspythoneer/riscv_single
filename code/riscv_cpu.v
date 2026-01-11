// riscv_cpu.v - Core RISC-V single-cycle CPU
// Perfectly aligned with t1c_riscv_cpu.v port naming

module riscv_cpu (
    input         clk,
    input         reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr,    // exact name to match top-level
    output [31:0] Mem_WrData,    // exact name to match top-level
    output [2:0]  Mem_Funct3,    // NEW: store/load size (funct3)
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [1:0] ResultSrc;
wire [2:0] ImmSrc;
wire [3:0] ALUControl;
wire       ALUSrc, RegWrite, Zero, PCSrc, ShiftArith, JALR;
wire       Less, LessU, Jump, UsePC;

// ---------------- Controller ----------------
controller c (
    .op(Instr[6:0]),
    .funct3(Instr[14:12]),
    .funct7b5(Instr[30]),
    .Zero(Zero),
    .Less(Less),
    .LessU(LessU),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .Jump(Jump),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .ShiftArith(ShiftArith),
    .JALR(JALR),
    .UsePC(UsePC)
);

// ---------------- Datapath ----------------
datapath dp (
    .clk(clk),
    .reset(reset),
    .ResultSrc(ResultSrc),
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .ShiftArith(ShiftArith),
    .UsePC(UsePC),
    .JALR(JALR),
    .Zero(Zero),
    .Less(Less),
    .LessU(LessU),
    .PC(PC),
    .Instr(Instr),
    .Mem_WrAddr(Mem_WrAddr),
    .Mem_WrData(Mem_WrData),
    .Mem_Funct3(Mem_Funct3),   // ✅ NEW connection
    .ReadData(ReadData),
    .Result(Result)
);

endmodule
