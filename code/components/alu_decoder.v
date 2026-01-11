module alu_decoder (
    input            opb5,
    input  [2:0]     funct3,
    input            funct7b5,   // Instr[30]
    input  [1:0]     ALUOp,
    output reg [3:0] ALUControl, // now 4 bits
    output reg       ShiftArith  // NEW: tells ALU to do arithmetic shift for R-type SRA
);

always @(*) begin
    // default
    ShiftArith = 1'b0;
    case (ALUOp)
        2'b00: ALUControl = 4'b0000; // ADD (lw/sw)
        2'b01: ALUControl = 4'b0001; // SUB (branches)
        default: begin
            case (funct3)
                3'b000: begin
                    // R-type subtract when funct7b5 & opb5 (keep your existing check)
                    if (funct7b5 & opb5) ALUControl = 4'b0001; // SUB
                    else ALUControl = 4'b0000;                 // ADD
                end
                3'b001: ALUControl = 4'b0010; // SLL / SLLI
                3'b010: ALUControl = 4'b0011; // SLT / SLTI (signed)
                3'b011: ALUControl = 4'b0100; // SLTU / SLTIU (unsigned)
                3'b100: ALUControl = 4'b0101; // XOR / XORI
                3'b101: begin                 // SRL / SRA (reg) or SRLI / SRAI (imm)
                    ALUControl = 4'b0110;    // use unified shift code
                    // set shift_arith when funct7 bit indicates arithmetic (Instr[30])
                    ShiftArith = funct7b5;
                end
                3'b110: ALUControl = 4'b1000; // OR / ORI
                3'b111: ALUControl = 4'b1001; // AND / ANDI
                default: ALUControl = 4'b0000;
            endcase
        end
    endcase
end

endmodule
