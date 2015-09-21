
// This is just an include file used by the testbench.

// display macros, qualified by desired level of verbosity
`define tbv_display $write("%t: %m: ", $time); $display
`define tbv_info $write("%t : [%m] : INFO : ", $time); $display
`define tbv_warn hw_tbv._tbv_warn; $write("%t : [%m] : WARN : ", $time); $display

// macros for recording success or failure of a test
// (all invocations of these will be used for reporting final pass/fail when tbv_finish is called)
`define tbv_okay hw_tbv._tbv_okay; if(0) $write("%t : [%m] : OKAY : ", $time); if(0) $display
`define tbv_error hw_tbv._tbv_error; $write("%t : [%m] : *** ERROR *** : ",$time); $display

// if condition is true, invokes tbv_okay; otherwise, invokes tbv_error
`define tbv_assert(cond,msg) if(cond) begin `tbv_okay(msg); end else begin `tbv_error(msg); end if(0)

// use instead of $finish (prints out pass/fail result, then finishes)
`define tbv_finish hw_tbv._tbv_finish

// generates random number in [min,max] range (inclusive)
// (wrapper for $dist_uniform - initial seed specified with `RANDSEED)
`define tbv_rand(min,max) hw_tbv._tbv_rand(min,max)


// *** random ***

`ifndef RANDSEED
    `define RANDSEED 42
`endif

// _tbv_rand: returns a random number in the specified range
// (just shorthand for $dist_uniform)
initial _tbv_rand.seed = `RANDSEED;
function signed [63:0] _tbv_rand;
    input signed [63:0] min;
    input signed [63:0] max;
    integer seed;
begin
    _tbv_rand = $dist_uniform(seed,min,max);
end
endfunction


// *** assertions ***

integer _tbv_err_cnt = 0;
integer _tbv_chk_cnt = 0;
integer _tbv_warn_cnt = 0;

// _tbv_assert_report: prints pass/fail based on running count of assertion failures
task _tbv_assert_report;
begin
    if(_tbv_err_cnt > 0 || _tbv_chk_cnt == 0) begin
        $display("%t: *** FAILED *** (%0d errors/%0d assertions, %0d warnings)", $time, _tbv_err_cnt, _tbv_chk_cnt, _tbv_warn_cnt);
    end else begin
        if(_tbv_warn_cnt > 0) begin
            $display("%t: *** PASSED with WARNINGS *** (%0d assertions evaluated, %0d warnings)", $time, _tbv_chk_cnt, _tbv_warn_cnt);
        end else begin
            $display("%t: *** PASSED *** (%0d assertions evaluated, %0d warnings)", $time, _tbv_chk_cnt, _tbv_warn_cnt);
        end
    end
end
endtask

// invoke to record a warning
task _tbv_warn;
begin
    _tbv_warn_cnt = _tbv_warn_cnt + 1;
end
endtask

// invoke to record a successfull check
task _tbv_okay;
begin
    _tbv_chk_cnt = _tbv_chk_cnt + 1;
end
endtask

// invoke to record a failing check
task _tbv_error;
begin
    _tbv_chk_cnt = _tbv_chk_cnt + 1;
    _tbv_err_cnt = _tbv_err_cnt + 1;
end
endtask

// print reports and end simulation
task _tbv_finish;
begin
    _tbv_assert_report;
    $finish;
end
endtask

integer _tbv_dump_disable = 0;

// initial setup
initial begin
    $timeformat(-6,3," us",15);

    `tbv_display("using random seed: %0d", `RANDSEED);

`ifdef DUMPFILE
    if($value$plusargs("NODUMP=%d",_tbv_dump_disable)) begin
        _tbv_dump_disable = 1;
    end
    if(!_tbv_dump_disable) begin
        `tbv_display("dumping enabled");
        $dumpfile(`DUMPFILE);
        $dumpvars;
    end else begin
        `tbv_display("dumping disabled");
    end
`endif
end

