# Program: 2×2 Matrix Multiplication (C = A × B)

## Purpose

Computes the product of two 2×2 integer matrices stored in data memory and writes
the result matrix back to memory.

**Input matrices (loaded into DMEM before execution):**

```
A = [[1, 2], [3, 4]]     (byte addresses 0x00–0x0C)
B = [[5, 6], [7, 8]]     (byte addresses 0x10–0x1C)
```

**Expected result:**

```
C = A × B = [[19, 22], [43, 50]]   (written to byte addresses 0x20–0x2C)
```

---

## Register Allocation

| Register | Role |
|----------|------|
| `x0`  | Hardwired zero |
| `x1`  | Base byte address of Matrix A (0x00) |
| `x2`  | Base byte address of Matrix B (0x10 = 16) |
| `x3`  | Running write pointer for Matrix C (starts at 0x20 = 32) |
| `x4`  | Matrix dimension N = 2 (loop bound) |
| `x5`  | Outer loop row index i (0..1) |
| `x6`  | Middle loop column index j (0..1) |
| `x7`  | Inner dot-product index k (0..1) |
| `x8`  | Accumulator (sum) for C[i][j] |
| `x9`  | Row pointer for Matrix A (&A[i][0]; advances by 8 bytes per row) |
| `x10` | Element pointer for A[i][k] (advances by 4 bytes per k) |
| `x11` | Element pointer for B[k][j] (advances by 8 bytes per k; one row of B) |
| `x12` | Loaded value A[i][k] |
| `x13` | Loaded value B[k][j] |
| `x14` | Product A[i][k] × B[k][j] |
| `x15` | Column byte offset for Matrix B (j × 4; advances by 4 per j) |

---

## Memory Layout

| Byte Address | DMEM Word | Element | Initial | Expected Final |
|:---:|:---:|:---:|:---:|:---:|
| `0x00` | `0x00` | A[0][0] | `0x00000001` | `0x00000001` |
| `0x04` | `0x01` | A[0][1] | `0x00000002` | `0x00000002` |
| `0x08` | `0x02` | A[1][0] | `0x00000003` | `0x00000003` |
| `0x0C` | `0x03` | A[1][1] | `0x00000004` | `0x00000004` |
| `0x10` | `0x04` | B[0][0] | `0x00000005` | `0x00000005` |
| `0x14` | `0x05` | B[0][1] | `0x00000006` | `0x00000006` |
| `0x18` | `0x06` | B[1][0] | `0x00000007` | `0x00000007` |
| `0x1C` | `0x07` | B[1][1] | `0x00000008` | `0x00000008` |
| `0x20` | `0x08` | **C[0][0]** | `0x00000000` | **`0x00000013` (19)** |
| `0x24` | `0x09` | **C[0][1]** | `0x00000000` | **`0x00000016` (22)** |
| `0x28` | `0x0A` | **C[1][0]** | `0x00000000` | **`0x0000002B` (43)** |
| `0x2C` | `0x0B` | **C[1][1]** | `0x00000000` | **`0x00000032` (50)** |

---

## Loading Instructions (Logisim Evolution)

1. Open `risc_v_cpu.circ` in Logisim Evolution.
2. Right-click the IMEM (ROM) component → **Load Image…** → select `imem.hex`.
3. Right-click the DMEM (RAM) component → **Load Image…** → select `dmem_initial.hex`.
4. Reset the simulation (Ctrl+R) and clock the circuit until the halt self-loop is reached
   (PC stops incrementing).
5. Inspect DMEM words `0x08`–`0x0B` and verify against `dmem_expected.hex`.

Both memory files use the **`v2.0 raw`** Logisim format (one 32-bit hex word per line,
no address prefixes). The DMEM is word-indexed; word `n` corresponds to byte address `n × 4`.

