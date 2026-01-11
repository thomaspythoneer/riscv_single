// alu.v - ALU (4-bit control) with less/lessu outputs
module alu #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] a, b,
    input  [3:0]       alu_ctrl,
    input              shift_arith,
    output reg [WIDTH-1:0] alu_out,
    output             zero,
    output             less,   // signed compare result (a < b)
    output             lessu   // unsigned compare result (a < b)
);

always @(*) begin
    case (alu_ctrl)
        4'b0000: alu_out = a + b;                         // ADD / ADDI / AUIPC
        4'b0001: alu_out = a - b;                         // SUB
        4'b0010: alu_out = a << b[4:0];                   // SLL / SLLI
        4'b0011: alu_out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT / SLTI
        4'b0100: alu_out = (a < b) ? 32'd1 : 32'd0;       // SLTU / SLTIU
        4'b0101: alu_out = a ^ b;                         // XOR / XORI
        4'b0110: begin
            // unified shift right (logical/arithmetic)
            if (shift_arith) alu_out = $signed(a) >>> b[4:0]; // SRA / SRAI
            else              alu_out = a >> b[4:0];         // SRL / SRLI
        end
        4'b1000: alu_out = a | b;                         // OR / ORI
        4'b1001: alu_out = a & b;                         // AND / ANDI
        default: alu_out = {WIDTH{1'b0}};
    endcase
end

assign zero = (alu_out == {WIDTH{1'b0}});
assign less  = ($signed(a) < $signed(b));
assign lessu = (a < b);

endmodule
