# RISC-V CPU: Machine Code Encoding — 2×2 Matrix Multiplication

## Overview

This document shows how the 32-instruction assembly program for 2×2 matrix
multiplication is encoded into 32-bit RISC-V machine words. Each instruction's
bit fields are broken down according to its format, and the resulting 32-bit hex
value is derived from the encoding rules in Section 1 and cross-checked against
the assembler output.

---

## 1. Instruction Encoding Formats

Each RISC-V instruction is exactly 32 bits wide. The five formats used in this
program are:

```
R-Type:  funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7]  | opcode[6:0]
I-Type:  imm[11:0][31:20]           | rs1[19:15] | funct3[14:12] | rd[11:7]  | opcode[6:0]
S-Type:  imm[11:5][31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[4:0][11:7] | opcode[6:0]
B-Type:  imm[12|10:5][31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[4:1|11][11:7] | opcode[6:0]
J-Type:  imm[20|10:1|11|19:12][31:12]                              | rd[11:7]  | opcode[6:0]
```

The B-type and J-type immediate bit positions in the instruction word are
scrambled relative to their logical position; the encoding always places the
sign bit at `instr[31]` regardless of format.

---

## 2. Opcodes and Function Codes Used

| Instruction | Format | `opcode` | `funct3` | `funct7` |
|-------------|--------|----------|----------|----------|
| `ADDI`      | I      | `0010011` | `000`   | —        |
| `ADD`       | R      | `0110011` | `000`   | `0000000` |
| `MUL`       | R      | `0110011` | `000`   | `0000001` |
| `LW`        | I      | `0000011` | `010`   | —        |
| `SW`        | S      | `0100011` | `010`   | —        |
| `BGE`       | B      | `1100011` | `101`   | —        |
| `JAL`       | J      | `1101111` | —       | —        |

---

## 3. Complete Instruction Encoding Table

### Encoding key fields as binary values

All register numbers are 5-bit binary. Immediates are given as sign-extended
values. Branch and jump offsets are **signed byte offsets from the current PC**
(always a multiple of 2; bit 0 is implicitly 0).

---

### Initialisation block (PC `0x00`–`0x14`)

**`addi x1, x0, 0`** — I-Type — PC `0x00`

```
imm[11:0]    rs1     funct3  rd      opcode
000000000000 00000   000     00001   0010011
```
`0x00000093`

---

**`addi x2, x0, 16`** — I-Type — PC `0x04`

```
imm[11:0]    rs1     funct3  rd      opcode
000000010000 00000   000     00010   0010011
```
`0x01000113`

Immediate 16 = `0b000000010000` occupies `instr[31:20]`.

---

**`addi x3, x0, 32`** — I-Type — PC `0x08`

```
imm[11:0]    rs1     funct3  rd      opcode
000000100000 00000   000     00011   0010011
```
`0x02000193`

---

**`addi x4, x0, 2`** — I-Type — PC `0x0C`

```
imm[11:0]    rs1     funct3  rd      opcode
000000000010 00000   000     00100   0010011
```
`0x00200213`

---

**`addi x5, x0, 0`** — I-Type — PC `0x10`

```
imm[11:0]    rs1     funct3  rd      opcode
000000000000 00000   000     00101   0010011
```
`0x00000293`

---

**`add x9, x1, x0`** — R-Type — PC `0x14`

```
funct7   rs2     rs1     funct3  rd      opcode
0000000  00000   00001   000     01001   0110011
```
`0x000084B3`

---

### Outer loop — `loop_i` (PC `0x18`–`0x20`)

**`bge x5, x4, done`** — B-Type — PC `0x18`

Target: `done` at `0x7C`. Offset = `0x7C − 0x18` = **+100** bytes.

```
100 = 0b01100100
imm[12]=0  imm[11]=0  imm[10:5]=000011  imm[4:1]=0010  imm[0]=0(implicit)

[31]   [30:25]   [24:20]  [19:15]  [14:12]  [11:8]  [7]    [6:0]
 0     000011    00100    00101    101      0010    0      1100011
```
`0x0642D263`

---

**`addi x6, x0, 0`** — I-Type — PC `0x1C`

`0x00000313`

---

**`addi x15, x0, 0`** — I-Type — PC `0x20`

`0x00000793`

---

### Middle loop — `loop_j` (PC `0x24`–`0x34`)

**`bge x6, x4, next_i`** — B-Type — PC `0x24`

Target: `next_i` at `0x70`. Offset = `0x70 − 0x24` = **+76** bytes.

```
76 = 0b01001100
imm[12]=0  imm[11]=0  imm[10:5]=000010  imm[4:1]=0110

[31]   [30:25]   [24:20]  [19:15]  [14:12]  [11:8]  [7]    [6:0]
 0     000010    00100    00110    101      0110    0      1100011
```
`0x04435663`

---

**`addi x8, x0, 0`** — I-Type — PC `0x28`

`0x00000413`

---

**`addi x7, x0, 0`** — I-Type — PC `0x2C`

`0x00000393`

---

**`add x10, x9, x0`** — R-Type — PC `0x30`

```
funct7   rs2     rs1     funct3  rd      opcode
0000000  00000   01001   000     01010   0110011
```
`0x00048533`

---

**`add x11, x2, x15`** — R-Type — PC `0x34`

```
funct7   rs2     rs1     funct3  rd      opcode
0000000  01111   00010   000     01011   0110011
```
`0x00F105B3`

---

### Inner loop — `loop_k` (PC `0x38`–`0x58`)

**`bge x7, x4, store_c`** — B-Type — PC `0x38`

Target: `store_c` at `0x5C`. Offset = `0x5C − 0x38` = **+36** bytes.

```
36 = 0b00100100
imm[12]=0  imm[11]=0  imm[10:5]=000001  imm[4:1]=0010

[31]   [30:25]   [24:20]  [19:15]  [14:12]  [11:8]  [7]    [6:0]
 0     000001    00100    00111    101      0010    0      1100011
```
`0x0243D263`

---

**`lw x12, 0(x10)`** — I-Type — PC `0x3C`

```
imm[11:0]    rs1     funct3  rd      opcode
000000000000 01010   010     01100   0000011
```
`0x00052603`

---

**`lw x13, 0(x11)`** — I-Type — PC `0x40`

```
imm[11:0]    rs1     funct3  rd      opcode
000000000000 01011   010     01101   0000011
```
`0x0005A683`

---

**`mul x14, x12, x13`** — R-Type — PC `0x44`

`MUL` uses `funct7 = 0000001` (RV32M) to distinguish it from `ADD` which shares
`funct3 = 000` and `opcode = 0110011`.

```
funct7   rs2     rs1     funct3  rd      opcode
0000001  01101   01100   000     01110   0110011
```
`0x02D60733`

---

**`add x8, x8, x14`** — R-Type — PC `0x48`

```
funct7   rs2     rs1     funct3  rd      opcode
0000000  01110   01000   000     01000   0110011
```
`0x00E40433`

---

**`addi x10, x10, 4`** — I-Type — PC `0x4C`

```
imm[11:0]    rs1     funct3  rd      opcode
000000000100 01010   000     01010   0010011
```
`0x00450513`

---

**`addi x11, x11, 8`** — I-Type — PC `0x50`

```
imm[11:0]    rs1     funct3  rd      opcode
000000001000 01011   000     01011   0010011
```
`0x00858593`

B pointer advances 8 bytes (one 2-element row of B in the 2×2 program).

---

**`addi x7, x7, 1`** — I-Type — PC `0x54`

`0x00138393`

---

**`jal x0, loop_k`** — J-Type — PC `0x58`

Target: `loop_k` at `0x38`. Offset = `0x38 − 0x58` = **−32** bytes.

```
−32 in 21-bit two's complement = 1_11111111_1_1111100000

imm[20]=1  imm[19:12]=11111111  imm[11]=1  imm[10:1]=1111110000  imm[0]=0

[31]  [30:21]     [20]  [19:12]   [11:7]  [6:0]
 1    1111110000   1    11111111  00000   1101111
```
`0xFE1FF06F`

---

### `store_c` block (PC `0x5C`–`0x6C`)

**`sw x8, 0(x3)`** — S-Type — PC `0x5C`

Immediate = 0, split as `imm[11:5] = 0000000`, `imm[4:0] = 00000`.

```
imm[11:5]  rs2     rs1     funct3  imm[4:0]  opcode
0000000    01000   00011   010     00000     0100011
```
`0x0081A023`

---

**`addi x3, x3, 4`** — I-Type — PC `0x60`

`0x00418193`

---

**`addi x15, x15, 4`** — I-Type — PC `0x64`

`0x00478793`

---

**`addi x6, x6, 1`** — I-Type — PC `0x68`

`0x00130313`

---

**`jal x0, loop_j`** — J-Type — PC `0x6C`

Target: `loop_j` at `0x24`. Offset = `0x24 − 0x6C` = **−72** bytes.

`0xFB9FF06F`

---

### `next_i` block (PC `0x70`–`0x78`)

**`addi x9, x9, 8`** — I-Type — PC `0x70`

A row pointer advances 8 bytes (one 2-element row of A).

`0x00848493`

---

**`addi x5, x5, 1`** — I-Type — PC `0x74`

`0x00128293`

---

**`jal x0, loop_i`** — J-Type — PC `0x78`

Target: `loop_i` at `0x18`. Offset = `0x18 − 0x78` = **−96** bytes.

`0xFA1FF06F`

---

### `done` — halt (PC `0x7C`)

**`jal x0, done`** — J-Type — PC `0x7C`

Offset = `0x7C − 0x7C` = **0** (self-loop). `rd = x0` so no return address is saved.

```
imm[20|10:1|11|19:12] = all zeros,  rd=00000,  opcode=1101111
```
`0x0000006F`

---

## 4. Summary Table

| PC | Assembly | Fmt | Hex |
|:---:|:---|:---:|:---:|
| `0x00` | `addi x1, x0, 0` | I | `00000093` |
| `0x04` | `addi x2, x0, 16` | I | `01000113` |
| `0x08` | `addi x3, x0, 32` | I | `02000193` |
| `0x0C` | `addi x4, x0, 2` | I | `00200213` |
| `0x10` | `addi x5, x0, 0` | I | `00000293` |
| `0x14` | `add x9, x1, x0` | R | `000084B3` |
| `0x18` | `bge x5, x4, done` (+100) | B | `0642D263` |
| `0x1C` | `addi x6, x0, 0` | I | `00000313` |
| `0x20` | `addi x15, x0, 0` | I | `00000793` |
| `0x24` | `bge x6, x4, next_i` (+76) | B | `04435663` |
| `0x28` | `addi x8, x0, 0` | I | `00000413` |
| `0x2C` | `addi x7, x0, 0` | I | `00000393` |
| `0x30` | `add x10, x9, x0` | R | `00048533` |
| `0x34` | `add x11, x2, x15` | R | `00F105B3` |
| `0x38` | `bge x7, x4, store_c` (+36) | B | `0243D263` |
| `0x3C` | `lw x12, 0(x10)` | I | `00052603` |
| `0x40` | `lw x13, 0(x11)` | I | `0005A683` |
| `0x44` | `mul x14, x12, x13` | R | `02D60733` |
| `0x48` | `add x8, x8, x14` | R | `00E40433` |
| `0x4C` | `addi x10, x10, 4` | I | `00450513` |
| `0x50` | `addi x11, x11, 8` | I | `00858593` |
| `0x54` | `addi x7, x7, 1` | I | `00138393` |
| `0x58` | `jal x0, loop_k` (−32) | J | `FE1FF06F` |
| `0x5C` | `sw x8, 0(x3)` | S | `0081A023` |
| `0x60` | `addi x3, x3, 4` | I | `00418193` |
| `0x64` | `addi x15, x15, 4` | I | `00478793` |
| `0x68` | `addi x6, x6, 1` | I | `00130313` |
| `0x6C` | `jal x0, loop_j` (−72) | J | `FB9FF06F` |
| `0x70` | `addi x9, x9, 8` | I | `00848493` |
| `0x74` | `addi x5, x5, 1` | I | `00128293` |
| `0x78` | `jal x0, loop_i` (−96) | J | `FA1FF06F` |
| `0x7C` | `jal x0, done` (0) | J | `0000006F` |

Total: **32 instructions** × 4 bytes = 128 bytes of instruction memory.

---

## 5. Immediate Offset Verification (Branches and Jumps)

All branch and jump targets are relative to the PC of the instruction itself:

| PC | Instruction | Offset | Target PC | Label |
|:---:|:---|:---:|:---:|:---|
| `0x18` | `bge x5, x4` | +100 | `0x7C` | `done` ✓ |
| `0x24` | `bge x6, x4` | +76  | `0x70` | `next_i` ✓ |
| `0x38` | `bge x7, x4` | +36  | `0x5C` | `store_c` ✓ |
| `0x58` | `jal x0`     | −32  | `0x38` | `loop_k` ✓ |
| `0x6C` | `jal x0`     | −72  | `0x24` | `loop_j` ✓ |
| `0x78` | `jal x0`     | −96  | `0x18` | `loop_i` ✓ |
| `0x7C` | `jal x0`     | 0    | `0x7C` | `done` (self-loop, halt) ✓ |

---

## 6. Instruction Memory Image

The hex values in the summary table above, in order from PC `0x00` to `0x7C`, are
the contents of `test_programs/matrix_multiplication_2x2/imem.hex`. Loading that
file into the IMEM (ROM) component reproduces the program as encoded here.

