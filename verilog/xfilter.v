//load pixel into circular buffer
//compute x filter
module xfilter(clk, rst, 
               i_valid_new_pixel,
               i_new_pixel,
               i_valid_lpos, 
               i_valid_cpos, 
               i_valid_rpos, 
               i_rowM,
               o_valid_filt,
               o_filt_pixel,
               o_colN,
               o_rowM
               );
parameter XB = 10;
parameter PB = 8;

input clk;
input rst;
input i_valid_new_pixel;
input [(PB + 2) - 1:0] i_new_pixel;
input i_valid_lpos;
input i_valid_cpos;
input i_valid_rpos;
input i_rowM;

output o_valid_filt;
output [PB - 1:0] o_filt_pixel;
output o_colN;
output o_rowM;

reg [(PB + 4) - 1:0] r_pixel_sum = 0;
reg [PB - 1:0] rr_pixel_sum = 0;

reg r_valid_lpos = 0;
reg r_valid_cpos = 0;
reg r_valid_rpos = 0;

reg r_valid_filt_pixel = 0;
reg rr_valid_cpos = 0;

reg r_valid_pixel_in = 0;
reg rr_valid_pixel_in = 0;

reg r_colN = 0, rr_colN = 0, rrr_colN = 0;
reg r_rowM = 0, rr_rowM = 0, rrr_rowM = 0;
wire [PB + 2 - 1:0] c_pixel0, c_pixel1, c_pixel2;
reg [PB + 2 - 1:0] r_pixel2 = 0;
wire c_valid_pixel_in = i_valid_lpos|i_valid_cpos|i_valid_rpos;

assign o_valid_filt = r_valid_filt_pixel;
assign o_filt_pixel = rr_pixel_sum;
assign o_colN = rrr_colN;
assign o_rowM = rrr_rowM;

always @(posedge clk)
begin
  //read in pixel
  r_valid_lpos <= i_valid_lpos;
  r_valid_cpos <= i_valid_cpos;
  r_valid_rpos <= i_valid_rpos;
  rr_valid_cpos <= r_valid_cpos;

  r_colN <= i_valid_rpos;
  rr_colN <= r_colN;
  rrr_colN <= rr_colN;

  r_rowM <= i_rowM;
  rr_rowM <= r_rowM;
  rrr_rowM <= rr_rowM;

  if (rst)
    begin
      r_valid_pixel_in <= 0;
      rr_valid_pixel_in <= 0;
      r_valid_filt_pixel <= 0;
    end
  else
    begin
      r_valid_pixel_in <= c_valid_pixel_in;
      rr_valid_pixel_in <= r_valid_pixel_in;
      r_valid_filt_pixel <= rr_valid_pixel_in;
    end

  r_pixel2 <= c_pixel2;
end

wire [PB + 4 - 1: 0] c_pixel_sum = (rr_valid_cpos) ? r_pixel_sum + r_pixel2 + 8: r_pixel_sum + 8;
reg r_valid_new_pixel = 0; //needed to check if new row's data was added

//add filter
always @(posedge clk)
begin
  r_valid_new_pixel <= i_valid_new_pixel;

  if (r_valid_rpos)
  begin
    if (r_valid_new_pixel) //new data added to queue
      r_pixel_sum <= {c_pixel1, 1'd0} + c_pixel2;
    else
      r_pixel_sum <= {c_pixel0, 1'd0} + c_pixel1;
  end
  else
  begin
    r_pixel_sum <= c_pixel0 + {c_pixel1, 1'd0};
  end

  rr_pixel_sum <= c_pixel_sum[PB + 4 -1: 4];
end

//3 pixel buffer
queue PIXBUF (.clk(clk), 
              .i_valid_pixel(i_valid_new_pixel),
              .i_pixel(i_new_pixel),
              .o_pixel0(c_pixel0),
              .o_pixel1(c_pixel1), 
              .o_pixel2(c_pixel2)
             );
endmodule

module queue(clk, i_valid_pixel, i_pixel, o_pixel0, o_pixel1, o_pixel2);
parameter PB = 8;

input clk;
input i_valid_pixel;
input [PB + 2 - 1:0] i_pixel;
output [PB + 2 - 1:0] o_pixel0;
output [PB + 2 - 1:0] o_pixel1;
output [PB + 2 - 1:0] o_pixel2;
 
reg [PB + 2 - 1:0] r_pixel0 = 0;
reg [PB + 2 - 1:0] r_pixel1 = 0;
reg [PB + 2 - 1:0] r_pixel2 = 0;

assign o_pixel0 = r_pixel0;
assign o_pixel1 = r_pixel1;
assign o_pixel2 = r_pixel2;
always @(posedge clk)
begin
  if (i_valid_pixel)
  begin
    r_pixel0 <= i_pixel;
    r_pixel1 <= r_pixel0;
    r_pixel2 <= r_pixel1;
  end

end
endmodule
