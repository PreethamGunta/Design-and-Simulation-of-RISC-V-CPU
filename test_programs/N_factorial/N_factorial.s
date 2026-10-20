# ============================================================================
# Program: Factorial of N  (N! using MUL)
# ISA subset: RV32I + MUL  (no pseudo-instructions)
# ============================================================================
# Memory layout:
#   DMEM[0x00] (word 0) = input N    (pre-loaded: N = 6)
#   DMEM[0x04] (word 1) = output N!  (written on completion)
#
# Register allocation:
#   x1 = N  (loaded from DMEM[0x00])
#   x2 = loop counter i  (1..N)
#   x3 = running factorial product  (initialised to 1)
#
# Algorithm: fact = 1; for i = 1..N: fact *= i
#
# Expected result:  6! = 720 = 0x2D0
# ============================================================================

.text
.globl main

main:
    lw   x1, 0(x0)          # x1 = N = DMEM[0x00]  (6)
    addi x2, x0, 1          # i = 1
    addi x3, x0, 1          # fact = 1

loop_fact:
    blt  x1, x2, done_fact  # if N < i  exit loop
    mul  x3, x3, x2         # fact = fact * i
    addi x2, x2, 1          # i++
    jal  x0, loop_fact      # repeat

done_fact:
    sw   x3, 4(x0)          # DMEM[0x04] = fact  (720 = 0x2D0)

halt_fact:
    jal  x0, halt_fact      # halt: infinite self-loop


# ============================================================================
# Disassembly (assembler-generated; matches imem.hex exactly)
# ============================================================================
# PC      Hex         Instruction
# 0x00    00002083    lw   x1 0 x0
# 0x04    00100113    addi x2 x0 1
# 0x08    00100193    addi x3 x0 1
# --- loop_fact (PC=0x0C) ---
# 0x0C    0020c863    blt  x1 x2 +16   -> done_fact  (0x1C)
# 0x10    022181b3    mul  x3 x3 x2
# 0x14    00110113    addi x2 x2 1
# 0x18    ff5ff06f    jal  x0 -12      -> loop_fact  (0x0C)
# --- done_fact (PC=0x1C) ---
# 0x1C    00302223    sw   x3 4 x0
# --- halt_fact (PC=0x20) ---
# 0x20    0000006f    jal  x0 0        -> halt_fact  (halt)

