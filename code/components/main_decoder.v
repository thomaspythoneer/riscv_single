// main_decoder.v - logic for main decoder
// Controls mapping: {RegWrite, ImmSrc[2:0], ALUSrc, MemWrite, ResultSrc[1:0], Branch, ALUOp[1:0], Jump}
// total bits = 1 + 3 + 1 +1 +2 +1 +2 +1 = 12

module main_decoder (
    input  [6:0] op,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output       RegWrite, Jump,
    output [2:0] ImmSrc,
    output [1:0] ALUOp,
    output reg   UsePC        // NEW: when set, ALU A input should be PC (for AUIPC)
);

reg [11:0] controls;

always @(*) begin
    // default
    UsePC = 1'b0;
    case (op)
        // opcodes
        7'b0000011: controls = 12'b1_000_1_0_01_0_00_0; // lw: I-type imm -> Result = ReadData
        7'b0100011: controls = 12'b0_001_1_1_00_0_00_0; // sw: S-type imm, MemWrite
        7'b0110011: controls = 12'b1_000_0_0_00_0_10_0; // R-type: ALU (RegWrite), ALUOp = 10
        7'b1100011: controls = 12'b0_010_0_0_00_1_01_0; // branch: B-type, ALUOp = 01 (sub)
        7'b0010011: controls = 12'b1_000_1_0_00_0_10_0; // I-type ALU (addi, xori, etc.)
        7'b1101111: controls = 12'b1_011_0_0_10_0_00_1; // jal: J-type imm, write PC+4
        7'b0110111: controls = 12'b1_100_0_0_11_0_00_0; // lui: U-type imm, write imm<<12 directly (ResultSrc=11 -> ImmExt)
        7'b0010111: begin
            // AUIPC: write PC + imm  -> ALU should add PC + imm
            controls = 12'b1_100_1_0_00_0_00_0; // RegWrite=1, ImmSrc=100(U), ALUSrc=1 (imm to b), ResultSrc=00 (ALUResult)
            UsePC = 1'b1;
        end
        7'b1100111: controls = 12'b1_000_1_0_10_0_00_1; // jalr: I-type (rd=PC+4, PC=rs1+imm)
        default:    controls = 12'bx_xxx_x_x_xx_x_xx_x; // undefined
    endcase
end

assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump} = controls;

endmodule
