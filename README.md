# dualCoreRiscV
Dual-Core RISC-V RTL Integration & Verification Verilog, SystemVerilog, C, GCC, objdump
• Integrated dual-core RISC-V RTL with shared-memory arbitration and peripherals on FPGA; verified inter-core
read/write ordering and debugged behaviour through waveform analysis.
• Compiled C test programs with GCC and used objdump/readelf to inspect instruction encodings and confirm
expected RTL paths were exercised.
## Prerequisites

### Knowledge
- Digital logic design — combinational/sequential logic, FSMs, clock domain crossing, synchronizers
- Computer architecture — pipelining, hazards, memory-mapped I/O, memory hierarchy
- RISC-V ISA — RV32I/RV64I base ISA, privileged spec (machine mode, CSRs, `mhartid`)
- Memory consistency & ordering — sequential vs. relaxed consistency, RAW/WAR hazards across bus masters
- Bus arbitration — round-robin / fixed-priority schemes and fairness trade-offs
- On-chip bus protocols — AXI-Lite/AXI4, Wishbone, or custom shared-bus interfaces

### Hardware
- FPGA development board (e.g., Xilinx Artix-7/Zynq, Intel Cyclone/MAX10) with sufficient LUTs/BRAM for dual-core + shared memory + peripherals
- JTAG/USB programming cable
- Host PC capable of running vendor synthesis tools (16GB+ RAM recommended)

### RTL / IP
- RISC-V core RTL (open-source: PicoRV32, VexRiscv, SERV, Ibex — or custom core), instantiated twice
- Shared memory controller with arbitration logic
- Peripheral IP — UART, GPIO, timer — memory-mapped into the address space
- Interconnect/bus fabric linking cores, memory, and peripherals
- Defined memory map (RAM, peripheral, per-core register ranges)

### Toolchain
- Verilog/SystemVerilog (synthesizable RTL, SVA if used)
- Simulator — Verilator, Icarus Verilog, or ModelSim/QuestaSim
- Vendor FPGA toolchain — Vivado or Quartus, matched to your board
- RISC-V GNU toolchain (`riscv64-unknown-elf-gcc`) for bare-metal C
- Binutils — `objdump`, `readelf`, `addr2line`
- GTKWave (or vendor waveform viewer)
- `make` for build automation
- Git

### Bare-Metal Software
- Linker script matching the RTL memory map
- Startup code (`crt0.s`) — stack setup, `mhartid`-based core dispatch
- C test programs targeting inter-core ordering scenarios (volatile MMIO pointers, flag/data producer-consumer patterns)

### Verification
- SystemVerilog testbench driving both cores / arbiter interface
- Waveform debug plan — arbiter grant/request, memory strobes, core PC signals
- Cross-check of `objdump`-disassembled binaries against RTL fetch/execute trace to confirm expected code paths
