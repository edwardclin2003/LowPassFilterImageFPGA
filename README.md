# RTL_convolution
This is an RTL block IP that does a 2D low pass separable filter for an image of 2^n x 2^n size where n > 1.  This code is optimized for FPGAs and has been verified with Xilinx ISE.  For the writeup of this code, check out the writeup folder

To run the verilog code, go into verilog/

To compile in ModelSim make sure you first have a working directory.  To create type:

vlib work

Next compilation, type:

vlog *.v

Run simulation testbench, type:

vsim hw_tbv

In Modelsim, just type:

run -all
