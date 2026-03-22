# 32-bit RISC-V Processor (RV32I)

## Overview and Scope

This project is a Verilog implementation of a 32-bit RISC-V processor that fully supports the RV32I Base Integer Instruction Set.

While a standard single-cycle processor utilizes a Harvard architecture (separate instruction and data memory ports), the interface provided for this project strictly defines a unified memory port (Von Neumann architecture). To successfully fetch instructions and read/write data over this single shared bus without structural hazards, this design implements a highly efficient multi-cycle architecture driven by a 3-state Finite State Machine (FSM).

---

## Features

- **Full RV32I base integer ISA support**  
  (excluding system instructions like `ecall` and `ebreak`)

- **3-state FSM**  
  Safely multiplexes instruction fetch and data memory access over a single unified bus

- **Word-addressable Program Counter**  
  PC increments by 1 internally and is automatically shifted for byte-addressable ALU calculations and branch targets

- **Flexible Memory Access**  
  Supports byte, halfword, and word operations with correct sign and zero extensions via a dedicated combinational load formatter

- **Modular Datapath Design**  
  Uses discrete sub-modules (ALU, Register File, Branch Comparator, Control Unit)

- **Register x0 Hardwired to Zero**

- **Memory Handshaking Support**  
  Active-high signals:
  - `mem_rbusy` (read busy)
  - `mem_wbusy` (write busy)  
  Enables handling of variable memory latency

---

## FSM Design

The core execution is governed by a 3-state machine ensuring memory stability and preventing instruction corruption.

### STATE_FETCH (0)
- Places PC on `mem_addr`
- Asserts `mem_rstrb` to initiate instruction fetch
- Waits until memory is ready
- Transitions to `STATE_EXEC`

### STATE_EXEC (1)
- Instruction is available on `mem_rdata`
- Instruction is decoded and executed

#### Behavior:
- **Arithmetic, Branch, Jump**
  - ALU computes result
  - Register file writes back
  - PC updates
  - Transition → `STATE_FETCH`

- **Store**
  - Compute memory address
  - Generate byte offset and `mem_wmask`
  - Drive shifted `mem_wdata`
  - Update PC
  - Transition → `STATE_FETCH`

- **Load**
  - Compute memory address
  - Assert `mem_rstrb`
  - Latch instruction internally (to avoid overwrite)
  - Transition → `STATE_LOAD`

### STATE_LOAD (2)
- Waits for memory data
- Formats `mem_rdata` (sign/zero extension)
- Writes result to destination register
- Increments PC
- Transition → `STATE_FETCH`

---

## Supported Instructions

| Category              | Instructions |
|----------------------|-------------|
| **R-type**           | ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU |
| **I-type**           | ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU |
| **Load**             | LB, LH, LW, LBU, LHU |
| **Store**            | SB, SH, SW |
| **Branch**           | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| **Jump**             | JAL, JALR |
| **Upper Immediate**  | LUI, AUIPC |

---

## Memory Interface

- `mem_addr`  
  Memory address (PC during fetch, ALU result >> 2 during load/store)

- `mem_rstrb`  
  Read strobe (active during fetch and load)

- `mem_rdata`  
  Data returned from memory

- `mem_wdata`  
  Write data (byte-shifted based on address offset)

- `mem_wmask`  
  Byte enable mask:
  - `0001` → SB  
  - `0011` → SH  
  - `1111` → SW  
  (shifted by offset)

- `mem_rbusy`  
  Active-high signal indicating read not ready

- `mem_wbusy`  
  Active-high signal indicating write not complete

---

## File Structure

- `24116022_riscv.v`  
  Top-level datapath, FSM, memory routing, and load formatter

- `alu.v`  
  Arithmetic Logic Unit

- `regfile.v`  
  32 × 32-bit Register File

- `imm_gen.v`  
  Immediate Generator for decoding and sign-extension

- `branch_comp.v`  
  Dedicated Branch Comparator

- `control_unit.v`  
  Instruction decoder and control signal generator

- `riscv_testbench.v`  
  Comprehensive validation suite for arithmetic, logic, memory, and branching

---

## Usage and Simulation

Ensure **Icarus Verilog (`iverilog`)** is installed.

### Compile

```bash
iverilog -o riscv_sim 24116022_riscv.v riscv_testbench.v
````

### Run Simulation

```bash
vvp riscv_sim
```
