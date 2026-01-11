// controller.v - control unit for single-cycle RISC-V

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Zero,
    input        Less,     // NEW: signed comparison flag from ALU
    input        LessU,    // NEW: unsigned comparison flag from ALU
    output [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc,
    output       ALUSrc,
    output       RegWrite,
    output       Jump,
    output [2:0] ImmSrc,
    output [3:0] ALUControl,
    output       ShiftArith,
    output       JALR,
    output       UsePC     // passes through main_decoder's UsePC
);

wire [1:0] ALUOp;
wire       Branch;
wire       branch_cond;

main_decoder md (
    .op(op),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .Branch(Branch),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .Jump(Jump),
    .ImmSrc(ImmSrc),
    .ALUOp(ALUOp),
    .UsePC(UsePC)
);

alu_decoder ad (
    .opb5(op[5]),
    .funct3(funct3),
    .funct7b5(funct7b5),
    .ALUOp(ALUOp),
    .ALUControl(ALUControl),
    .ShiftArith(ShiftArith)
);

// Branch condition decoding (funct3 encodings for branch)
assign branch_cond =
       ((funct3 == 3'b000) & Zero)            // BEQ
     | ((funct3 == 3'b001) & ~Zero)           // BNE
     | ((funct3 == 3'b100) & Less)            // BLT (signed)
     | ((funct3 == 3'b101) & ~Less)           // BGE (signed >=)
     | ((funct3 == 3'b110) & LessU)           // BLTU (unsigned)
     | ((funct3 == 3'b111) & ~LessU);         // BGEU (unsigned >=)

// PCSrc is asserted for Jump or branch taken
assign PCSrc = Jump | (Branch & branch_cond);

// JALR detection (main_decoder already handles JALR controls, but expose it explicitly)
assign JALR = (op == 7'b1100111);

endmodule
