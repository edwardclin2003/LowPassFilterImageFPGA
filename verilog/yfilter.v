module yfilter(clk, rst, 
               i_new_pixelset,
               i_type, 
               i_col1,
               i_colN,
               o_valid_filt,
               o_filt_pixel,
               o_col1,
               o_colN,
               o_rowM
               );

parameter YB = 10;
parameter PB = 8;

input clk;
input rst;
input [3 * PB - 1:0] i_new_pixelset;

input [1:0] i_type;

input i_col1, i_colN;

output o_valid_filt;
output [(PB + 2) - 1:0] o_filt_pixel;
output o_col1;
output o_colN;
output o_rowM;

reg [PB - 1:0] r_new_pixelt = 0;
reg [PB - 1:0] r_new_pixelc = 0;
reg [PB - 1:0] r_new_pixelb = 0;

reg [1:0] r_vert_type = 0;
reg rr_valid_cpos = 0;
reg [PB - 1:0] rr_new_pixelb = 0;

reg r_valid_filt_pixel = 0;
reg [(PB + 2) - 1:0] r_filt_pixel = 0;
reg rr_valid_filt_pixel = 0;
reg [(PB + 2) - 1:0] rr_filt_pixel = 0;

reg r_col1 = 0, r_colN = 0;
reg rr_col1 = 0, rr_colN = 0;
reg rrr_col1 = 0, rrr_colN = 0;
reg rr_rowM = 0, rrr_rowM = 0;
assign o_valid_filt = rr_valid_filt_pixel;
assign o_filt_pixel = rr_filt_pixel;

assign o_col1 = rrr_col1;
assign o_colN = rrr_colN;
assign o_rowM = rrr_rowM;

always @(posedge clk)
begin
  //reads from BRAM in this cycle
  r_vert_type <= i_type;

  r_new_pixelt <= i_new_pixelset[PB - 1:0];
  r_new_pixelc <= i_new_pixelset[2 * PB - 1:PB];
  r_new_pixelb <= i_new_pixelset[3 * PB - 1:2 * PB];

  rr_valid_cpos <= r_vert_type[1] & ~r_vert_type[0];//2
  rr_new_pixelb <= r_new_pixelb;

  if (r_vert_type == 1)
    r_filt_pixel <= {r_new_pixelc, 1'd0} + r_new_pixelb;
  else
    r_filt_pixel <= r_new_pixelt + {r_new_pixelc, 1'd0};

  if (rr_valid_cpos)
    rr_filt_pixel <= r_filt_pixel + rr_new_pixelb;
  else
    rr_filt_pixel <= r_filt_pixel;

  if (rst)
  begin
    r_valid_filt_pixel <= 0;
    rr_valid_filt_pixel <= 0;
  end
  else
  begin
    r_valid_filt_pixel <= r_vert_type[0] | r_vert_type[1];
    rr_valid_filt_pixel <= r_valid_filt_pixel;
  end

  r_col1 <= i_col1;
  rr_col1 <= r_col1;
  rrr_col1 <= rr_col1;
  r_colN <= i_colN;
  rr_colN <= r_colN;
  rrr_colN <= rr_colN;

  rr_rowM <= r_vert_type[0] & r_vert_type[1];//bottom row is 3
  rrr_rowM <= rr_rowM;
end
endmodule
