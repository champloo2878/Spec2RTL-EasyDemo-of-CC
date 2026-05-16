# IEEE 754 Single-Precision Floating Point Adder

## Interface
- Input a: 32-bit IEEE 754 float
- Input b: 32-bit IEEE 754 float
- Output result: 32-bit IEEE 754 float (a + b)

## Behavior
- Round to nearest, ties to even (default IEEE 754 rounding)
- Handle special values: NaN (propagate), Inf, zero, denormalized
- Result must be IEEE 754 compliant

## IEEE 754 Single-Precision Format
- Bit 31: sign
- Bits 30:23: exponent (biased by 127)
- Bits 22:0: mantissa/significand (23 bits, with implicit leading 1 for normal numbers)

## Special Value Encodings
| Value | Sign | Exponent | Mantissa |
|---|---|---|---|
| Zero | 0 or 1 | 0x00 | 0x000000 |
| Denormalized | 0 or 1 | 0x00 | non-zero |
| Normal | 0 or 1 | 0x01-0xFE | any |
| Infinity | 0 or 1 | 0xFF | 0x000000 |
| NaN | 0 or 1 | 0xFF | non-zero |

## Special Case Rules
- NaN + anything = NaN (propagate the first NaN operand)
- +Inf + (+Inf) = +Inf
- +Inf + (-Inf) = NaN
- Any normal + Inf of same sign = that Inf
- Zero + Zero = Zero (sign handling per IEEE 754)
- Denormalized inputs are treated as their actual represented value
