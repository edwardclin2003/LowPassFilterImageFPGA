
// This is a FIFO module that you may use in your design.

// Module Description:
// Synchronous FIFO using distributed RAM.
// Depth is a power-of-2 (2**ADDR).
// Due to distributed RAM usage, depth should generally be <= 32 words (on 6-input LUT devices).
//
// Read port uses First Word Fall Through:
//   When not empty, rd_data is the value at the front of the FIFO
//   The reader must consume rd_data on the same cycle that it asserts rd_pop

module hw_fifo #(
    parameter DATA          = 8,    // width of data in FIFO
    parameter ADDR          = 4,    // depth of FIFO is 2**ADDR
    parameter ALMOST_FULL   = 0,    // assert almost_full when <= ALMOST_FULL free spaces remain (0 makes it equivalent to full)
    parameter ALMOST_EMPTY  = 0     // assert almost_empty when <= ALMOST_EMPTY valid entries remain (0 makes it equivalent to empty)
) (
    // system
    input   wire                clk,
    input   wire                rst,

    // input
    input   wire                wr_push,
    input   wire    [DATA-1:0]  wr_data,
    output  wire                wr_full,
    output  reg                 wr_almost_full,

    // output
    input   wire                rd_pop,
    output  wire    [DATA-1:0]  rd_data,
    output  reg                 rd_empty,
    output  reg                 rd_almost_empty
);

localparam DEPTH    = (2**ADDR);

// ** address generation **

reg [ADDR-1:0] wr_addr;
reg [ADDR-1:0] rd_addr;

always @(posedge clk) begin
    if(rst) begin
        wr_addr <= 0;
        rd_addr <= 0;
    end else begin
        if(wr_push) begin
            wr_addr <= wr_addr + 1;
        end
        if(rd_pop) begin
            rd_addr <= rd_addr + 1;
        end
    end
end

// ** storage memory **

reg [DATA-1:0] mem[DEPTH-1:0];

assign rd_data = mem[rd_addr]; // async read to achieve First Word Fall Through

always @(posedge clk) begin
    if(wr_push) begin
        mem[wr_addr] <= wr_data;
    end
end

// ** flags **

reg [ADDR:0] cnt; // 1 extra bit, since we want to store [0,DEPTH] (not just DEPTH-1)

assign wr_full = cnt[ADDR]; // full when (cnt == DEPTH)

/* verilator lint_off WIDTH */
always @(posedge clk) begin
    if(rst) begin
        // counts
        cnt             <= 0;
        // empty flags
        rd_empty        <= 1'b1;
        rd_almost_empty <= 1'b1;
        // full flags
        wr_almost_full  <= 1'b0;
    end else begin

        // pushed; count increments
        if(wr_push && !rd_pop) begin
            cnt             <= cnt + 1;
            rd_empty        <= 1'b0; // can't be empty on push
            if(cnt == (      ALMOST_EMPTY  )) rd_almost_empty <= 1'b0;
            if(cnt == (DEPTH-ALMOST_FULL -1)) wr_almost_full  <= 1'b1;
        end

        // popped; count decrements
        if(!wr_push && rd_pop) begin
            cnt             <= cnt - 1;
            rd_empty        <= (cnt == 1); // cnt will be 0 (empty)
            if(cnt == (      ALMOST_EMPTY+1)) rd_almost_empty <= 1'b1;
            if(cnt == (DEPTH-ALMOST_FULL   )) wr_almost_full  <= 1'b0;
        end

    end
end
/* verilator lint_on WIDTH */

endmodule

