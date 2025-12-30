// Copyright (c) 2025 Brady Lindell

// This source describes Open Hardware and is licensed under the
// CERN Open Hardware Licence v2 – Strongly Reciprocal (CERN-OHL-S).

import params_pkg::*;

module values_mem #(
    parameter int VAL_MEM_INDEX = 0
)(
    input logic [VALUE_MEM_ADDRESS_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] dout
);
    localparam bit IS_SHORT =
        (VALUE_LENGTH_CHANGE_INDEX >= 0) && (VAL_MEM_INDEX >= VALUE_LENGTH_CHANGE_INDEX);

    localparam int DEPTH = VALUE_MEM_FILE_LENGTH - IS_SHORT;

    logic [DATA_WIDTH-1:0] ram [DEPTH-1:0];

    initial begin
        $readmemh($sformatf("hex/values_%0d.hex", VAL_MEM_INDEX), ram);
    end

    assign dout = ram[addr];
endmodule