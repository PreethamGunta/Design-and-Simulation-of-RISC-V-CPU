# Program: 3×3 Matrix Multiplication (C = A × B)

## Purpose

Computes the product of two 3×3 integer matrices and writes the result to DMEM.
It uses the same loop structure as the 2×2 program but with N=3 and row strides
of 12 bytes instead of 8.

**Input matrices:**

```
A = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]    (byte addresses 0x00–0x20)
B = [[9, 8, 7], [6, 5, 4], [3, 2, 1]]    (byte addresses 0x24–0x44)
```

**Expected result:**

```
C = A × B = [[30, 24, 18], [84, 69, 54], [138, 114, 90]]
            (written to byte addresses 0x48–0x68)
```

## Memory Layout

| Byte Address | DMEM Word | Element | Initial | Expected Final |
|:---:|:---:|:---:|:---:|:---:|
| `0x00`–`0x20` | `0x00`–`0x08` | A[0][0]..A[2][2] | `1`..`9` | unchanged |
| `0x24`–`0x44` | `0x09`–`0x11` | B[0][0]..B[2][2] | `9`..`1` | unchanged |
| `0x48` | `0x12` | **C[0][0]** | `0` | **`0x1E` (30)** |
| `0x4C` | `0x13` | **C[0][1]** | `0` | **`0x18` (24)** |
| `0x50` | `0x14` | **C[0][2]** | `0` | **`0x12` (18)** |
| `0x54` | `0x15` | **C[1][0]** | `0` | **`0x54` (84)** |
| `0x58` | `0x16` | **C[1][1]** | `0` | **`0x45` (69)** |
| `0x5C` | `0x17` | **C[1][2]** | `0` | **`0x36` (54)** |
| `0x60` | `0x18` | **C[2][0]** | `0` | **`0x8A` (138)** |
| `0x64` | `0x19` | **C[2][1]** | `0` | **`0x72` (114)** |
| `0x68` | `0x1A` | **C[2][2]** | `0` | **`0x5A` (90)** |

## Differences from 2×2 Program

The 3×3 program differs from the 2×2 in two instructions only:

- `addi x11, x11, 12` (was `8`) — B column pointer advances by one 3-element row (12 bytes)
- `addi x9, x9, 12` (was `8`) — A row pointer advances by one 3-element row (12 bytes)

All other instructions and the overall loop structure are identical.

