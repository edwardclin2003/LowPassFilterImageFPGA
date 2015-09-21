//
// Copyright (C) 2015 Project
// based on code by Edward Lin
// License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
//
//Determines which vertical edges exist for a given pixel.
//Start from top left corner all the way down to the bottom right corner
//Also sends out BRAM address to read out the pixels needed to process the vertical filter

module isedgevertical(clk, 
                      rst, 
                      i_valid_data,
                      i_maxrow,
                      i_maxcol,
                      i_col1,
                      i_stall,
                      o_type,
                      o_col1,
                      o_colN,
                      o_lastrow
                      );
parameter XB = 10;
parameter YB = 10;

input clk;
input rst;
//valid data for vertical filtering
input i_valid_data;
input i_maxrow;
input i_maxcol;
input i_col1;
//image size
//stall signal
input i_stall;
//output edge information
output [1:0] o_type;
output o_col1;
output o_colN;
output o_lastrow;

reg r_col1 = 0, r_maxcol = 0;
reg [1:0] r_type = 0;

//state machine to determine which pixels should be taken into account
reg [1:0] r_pos_state = 0;

assign o_type = r_type;
assign o_col1 = r_col1;
assign o_colN = r_maxcol;

assign o_lastrow = (r_pos_state == 3) & (i_stall == 0);

always @(posedge clk)
begin
  if (rst == 1)
  begin
    r_pos_state <= 0;
  end
  else
  begin
    case(r_pos_state)
      2'd0:
      begin 
        if ((i_valid_data == 1) && (i_maxcol == 1))
          r_pos_state <= 1; //begin processing after first row is inserted
      end
      2'd1://top edge
      begin
        if ((i_valid_data == 1) && (i_maxcol == 1))
          r_pos_state <= 2; //center
      end
      2'd2: //center
      begin
        if ((i_valid_data == 1) && (i_maxcol == 1) && (i_maxrow == 1))
          r_pos_state <= 3; //bottom edge
      end
      2'd3:
      begin
        if ((i_maxcol == 1) & ~i_stall)
          r_pos_state <= 0; //done
      end
    endcase
  end

  casex({i_valid_data, r_pos_state, o_lastrow})
    4'b101x:
      r_type <= 1; //top edge
    4'b110x:
      r_type <= 2; //center
    4'b0xx1:
      r_type <= 3; //bottom
    default:
      r_type <= 0;
  endcase

  r_col1 <= i_col1;
  r_maxcol <= i_maxcol; 
end
endmodule
