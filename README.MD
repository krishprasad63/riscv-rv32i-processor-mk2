# RISC-V RV32I 5-Stage Pipelined Processor with Forwarding and Hazard Detection (Verilog)

A modular 32-bit pipelined processor implementing a subset of the RV32I instruction set architecture in Verilog HDL. The design follows the classic five-stage pipeline (IF, ID, EX, MEM, WB) and resolves data hazards in hardware through a forwarding unit and a load-use hazard detection unit. Control hazards are handled by flushing the pipeline when a branch is taken.

This repository is the second version of the processor. The earlier version had no hazard handling and relied on manually inserted NOP instructions; this version resolves ALU data dependencies, load-use hazards and taken branches in hardware.

The design is developed and verified using Xilinx Vivado behavioral simulation.

---

## Features

- 32-bit, five-stage pipeline: Instruction Fetch, Instruction Decode, Execute, Memory Access, Write Back
- Pipeline registers between stages: IF/ID, ID/EX, EX/MEM, MEM/WB
- Data forwarding unit (EX/MEM to EX and MEM/WB to EX paths)
- Load-use hazard detection unit with pipeline stall and bubble insertion
- Branch handling with IF/ID and ID/EX flush on a taken branch
- 32-register register file with register x0 hardwired to zero
- ALU with arithmetic, logical, shift and comparison operations
- Shift-and-add multiplier for the MUL instruction
- Word-addressed data memory (1K words) and byte-organised instruction memory
- Dedicated hazard testbenches (forwarding, forwarding chain, load-use, branch flush) and program-level tests (Fibonacci, factorial, array sum, bubble sort)
- Testbenches that report register and memory contents with PASS/FAIL checking; the compare-and-swap test also reports pipeline statistics (cycles, forwarding events, stalls, flushes)

---

## Pipeline Architecture

| Stage | Function |
| ----- | -------- |
| IF  | Fetches the instruction at the program counter; the program counter can be held during a stall |
| ID  | Decodes the instruction, reads the register file, generates control signals and the immediate; hazard detection is performed here |
| EX  | ALU operation, branch condition evaluation and branch target calculation; forwarded operands are selected here |
| MEM | Data memory read or write |
| WB  | Selects between ALU result and memory data and writes the result to the register file |

### Data Hazard Handling

**Forwarding unit** (`forwarding_unit.v`). Compares the source registers of the instruction in EX with the destination registers of the instructions in MEM and WB, and selects the operand source for each ALU input:

| Select | Source |
| ------ | ------ |
| 2'b00 | Register file value read in ID |
| 2'b10 | ALU result from the EX/MEM register |
| 2'b01 | Write-back data from the MEM/WB stage |

The EX/MEM path has priority over the MEM/WB path, writes to x0 are never forwarded, and the store data is forwarded as well, so a store can use a result produced by the immediately preceding instruction.

**Hazard detection unit** (`hazard_detection_unit.v`). A load whose result is used by the next instruction cannot be forwarded in time. The unit detects this load-use case, holds the program counter and the IF/ID register for one cycle, and zeroes the control signals entering ID/EX so that a bubble is inserted. The dependent instruction then receives the loaded value through forwarding.

### Control Hazard Handling

Branches are resolved in the EX stage. When BEQ, BNE, BLT or BGE is taken, the program counter is redirected to the branch target and the instructions in the IF/ID and ID/EX registers are flushed.

---

## Supported Instructions

| Type | Instructions |
| ---- | ------------ |
| Arithmetic | ADD, SUB, ADDI |
| Logical | AND, OR, XOR, NOR, ANDI, ORI, XORI |
| Shift | SLL, SRL, SRA, SLLI, SRLI, SRAI |
| Comparison | SLT, SLTI |
| Multiplication | MUL (shift-and-add multiplier) |
| Memory | LW, SW |
| Branch | BEQ, BNE, BLT, BGE |

This is a subset of RV32I; the complete instruction set is not implemented.

---

## Repository Structure

```text
Design Sources/
├── riscv.v                    Top-level module
├── fetch_stage.v
├── program_counter.v
├── instruction_memory.v
├── if_id_register.v
├── decode_stage.v
├── control_unit.v
├── register_file.v
├── hazard_detection_unit.v
├── id_ex_register.v
├── forwarding_unit.v
├── execute_stage.v
├── alu_riscv.v
├── shift_add_mul.v
├── ex_mem_register.v
├── memory_stage.v
├── mem_wb_register.v
├── write_back_stage.v
├── writeback_stage.v
├── tb_blt.v                   Branch-less-than testbench
└── tb_compare_swap.v          Compare-and-swap testbench (bubble sort kernel)

Testbenches/
├── tb_riscv.v
├── tb_add.v
├── tb_add_rtype.v
├── tb_move.v
├── tb_lw_sw.v
├── tb_lw_sw_address.v
├── tb_mul_rtype.v
├── tb_mul_x2.v
├── tb_forwarding.v
├── tb_forwarding_chain.v
├── tb_sub_forwarding.v
├── tb_load_use_hazard.v
├── tb_branch_flush.v
├── tb_dual_load_branch.v
├── tb_bne.v
├── tb_bne_x4.v
├── tb_branch_loop.v
├── tb_loop.v
├── tb_loop_blt.v
├── tb_compare_loop.v
├── tb_unconditional_swap.v
├── testing_loop.v
├── tb_fibonacci.v
├── tb_factorial.v
├── tb_array_sum.v
└── tb_bubble_sort.v
```

---

## Verification

Each testbench loads a program into instruction memory, runs the processor and reports the final register and memory contents. Some testbenches still contain NOP instructions carried over from the first version of the processor; they remain valid because NOPs do not change processor state.

| Area | Testbenches |
| ---- | ----------- |
| Arithmetic and register operations | tb_add, tb_add_rtype, tb_move |
| Load and store | tb_lw_sw, tb_lw_sw_address |
| Multiplication | tb_mul_rtype, tb_mul_x2 |
| Data forwarding | tb_forwarding, tb_forwarding_chain, tb_sub_forwarding |
| Load-use hazard and stalls | tb_load_use_hazard, tb_dual_load_branch |
| Branches, flush and loops | tb_bne, tb_bne_x4, tb_branch_flush, tb_branch_loop, tb_loop, tb_loop_blt, tb_compare_loop, testing_loop, tb_blt |
| Programs | tb_fibonacci, tb_factorial, tb_array_sum, tb_bubble_sort |
| Compare and swap | tb_unconditional_swap, tb_compare_swap |

The bubble sort test sorts the array {40, 10, 30, 20, 50} into {10, 20, 30, 40, 50} and still places NOP instructions after load instructions.

`tb_compare_swap` reports the final register and memory values against the expected values with a PASS/FAIL result, followed by pipeline statistics: total cycles, forwarding events, pipeline stalls and pipeline flushes.

---

## Running the Simulation

1. Launch Xilinx Vivado and create a new RTL project.
2. Add all files from `Design Sources` as design sources. Exclude `tb_blt.v` and `tb_compare_swap.v` from synthesis sources and add them as simulation sources.
3. Add the required testbench from `Testbenches` as a simulation source.
4. Set the chosen testbench as the top module for simulation.
5. Run Behavioral Simulation and inspect the waveform and the console report.

---

## Development Environment

| Component | Tool |
| --------- | ---- |
| HDL | Verilog |
| Simulation | Xilinx Vivado |
| ISA | RISC-V RV32I (implemented subset) |

---

## Future Work

- Complete RV32I instruction set (JAL, JALR, LUI, AUIPC, byte and halfword memory access)
- Branch prediction
- Instruction and data caches
- UART interface
- FPGA synthesis and hardware deployment

---

## Author

**Krish Prasad**

Electronics and Communication Engineering

Contact: krishprasad.kp7@gmail.com

---

## License

This project is intended for educational, academic and research purposes. Appropriate acknowledgment is appreciated if it is used as a reference.
