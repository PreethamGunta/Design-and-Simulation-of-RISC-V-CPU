# ============================================================================
# Program: Maximum Value in an Array
# ISA subset: RV32I only  (no pseudo-instructions)
# ============================================================================
# Memory layout:
#   DMEM[0x00..0x10] (words 0-4) = array  [12, 5, 27, 8, 19]
#   DMEM[0x14]       (word 5)    = array length N  (pre-loaded: 5)
#   DMEM[0x18]       (word 6)    = output MAX  (written on completion)
#
# Register allocation:
#   x1 = current array element byte pointer  (starts at 0x00)
#   x2 = array length N  (loaded from DMEM[0x14])
#   x3 = running maximum value
#   x4 = loop index i  (starts at 1; index 0 is used to seed max_val)
#   x5 = current element arr[i]
#
# Algorithm: initialise max_val = arr[0], then iterate i=1..N-1.
#   At each step, if arr[i] > max_val, update max_val.
#
# Expected result:  MAX([12, 5, 27, 8, 19]) = 27 = 0x1B
# ============================================================================

.text
.globl main

main:
    addi x1, x0, 0          # x1 = &arr[0]  (byte address 0x00)
    lw   x2, 20(x0)         # x2 = N = DMEM[0x14]  (5)
    lw   x3, 0(x1)          # x3 = max_val = arr[0]  (12)
    addi x4, x0, 1          # i = 1  (first element already used to seed max)
    addi x1, x1, 4          # x1 = &arr[1]

loop_max:
    bge  x4, x2, done_max   # if i >= N  exit
    lw   x5, 0(x1)          # x5 = arr[i]
    bge  x3, x5, skip_upd   # if max_val >= arr[i]  skip update
    add  x3, x5, x0         # max_val = arr[i]

skip_upd:
    addi x1, x1, 4          # advance pointer to &arr[i+1]
    addi x4, x4, 1          # i++
    jal  x0, loop_max       # repeat

done_max:
    sw   x3, 24(x0)         # DMEM[0x18] = max_val  (27 = 0x1B)

halt_max:
    jal  x0, halt_max       # halt: infinite self-loop


# ============================================================================
# Disassembly (assembler-generated; matches imem.hex exactly)
# ============================================================================
# PC      Hex         Instruction
# 0x00    00000093    addi x1 x0 0
# 0x04    01402103    lw   x2 20 x0
# 0x08    0000a183    lw   x3 0 x1
# 0x0C    00100213    addi x4 x0 1
# 0x10    00408093    addi x1 x1 4
# --- loop_max (PC=0x14) ---
# 0x14    00225e63    bge  x4 x2 +28   -> done_max  (0x30)
# 0x18    0000a283    lw   x5 0 x1
# 0x1C    0051d463    bge  x3 x5 +8    -> skip_upd  (0x24)
# 0x20    000281b3    add  x3 x5 x0
# --- skip_upd (PC=0x24) ---
# 0x24    00408093    addi x1 x1 4
# 0x28    00120213    addi x4 x4 1
# 0x2C    fe9ff06f    jal  x0 -24      -> loop_max  (0x14)
# --- done_max (PC=0x30) ---
# 0x30    00302c23    sw   x3 24 x0
# --- halt_max (PC=0x34) ---
# 0x34    0000006f    jal  x0 0        -> halt_max  (halt)

