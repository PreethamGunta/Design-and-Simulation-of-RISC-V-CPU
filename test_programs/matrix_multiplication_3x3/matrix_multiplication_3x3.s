# ============================================================================
# Program: 3x3 Matrix Multiplication  (C = A * B)  [Bonus]
# ISA subset: RV32I + MUL  (no pseudo-instructions)
# ============================================================================
# Matrices stored in DMEM in row-major order (row stride = 3 * 4 = 12 bytes):
#   Matrix A  base = 0x00       (x1)  words 0x00-0x08  (elements 1..9)
#   Matrix B  base = 0x24 = 36  (x2)  words 0x09-0x11  (elements 9..1)
#   Matrix C  base = 0x48 = 72  (x3)  words 0x12-0x1A  (results)
#
# Register allocation:
#   x1  = base byte address of Matrix A (0x00)
#   x2  = base byte address of Matrix B (0x24 = 36)
#   x3  = running write pointer for Matrix C (starts at 0x48 = 72)
#   x4  = matrix dimension N = 3
#   x5  = outer loop row index i  (0..2)
#   x6  = middle loop column index j  (0..2)
#   x7  = inner dot-product index k  (0..2)
#   x8  = accumulator (sum) for C[i][j]
#   x9  = row pointer for A  (&A[i][0]; steps +12 bytes per row)
#   x10 = element pointer for A[i][k]  (steps +4 bytes per k)
#   x11 = element pointer for B[k][j]  (steps +12 bytes per k; one row stride)
#   x12 = loaded value A[i][k]
#   x13 = loaded value B[k][j]
#   x14 = product A[i][k] * B[k][j]
#   x15 = column byte offset for B  (j * 4; steps +4 bytes per j)
# ============================================================================

.text
.globl main

main:
    addi x1, x0, 0          # x1 = base address of A (0x00)
    addi x2, x0, 36         # x2 = base address of B (0x24)
    addi x3, x0, 72         # x3 = write pointer for C (0x48)
    addi x4, x0, 3          # x4 = N = 3 (loop bound)
    addi x5, x0, 0          # i = 0
    add  x9, x1, x0         # x9 = &A[0][0]

loop_i_3x3:
    bge  x5, x4, done_3x3   # if i >= 3 exit
    addi x6, x0, 0          # j = 0
    addi x15, x0, 0         # col_B_offset = 0

loop_j_3x3:
    bge  x6, x4, next_i_3x3 # if j >= 3 advance to next row of A
    addi x8, x0, 0          # sum = 0
    addi x7, x0, 0          # k = 0
    add  x10, x9, x0        # x10 = &A[i][0]
    add  x11, x2, x15       # x11 = &B[0][j]

loop_k_3x3:
    bge  x7, x4, store_c_3x3 # if k >= 3 write result
    lw   x12, 0(x10)         # x12 = A[i][k]
    lw   x13, 0(x11)         # x13 = B[k][j]
    mul  x14, x12, x13       # x14 = A[i][k] * B[k][j]
    add  x8, x8, x14         # sum += product
    addi x10, x10, 4         # advance A pointer across row i
    addi x11, x11, 12        # advance B pointer down column j  (row stride = 12)
    addi x7, x7, 1           # k++
    jal  x0, loop_k_3x3     # repeat inner loop

store_c_3x3:
    sw   x8, 0(x3)           # DMEM[x3] = sum  (write C[i][j])
    addi x3, x3, 4           # advance C write pointer
    addi x15, x15, 4         # next column of B
    addi x6, x6, 1           # j++
    jal  x0, loop_j_3x3     # repeat middle loop

next_i_3x3:
    addi x9, x9, 12          # advance A row pointer  (row stride = 12 bytes)
    addi x5, x5, 1           # i++
    jal  x0, loop_i_3x3     # repeat outer loop

done_3x3:
    jal  x0, done_3x3        # halt: infinite self-loop


# ============================================================================
# Disassembly (assembler-generated; matches imem.hex exactly)
# ============================================================================
# PC      Hex         Instruction
# 0x00    00000093    addi x1 x0 0
# 0x04    02400113    addi x2 x0 36
# 0x08    04800193    addi x3 x0 72
# 0x0C    00300213    addi x4 x0 3
# 0x10    00000293    addi x5 x0 0
# 0x14    000084b3    add  x9 x1 x0
# --- loop_i_3x3 (PC=0x18) ---
# 0x18    0642d263    bge  x5 x4 +100  -> done_3x3   (0x7C)
# 0x1C    00000313    addi x6 x0 0
# 0x20    00000793    addi x15 x0 0
# --- loop_j_3x3 (PC=0x24) ---
# 0x24    04435663    bge  x6 x4 +76   -> next_i_3x3 (0x70)
# 0x28    00000413    addi x8 x0 0
# 0x2C    00000393    addi x7 x0 0
# 0x30    00048533    add  x10 x9 x0
# 0x34    00f105b3    add  x11 x2 x15
# --- loop_k_3x3 (PC=0x38) ---
# 0x38    0243d263    bge  x7 x4 +36   -> store_c_3x3 (0x5C)
# 0x3C    00052603    lw   x12 0 x10
# 0x40    0005a683    lw   x13 0 x11
# 0x44    02d60733    mul  x14 x12 x13
# 0x48    00e40433    add  x8 x8 x14
# 0x4C    00450513    addi x10 x10 4
# 0x50    00c58593    addi x11 x11 12        # <-- differs from 2x2 (was 8, now 12)
# 0x54    00138393    addi x7 x7 1
# 0x58    fe1ff06f    jal  x0 -32      -> loop_k_3x3  (0x38)
# --- store_c_3x3 (PC=0x5C) ---
# 0x5C    0081a023    sw   x8 0 x3
# 0x60    00418193    addi x3 x3 4
# 0x64    00478793    addi x15 x15 4
# 0x68    00130313    addi x6 x6 1
# 0x6C    fb9ff06f    jal  x0 -72      -> loop_j_3x3  (0x24)
# --- next_i_3x3 (PC=0x70) ---
# 0x70    00c48493    addi x9 x9 12          # <-- differs from 2x2 (was 8, now 12)
# 0x74    00128293    addi x5 x5 1
# 0x78    fa1ff06f    jal  x0 -96      -> loop_i_3x3  (0x18)
# --- done_3x3 (PC=0x7C) ---
# 0x7C    0000006f    jal  x0 0        -> done_3x3    (halt)

