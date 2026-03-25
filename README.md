# Structural Verilog Arithmetic Circuit

## Overview
This repository contains the design and implementation of a digital system designed to compute the arithmetic function **$(A - B) + (C - D)$**. The project utilizes a hierarchical Verilog approach, emphasizing structural modeling to understand hardware-level computation.

The system processes four 8-bit inputs ($A, B, C, D$) received from a shared bus, stores them in registers, and outputs a 10-bit result along with a `valid` signal upon completion.

## Key Features
* **Hierarchical Design**: Follows a strict separation between **Controller** (state management and load signals) and **Datapath** (storage and arithmetic operations).
* **Structural Modeling**: Arithmetic units (adders and subtractors) are built from 1-bit full adders without using behavioral operators like `+` or `-`.
* **2's Complement Logic**: Subtraction is handled using NOT gates and XOR-based sign-bit extension for accurate negative value handling.
* **Data Recycling Loops**: Implements 2-to-1 multiplexers to maintain register states on a free-running clock without modifying internal `always` blocks.

## Architecture & Modules
| Module Name | Category | Functional Description |
| :--- | :--- | :--- |
| `project2` | Top-Level | Instantiates and routes signals between the Controller and Datapath. |
| `controller` | Control Logic | Decodes 2-bit op codes, manages operand tracking, and asserts the `valid` signal. |
| `datapath` | Datapath | Houses registers and structural arithmetic units for computation. |
| `RCA8` / `RCA9` | Arithmetic | 8-bit ripple-carry subtractors and a 9-bit ripple-carry adder. |
| `m8`, `r8`, `r10` | Routing/State | 8-bit multiplexers for data loops and arrays of 1-bit D-Flip-Flops (DFFs). |
| `my_dff`, `f_add` | Base Logic | Basic 1-bit DFF and 1-bit full adder building blocks. |

## Verification
The design was verified using RTL Analysis and functional testbenches.
* **Functional Accuracy**: Achieved a 100% functional score (60.0/60.0) on automated test suites.
* **Scenarios Covered**: Verified against continuous data loading, discontinuous data streams, and pause states.
* **Simulation**: Confirmed correct timing for synchronous result updates and `valid` signal assertion.

## Future Improvements
* **Performance**: Replace ripple-carry designs with **Carry-Lookahead Adders** to optimize critical path delay.
* **Scalability**: Parameterize the bit-width to allow the circuit to handle larger operands (e.g., 16-bit or 32-bit).

---
*Developed as part of ECE 310: Design of Complex Digital Systems.*
