// data_mem.v - unified byte-addressable memory
// Supports SB, SH, SW, LB, LH, LW, LBU, LHU (funct3 determines behavior)

module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 64) (
    input                    clk,
    input                    wr_en,
    input      [ADDR_WIDTH-1:0] wr_addr,
    input      [DATA_WIDTH-1:0] wr_data,
    input      [2:0]         funct3,        // determines access size/type
    output reg [DATA_WIDTH-1:0] rd_data_mem
);

    // ===== Memory Array =====
    reg [7:0] mem [0:(MEM_SIZE*4)-1];  // byte-addressable (64 words = 256 bytes)
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE*4; i = i + 1)
            mem[i] = 8'b0;
    end

    // ===== READ LOGIC =====
    always @(*) begin
        case (funct3)
            // LB - signed byte
            3'b000: rd_data_mem = {{24{mem[wr_addr][7]}}, mem[wr_addr]};

            // LH - signed halfword
            3'b001: rd_data_mem = {{16{mem[wr_addr + 1][7]}},
                                   mem[wr_addr + 1], mem[wr_addr]};

            // LW - word
            3'b010: rd_data_mem = {mem[wr_addr + 3], mem[wr_addr + 2],
                                   mem[wr_addr + 1], mem[wr_addr]};

            // LBU - unsigned byte
            3'b100: rd_data_mem = {24'b0, mem[wr_addr]};

            // LHU - unsigned halfword
            3'b101: rd_data_mem = {16'b0, mem[wr_addr + 1], mem[wr_addr]};

            default: rd_data_mem = 32'bx;
        endcase
    end

    // ===== WRITE LOGIC =====
    always @(posedge clk) begin
        if (wr_en) begin
            case (funct3)
                // SB - store byte
                3'b000: mem[wr_addr] <= wr_data[7:0];

                // SH - store halfword
                3'b001: begin
                    mem[wr_addr]     <= wr_data[7:0];
                    mem[wr_addr + 1] <= wr_data[15:8];
                end

                // SW - store word
                3'b010: begin
                    mem[wr_addr]     <= wr_data[7:0];
                    mem[wr_addr + 1] <= wr_data[15:8];
                    mem[wr_addr + 2] <= wr_data[23:16];
                    mem[wr_addr + 3] <= wr_data[31:24];
                end
            endcase
        end
    end

endmodule
