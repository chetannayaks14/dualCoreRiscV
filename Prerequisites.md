1. Conceptual Knowledge
Digital logic fundamentals — combinational vs. sequential design, FSMs, clock domain basics, metastability/synchronizers (important once you have two independent cores).
Computer architecture basics — pipelining, hazards, memory hierarchy, memory-mapped I/O.
RISC-V ISA — RV32I/RV64I base integer instruction set; if your cores support it, the privileged spec (machine mode, CSRs, interrupts) since dual-core systems usually need mhartid to distinguish cores.
Memory consistency / ordering concepts — since you're verifying inter-core read/write ordering, you should be comfortable with:
Sequential consistency vs. relaxed ordering
Read-after-write / write-after-read hazards across masters
Why arbitration order ≠ program order unless explicitly enforced
Bus arbitration schemes — round-robin, fixed-priority, TDMA — and their fairness/starvation trade-offs.
Bus/interconnect protocols — AXI-Lite/AXI4, Wishbone, or a custom shared-bus protocol, depending on what your core IP uses.
2. Hardware
An FPGA development board (e.g., Xilinx Artix-7/Zynq, Intel Cyclone/MAX10) with enough LUTs/BRAM for two cores + shared memory + peripherals.
JTAG/USB programming cable (often integrated on dev boards).
A host PC capable of running vendor synthesis tools (Vivado/Quartus are resource-heavy — 16GB+ RAM recommended).
3. RTL / Existing IP
A RISC-V core RTL implementation — either an open-source core (PicoRV32, VexRiscv, SERV, Ibex, Rocket) instantiated twice, or a custom core you've written.
Shared memory controller / arbiter RTL — this is core to the project; you need arbitration logic (e.g., round-robin) between the two core's memory requests.
Peripheral IP — UART (for print/debug output), GPIO, timer — memory-mapped into the address space.
Interconnect/bus fabric connecting cores, memory, and peripherals.
A defined memory map (address ranges for RAM, peripherals, per-core registers).
4. Toolchain & Software
Verilog/SystemVerilog proficiency — RTL coding style, synthesizable constructs, assertions (SVA) if used for verification.
Simulator — Verilator, Icarus Verilog, or ModelSim/QuestaSim for pre-synthesis functional verification.
Vendor FPGA toolchain — Vivado (Xilinx) or Quartus (Intel), matched to your board.
RISC-V GNU toolchain (riscv-gnu-toolchain or riscv64-unknown-elf-gcc) — cross-compiler for bare-metal C.
Binutils — objdump, readelf, addr2line for inspecting instruction encodings and confirming expected code paths.
Waveform viewer — GTKWave (open source) or the vendor's simulator waveform tool.
Build tooling — make (or a simple build script) to compile, link, and convert C programs to .hex/.mem for RTL initialization.
Git for version control.
5. Bare-Metal Software Setup
Linker script defining memory regions matching your RTL's memory map.
Startup code / crt0.s — sets up stack pointer, mhartid-based core differentiation, jumps to main().
C test programs specifically designed to exercise inter-core ordering scenarios — e.g., core 0 writes a flag then data, core 1 polls the flag and reads data, checking for stale reads.
Familiarity with memory-mapped I/O in C (volatile pointers, avoiding compiler reordering of accesses you want to test).
6. Verification Methodology
A testbench structure — even simple directed SV testbenches driving both cores or the arbiter interface.
A plan for waveform-based debug: knowing what signals to probe (arbiter grant/request, memory read/write strobes, core PC) to trace ordering violations.
A way to cross-check RTL execution against expected instruction flow — this is where objdump-disassembled binaries get compared against what the RTL actually fetches/executes, confirming the right code paths were hit.
