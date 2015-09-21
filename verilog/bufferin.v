//
// Copyright (C) 2015 Project
// based on code by Edward Lin
// License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
//
//buffers pixels as they come in from stream
//doesn't begin processing till after one row is buffered
//reads a pixel from each of the two previous rows
//reduces BRAM size since less than 19 bits wide

module bufferin (clk,
                 rst,
                 o_rd_data,
                 i_valid_wr,
                 i_wr_addr,
                 i_wr_data
                );

parameter XB = 10;
parameter PB = 8;

input clk;
input rst;

output [3 * PB - 1:0] o_rd_data;

input i_valid_wr;
input [XB - 1:0] i_wr_addr;
input [PB - 1:0] i_wr_data;


reg r_valid_wr = 0;
reg [XB - 1:0] r_wr_addr = 0;
reg [PB - 1:0] r_wr_data = 0;

wire [2 * PB - 1:0] c_pixel_data;

assign o_rd_data = {r_wr_data, c_pixel_data};

wire [2 * PB - 1:0] c_wr_data = {r_wr_data, c_pixel_data[2 * PB - 1:PB]}; //new pixel from row and previous row pixel

always @(posedge clk)
begin
  if (rst)
    r_valid_wr <= 0;
  else
    r_valid_wr <= i_valid_wr;

  r_wr_addr <= i_wr_addr;
  r_wr_data <= i_wr_data;
end

//each entry contains row X and row X + 1 entry
dualportBRAM #(XB, 2 * PB) BRAMBUF (.clka(clk),
                                        .ssra(rst),
                                        .ena(1'd1),
                                        .wea(r_valid_wr),
                                        .addra(r_wr_addr),
                                        .dia(c_wr_data),
                                        .doa(),
                                        .dacka(),
                                        .clkb(clk),
                                        .ssrb(rst),
                                        .enb(1'd1),
                                        .web(1'd0),
                                        .addrb(i_wr_addr),
                                        .dib(),
                                        .dob(c_pixel_data),
                                        .dackb());
endmodule
