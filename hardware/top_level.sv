// Copyright (c) 2025 Brady Lindell

// This source describes Open Hardware and is licensed under the
// CERN Open Hardware Licence v2 – Strongly Reciprocal (CERN-OHL-S).

import params_pkg::*;

module top_level (
    input logic clk, reset
);
    // Packed array only because $countones doesn't synthesize on unpacked
    logic unsigned [VALUE_PARALLELISM-1:0] incr_count, done_parts;
    logic unsigned [COUNTER_WIDTH-1:0] count_ns;
    logic unsigned [$clog2(VALUE_PARALLELISM):0] increment;

    logic done;

    (* dont_touch = "true" *)
    logic unsigned [COUNTER_WIDTH-1:0] count;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 0;
        end else begin
            count <= count_ns;
        end
    end

    always_comb begin
        increment = $countones(incr_count);
        count_ns = count + increment;
        done = &done_parts;
    end

    generate
        for (genvar i = 0; i < VALUE_PARALLELISM; i++) begin : gen_value_mem
            range_checker #(
                .VAL_MEM_INDEX(i)
            ) range (
                .clk(clk),
                .reset(reset),
                .jump(incr_count[i]),
                .done(done_parts[i])
            );
        end
    endgenerate
endmodule