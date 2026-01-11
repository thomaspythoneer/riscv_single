// reg_file.v - register file for single-cycle RISC-V CPU
// with 32 registers (x0 hardwired to 0)

module reg_file #(parameter DATA_WIDTH = 32) (
    input                     clk,
    input                     wr_en,
    input       [4:0]         rd_addr1, rd_addr2, wr_addr,
    input       [DATA_WIDTH-1:0] wr_data,
    output      [DATA_WIDTH-1:0] rd_data1, rd_data2
);

reg [DATA_WIDTH-1:0] reg_file_arr [0:31];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1)
        reg_file_arr[i] = 0;
end

// Prevent writes to x0
always @(posedge clk) begin
    if (wr_en && (wr_addr != 0))
        reg_file_arr[wr_addr] <= wr_data;
end

// Safe reads
assign rd_data1 = (rd_addr1 != 0) ? reg_file_arr[rd_addr1] : 0;
assign rd_data2 = (rd_addr2 != 0) ? reg_file_arr[rd_addr2] : 0;

endmodule
