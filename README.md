# LowPassFilterImageFPGA
This is an RTL IP block that does a 2D low pass separable filter on an image of 2^m x 2^n size where m, n > 1.  Pixels are input in row major order, up to one per cycle, and the output filtered pixels are in the same row major order.  This code is optimized for FPGAs and has been verified with Xilinx ISE.  For the writeup of this code, check out the writeup folder

The top module is hw_dut.v.  Top test module is hw_tbv.v

To simulate the verilog code, go into verilog/

To compile in ModelSim make sure you first have a working directory.  To create type:

vlib work

Next compilation, type:

vlog *.v

Run simulation testbench, type:

vsim hw_tbv

In Modelsim, just type:

run -all
