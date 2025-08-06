##### Variables #####

# top module and file name must be same
TOP = testbench_top

# waveform file name
WAVE = wave_i2c_slave

# UVM-1.2 library directory path
#UVM_PATH = /home/Fenil/tools/mentor/questa/2023.1/questasim/verilog_src/uvm-1.2
UVM_PATH = $(shell dirname $(shell which vsim))/../verilog_src/uvm-1.2


# testcane name
TEST?=sanity

# verbosity
VERBOSITY = UVM_HIGH

# pkt count
wr_pkt = 1
rd_pkt = 1

##### Commands #####

open:
	#bash SCRIPT/open_file.sh
	gvim --cmd 'set title titlestring=I2C_Slave_Verification_Environment' testbench_top.sv 

all: prepare compile simulate

prepare:
	@if [ -d work ]; then rm -rf work; fi
	@if [ -f questa.tops ]; then rm -f questa.tops; fi

compile:
	vlog -sv -O0 +acc +define+UVM_NO_DPI +define+QUESTA \
	-writetoplevels questa.tops $(TOP).sv

	
simulate:
	vsim -f questa.tops -sv_seed random +UVM_NO_RELNOTES -voptargs="+acc=npr" -syncio -batch \
	+UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +wr_pkt=$(wr_pkt) +rd_pkt=$(rd_pkt) \
	-do "vcd file $(WAVE).vcd; vcd add -r /$(TOP)/*; run -all; exit" \
	# | perl -pe 'use Term::ANSIColor; s/(UVM_ERROR.*)/color("red").$$1.color("reset")/ge; s/(UVM_INFO.*)/color("ansi4").$$1.color("reset")/ge; s/(UVM_INFO.*SCOREBOARD.*)/color("ansi34").$$1.color("reset")/ge; s/(UVM_INFO.*src.*)/color("ansi15").$$1.color("reset")/ge; s/(UVM_WARNING.*)/color("yellow").$$1.color("reset")/ge;  s/(UVM_FATAL.*)/color("bold bright_red").$$1.color("reset")/ge'

view:
	vcd2wlf $(WAVE).vcd $(WAVE).wlf
	vsim $(WAVE).wlf

clean:
	find . -mindepth 1 ! -name '.' \
		! -name 'COMPONENT' \
		! -name 'DUT' \
		! -name 'makefile' \
		! -name 'package.sv' \
		! -name 'testbench_top.sv' \
		! -name 'old_testbench.v' \
		! -name 'TESTCASE' \
		! -name '.testbench_top.sv.swp' \
		! -name '.old_testbench.v.swp' \
		! -name '.package.sv.swp' \
		! -name '.makefile.swp' \
		! -path './COMPONENT/*' \
		! -path './DUT/*' \
		! -path './TESTCASE/*' \
		-exec rm -rf {} +
	
help:
	echo -n "\nAvailable test case:\n sanity        : sanity test\n full_mem      : write and then read entire memory\n walk_0        : walk a bit 0 accross a addess\n walk_1        : walk a bit 1 accross a addess\n psel_v_setup  : psel violation in setup test\n pen_v_setup   : penable violation in setup test\n psel_v_access : psel violation in access test\n pen_v_access  : penable violation in access test\n pwr_v_access  : pwrite violation in access test\n pwd_v_access  : pwdata violation in access test\n paddr_v_access:paddr violation in access test\n random_signal : all signal are random\n random_v      : run any one violation\n rw_idle       : multiple read write with idle test\n\n"

