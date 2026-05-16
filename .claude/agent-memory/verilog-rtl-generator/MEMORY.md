# Verilog RTL Generator — Persistent Memory

## Floating-Point Adder Design Patterns

### IEEE 754 Single-Precision Addition Pipeline
The standard pipeline for a combinational FP adder:
1. **Unpack**: Extract sign, exponent (8-bit biased), mantissa (23-bit) from 32-bit operands
2. **Classify**: Determine NaN, Inf, Zero, Denormal, Normal for each operand
3. **Special cases** (bypass path): NaN propagation, Inf arithmetic, zero cases
4. **Normal path**: Compute effective exponents, sort by magnitude, align, add/sub, normalize, round, pack

### Internal Bit Widths
- Significand (with implicit bit): 24 bits = {implicit, mantissa[22:0]}
- Alignment extension: 27 bits = {sig, 3'b000} (sig + G + R + extra for sticky)
- Addition: 28 bits = {1'b0, sig, 3'b000} (carry reserve + sig + G + R + extra)
- Normalization shift: up to 26 positions left (28-bit value), 1 position right (overflow)
- Underflow shift: up to 24 positions right (27-bit value)

### Sticky Bit Tracking
Sticky is an accumulating OR of all bits shifted below position 0 across the pipeline:
1. **Alignment sticky**: bits shifted out when aligning the smaller operand
2. **Normalization sticky**: bits shifted out during left-shift normalization OR old alignment sticky
3. **First-round sticky**: normalization_sticky | S_stage (bit[0] after normalization)
4. **Underflow sticky**: old_sticky shifted out + new bits shifted out during underflow right-shift

Key insight: When left-shifting for normalization, bits [N-1:0] of pre_sum shift below position 0 and must be ORed into sticky. Use a case-statement mask to capture these.

### Sticky Mask Generation (Verilog-2001)
For variable shift amounts where `<<` with variable shift is synthesizable but shift-out detection requires explicit masks:
```verilog
wire [WIDTH-1:0] mask;
assign mask = (shift == 0) ? 0 : (shift == 1) ? 1 : (shift == 2) ? 3 : ...;
wire sticky = |(value & mask);
```
This case-statement pattern is clean and synthesizable for small max shift values (<= 32).

### Round-to-Nearest-Even
```
round_up = G && (R || sticky || LSB);
```
- G=0: truncate (round down)
- G=1, R=1 or sticky=1: round up (> halfway)
- G=1, R=0, sticky=0: exact tie, round to even (LSB=1 -> round up)

### Common Pitfalls

1. **Wire/assign inside always blocks**: Verilog-2001 forbids `wire` declarations and `assign` statements inside `always` blocks. All wires must be declared at module scope with continuous `assign` outside procedural blocks.

2. **Underflow condition**: Use `< -126` not `<= -126`. Effective exponent == -126 produces the smallest normal (biased_exp = 1), not a denormal.

3. **Dead always blocks**: If an always block produces a reg that is never read, remove it entirely. It may contain illegal constructs that cause synthesis errors.

4. **Unused wires**: Clean up wires that are declared and assigned but never referenced. They clutter the code and may obscure real issues.

5. **2's complement extraction for biased exponent**: For effective exponents in [-126, 127], extracting the lower 8 bits of the signed 10-bit value and adding 127 gives the correct biased exponent due to modular 2's complement arithmetic.

### Special Case Priority (IEEE 754)
The special cases must be checked in priority order:
1. NaN (either operand) → propagate first NaN
2. Both Inf → same sign → that Inf; opposite → canonical quiet NaN
3. One Inf, one finite → that Inf (Inf's sign)
4. Both Zero → sign depends on rounding mode (roundTiesToEven: +0 for opposite signs)
5. Otherwise → normal computation path

### Effective Exponent for Denormals
- Normal: eff_exp = biased_exp - 127
- Denormal: eff_exp = -126 (NOT -127; this is the IEEE 754 special case)
- Denormal significand: implicit bit = 0 (not 1)
