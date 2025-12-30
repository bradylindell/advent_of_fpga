// Copyright (c) 2025 Brady Lindell

// This source describes Open Hardware and is licensed under the
// CERN Open Hardware Licence v2 – Strongly Reciprocal (CERN-OHL-S).

import params_pkg::*;

module range_checker #(
    parameter int VAL_MEM_INDEX = 0
)(
    input logic clk, reset,
    output logic jump, done
);
    logic unsigned [RANGE_MEM_ADDRESS_WIDTH-1:0] range_addr;
    logic unsigned [RANGE_MEM_ADDRESS_WIDTH-1:0] range_addr_ns;
    logic unsigned [VALUE_MEM_ADDRESS_WIDTH-1:0] value_addr;
    logic unsigned [VALUE_MEM_ADDRESS_WIDTH-1:0] value_addr_ns;
    logic unsigned [DATA_WIDTH-1:0] low_range_dout [RANGE_PARALLELISM-1:0];
    logic unsigned [DATA_WIDTH-1:0] high_range_dout [RANGE_PARALLELISM-1:0];
    logic unsigned [DATA_WIDTH-1:0] value_dout;

    logic [RANGE_PARALLELISM-1:0] any_jump;
    logic set_done;

    always_ff @(posedge clk) begin
        if (reset) begin
            range_addr <= '0;
            value_addr <= '0;
            done <= 0;
        end else begin
            range_addr <= range_addr_ns;
            value_addr <= value_addr_ns;
            if (set_done) begin
                done <= 1;
            end
        end
    end

    always_comb begin
        range_addr_ns = range_addr;
        value_addr_ns = value_addr;
        set_done = 0;

        for (int i = 0; i < RANGE_PARALLELISM; i++) begin
            any_jump[i] = (value_dout >= low_range_dout[i]) && (value_dout <= high_range_dout[i]);
        end

        jump = |any_jump && !done;

        if (jump || range_addr == RANGE_MEM_FILE_LENGTH-1) begin
            if (value_addr != VALUE_MEM_FILE_LENGTH-1) begin
                value_addr_ns = value_addr + 1'b1;
                range_addr_ns = 0;
            end else begin
                set_done = 1;
            end
        end else begin
            range_addr_ns = range_addr + 1'b1;
        end
    end

    // Instantiate memory units
    values_mem #(
        .VAL_MEM_INDEX(VAL_MEM_INDEX)
    ) value_mem_inst (
        .addr(value_addr),
        .dout(value_dout)
    );

    generate
        for (genvar i = 0; i < RANGE_PARALLELISM; i++) begin : gen_range_mem
            range_mem #(
                .RANGE_MEM_INDEX(i),
                .KIND("low")
            ) low (
                .addr(range_addr),
                .dout(low_range_dout[i])
            );
            range_mem #(
                .RANGE_MEM_INDEX(i),
                .KIND("high")
            ) high (
                .addr(range_addr),
                .dout(high_range_dout[i])
            );
        end
    endgenerate
endmodule