# Copyright (c) 2025 Brady Lindell

# This source describes Open Hardware and is licensed under the
# CERN Open Hardware Licence v2 – Strongly Reciprocal (CERN-OHL-S).

import math
from pathlib import Path
import shutil
import argparse

def main():
    # The RANGE_PARALLELISM value is equal to how many ranges are checked in one clock cycle, for
    # each value. The VALUE_PARALLELISM is equal to how many values are checked. So, for
    # a RANGE_PARALLELISM of 8, and a VALUE_PARALLELISM of 4, there are 4 values, each checked
    # for 8 ranges each clock cycle. In this case, 32 total ranges are checked each clock cycle.
    args = parse_args()
    RANGE_PARALLELISM = args.range_parallelism
    VALUE_PARALLELISM = args.value_parallelism
    input_file = args.input_file
    print(f"Input file: {input_file}")
    print(f"Range Parallelism: {RANGE_PARALLELISM}")
    print(f"Value Parallelism: {VALUE_PARALLELISM}")

    initialize_directories()
    ranges_count, values_count, bit_width, hex_width = gen_parameters(input_file)

    # Writes the parameter file and memory initialization files
    write_files(input_file, ranges_count, values_count, bit_width,
                hex_width, RANGE_PARALLELISM, VALUE_PARALLELISM)

def parse_args():
    p = argparse.ArgumentParser(
        description="Generate SV + hex files from input file"
    )
    p.add_argument(
        "input_file",
        type=str,
        help="What is the input file?"
    )
    p.add_argument(
        "range_parallelism",
        type=int,
        help="How many range lanes to generate (RANGE_PARALLELISM)"
    )
    p.add_argument(
        "value_parallelism",
        type=int,
        help="How many value lanes to generate (VALUE_PARALLELISM)"
    )
    return p.parse_args()

def initialize_directories():
    hardware_dir = Path("../hardware")

    # delete the hex directory if it exists
    utils_dir = hardware_dir / "hex"
    if utils_dir.exists() and utils_dir.is_dir():
        shutil.rmtree(utils_dir)

    # Create the hex directory
    (Path("../hardware") / "hex").mkdir()

def gen_parameters(input_file):
    ranges_count = 0
    values_count = 0
    max_val = 0
    # Parse input file and accumulate parameters
    with open(input_file, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue
            
            if '-' in line:
                ranges_count += 1
                a_string, b_string = line.split('-')

                # Don't need to check lower bound, the upper bound is by definition larger
                b_int = int(b_string)

                if b_int > max_val:
                    max_val = b_int
            else:   
                values_count += 1
                line_int = int(line)
                if line_int > max_val:
                    max_val = line_int

    bit_width = max_val.bit_length()
    hex_width = (bit_width + 3) // 4
    return ranges_count, values_count, bit_width, hex_width

def write_files(input_file, ranges_count, values_count, bit_width,
                hex_width, RANGE_PARALLELISM, VALUE_PARALLELISM):
    # Throw an error if the value or range parallelism is too big
    if RANGE_PARALLELISM > ranges_count:
        raise Exception("Error: Range parallelism cannot be greater than the number of ranges")
    if VALUE_PARALLELISM > values_count:
        raise Exception("Error: Value parallelism cannot be greater than the number of ranges")
    
    # Write the parameter file
    f_inp = open(input_file, "r")
    f_param = open("../hardware/params_pkg.sv", "w")
    f_param.write("// Copyright (c) 2025 Brady Lindell\n\n")
    f_param.write("// This source describes Open Hardware and is licensed under the\n")
    f_param.write("// CERN Open Hardware Licence v2 - Strongly Reciprocal (CERN-OHL-S).\n\n")
    
    f_param.write("package params_pkg;\n")
    f_param.write("\t// The width of all range and value data\n")
    f_param.write(f"\tlocalparam int unsigned DATA_WIDTH = {bit_width};\n\n")
    f_param.write("\t// The parallelism values, received from the script execution arguments\n")
    f_param.write(f"\tlocalparam int unsigned RANGE_PARALLELISM = {RANGE_PARALLELISM};\n")
    f_param.write(f"\tlocalparam int unsigned VALUE_PARALLELISM = {VALUE_PARALLELISM};\n\n")
    f_param.write("\t// Number of values and ranges in the input file\n")
    f_param.write(f"\tlocalparam int unsigned RANGES_COUNT = {ranges_count};\n")
    f_param.write(f"\tlocalparam int unsigned VALUES_COUNT = {values_count};\n\n")
    counter_width = math.ceil(math.log2(values_count))
    f_param.write("\t// Number of bits needed to represent the count value\n")
    f_param.write(f"\tlocalparam int unsigned COUNTER_WIDTH = {counter_width};\n\n")

    # Keep track of the length of the hex files
    range_hex_length = [0] * RANGE_PARALLELISM
    value_hex_length = [0] * VALUE_PARALLELISM

    # Vars to track while parsing input file
    in_ranges = True
    value_index = 0
    range_index = 0
    values_per_lane = (values_count + VALUE_PARALLELISM - 1) // VALUE_PARALLELISM
    value_arr = [
        ["" for _ in range(values_per_lane)]
        for _ in range(VALUE_PARALLELISM)
    ]
    cols = (ranges_count + RANGE_PARALLELISM - 1) // RANGE_PARALLELISM
    range_low_bound_arr  = [[""] * cols for _ in range(RANGE_PARALLELISM)]
    range_high_bound_arr = [[""] * cols for _ in range(RANGE_PARALLELISM)]

    # Iterate through input text and split into memory initialization files
    for line in f_inp:
        line = line.strip()
        
        # blank line switches to values section
        if line == "":
            in_ranges = False
            continue
            
        if in_ranges:
            low_string, high_string = line.split('-')
            low_hex = format(int(low_string), f"0{hex_width}x")
            high_hex = format(int(high_string), f"0{hex_width}x")

            index = range_index % RANGE_PARALLELISM
            entry_number = range_index // RANGE_PARALLELISM

            range_hex_length[index] += 1
            range_low_bound_arr[index][entry_number] = low_hex
            range_high_bound_arr[index][entry_number] = high_hex
            range_index += 1
        else:
            line_hex = format(int(line), f"0{hex_width}x")

            index = value_index % VALUE_PARALLELISM
            entry_number = value_index // VALUE_PARALLELISM

            value_hex_length[index] += 1
            value_arr[index][entry_number] = line_hex
            value_index += 1

    # Write files from array values
    array_to_hex(range_high_bound_arr, "range_high_bound")
    range_length_change_index = array_to_hex(range_low_bound_arr, "range_low_bound")
    value_length_change_index = array_to_hex(value_arr, "values")


    # Finish writing parameter file
    f_param.write("\t// Hex file lengths and address widths\n")
    f_param.write(f"\tlocalparam int unsigned RANGE_MEM_FILE_LENGTH = {range_hex_length[0]};\n")
    f_param.write(f"\tlocalparam int unsigned RANGE_MEM_ADDRESS_WIDTH ="
                  f" {math.ceil(math.log2(max(range_hex_length)))};\n")
    f_param.write(f"\tlocalparam int unsigned VALUE_MEM_FILE_LENGTH = {value_hex_length[0]};\n")
    f_param.write(f"\tlocalparam int unsigned VALUE_MEM_ADDRESS_WIDTH ="
                  f" {math.ceil(math.log2(max(value_hex_length)))};\n\n")
    f_param.write("\t// If the memory files are varying lengths, "
                  "at what index do the shorter lengths start?\n")
    f_param.write("\t// Note: A value of -1 means that all of the files are the same length\n\n")
    f_param.write("\t// Ex. I have 5 values to go into 4 .hex files."
                  " The first .hex file will have a length\n")
    f_param.write("\t// of 2, and the rest will have a length of 1. "
                  "Thus, the length change index is 1,\n")
    f_param.write("\t// because it is the first index where the .hex file is one line shorter.\n")
    f_param.write("\tlocalparam int signed VALUE_LENGTH_CHANGE_INDEX ="
                  f" {value_length_change_index};\n")
    f_param.write("\tlocalparam int signed RANGE_LENGTH_CHANGE_INDEX = "
                  f"{range_length_change_index};\n")
    f_param.write("endpackage")

    # Close all the files
    f_inp.close()
    f_param.close()

# Helper function to map the 2d arrays to hex files
def array_to_hex(array, type):
    length_change_index = -1
    for i in range(len(array)):
        file = open(f"../hardware/hex/{type}_{i}.hex", "w")
        for j in range(len(array[i])):
            temp = array[i][j]
            if (temp == ""):
                if (length_change_index == -1):
                    length_change_index = i
            else:
                file.write(f"{temp}\n")
        file.close()
    return length_change_index

# Main guard
if __name__ == "__main__":
    main()