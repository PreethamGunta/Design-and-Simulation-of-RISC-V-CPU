# ============================================================================
# Program: 2x2 Matrix Multiplication  (C = A * B)
# ISA subset: RV32I + MUL  (no pseudo-instructions)
# ============================================================================
# Matrices stored in DMEM in row-major order:
#   Matrix A  base = 0x00  (x1)  words 0x00-0x03
#   Matrix B  base = 0x10  (x2)  words 0x04-0x07
#   Matrix C  base = 0x20  (x3)  words 0x08-0x0B
#
# Register allocation:
#   x1  = base byte address of Matrix A (0x00)
#   x2  = base byte address of Matrix B (0x10 = 16)
#   x3  = running write pointer for Matrix C (starts at 0x20 = 32)
#   x4  = matrix dimension N = 2
#   x5  = outer loop row index i  (0..1)
#   x6  = middle loop column index j  (0..1)
#   x7  = inner dot-product index k  (0..1)
#   x8  = accumulator (sum) for C[i][j]
#   x9  = row pointer for A  (&A[i][0]; steps +8 bytes per row)
#   x10 = element pointer for A[i][k]  (steps +4 bytes per k)
#   x11 = element pointer for B[k][j]  (steps +8 bytes per k; one row stride)
#   x12 = loaded value A[i][k]
#   x13 = loaded value B[k][j]
#   x14 = product A[i][k] * B[k][j]
#   x15 = column byte offset for B  (j * 4; steps +4 bytes per j)
# ============================================================================

.text
.globl main

main:
    addi x1, x0, 0          # x1 = base address of A (0x00)
    addi x2, x0, 16         # x2 = base address of B (0x10)
    addi x3, x0, 32         # x3 = write pointer for C (0x20)
    addi x4, x0, 2          # x4 = N = 2 (loop bound)
    addi x5, x0, 0          # i = 0
    add  x9, x1, x0         # x9 = &A[0][0]

loop_i:
    bge  x5, x4, done        # if i >= 2 exit
    addi x6, x0, 0           # j = 0
    addi x15, x0, 0          # col_B_offset = 0

loop_j:
    bge  x6, x4, next_i      # if j >= 2 advance to next row of A
    addi x8, x0, 0           # sum = 0  (accumulator for C[i][j])
    addi x7, x0, 0           # k = 0
    add  x10, x9, x0         # x10 = &A[i][0]
    add  x11, x2, x15        # x11 = &B[0][j]  (base_B + j*4)

loop_k:
    bge  x7, x4, store_c     # if k >= 2 write result
    lw   x12, 0(x10)         # x12 = A[i][k]
    lw   x13, 0(x11)         # x13 = B[k][j]
    mul  x14, x12, x13       # x14 = A[i][k] * B[k][j]
    add  x8, x8, x14         # sum += product
    addi x10, x10, 4         # advance A pointer across row i
    addi x11, x11, 8         # advance B pointer down column j  (row stride = 8)
    addi x7, x7, 1           # k++
    jal  x0, loop_k          # repeat inner loop

store_c:
    sw   x8, 0(x3)           # DMEM[x3] = sum  (write C[i][j])
    addi x3, x3, 4           # advance C write pointer
    addi x15, x15, 4         # next column of B  (col_B_offset += 4)
    addi x6, x6, 1           # j++
    jal  x0, loop_j          # repeat middle loop

next_i:
    addi x9, x9, 8           # advance A row pointer  (row stride = 8 bytes)
    addi x5, x5, 1           # i++
    jal  x0, loop_i          # repeat outer loop

done:
    jal  x0, done            # halt: infinite self-loop  (encodes as jal x0, 0)


# ============================================================================
# Disassembly (assembler-generated; matches imem.hex exactly)
# ============================================================================
# PC      Hex         Instruction
# 0x00    00000093    addi x1 x0 0
# 0x04    01000113    addi x2 x0 16
# 0x08    02000193    addi x3 x0 32
# 0x0C    00200213    addi x4 x0 2
# 0x10    00000293    addi x5 x0 0
# 0x14    000084b3    add  x9 x1 x0
# --- loop_i (PC=0x18) ---
# 0x18    0642d263    bge  x5 x4 +100  -> done   (0x7C)
# 0x1C    00000313    addi x6 x0 0
# 0x20    00000793    addi x15 x0 0
# --- loop_j (PC=0x24) ---
# 0x24    04435663    bge  x6 x4 +76   -> next_i  (0x70)
# 0x28    00000413    addi x8 x0 0
# 0x2C    00000393    addi x7 x0 0
# 0x30    00048533    add  x10 x9 x0
# 0x34    00f105b3    add  x11 x2 x15
# --- loop_k (PC=0x38) ---
# 0x38    0243d263    bge  x7 x4 +36   -> store_c (0x5C)
# 0x3C    00052603    lw   x12 0 x10
# 0x40    0005a683    lw   x13 0 x11
# 0x44    02d60733    mul  x14 x12 x13
# 0x48    00e40433    add  x8 x8 x14
# 0x4C    00450513    addi x10 x10 4
# 0x50    00858593    addi x11 x11 8
# 0x54    00138393    addi x7 x7 1
# 0x58    fe1ff06f    jal  x0 -32      -> loop_k  (0x38)
# --- store_c (PC=0x5C) ---
# 0x5C    0081a023    sw   x8 0 x3
# 0x60    00418193    addi x3 x3 4
# 0x64    00478793    addi x15 x15 4
# 0x68    00130313    addi x6 x6 1
# 0x6C    fb9ff06f    jal  x0 -72      -> loop_j  (0x24)
# --- next_i (PC=0x70) ---
# 0x70    00848493    addi x9 x9 8
# 0x74    00128293    addi x5 x5 1
# 0x78    fa1ff06f    jal  x0 -96      -> loop_i  (0x18)
# --- done (PC=0x7C) ---
# 0x7C    0000006f    jal  x0 0        -> done     (halt)

