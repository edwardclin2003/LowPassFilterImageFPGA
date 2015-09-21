//
// Copyright (C) 2015 Project
// based on code by Edward Lin
// License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
//
//start from first row and from far left to far right to detect image boundary

module isedgehorizontal(clk, 
                        rst, 
                        i_valid_data, 
                        i_col1,
                        i_colN,
                        i_rowM, 
                        o_edge0, 
                        o_center, 
                        o_edge1,
                        o_rowM);
parameter XB = 10;
input clk;
input rst;
input i_valid_data;
input i_col1;
input i_colN;
input i_rowM;
output o_edge0;
output o_center;
output o_edge1;
output o_rowM;

reg [1:0] r_pos_state = 0;
reg r_rowM = 0;
assign o_edge0 = i_valid_data & (i_col1 == 1); //left side
assign o_center = r_pos_state[0] & i_valid_data; //center
assign o_edge1 = r_pos_state[1];//right side
assign o_rowM = i_rowM & i_col1 | r_rowM;

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
        if (i_valid_data == 1 && i_col1 == 1)
        begin
          r_pos_state <= 1; //center
        end
      end
      2'd1:
      begin
        if (i_valid_data == 1 && i_colN == 1)
          r_pos_state <= 2; //last entry
      end
      2'd2:
      begin
        r_pos_state <= 0;
      end
    endcase
  end

  casex({o_edge0&i_rowM, o_edge1})
    2'b1x:
      r_rowM <= 1;
    2'b01:
      r_rowM <= 0;
  endcase

end
endmodule
