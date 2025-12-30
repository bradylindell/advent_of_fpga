// Copyright (c) 2025 Brady Lindell

// This source describes Open Hardware and is licensed under the
// CERN Open Hardware Licence v2 – Strongly Reciprocal (CERN-OHL-S).

import params_pkg::*;

module range_mem #(
    parameter int RANGE_MEM_INDEX = 0,
    parameter string KIND = "low"
)(
    input logic [RANGE_MEM_ADDRESS_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] dout
);
    localparam bit IS_SHORT =
        (RANGE_LENGTH_CHANGE_INDEX >= 0) && (RANGE_MEM_INDEX >= RANGE_LENGTH_CHANGE_INDEX);

    localparam int DEPTH = RANGE_MEM_FILE_LENGTH - IS_SHORT;

    logic [DATA_WIDTH-1:0] ram [DEPTH-1:0];

    initial begin
        $readmemh($sformatf("hex/range_%s_bound_%0d.hex", KIND, RANGE_MEM_INDEX), ram);
    end

    assign dout = ram[addr];
endmodule