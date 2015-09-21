//Classic inferred dual port BRAM

module dualportBRAM (clka,
	             ssra,
	             ena,
	             wea,
	             addra,
	             dia,
	             doa,
	             dacka,
	             clkb,
	             ssrb,
	             enb,
	             web,
	             addrb,
	             dib,
	             dob,
	             dackb);
   parameter INDEXWIDTH=9;
   parameter WIDTH=8;
   
   input clka;
   input ssra;
   input ena;
   input wea;
   input [INDEXWIDTH - 1:0] addra;
   input [WIDTH - 1:0] 	  dia;
   output [WIDTH - 1:0] 	  doa;
   output 		  dacka;
   
   input 		  clkb;
   input 		  ssrb;
   input 		  enb;
   input 		  web;
   input [INDEXWIDTH - 1:0] addrb;
   input [WIDTH - 1:0] 	  dib;
   output [WIDTH - 1:0] 	  dob;
   output 		  dackb;  

   reg [WIDTH - 1:0] 	  ram [2**INDEXWIDTH - 1:0];
   reg 			  dacka=0;
   reg [WIDTH - 1:0] 	  doa=0;
   reg 			  dackb=0;   
   reg [WIDTH - 1:0] 	  dob=0;
  
   always @(posedge clka) begin
      if (ena)
	begin
	   if (wea)
	     ram[addra] <= dia;
	   if (ssra)
	     doa <= 0;
	   else
	     doa <= ram[addra];
	end
      if (ena&~ssra)
	dacka<=1;
      else
	dacka<=0;
       
   end // always @ (posedge clka or posedge ssra)
   
   always @(posedge clkb) begin
      if (enb)
	begin
	   if (web)
	     ram[addrb] <= dib;
	   if (ssrb)
	     dob <= 0;
	   else
	     dob <= ram[addrb];
	end
      if (enb&~ssrb)
	dackb<=1;
      else
	dackb<=0;
      
   end
endmodule // realSRAM2_2
