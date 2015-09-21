
// This is the top-level of the filter module, which you must implement.

// Module Description:
// Simple 2D image low-pass filter module.
// Convolves input image with 3x3 kernel:
//  [ 1 2 1 ]
//  [ 2 4 2 ] * 1/16
//  [ 1 2 1 ]
// Input pixels that fall outside of the image are assumed to be 0.
// Output is rounded to nearest integer.

module hw_dut #(
    parameter XB        = 10,
    parameter YB        = 10,
    parameter PB        = 8
) (
    // system
    input   wire                clk,
    input   wire                rst,                // active-high synchronous reset

    // configuration
    // will be static for at least 8 cycles before rst is released
    input   wire    [XB-1:0]    cfg_width,          // width of image in pixels; 0 based ('d0 = 1 pixel wide)
    input   wire    [YB-1:0]    cfg_height,         // height of image in pixels; 0 based ('d0 = 1 pixel high)

    // unfiltered pixel input stream (row-major)
    // data is transferred on each clock edge where ready and valid are both asserted
    output  reg                 px_in_ready,
    input   wire                px_in_valid,
    input   wire    [PB-1:0]    px_in_data,         // unfiltered pixel data

    // filtered pixel output stream (row-major)
    // data is transferred on each clock edge where ready and valid are both asserted
    input   wire                px_out_ready,
    output  reg                 px_out_valid,
    output  reg                 px_out_last_y,      // asserts for all pixels in last row
    output  reg                 px_out_last_x,      // asserts for last pixel in each row
    output  reg     [PB-1:0]    px_out_data,        // filtered pixel data

    // status
    output  reg                 done                // asserts once last pixel has been accepted by output consumer
);

//registered width and height of image
reg [XB - 1:0] r_cfg_width=0;
reg [YB - 1:0] r_cfg_height=0;

reg [XB - 1:0] r_cur_row=0;
reg [YB - 1:0] r_cur_col=0;

reg [1:0] r_process_state=0;

wire c_valid_input_pixel = px_in_ready & px_in_valid;
wire c_lastrow;

always @(posedge clk)
begin
  if (rst == 1)
  begin
    r_cfg_width <= cfg_width;
    r_cfg_height <= cfg_height;
  end
end

wire c_col1 = (r_cur_col == 1);
wire c_maxrow = (r_cur_row == r_cfg_height);
wire c_maxcol = (r_cur_col == r_cfg_width);

//handles input pixel handshaking
//stall (px_out_ready = 0) when output cannot send more data out
always @(posedge clk)
begin
  if (rst == 1)
  begin
    r_process_state <= 0;
    px_in_ready <= 0;
  end
  else
  begin
    case(r_process_state)
      2'd0:
      begin
        px_in_ready <= 1;
        r_process_state <= 1;
      end
      2'd1:
      begin
        casex({(c_valid_input_pixel == 1 && c_maxrow == 1 && c_maxcol == 1), px_out_ready})
          2'b1x:
          begin //done fetching.  Wait for reset
            px_in_ready <= 0;
            r_process_state <= 3;    
          end
          2'b00:
          begin //wait 
            px_in_ready <= 0;
            r_process_state<=2;
          end
        endcase
      end
      2'd2:
        begin
          if (px_out_ready == 1)
          begin //continue
            px_in_ready <= 1;
            r_process_state<=1;
          end
        end
    endcase
  end

end


//count what index of the pixels have come through
always @(posedge clk)
begin
  case({c_valid_input_pixel && c_maxcol, c_maxrow})
  2'b11:
    begin
      r_cur_row <= 0;
    end
  2'b10:
    begin
      r_cur_row <= r_cur_row + 1;
    end
  endcase

  case({c_valid_input_pixel | c_lastrow, c_maxcol})
  2'b11:
    begin
      r_cur_col <= 0;
    end
  2'b10:
    begin
      r_cur_col <= r_cur_col + 1;
    end
  endcase
end

wire c_lrow_valid, c_crow_valid, c_rrow_valid;
wire [1:0] c_vert_type;
wire c_valid_filt_pixel;

wire [3 * PB - 1:0] c_col_rd_data;

wire c_valid_xfilt;
wire [PB - 1:0] c_xfilt_pixel;
wire c_islastcol;
wire c_valid_yfilt;
wire [(PB + 2) - 1:0] c_yfilt_pixel;

bufferin #(XB, PB) PIXROWBUF (.clk(clk),
                              .rst(rst),
                              .o_rd_data(c_col_rd_data),
                              .i_valid_wr(c_valid_input_pixel),
                              .i_wr_addr(r_cur_col),
                              .i_wr_data(px_in_data)
                             );

wire c_col1_passthru0, c_colN_passthru0;
wire c_col1_passthru1, c_colN_passthru1;
wire c_rowM_passthru0, c_rowM_passthru1, c_rowM_passthru2, c_rowM_passthru3;
wire c_lastcol;

isedgevertical #(YB) VERTEDGE (.clk(clk),
                               .rst(rst),
                               .i_valid_data(c_valid_input_pixel),
                               .i_maxrow(c_maxrow),
                               .i_maxcol(c_maxcol),
                               .i_col1(c_col1),
                               .i_stall(~px_out_ready),
                               .o_type(c_vert_type),
                               .o_col1(c_col1_passthru0),
                               .o_colN(c_colN_passthru0),
                               .o_lastrow(c_lastrow));

//process vertical filter using edge boundary information
yfilter #(YB, PB) VERTFILTER (.clk(clk),
                              .rst(rst),
                              .i_new_pixelset(c_col_rd_data),
                              .i_type(c_vert_type),
                              .i_col1(c_col1_passthru0),
                              .i_colN(c_colN_passthru0),
                              .o_valid_filt(c_valid_yfilt),
                              .o_filt_pixel(c_yfilt_pixel),
                              .o_col1(c_col1_passthru1),
                              .o_colN(c_colN_passthru1),
                              .o_rowM(c_rowM_passthru1)
                              );

isedgehorizontal #(XB) HORIZEDGE (.clk(clk),
                                  .rst(rst),
                                  .i_valid_data(c_valid_yfilt),
                                  .i_col1(c_col1_passthru1),
                                  .i_colN(c_colN_passthru1),
                                  .i_rowM(c_rowM_passthru1),
                                  .o_edge0(c_lrow_valid),
                                  .o_center(c_crow_valid),
                                  .o_edge1(c_rrow_valid),
                                  .o_rowM(c_rowM_passthru2));

//process horizontal filter using edge boundary information
xfilter #(XB, PB) HORIZFILTER (.clk(clk),
                               .rst(rst),
                               .i_valid_new_pixel(c_valid_yfilt),
                               .i_new_pixel(c_yfilt_pixel),
                               .i_valid_lpos(c_lrow_valid),
                               .i_valid_cpos(c_crow_valid),
                               .i_valid_rpos(c_rrow_valid),
                               .i_rowM(c_rowM_passthru2),
                               .o_valid_filt(c_valid_xfilt),
                               .o_filt_pixel(c_xfilt_pixel),
                               .o_colN(c_lastcol),
                               .o_rowM(c_rowM_passthru3)
                               );

//logic to pass data out
wire c_empty_pixfifo;
wire [PB - 1:0] c_px_out_data;
wire c_px_out_last_x, c_px_out_last_y;
wire c_pop_pixel = (~px_out_valid | (px_out_valid & px_out_ready)) & ~c_empty_pixfifo;

always @(posedge clk)
begin
  if (rst)
    px_out_valid <= 0;
  else
  begin
    px_out_valid <= ~c_empty_pixfifo | (px_out_valid & ~px_out_ready);
  end

  if (c_pop_pixel)
  begin
    px_out_data <= c_px_out_data;
    px_out_last_x <= c_px_out_last_x;
    px_out_last_y <= c_px_out_last_y;
  end
end

//fifo to manage when stalls occur
//16 entry deep
//maintains last column bit, last row bit, and pixel value

hw_fifo #(PB + 2, 4) PIXFIFO (.clk(clk),
     		            .rst(rst),
                            .wr_push(c_valid_xfilt),
                            .wr_data({c_lastcol, c_rowM_passthru3, c_xfilt_pixel}),
                            .wr_full(),
                            .wr_almost_full(),
                            .rd_pop(c_pop_pixel),
                            .rd_data({c_px_out_last_x, c_px_out_last_y, c_px_out_data}),
                            .rd_empty(c_empty_pixfifo),
                            .rd_almost_empty()
			   ); 

endmodule
