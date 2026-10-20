# ============================================================================
# Program: Sum of First N Natural Numbers  (1 + 2 + ... + N)
# ISA subset: RV32I only  (no pseudo-instructions)
# ============================================================================
# Memory layout:
#   DMEM[0x00] (word 0) = input N  (pre-loaded: N = 10)
#   DMEM[0x04] (word 1) = output sum  (written on completion)
#
# Register allocation:
#   x1 = N  (loaded from DMEM[0x00])
#   x2 = loop counter i  (1..N)
#   x3 = running sum (accumulator)
#
# Expected result:  sum(1..10) = 55 = 0x37
# ============================================================================

.text
.globl main

main:
    lw   x1, 0(x0)          # x1 = N = DMEM[0x00]  (10)
    addi x2, x0, 1          # i = 1
    addi x3, x0, 0          # sum = 0

loop_sum:
    blt  x1, x2, done_sum   # if N < i  exit loop  (all N terms added)
    add  x3, x3, x2         # sum += i
    addi x2, x2, 1          # i++
    jal  x0, loop_sum       # repeat

done_sum:
    sw   x3, 4(x0)          # DMEM[0x04] = sum  (55 = 0x37)

halt_sum:
    jal  x0, halt_sum       # halt: infinite self-loop


# ============================================================================
# Disassembly (assembler-generated; matches imem.hex exactly)
# ============================================================================
# PC      Hex         Instruction
# 0x00    00002083    lw   x1 0 x0
# 0x04    00100113    addi x2 x0 1
# 0x08    00000193    addi x3 x0 0
# --- loop_sum (PC=0x0C) ---
# 0x0C    0020c863    blt  x1 x2 +16   -> done_sum  (0x1C)
# 0x10    002181b3    add  x3 x3 x2
# 0x14    00110113    addi x2 x2 1
# 0x18    ff5ff06f    jal  x0 -12      -> loop_sum  (0x0C)
# --- done_sum (PC=0x1C) ---
# 0x1C    00302223    sw   x3 4 x0
# --- halt_sum (PC=0x20) ---
# 0x20    0000006f    jal  x0 0        -> halt_sum  (halt)

