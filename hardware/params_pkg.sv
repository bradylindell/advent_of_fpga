// Copyright (c) 2025 Brady Lindell

// This source describes Open Hardware and is licensed under the
// CERN Open Hardware Licence v2 - Strongly Reciprocal (CERN-OHL-S).

package params_pkg;
	// The width of all range and value data
	localparam int unsigned DATA_WIDTH = 49;

	// The parallelism values, received from the script execution arguments
	localparam int unsigned RANGE_PARALLELISM = 1;
	localparam int unsigned VALUE_PARALLELISM = 1;

	// Number of values and ranges in the input file
	localparam int unsigned RANGES_COUNT = 190;
	localparam int unsigned VALUES_COUNT = 1000;

	// Number of bits needed to represent the count value
	localparam int unsigned COUNTER_WIDTH = 10;

	// Hex file lengths and address widths
	localparam int unsigned RANGE_MEM_FILE_LENGTH = 190;
	localparam int unsigned RANGE_MEM_ADDRESS_WIDTH = 8;
	localparam int unsigned VALUE_MEM_FILE_LENGTH = 1000;
	localparam int unsigned VALUE_MEM_ADDRESS_WIDTH = 10;

	// If the memory files are varying lengths, at what index do the shorter lengths start?
	// Note: A value of -1 means that all of the files are the same length

	// Ex. I have 5 values to go into 4 .hex files. The first .hex file will have a length
	// of 2, and the rest will have a length of 1. Thus, the length change index is 1,
	// because it is the first index where the .hex file is one line shorter.
	localparam int signed VALUE_LENGTH_CHANGE_INDEX = -1;
	localparam int signed RANGE_LENGTH_CHANGE_INDEX = -1;
endpackage