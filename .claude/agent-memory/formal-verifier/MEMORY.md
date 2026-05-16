# Formal Verifier Agent Memory

## IEEE 754 FP32 Reference Values
- +0: 32'h00000000, -0: 32'h80000000
- 1.0: 32'h3f800000, -1.0: 32'hbf800000
- 2.0: 32'h40000000, -2.0: 32'hc0000000
- 0.5: 32'h3f000000, -0.5: 32'hbf000000
- 1.5: 32'h3fc00000, 2.5: 32'h40200000
- 3.0: 32'h40400000, 4.0: 32'h40800000
- +Inf: 32'h7f800000, -Inf: 32'hff800000
- QNaN (canonical): 32'h7fc00000
- Min normal: 32'h00800000, Max normal: 32'h7f7fffff
- Min subnormal: 32'h00000001
- 2^127: 32'h7f000000, 2^(-24): 32'h33800000

## RNE Rounding Rules
- Guard (G) = first bit shifted out beyond mantissa LSB
- Round (R) = second bit shifted out
- Sticky (S) = OR of all bits shifted out beyond R
- Round up iff G=1 AND (R=1 OR S=1 OR mantissa_LSB=1)
- Tie case: G=1, R=0, S=0 → round to make LSB=0 (even)

## IEEE 754 Special Case Rules
- NaN + anything = NaN (propagate NaN)
- Inf + same-sign Inf = that Inf
- Inf + opposite-sign Inf = NaN
- Inf + finite = Inf (Inf sign dominates)
- (+0) + (+0) = +0, (-0) + (-0) = -0
- (-0) + (+0) = +0 (default RNE rounding mode)
- Exact zero result from RNE → +0 (except for (-0)+(-0) = -0)

## FP32 Encoding Quick Reference
- Sign: bit 31
- Exponent: bits 30:23, biased by 127
- Mantissa fraction: bits 22:0
- Normal: implicit leading 1, value = (-1)^s * 2^(e-127) * (1 + f/2^23)
- Subnormal: implicit leading 0, value = (-1)^s * 2^(-126) * (f/2^23)
- Exp=0xFF, f=0 → Inf; Exp=0xFF, f!=0 → NaN
- Exp=0x00, f=0 → Zero; Exp=0x00, f!=0 → Subnormal

## Test Vector Categories (in order)
1. Trivial (2-4): zero, identity operations
2. Normal (5-10): representative positive/negative, varying magnitudes
3. Boundary (3-5): min normal, max normal, overflow
4. Special (3-5): NaN, Inf, zero signs
5. Edge (3-5): cancellation, rounding ties, underflow
6. Corner (2-3): NaN+Inf, subnormal+normal, zero sign combos

## Common Pitfalls
- When aligning mantissas for addition, the implicit leading bit MUST be included
- Subnormal numbers have exp=0x00 but implicit leading bit=0 (not 1)
- When shifting the smaller mantissa right, bits shifted out contribute to G/R/S
- The sticky bit is OR of ALL bits beyond R, not just the bit at S position
- Overflow: exp becomes 0xFF → result is Inf (not NaN)
- Underflow: result may become subnormal or zero
