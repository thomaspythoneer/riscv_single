// datapath.v - RISC-V single-cycle datapath (final fixed version)
// Supports: ALU ops, branches, jumps, loads/stores, LUI, AUIPC
// Compatible with controller, riscv_cpu.v, and t1c_riscv_cpu.v

module datapath (
    input         clk, reset,
    input  [1:0]  ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input  [2:0]  ImmSrc,
    input  [3:0]  ALUControl,
    input         ShiftArith,
    input         JALR,
    input         UsePC,             // for AUIPC
    output        Zero,
    output        Less,              // signed comparison flag
    output        LessU,             // unsigned comparison flag
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr,
    output [31:0] Mem_WrData,
    output [2:0]  Mem_Funct3,        // funct3 for store/load width
    input  [31:0] ReadData,
    output [31:0] Result
);

    // ===== Internal wires =====
    reg  [31:0] PCNext;          // must be reg, assigned in always @(*)
    wire [31:0] PCPlus4, PCTarget;
    wire [31:0] ImmExt;
    wire [31:0] SrcA, SrcB;
    wire [31:0] RegData2;
    wire [31:0] ALUResult;

    // ===== Program Counter logic =====
    reset_ff #(32) pcreg (
        .clk(clk),
        .reset(reset),
        .d(PCNext),
        .q(PC)
    );

    adder pcadd4      (PC, 32'd4, PCPlus4);
    adder pcaddbranch (PC, ImmExt, PCTarget); // for branches/jumps

    // ===== Register File =====
    reg_file rf (
        .clk(clk),
        .wr_en(RegWrite),
        .rd_addr1(Instr[19:15]),
        .rd_addr2(Instr[24:20]),
        .wr_addr(Instr[11:7]),
        .wr_data(Result),
        .rd_data1(SrcA),
        .rd_data2(RegData2)
    );

    // ===== Immediate Generator =====
    imm_extend ext (
        .instr(Instr),
        .immsrc(ImmSrc),
        .immext(ImmExt)
    );

    // ===== ALU Input MUX =====
    wire [31:0] ALUA = (UsePC) ? PC : SrcA; // AUIPC uses PC as input A

    mux2 #(32) srcbmux (
        .d0(RegData2),
        .d1(ImmExt),
        .sel(ALUSrc),
        .y(SrcB)
    );

    // ===== ALU =====
    wire alu_zero, alu_less, alu_lessu;

    alu alu_unit (
        .a(ALUA),
        .b(SrcB),
        .alu_ctrl(ALUControl),
        .shift_arith(ShiftArith),
        .alu_out(ALUResult),
        .zero(alu_zero),
        .less(alu_less),
        .lessu(alu_lessu)
    );

    assign Zero  = alu_zero;
    assign Less  = alu_less;
    assign LessU = alu_lessu;

    // ===== Result Selection =====
    reg [31:0] result_sel;
    always @(*) begin
        case (ResultSrc)
            2'b00: result_sel = ALUResult;  // ALU result
            2'b01: result_sel = ReadData;   // Load result
            2'b10: result_sel = PCPlus4;    // JAL/JALR (rd = PC + 4)
            2'b11: result_sel = ImmExt;     // LUI (imm << 12)
            default: result_sel = 32'bx;
        endcase
    end

    assign Result = result_sel;

    // ===== Memory Connections =====
    assign Mem_WrAddr = ALUResult;
    assign Mem_WrData = RegData2;
    assign Mem_Funct3 = Instr[14:12];  // SB/SH/SW width info

    // ===== PC Next Logic =====
    //
    // Priority:
    //   1. JALR  -> target = (rs1 + imm) & ~1
    //   2. Branch or JAL -> PCTarget (PC + ImmExt)
    //   3. Otherwise -> PC + 4
    //
    wire [31:0] JALRTarget = (SrcA + ImmExt) & ~32'b1;

    always @(*) begin
        PCNext = PCPlus4;  // default sequential PC
        if (JALR)
            PCNext = JALRTarget;
        else if (PCSrc)
            PCNext = PCTarget;
    end

endmodule
