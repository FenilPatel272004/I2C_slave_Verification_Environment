# UVM-Based I2C Slave Verification Environment

This repository contains a UVM (Universal Verification Methodology) testbench for verifying an I2C slave RTL design. The testbench supports repeated start conditions, SDA/SCL control, configurable packet counts, and a layered UVM structure.

## Repository Structure

```
.
├── DUT/             # I2C Slave RTL design (SystemVerilog/Verilog)
├── COMPONENT/       # UVM components (driver, monitor, agent, etc.)
├── TESTCASE/        # UVM testcases
├── testbench_top.sv # Top-level testbench module
├── i2c_pkg.sv       # UVM package including all components
├── Makefile         # Makefile for compilation & simulation
└── README.md        # This file
```

## Prerequisites

- **Simulator**: Mentor Graphics QuestaSim or ModelSim (with UVM support)
- **UVM library** must be properly installed and accessible (via `-uvm` switch in `vlog`)

## How to Run the Simulation

### 1. Compile and Run Using Makefile

```bash
make all
```

This will:
- Compile the design (`i2c_slave.v`) and testbench files
- Run the simulation using the default test (`sanity`)

### 2. Clean All Compiled Files

```bash
make clean
```

Removes all generated files, including `work/`, `transcript`, `vsim.wlf`, etc.

### 3. View the Simulation Waveform

After simulation:

```bash
make view
```

Opens the `vsim` GUI for waveform viewing. You can add a `.do` file to preload signal configurations.

## Customizing the Simulation

To change which test runs, edit the Makefile under the `run:` target:

```make
run:
	vsim -c -do "run -all; quit" work.testbench_top +UVM_TESTNAME=sanity
```

Replace `sanity` with the name of your custom test.

## Testcase Behavior

The current testbench performs the following:
- Writes random data to the I2C slave at random addresses
- Performs repeated read operations from the same addresses
- Uses repeated-start conditions to group packets under one transaction
- Applies a STOP condition only after the final packet

Packet generation logic can be edited in `sanity.sv`.

## Contribution

Feel free to raise issues or contribute improvements for:
- Additional testcases
- New protocol features (e.g., clock stretching support)
- Improved coverage and assertions
