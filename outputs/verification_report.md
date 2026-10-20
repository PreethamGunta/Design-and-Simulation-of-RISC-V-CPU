# Simulation Verification Report

**Date:** 2026-10-21  
**Circuit:** `risc_v_cpu.circ`  
**Simulator:** Logisim Evolution v5.0.0  
**Java:** 24.0.2  
**Command pattern:**
```
java -jar logisim-evolution.jar --tty halt -l imem.hex imem -l dmem_initial.hex dmem --save dmem_final.hex risc_v_cpu.circ
```

The Logisim `--tty halt` mode runs the simulation headlessly until the circuit's halt
pin is asserted. In this CPU, the halt pin is connected to detect the self-loop
instruction `JAL x0, 0` (`0x0000006F`). Each simulation was run independently with a
fresh data-memory image.

---

## Results

| Program | Expected | Actual |
|---------|----------|--------|
| 2×2 Matrix Multiplication | C = [[19, 22], [43, 50]] at DMEM words 8–11 | `00000013 00000016 0000002b 00000032` |
| 3×3 Matrix Multiplication | C = [[30,24,18],[84,69,54],[138,114,90]] at words 18–26 | `1e 18 12 54 45 36 8a 72 5a` |
| Sum of 1 to N (N=10) | Sum = 55 (`0x37`) at DMEM word 1 | `00000037` |
| Maximum of Array | MAX = 27 (`0x1b`) at DMEM word 6 | `0000001b` |
| N Factorial (N=6) | 6! = 720 (`0x2d0`) at DMEM word 1 | `000002d0` |

---

## Detailed Verification

### 2×2 Matrix Multiplication

**Input:** A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]]  
**Expected:** C = A × B = [[19, 22], [43, 50]]

Manual verification:
- C[0][0] = 1×5 + 2×7 = 5 + 14 = **19** = `0x13` ✓
- C[0][1] = 1×6 + 2×8 = 6 + 16 = **22** = `0x16` ✓
- C[1][0] = 3×5 + 4×7 = 15 + 28 = **43** = `0x2B` ✓
- C[1][1] = 3×6 + 4×8 = 18 + 32 = **50** = `0x32` ✓

Input matrices A and B (words 0–7) were preserved unchanged. ✓

---

### 3×3 Matrix Multiplication

**Input:** A = [[1,2,3],[4,5,6],[7,8,9]], B = [[9,8,7],[6,5,4],[3,2,1]]  
**Expected:** C = A × B = [[30,24,18],[84,69,54],[138,114,90]]

Manual verification (selected elements):
- C[0][0] = 1×9 + 2×6 + 3×3 = 9+12+9 = **30** = `0x1E` ✓
- C[1][1] = 4×8 + 5×5 + 6×2 = 32+25+12 = **69** = `0x45` ✓
- C[2][2] = 7×7 + 8×4 + 9×1 = 49+32+9 = **90** = `0x5A` ✓

---

### Sum of 1 to N (N=10)

1 + 2 + 3 + ... + 10 = 10×11/2 = **55** = `0x37` ✓

---

### Maximum of Array

Array: [12, 5, 27, 8, 19] → MAX = **27** = `0x1B` ✓  
Array values and length N (words 0–5) were preserved unchanged. ✓

---

### N Factorial (N=6)

6! = 1×2×3×4×5×6 = **720** = `0x2D0` ✓  
Input N=6 (word 0) was preserved unchanged. ✓

---

## Halt Behavior

All simulations terminated with:
```
[main] ERROR com.cburch.logisim.gui.start.TtyInterface - halted due to halt pin
```
Exit code 0 in all cases. The CPU correctly executes the `JAL x0, 0` (`0x0000006F`)
self-loop at the end of each program, which activates the halt pin and stops the
headless simulation.

---

## Notes

- The `--save` flag produces a `v3.0 hex words plain` file containing the full 16 M × 32
  DMEM contents. Only the first few words (relevant to each program) were compared.
- The output format differs from the `v2.0 raw` format used in `dmem_expected.hex` files;
  the word values are identical when correctly extracted.
- No circuit modifications were made. The test programs were loaded via the `-l` flag
  without altering `risc_v_cpu.circ`.
