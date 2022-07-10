SCALA_FILE = $(shell find ./src/main/scala -name '*.scala' 2>/dev/null)
VERILOG_FILE = $(shell find ./vsrc -name '*.v')
SYSTEMVERILOG_FILE = $(shell find ./vsrc -name '*.sv')

USE_READY_TO_RUN_NEMU = true

.DEFAULT_GOAL = verilog

include Makefile.include

ifeq ($(wildcard src/*), )
	SCALA_CODE = "false"
else
	SCALA_CODE = "true"
endif

build/SimTop.v: $(SCALA_FILE)
	mkdir -p build
ifeq ($(SCALA_CODE), "true")
	mill chiselModule.runMain $(SCALA_OPTS)
endif
	# cp -r vsrc/* build

verilog: build/SimTop.v

sim-verilog: verilog

emu: verilog
	$(MAKE) -C ./difftest emu $(DIFFTEST_OPTS)

clean:
	rm -rf build out

export NOOP_HOME=$(abspath .)
# export FST_HOME=~

sim:
	rm -rf build
	mkdir -p build
	# cp -r vsrc/* build
	make EMU_TRACE=1 emu -j12 NOOP_HOME=$(NOOP_HOME) NEMU_HOME=.

test-lab1a: sim
	TEST=$(TEST) ./build/emu --diff ./riscv64-nemu-interpreter-so -i ./ready-to-run/lab1/lab1-test-a.bin $(VOPT) || true

test-lab1: sim
	TEST=$(TEST) ./build/emu --diff ./riscv64-nemu-interpreter-so -i ./ready-to-run/lab1/lab1-test.bin $(VOPT) || true

test-lab2: sim
	TEST=$(TEST) ./build/emu --diff ./riscv64-nemu-interpreter-so -i ./ready-to-run/lab2/all-test-rv64i.bin $(VOPT) || true
		
test-lab3: sim
	TEST=$(TEST) ./build/emu --diff ./riscv64-nemu-interpreter-so -i ./ready-to-run/lab3/all-test-rv64im.bin $(VOPT) || true

microbench:
	make sim BENCHMARK=1
	./build/emu --diff ./riscv64-nemu-interpreter-so -i ./ready-to-run/challenge/microbench-riscv64-nutshell.bin $(VOPT) || true

test-lab4: sim
	TEST=$(TEST) ./build/emu --no-diff -i ./ready-to-run/lab4/all-test-priv.bin $(VOPT) || true

test-lab4full: sim
	TEST=$(TEST) ./build/emu --diff ./riscv64-nemu-interpreter-so -i ./ready-to-run/lab4/all-test-privfull.bin $(VOPT) || true

include verilate/Makefile.include
include verilate/Makefile.verilate.mk
include verilate/Makefile.vsim.mk

test-cache:
	@rm -rf build && make vsim -j4

test-cache-gdb:
	@rm -rf build && make vsim-gdb -j4

test-refcache:
	@rm -rf build && make vsim -j4 REFERENCE_CACHE=1

.PHONY: verilog emu clean sim
