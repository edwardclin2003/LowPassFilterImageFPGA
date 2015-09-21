
// This is the top-level testbench module.

// If you're using Icarus Verilog, you can start the simulation on command line like so:
//  iverilog ../rtl/hw_tbv.v ../rtl/hw_dut.v <extra verilog files here> && ./a.out

`timescale 1ns/1ps

module hw_tbv;

`include "hw_tbv_utils.vh"

parameter XB = 10;
parameter YB = 10;
parameter PB = 8;

localparam MIN_WIDTH    = 4;
localparam MIN_HEIGHT   = 4;
localparam MAX_WIDTH    = (2**XB);
localparam MAX_HEIGHT   = (2**YB);
localparam MAX_PX       = 25000;
localparam MAX_DATA     = (2**PB)-1;


// ** DUT **

reg             clk = 1'b0;
reg             rst = 1'b1;

reg  [XB-1:0]   cfg_width;
reg  [YB-1:0]   cfg_height;

wire            px_in_ready;
reg             px_in_valid;
reg  [PB-1:0]   px_in_data;

reg             px_out_ready;
wire            px_out_valid;
wire            px_out_last_y;
wire            px_out_last_x;
wire [PB-1:0]   px_out_data;

wire            dut_done;

hw_dut #(
    .XB             ( XB ),
    .YB             ( YB ),
    .PB             ( PB )
) dut (
    .clk            ( clk ),
    .rst            ( rst ),
    .cfg_width      ( cfg_width ),
    .cfg_height     ( cfg_height ),
    .px_in_ready    ( px_in_ready ),
    .px_in_valid    ( px_in_valid ),
    .px_in_data     ( px_in_data ),
    .px_out_ready   ( px_out_ready ),
    .px_out_valid   ( px_out_valid ),
    .px_out_last_y  ( px_out_last_y ),
    .px_out_last_x  ( px_out_last_x ),
    .px_out_data    ( px_out_data ),
    .done           ( dut_done )
);

// ** Input **

integer tbi_rate = 100;
integer tbi_x;
integer tbi_y;
reg tbi_done;
reg [PB-1:0] tbi_mem[MAX_HEIGHT*MAX_WIDTH-1:0];

always @(posedge clk) begin
    if(rst) begin
        tbi_x       <= 0;
        tbi_y       <= 0;
        tbi_done    <= 1'b0;
        px_in_valid <= 1'b0;
        px_in_data  <= {PB{1'bx}};
    end else begin
        if(px_in_ready) begin
            px_in_valid <= 1'b0;
            px_in_data  <= {PB{1'bx}};
        end
        if(!tbi_done && (`tbv_rand(0,99) < tbi_rate) && (!px_in_valid || px_in_ready)) begin
            px_in_valid <= 1'b1;
            px_in_data  <= tbi_mem[tbi_x+(tbi_y*MAX_WIDTH)];
            tbi_x       <= tbi_x + 1;
            if(tbi_x == cfg_width) begin
                tbi_x       <= 0;
                tbi_y       <= tbi_y + 1;
                if(tbi_y == cfg_height) begin
                    tbi_y       <= 0;
                    tbi_done    <= 1'b1;
                end
            end
        end
        if(tbi_done && px_in_ready && !px_in_valid) begin
            `tbv_warn("dut is attempting to read beyond end of image");
        end
    end
end

// ** Output **

integer tbo_rate = 100;
integer tbo_x;
integer tbo_y;
reg tbo_done;
reg [PB-1:0] tbo_mem[MAX_HEIGHT*MAX_WIDTH-1:0];

always @(posedge clk) begin
    if(rst) begin
        tbo_x       <= 0;
        tbo_y       <= 0;
        tbo_done    <= 1'b0;
        px_out_ready <= 1'b0;
    end else begin
        if(px_out_ready && px_out_valid) begin
            if(tbo_done) begin
                `tbv_error("unexpected output");
            end else begin
                if((px_out_last_x == (tbo_x == cfg_width )) &&
                   (px_out_last_y == (tbo_y == cfg_height)) &&
                   (px_out_data == (tbo_mem[tbo_x+(tbo_y*MAX_WIDTH)]))
                ) begin
                    `tbv_okay("output okay");
                end else begin
                    `tbv_error("mismatch at (%4d,%4d): (%d,%d,%d) != (%d,%d,%d)",
                        tbo_x,tbo_y,
                        (tbo_x == cfg_width), (tbo_y == cfg_height), tbo_mem[tbo_x+(tbo_y*MAX_WIDTH)],
                        px_out_last_x, px_out_last_y, px_out_data
                    );
                end
                tbo_x       <= tbo_x + 1;
                if(tbo_x == cfg_width) begin
                    tbo_x       <= 0;
                    tbo_y       <= tbo_y + 1;
                    if(tbo_y == cfg_height) begin
                        tbo_y       <= 0;
                        tbo_done    <= 1'b1;
                    end
                end
            end
        end
        px_out_ready <= (`tbv_rand(0,99) < tbo_rate);
    end
end

// ** Stimulus **

initial forever #5 clk = !clk;

function integer sample_tbi_mem;
    input integer y;
    input integer x;
    begin
        sample_tbi_mem = 0;
        if(y >= 0 && y <= cfg_height && x >= 0 && x <= cfg_width) begin
            sample_tbi_mem = tbi_mem[x+(y*MAX_WIDTH)];
        end
    end
endfunction

task run_test;
    integer width, height;
    integer x, y;
    integer sum;
    begin
        // assert reset
        @(posedge clk);
        rst <= 1'b1;
        @(posedge clk);

        // randomize resolution
        if(`tbv_rand(0,1)) begin
            // width first
            case(`tbv_rand(0,9))
                0: width = MIN_WIDTH;
                1: width = MAX_WIDTH;
                default: width = `tbv_rand(MIN_WIDTH,MAX_WIDTH);
            endcase
            height = MAX_PX/width;
            if(height < MIN_HEIGHT) height = MIN_HEIGHT;
            else if(height > MAX_HEIGHT) height = MAX_HEIGHT;
            height = `tbv_rand(MIN_HEIGHT,height);
        end else begin
            // height first
            case(`tbv_rand(0,9))
                0: height = MIN_HEIGHT;
                1: height = MAX_HEIGHT;
                default: height = `tbv_rand(MIN_HEIGHT,MAX_HEIGHT);
            endcase
            width = MAX_PX/height;
            if(width < MIN_WIDTH) width = MIN_WIDTH;
            else if(width > MAX_WIDTH) width = MAX_WIDTH;
            width = `tbv_rand(MIN_WIDTH,width);
        end

        // randomize rates
        tbi_rate = `tbv_rand(0,1) ? 100 : `tbv_rand(10,99);
        tbo_rate = `tbv_rand(0,1) ? 100 : `tbv_rand(10,99);

        // report config
        `tbv_info("    width:      %0d",width);
        `tbv_info("    height:     %0d",height);
        `tbv_info("    in rate:    %0d",tbi_rate);
        `tbv_info("    out rate:   %0d",tbo_rate);

        // drive config
        @(posedge clk);
        cfg_width   <= width-1;
        cfg_height  <= height-1;
        repeat(16) @(posedge clk);

        // create input
        for(y=0;y<height;y=y+1) begin
            for(x=0;x<width;x=x+1) begin
                tbi_mem[x+(y*MAX_WIDTH)] = `tbv_rand(0,MAX_DATA);
            end
        end

        // create output
        for(y=0;y<height;y=y+1) begin
            for(x=0;x<width;x=x+1) begin
                sum = 0;

                sum = sum + 1*sample_tbi_mem(y-1,x-1);
                sum = sum + 2*sample_tbi_mem(y-1,x  );
                sum = sum + 1*sample_tbi_mem(y-1,x+1);

                sum = sum + 2*sample_tbi_mem(y  ,x-1);
                sum = sum + 4*sample_tbi_mem(y  ,x  );
                sum = sum + 2*sample_tbi_mem(y  ,x+1);

                sum = sum + 1*sample_tbi_mem(y+1,x-1);
                sum = sum + 2*sample_tbi_mem(y+1,x  );
                sum = sum + 1*sample_tbi_mem(y+1,x+1);

                sum = (sum+8)/16;

                tbo_mem[x+(y*MAX_WIDTH)] = sum;
            end
        end

        // release reset
        @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);

        // wait for completion
        while(!tbo_done) @(posedge clk);

        // wait a bit to see if any invalid pixels get produced
        repeat(`tbv_rand(1,100)) @(posedge clk);

        // assert reset
        @(posedge clk);
        rst <= 1'b1;
        @(posedge clk);

        // wait a bit before next frame
        repeat(`tbv_rand(1,100)) @(posedge clk);
    end
endtask

integer testnum = 0;

initial begin
    for(testnum=0;testnum<20;testnum=testnum+1) begin
        `tbv_info("test %0d",testnum);
        run_test;
    end
    `tbv_finish;
end


// ** Watchdog **

integer watchdog_cnt = 0;

always @(posedge clk) begin
    if(rst || (px_in_ready && px_in_valid) || (px_out_ready && px_out_valid)) begin
        watchdog_cnt <= 0;
    end else begin
        watchdog_cnt <= watchdog_cnt + 1;
        if(watchdog_cnt > 1000) begin
            `tbv_error("watchdog timeout");
            `tbv_finish;
        end
    end
end

endmodule

