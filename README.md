# 5-Stage Pipelined CPU (Verilog)

A simple pipelined CPU in Verilog with 5 stages: IF, ID, EX, MEM, WB. Supports arithmetic, logic, memory access, and branching using a simulated memory (`ram.dat`).

## Features
- Modular 5-stage pipeline
- ALU: ADD, SUB, AND, OR, SLT
- Register file: dual-read, single-write
- Auto control logic (`yC1`–`yC4`)
- Branch/jump/interrupt handling

## Run
```bash
iverilog -o cpu cpu.v pipeline.v
vvp cpu
