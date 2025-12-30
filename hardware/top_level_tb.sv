// Copyright (c) 2025 Brady Lindell

// This source describes Open Hardware and is licensed under the
// CERN Open Hardware Licence v2 – Strongly Reciprocal (CERN-OHL-S).

import params_pkg::*;

module top_level_tb();
    logic clk, reset;

    // instantiate the module
    top_level dut (.*);

    // infinitely toggle the clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    int cycle_count = 0;
    int cycle_period_length = 10; // 100Mhz clock

    initial begin
        reset <= 0;
        @(posedge clk); reset <= 1;
        @(posedge clk); @(negedge clk); reset <= 0;

        while (!dut.done) begin
            @(posedge clk);
            cycle_count++;
        end

        repeat(5) @(posedge clk);

        $display("Cycles to finish: %0d", cycle_count);
        $display("Runtime: %0t ns", cycle_count*cycle_period_length);
        $display("Runtime: %0t us", cycle_count*cycle_period_length/1000);
        $display("Runtime: %0t ms", cycle_count*cycle_period_length/1000_000);

        $stop;
    end
endmodule