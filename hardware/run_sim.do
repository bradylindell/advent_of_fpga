# Simulation macro for use in ModelSim. The steps are:
# 1. Compile utils/params_pkg.sv
# 2. Compile the rest of the utils directory
# 3. Compile the rest of the hardware directory
# 4. Simulate using the testbench "top_level_tb"

# Create work library
vlib work

# Compile files
vlog "params_pkg.sv"
vlog "./*.sv"

# Block text editor from opening (may or may not be needed)
# set PrefSource(OpenOnBreak) 0

# Simulate
vsim -voptargs="+acc" -t 1ps -lib work top_level_tb

# Source the wave.do file
do wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all