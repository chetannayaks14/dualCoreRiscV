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


## Testing

### Objective
Verify correctness of instruction execution across the dual-core pipeline, with focus on the five-stage flow (IF → ID → EX → MEM → WB), covering ALU operations, memory loads/stores, cache behavior, and inter-core synchronization.

### Methodology
- Simulation-based verification using a **SystemVerilog testbench** with trace logging and assertions
- Directed, scenario-based test cases — each isolating a specific pipeline stage or memory interaction
- Register and pipeline state captured via simulation logs: PC values, instruction encodings, ALU outputs, and register file updates at each cycle

### Test Scenarios
| # | Scenario | Purpose |
|---|----------|---------|
| 1 | ALU x1–x4 propagation (arithmetic startup) | Verify back-to-back ALU instructions flow correctly through all 5 stages and update the register file on WB |
| 2 | LD from memory (`MEM[8]`) — simultaneous dual-core load | Confirm both cores loading the same address read identical, correctly-initialized values |
| 3 | SD to `MEM[0]` — dual concurrent stores | Evaluate synchronization/race behavior when both cores store to the same shared address |
| 4 | Coherent LD across cores (`MEM[16]`, 1-cycle offset) | Verify memory coherence when one core's load trails the other's by a single cycle |
| 5 | Pipeline stall and hazard resolution | Confirm hazards are handled without incorrect overwrites or stalls |
| 6 | Out-of-bounds LD (`MEM[0xFF]`) | Check behavior on an invalid/out-of-range memory access |
| 7 | NOP instruction behavior | Confirm NOPs pass through the pipeline without side effects |
| 8 | Instruction memory dual-port verification | Confirm conflict-free, simultaneous instruction fetch for both cores via `imem_dualport.sv` |

### Example: Arithmetic Startup Test
Core executes:
ADDI x1, x0, 9
ADDI x2, x1, 5
ADD x3, x1, x2
ADD x4, x3, x2

Result (after 6 clock cycles, all instructions retired at WB):
Core 0: x1=9, x2=14, x3=23, x4=37
Core 1: x1=3, x2=10, x3=13, x4=23

### Key Findings
- **Uninitialized shared memory** (`MEM[8]`) caused both cores to read `0` instead of the expected value — surfaced the importance of proper memory initialization before simulation.
- **Concurrent stores to `MEM[0]`** from both cores exposed a race condition when source registers weren't pre-loaded, confirming the need for explicit synchronization around shared-address writes.
- **Coherence check at `MEM[16]`** caught a case where Core0's load returned `0` instead of the expected pre-loaded value (`10`), flagging a coherence/timing gap between offset loads.
- Register trace logs confirmed correct write-backs at the WB stage and proper hazard handling (no unintended overwrites or missed stalls) once the above issues were addressed.

### Results Summary
- All test scenarios passed after fixes.
- Final register values and memory contents matched expected results across both cores.
- Cache-to-memory coherence held for all read/write combinations tested.
- Verified the dual-core pipeline behaves **deterministically and stably** under inter-core stress.


- Waveform debug plan — arbiter grant/request, memory strobes, core PC signals
- Cross-check of `objdump`-disassembled binaries against RTL fetch/execute trace to confirm expected code paths
