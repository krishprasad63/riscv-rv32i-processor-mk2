# RISC-V 32-bit Pipelined Processor (Verilog)

A modular **32-bit RISC-V Pipelined Processor** implemented in **Verilog HDL**, following a classic five-stage pipeline architecture. This project is designed as an educational and learning-oriented implementation of a subset of the **RV32I Instruction Set Architecture (ISA)**, with a focus on understanding processor organization, pipelining, instruction execution, and hardware verification.

Each hardware component is implemented as an independent Verilog module, making the design easy to understand, modify, verify, and extend. The repository also includes a comprehensive collection of simulation testbenches covering arithmetic operations, branching, memory operations, multiplication, loops, and array-based programs.

The project has been developed and verified using **Xilinx Vivado**.

---

# Features

- 32-bit RISC-V Processor
- Five-stage pipelined architecture
- Modular Verilog implementation
- RV32I instruction subset implementation
- Register File
- ALU supporting arithmetic and logical operations
- Shift-and-Add Multiplier
- Branch instruction support
- Load and Store instructions
- Pipeline registers between stages
- Modular control unit
- Instruction memory
- Comprehensive simulation testbenches
- Developed and simulated using **Xilinx Vivado**

---

# Pipeline Architecture

The processor follows the standard five-stage pipeline:

```
Instruction Fetch (IF)
        │
        ▼
Instruction Decode (ID)
        │
        ▼
Execute (EX)
        │
        ▼
Memory Access (MEM)
        │
        ▼
Write Back (WB)
```

Each stage is separated using dedicated pipeline registers.

---

# Repository Structure

```
Design Sources/
│
├── alu_riscv.v
├── control_unit.v
├── decode_stage.v
├── execute_stage.v
├── ex_mem_register.v
├── fetch_stage.v
├── id_ex_register.v
├── if_id_register.v
├── instruction_memory.v
├── mem_wb_register.v
├── memory_stage.v
├── program_counter.v
├── riscv.v
└── shift_add_mul.v


Testbenches/
│
├── tb_add.v
├── tb_add_rtype.v
├── tb_array_sum.v
├── tb_bne.v
├── tb_bne_x4.v
├── tb_branch_loop.v
├── tb_factorial.v
├── tb_fibonacci.v
├── tb_loop.v
├── tb_lw_sw.v
├── tb_lw_sw_address.v
├── tb_move.v
├── tb_mul_rtype.v
├── tb_mul_x2.v
├── tb_riscv.v
└── testing_loop.v
```

---

# Processor Modules

The processor is organized into independent hardware modules.

- Program Counter
- Instruction Fetch Stage
- Instruction Decode Stage
- Execute Stage
- Memory Stage
- Write Back Stage
- Instruction Memory
- Register File
- Arithmetic Logic Unit (ALU)
- Shift-and-Add Multiplier
- Control Unit
- IF/ID Pipeline Register
- ID/EX Pipeline Register
- EX/MEM Pipeline Register
- MEM/WB Pipeline Register

---

# Supported Instructions

The current implementation supports a subset of the RV32I ISA including:

### Arithmetic Instructions

- ADD
- ADDI
- SUB

### Logical Instructions

- AND
- OR
- XOR
- NOR

### Shift Instructions

- SLL
- SRL
- SRA

### Comparison

- SLT

### Memory Operations

- LW
- SW

### Branch Instructions

- BEQ
- BNE
- BLT
- BGE

### Multiplication

- MUL (implemented using Shift-and-Add multiplication)

---

# Included Test Programs

The repository contains dedicated testbenches for validating different processor functionalities.

Current test programs include:

- Arithmetic Operations
- Register-to-Register Operations
- Load Instruction
- Store Instruction
- Load/Store Address Verification
- Move Operations
- Branch Instructions
- Branch Loops
- Multiplication
- Fibonacci Sequence
- Factorial
- Array Sum

Each testbench focuses on verifying a specific processor feature and includes simulation outputs for functional validation.

---

# About the Testbenches

The current processor implementation **does not yet include hardware-based hazard handling mechanisms**, such as:

- Data Forwarding
- Hazard Detection Unit
- Pipeline Stall Logic

As a result, several test programs intentionally include **NOP (No Operation)** instructions to ensure correct execution within the pipelined architecture.

A NOP performs no operation and does not modify the processor state.

In RISC-V, the NOP instruction used throughout this project is:

```assembly
nop
```

Machine code:

```
0x00000013
```

These NOP instructions introduce deliberate delay between dependent instructions, allowing previous instructions to complete all required pipeline stages before their results are used by subsequent instructions.

For example,

```assembly
addi x1, x0, 10
nop
nop
nop
nop
sw x1, 0(x0)
```

The inserted NOPs allow the `addi` instruction to complete its Write-Back stage before the `sw` instruction reads the updated value from the register file.

Similarly, NOPs are inserted after:

- Arithmetic instructions whose results are immediately reused.
- Load (`lw`) instructions before dependent instructions.
- Instructions that could otherwise introduce Read-After-Write (RAW) hazards in the current implementation.

This software scheduling approach is commonly adopted during the initial stages of processor development before hardware hazard handling mechanisms are introduced.

Future versions of this processor are planned to include:

- Data Forwarding Unit
- Hazard Detection Unit
- Pipeline Stall Logic

Once these features are implemented, programs will execute correctly without requiring manually inserted NOP instructions.

---

# Getting Started

## Clone the Repository

```bash
git clone https://github.com/<your-username>/<repository-name>.git
```

---

## Open the Project

1. Launch **Xilinx Vivado**.
2. Create a new RTL Project.
3. Add all files from the **Design Sources** directory.
4. Add the required testbench from the **Testbenches** directory under Simulation Sources.
5. Set the desired testbench as the **Top Module**.
6. Run **Behavioral Simulation**.

---

# Reusing the Design

The project has been developed using a modular architecture, allowing individual hardware blocks or the complete processor to be integrated into other Verilog-based projects.

Users who wish to study, modify, extend, or build upon this implementation may:

- Reuse individual modules as standalone hardware components.
- Integrate the processor into larger digital system designs.
- Extend the supported instruction set.
- Add pipeline hazard handling mechanisms.
- Implement forwarding and stalling logic.
- Target FPGA hardware after functional verification.

Because every pipeline stage is implemented as an independent module, the design can be easily customized without affecting the overall project organization.

---

# Development Environment

| Component | Tool |
|----------|------|
| HDL | Verilog |
| Simulation | Xilinx Vivado |
| Processor ISA | RISC-V RV32I (Implemented Subset) |

---

# Future Work

Planned enhancements include:

- Complete RV32I Instruction Set support
- Data Forwarding
- Hazard Detection Unit
- Pipeline Stall Logic
- Branch Prediction
- Instruction Cache
- Data Cache
- UART Interface
- FPGA Deployment
- Performance Optimization

---

# Author

**Krish Prasad**

ECE Enthusiast

For queries, suggestions, or collaboration:

📧 **krishprasad.kp7@gmail.com**

---

# License

This project is intended for educational, academic, and research purposes.

If you find this repository useful for learning or as a reference for your own work, appropriate acknowledgment is appreciated.