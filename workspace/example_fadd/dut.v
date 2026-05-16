// Module: fadd
// Generated from spec: example_fadd
// IEEE 754 Single-Precision Floating Point Adder
// Round to nearest, ties to even
//
module fadd (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result
);

    // =========================================================================
    // SPEC: IEEE 754 Single-Precision Format
    // Bit 31: sign, Bits 30:23: exponent (biased by 127), Bits 22:0: mantissa
    // =========================================================================

    // --- Unpack operand A ---
    wire        sign_a;
    wire [7:0]  exp_a;
    wire [22:0] mant_a;
    assign sign_a = a[31];
    assign exp_a  = a[30:23];
    assign mant_a = a[22:0];

    // --- Unpack operand B ---
    wire        sign_b;
    wire [7:0]  exp_b;
    wire [22:0] mant_b;
    assign sign_b = b[31];
    assign exp_b  = b[30:23];
    assign mant_b = b[22:0];

    // =========================================================================
    // SPEC: Special Value Encodings — classify each operand
    // =========================================================================

    wire exp_zero_a, exp_ones_a, mant_zero_a;
    wire exp_zero_b, exp_ones_b, mant_zero_b;
    assign exp_zero_a  = (exp_a == 8'h00);
    assign exp_ones_a  = (exp_a == 8'hFF);
    assign mant_zero_a = (mant_a == 23'd0);
    assign exp_zero_b  = (exp_b == 8'h00);
    assign exp_ones_b  = (exp_b == 8'hFF);
    assign mant_zero_b = (mant_b == 23'd0);

    // SPEC: Zero — exp=0x00, mant=0x000000
    wire is_zero_a, is_zero_b;
    assign is_zero_a = exp_zero_a && mant_zero_a;
    assign is_zero_b = exp_zero_b && mant_zero_b;

    // SPEC: Denormalized — exp=0x00, mant!=0
    wire is_denormal_a, is_denormal_b;
    assign is_denormal_a = exp_zero_a && !mant_zero_a;
    assign is_denormal_b = exp_zero_b && !mant_zero_b;

    // SPEC: Infinity — exp=0xFF, mant=0x000000
    wire is_inf_a, is_inf_b;
    assign is_inf_a = exp_ones_a && mant_zero_a;
    assign is_inf_b = exp_ones_b && mant_zero_b;

    // SPEC: NaN — exp=0xFF, mant!=0
    wire is_nan_a, is_nan_b;
    assign is_nan_a = exp_ones_a && !mant_zero_a;
    assign is_nan_b = exp_ones_b && !mant_zero_b;

    // SPEC: Normal — exp between 0x01 and 0xFE
    wire is_normal_a, is_normal_b;
    assign is_normal_a = !exp_zero_a && !exp_ones_a;
    assign is_normal_b = !exp_zero_b && !exp_ones_b;

    // =========================================================================
    // SPEC: Special Case Rules — compute special-case result
    // =========================================================================

    // SPEC: NaN + anything = NaN (propagate the first NaN operand)
    wire        special_nan;
    wire [31:0] nan_result;
    assign special_nan = is_nan_a || is_nan_b;
    assign nan_result  = is_nan_a ? a : b;

    // SPEC: Inf handling — both Inf same sign -> that Inf; opposite sign -> NaN
    wire        special_inf_inf;
    wire [31:0] inf_inf_result;
    assign special_inf_inf = is_inf_a && is_inf_b;
    assign inf_inf_result  = (sign_a == sign_b) ? {sign_a, 8'hFF, 23'd0}
                                                : 32'h7FC00000; // canonical quiet NaN

    // SPEC: Any normal + Inf of same sign = that Inf
    // Also handles: denormal + Inf, zero + Inf, finite + Inf
    // Finite means normal, denormal, or zero (anything not NaN and not Inf)
    wire        finite_a, finite_b;
    assign finite_a = !is_nan_a && !is_inf_a;
    assign finite_b = !is_nan_b && !is_inf_b;

    // SPEC: One operand is Inf, the other is finite — result is Inf with Inf's sign
    wire        special_inf_finite;
    wire [31:0] inf_finite_result;
    assign special_inf_finite = (is_inf_a && finite_b) || (is_inf_b && finite_a);
    assign inf_finite_result  = is_inf_a ? {sign_a, 8'hFF, 23'd0} : {sign_b, 8'hFF, 23'd0};

    // SPEC: Zero + Zero = Zero (sign handling per IEEE 754)
    // roundTiesToEven: +0 + +0 = +0, -0 + -0 = -0, +0 + -0 = +0, -0 + +0 = +0
    wire        special_zero;
    wire [31:0] zero_result;
    assign special_zero = is_zero_a && is_zero_b;
    assign zero_result  = ((sign_a == sign_b) ? {sign_a, 31'd0} : 32'd0);

    // Flattened special-case decision
    wire        is_special;
    assign is_special = special_nan || special_inf_inf || special_inf_finite || special_zero;

    // Priority-encoded special result
    reg [31:0] special_out;
    always @(*) begin
        special_out = 32'd0;
        if (special_nan)            special_out = nan_result;
        else if (special_inf_inf)   special_out = inf_inf_result;
        else if (special_inf_finite) special_out = inf_finite_result;
        else if (special_zero)      special_out = zero_result;
        else                        special_out = 32'd0;
    end

    // =========================================================================
    // SPEC: Normal/Denormal Addition Path
    // =========================================================================

    // SPEC: Denormalized inputs are treated as their actual represented value
    // Effective exponent: normal -> exp - 127; denormal -> -126
    wire signed [8:0] eff_exp_a_wire;
    wire signed [8:0] eff_exp_b_wire;
    assign eff_exp_a_wire = exp_zero_a ? (-9'sd126) : ($signed({1'b0, exp_a}) - 9'sd127);
    assign eff_exp_b_wire = exp_zero_b ? (-9'sd126) : ($signed({1'b0, exp_b}) - 9'sd127);

    // SPEC: Implicit leading 1 for normal numbers, implicit leading 0 for denormal
    wire [23:0] sig_a, sig_b;
    assign sig_a = exp_zero_a ? {1'b0, mant_a} : {1'b1, mant_a};
    assign sig_b = exp_zero_b ? {1'b0, mant_b} : {1'b1, mant_b};

    // =========================================================================
    // SPEC: Sort operands by magnitude — determine which is larger
    // =========================================================================
    // Compare effective exponents first; if equal, compare significands
    // This is needed for: same-sign addition (preserve sign) and opposite-sign
    // subtraction (larger minus smaller, result sign = larger's sign)

    wire a_larger_eff_exp;   // eff_exp_a > eff_exp_b
    assign a_larger_eff_exp = (eff_exp_a_wire > eff_exp_b_wire);

    wire exp_equal;
    assign exp_equal = (eff_exp_a_wire == eff_exp_b_wire);

    wire a_larger_sig;       // sig_a > sig_b (used only when exp equal)
    assign a_larger_sig = (sig_a > sig_b);

    wire a_is_larger;
    assign a_is_larger = a_larger_eff_exp || (exp_equal && a_larger_sig);

    // Swap: large sign, large eff exp, large significand
    wire        sign_large, sign_small;
    wire signed [8:0] eff_exp_large, eff_exp_small;
    wire [23:0] sig_large, sig_small;

    assign sign_large       = a_is_larger ? sign_a : sign_b;
    assign sign_small       = a_is_larger ? sign_b : sign_a;
    assign eff_exp_large    = a_is_larger ? eff_exp_a_wire : eff_exp_b_wire;
    assign eff_exp_small    = a_is_larger ? eff_exp_b_wire : eff_exp_a_wire;
    assign sig_large        = a_is_larger ? sig_a : sig_b;
    assign sig_small        = a_is_larger ? sig_b : sig_a;

    // =========================================================================
    // SPEC: Align smaller significand by right-shifting
    // =========================================================================

    // Exponent difference (non-negative by construction)
    wire signed [8:0] exp_diff_signed;
    assign exp_diff_signed = eff_exp_large - eff_exp_small;

    // Clamp shift amount to 27 (anything larger means small number becomes only sticky)
    wire [4:0] align_shift;
    assign align_shift = (exp_diff_signed > 9'sd27) ? 5'd27 : exp_diff_signed[4:0];

    // Extend small significand for alignment: {sig, 3'b000} = 27 bits
    // Bits [26:3] = significand, bits [2:0] = guard/round/extra for sticky
    wire [26:0] sig_small_ext;
    assign sig_small_ext = {sig_small, 3'b000};

    // Right-shift small significand by align_shift
    wire [26:0] sig_small_aligned;
    assign sig_small_aligned = sig_small_ext >> align_shift;

    // SPEC: Sticky bit — OR of all bits shifted out during alignment
    // Construct a mask of align_shift ones at the bottom, then AND with original
    wire [26:0] sticky_mask;
    assign sticky_mask = (align_shift == 5'd0)  ? 27'd0 :
                         (align_shift == 5'd1)  ? 27'd1 :
                         (align_shift == 5'd2)  ? 27'd3 :
                         (align_shift == 5'd3)  ? 27'd7 :
                         (align_shift == 5'd4)  ? 27'd15 :
                         (align_shift == 5'd5)  ? 27'd31 :
                         (align_shift == 5'd6)  ? 27'd63 :
                         (align_shift == 5'd7)  ? 27'd127 :
                         (align_shift == 5'd8)  ? 27'd255 :
                         (align_shift == 5'd9)  ? 27'd511 :
                         (align_shift == 5'd10) ? 27'd1023 :
                         (align_shift == 5'd11) ? 27'd2047 :
                         (align_shift == 5'd12) ? 27'd4095 :
                         (align_shift == 5'd13) ? 27'd8191 :
                         (align_shift == 5'd14) ? 27'd16383 :
                         (align_shift == 5'd15) ? 27'd32767 :
                         (align_shift == 5'd16) ? 27'd65535 :
                         (align_shift == 5'd17) ? 27'd131071 :
                         (align_shift == 5'd18) ? 27'd262143 :
                         (align_shift == 5'd19) ? 27'd524287 :
                         (align_shift == 5'd20) ? 27'd1048575 :
                         (align_shift == 5'd21) ? 27'd2097151 :
                         (align_shift == 5'd22) ? 27'd4194303 :
                         (align_shift == 5'd23) ? 27'd8388607 :
                         (align_shift == 5'd24) ? 27'd16777215 :
                         (align_shift == 5'd25) ? 27'd33554431 :
                         (align_shift == 5'd26) ? 27'd67108863 :
                                                  27'd134217727;

    wire sticky_align;
    assign sticky_align = |(sig_small_ext & sticky_mask);

    // =========================================================================
    // SPEC: Add or subtract significands based on sign comparison
    // =========================================================================

    // Same sign -> add; opposite sign -> subtract (large - small, guaranteed non-negative)
    wire same_sign;
    assign same_sign = (sign_large == sign_small);

    // Extend large significand: 28 bits {1'b0, sig, 3'b000} = reserve carry, sig, G, R, extra
    wire [27:0] sig_large_ext;
    assign sig_large_ext = {1'b0, sig_large, 3'b000};

    // Small aligned extended to 28 bits
    wire [27:0] sig_small_aligned_ext;
    assign sig_small_aligned_ext = {1'b0, sig_small_aligned};

    // Perform addition or subtraction
    wire [27:0] pre_sum;
    assign pre_sum = same_sign ? (sig_large_ext + sig_small_aligned_ext)
                               : (sig_large_ext - sig_small_aligned_ext);

    // =========================================================================
    // SPEC: Normalize the result — position leading 1 at bit [26]
    // =========================================================================

    // Leading-one detector for 28-bit pre_sum
    reg [4:0] lead_one_pos;
    reg       sum_is_zero;
    integer   li;
    always @(*) begin
        lead_one_pos = 5'd0;
        sum_is_zero  = 1'b1;
        for (li = 27; li >= 0; li = li - 1) begin
            // FIX: Only capture the FIRST (highest-position) 1-bit.
            // The old code `if (pre_sum[li])` would overwrite lead_one_pos
            // on every 1-bit, ending with the LOWEST-position 1. This
            // caused wrong normalization shifts when pre_sum had multiple
            // 1-bits, producing operand-a or operand-b as the result.
            if (pre_sum[li] && sum_is_zero) begin
                lead_one_pos = li[4:0];
                sum_is_zero  = 1'b0;
            end
        end
    end

    // Normalization: shift left so leading 1 is at bit 26
    // If bit 27 is already 1 (overflow from add): shift right by 1
    // If left shift needed (lead_one_pos < 26): shift left by (26 - lead_one_pos)
    wire        norm_overflow;   // bit 27 set -> need right shift
    wire [4:0]  norm_left_shift; // amount to shift left (0 if overflow or already normalized)

    assign norm_overflow   = (lead_one_pos == 5'd27);
    assign norm_left_shift = norm_overflow ? 5'd0 :
                             (lead_one_pos >= 5'd26) ? 5'd0 :
                             (5'd26 - lead_one_pos);

    // Left-shift normalization (when lead_one_pos < 26 and no overflow)
    wire [27:0] pre_sum_left_shifted;
    assign pre_sum_left_shifted = pre_sum << norm_left_shift;

    // Right-shift normalization (when overflow, lead_one_pos == 27)
    wire [27:0] pre_sum_right_shifted;
    assign pre_sum_right_shifted = pre_sum >> 5'd1;

    // Select the appropriate norm-shifted result
    wire [27:0] norm_sum;
    assign norm_sum = norm_overflow ? pre_sum_right_shifted : pre_sum_left_shifted;

    // Compute the effective exponent after normalization
    // eff_exp_large is the base exponent
    // For overflow (right shift by 1): eff_exp_large + 1
    // For left shift by N: eff_exp_large - N
    // For no shift: eff_exp_large
    wire signed [8:0] norm_exp_delta;
    assign norm_exp_delta = norm_overflow ? 9'sd1
                          : ($signed({4'd0, norm_left_shift}) * (-9'sd1));

    wire signed [9:0] result_eff_exp_signed;
    assign result_eff_exp_signed = $signed({eff_exp_large[8], eff_exp_large}) + $signed({norm_exp_delta[8], norm_exp_delta});

    // =========================================================================
    // SPEC: Sticky bit for normalization — track bits shifted out during left-shift norm
    // =========================================================================
    // When left-shifting by N, bits [N-1:0] of pre_sum are shifted up.
    // But bits that were originally below position 0 become new lower bits.
    // The sticky from alignment was at position 0 of pre_sum (since sig_small_aligned
    // had its extra bits at positions [2:0]).
    //
    // After normalization left-shift by N:
    //   G = norm_sum[2], R = norm_sum[1], S_extra = norm_sum[0]
    //   Sticky = sticky_align OR (any bits of pre_sum below position 0 that were shifted out)
    //
    // pre_sum had 28 bits [27:0]. The bottom 3 bits were G, R, and a "sticky pending" bit.
    // After left shift by N (0..26):
    //   New bit[0] comes from old bit[-N], which is 0 (no bits below pre_sum)
    //   New bit[1] comes from old bit[1-N], which is 0 for N>=2
    //
    // Actually, the alignment sticky (sticky_align) is the OR of bits shifted out
    // during alignment. This is an external flag. During normalization left shift,
    // the bits that were at the bottom of pre_sum move up. Any hole at the bottom
    // just gets zeros, and sticky_align still applies.

    wire sticky_from_norm;
    // FIX: During left-shift normalization by N, original pre_sum bits [N-1:0]
    // shift below position 0 and must be ORed into sticky along with sticky_align.
    //
    // During right-shift (overflow): bit 0 of pre_sum shifts out.
    // Sticky |= pre_sum[0] | sticky_align

    // Compute a mask for bits shifted out below position 0 during left-shift norm
    wire [27:0] norm_left_shift_mask;
    assign norm_left_shift_mask = (norm_left_shift == 5'd0)  ? 28'd0 :
                                  (norm_left_shift == 5'd1)  ? 28'd1 :
                                  (norm_left_shift == 5'd2)  ? 28'd3 :
                                  (norm_left_shift == 5'd3)  ? 28'd7 :
                                  (norm_left_shift == 5'd4)  ? 28'd15 :
                                  (norm_left_shift == 5'd5)  ? 28'd31 :
                                  (norm_left_shift == 5'd6)  ? 28'd63 :
                                  (norm_left_shift == 5'd7)  ? 28'd127 :
                                  (norm_left_shift == 5'd8)  ? 28'd255 :
                                  (norm_left_shift == 5'd9)  ? 28'd511 :
                                  (norm_left_shift == 5'd10) ? 28'd1023 :
                                  (norm_left_shift == 5'd11) ? 28'd2047 :
                                  (norm_left_shift == 5'd12) ? 28'd4095 :
                                  (norm_left_shift == 5'd13) ? 28'd8191 :
                                  (norm_left_shift == 5'd14) ? 28'd16383 :
                                  (norm_left_shift == 5'd15) ? 28'd32767 :
                                  (norm_left_shift == 5'd16) ? 28'd65535 :
                                  (norm_left_shift == 5'd17) ? 28'd131071 :
                                  (norm_left_shift == 5'd18) ? 28'd262143 :
                                  (norm_left_shift == 5'd19) ? 28'd524287 :
                                  (norm_left_shift == 5'd20) ? 28'd1048575 :
                                  (norm_left_shift == 5'd21) ? 28'd2097151 :
                                  (norm_left_shift == 5'd22) ? 28'd4194303 :
                                  (norm_left_shift == 5'd23) ? 28'd8388607 :
                                  (norm_left_shift == 5'd24) ? 28'd16777215 :
                                  (norm_left_shift == 5'd25) ? 28'd33554431 :
                                  (norm_left_shift == 5'd26) ? 28'd67108863 :
                                                               28'd134217727;
    wire pre_sum_bits_shifted_out_norm;
    assign pre_sum_bits_shifted_out_norm = |(pre_sum & norm_left_shift_mask);

    assign sticky_from_norm = norm_overflow ? (sticky_align | pre_sum[0]) :
                              sticky_align | pre_sum_bits_shifted_out_norm;

    // =========================================================================
    // SPEC: Extract significand and rounding bits from norm_sum
    // =========================================================================
    // After normalization, the 24-bit significand is at norm_sum[26:3]
    // G = norm_sum[2], R = norm_sum[1], S_stage = norm_sum[0]

    wire [23:0] norm_sig;
    wire        G, R, S_stage;
    assign norm_sig  = norm_sum[26:3];
    assign G         = norm_sum[2];
    assign R         = norm_sum[1];
    assign S_stage   = norm_sum[0];

    wire sticky;
    assign sticky = sticky_from_norm | S_stage;

    // =========================================================================
    // SPEC: Round to nearest, ties to even (default IEEE 754 rounding)
    // =========================================================================
    // Round-up condition:
    //   (G == 1) AND ((R == 1) OR (sticky == 1) OR (norm_sig[0] == 1))
    // This covers:
    //   - G=1, R=1 or sticky=1: definitely > halfway, round up
    //   - G=1, R=0, sticky=0: exact tie (halfway), round to even (LSB=1 -> round up)
    //   - G=0: round down (truncate)

    wire round_up;
    assign round_up = G && (R || sticky || norm_sig[0]);

    // Rounded significand
    wire [23:0] rounded_sig;
    wire        round_overflow;
    assign {round_overflow, rounded_sig} = {1'b0, norm_sig} + {24'd0, round_up};

    // =========================================================================
    // SPEC: Final exponent adjustment (handle rounding overflow)
    // =========================================================================
    // If rounding causes overflow (rounded_sig == 0 and round_overflow == 1,
    // or more precisely, the 24-bit sig becomes 25 bits with MSB set):
    // Shift right by 1, increment effective exponent.

    wire        final_round_overflow;
    assign final_round_overflow = round_overflow;

    wire [23:0] final_sig_after_round;
    assign final_sig_after_round = final_round_overflow ? {1'b0, rounded_sig[23:1]} : rounded_sig;

    wire signed [9:0] final_eff_exp;
    assign final_eff_exp = $signed(result_eff_exp_signed)
                         + (final_round_overflow ? 10'sd1 : 10'sd0);

    // =========================================================================
    // SPEC: Pack final IEEE 754 result — handle overflow, underflow, normal, zero
    // =========================================================================

    // The 23-bit fraction is the lower 23 bits of the 24-bit significand
    wire [22:0] final_frac;
    assign final_frac = final_sig_after_round[22:0];

    // =========================================================================
    // SPEC: Handle underflow — convert to denormal when effective exponent < -126
    // =========================================================================
    // When final_eff_exp < -126, represent result as denormal or zero.
    // Right-shift amount: rsh = -126 - final_eff_exp
    // The pre-normalized significand is final_sig_after_round (24 bits).
    // Shift right by rsh to convert from normal to denormal representation.

    wire        is_underflow;
    wire signed [9:0] underflow_rsh_signed;
    // FIX: use < instead of <=; effective exponent == -126 produces smallest normal (biased_exp=1)
    assign is_underflow        = (final_eff_exp < (-10'sd126)) && !sum_is_zero;
    assign underflow_rsh_signed = (-10'sd126) - final_eff_exp;

    // Clamp right-shift for underflow to 24 (more than 24 shifts means everything becomes zero)
    wire [4:0] underflow_rsh;
    assign underflow_rsh = (underflow_rsh_signed > 10'sd24) ? 5'd24
                                                             : underflow_rsh_signed[4:0];

    // Extend for underflow shift: {sig, 2'b00, sticky} = 27 bits
    // sticky at bit[0] captures all sub-LSB bits from first rounding
    wire [26:0] underflow_sig_ext;
    assign underflow_sig_ext = {final_sig_after_round, 2'b00, sticky};

    // Right shift the extended value
    wire [26:0] underflow_shifted;
    assign underflow_shifted = underflow_sig_ext >> underflow_rsh;

    // FIX: Compute bits shifted out during underflow right-shift
    // Original underflow_sig_ext positions [rsh-1:0] are shifted out.
    // This includes the old sticky at position 0 (for rsh >= 1).
    // The new underflow sticky = underflow_shifted[0] | OR(bits shifted out)
    wire [26:0] uf_sticky_mask;
    assign uf_sticky_mask = (underflow_rsh == 5'd0)  ? 27'd0 :
                            (underflow_rsh == 5'd1)  ? 27'd1 :
                            (underflow_rsh == 5'd2)  ? 27'd3 :
                            (underflow_rsh == 5'd3)  ? 27'd7 :
                            (underflow_rsh == 5'd4)  ? 27'd15 :
                            (underflow_rsh == 5'd5)  ? 27'd31 :
                            (underflow_rsh == 5'd6)  ? 27'd63 :
                            (underflow_rsh == 5'd7)  ? 27'd127 :
                            (underflow_rsh == 5'd8)  ? 27'd255 :
                            (underflow_rsh == 5'd9)  ? 27'd511 :
                            (underflow_rsh == 5'd10) ? 27'd1023 :
                            (underflow_rsh == 5'd11) ? 27'd2047 :
                            (underflow_rsh == 5'd12) ? 27'd4095 :
                            (underflow_rsh == 5'd13) ? 27'd8191 :
                            (underflow_rsh == 5'd14) ? 27'd16383 :
                            (underflow_rsh == 5'd15) ? 27'd32767 :
                            (underflow_rsh == 5'd16) ? 27'd65535 :
                            (underflow_rsh == 5'd17) ? 27'd131071 :
                            (underflow_rsh == 5'd18) ? 27'd262143 :
                            (underflow_rsh == 5'd19) ? 27'd524287 :
                            (underflow_rsh == 5'd20) ? 27'd1048575 :
                            (underflow_rsh == 5'd21) ? 27'd2097151 :
                            (underflow_rsh == 5'd22) ? 27'd4194303 :
                            (underflow_rsh == 5'd23) ? 27'd8388607 :
                            (underflow_rsh == 5'd24) ? 27'd16777215 :
                                                       27'd33554431;

    wire uf_bits_shifted_out;
    assign uf_bits_shifted_out = |(underflow_sig_ext & uf_sticky_mask);

    // Extract G, R from the underflow-shifted result
    // The shifted significand includes extra bits for rounding
    wire [23:0] uf_sig;
    wire        uf_G, uf_R;
    assign uf_sig = underflow_shifted[26:3];
    assign uf_G   = underflow_shifted[2];
    assign uf_R   = underflow_shifted[1];

    // Underflow sticky: combines shifted-out bits with bit[0] of shifted result
    wire uf_sticky;
    assign uf_sticky = underflow_shifted[0] | uf_bits_shifted_out;

    // SPEC: Round-to-nearest-even on the denormalized result
    wire uf_round_up;
    assign uf_round_up = uf_G && (uf_R || uf_sticky || uf_sig[0]);

    wire [23:0] uf_rounded_sig;
    wire        uf_round_overflow;
    assign {uf_round_overflow, uf_rounded_sig} = {1'b0, uf_sig} + {24'd0, uf_round_up};

    // If rounding overflows the denormal significand, it becomes the smallest normal
    // (biased exponent = 1, mantissa = 0)
    wire [22:0] uf_frac;
    assign uf_frac = uf_rounded_sig[22:0];

    wire uf_is_zero;
    assign uf_is_zero = (uf_rounded_sig == 24'd0) && !uf_round_overflow;

    wire [31:0] underflow_result;
    assign underflow_result = uf_is_zero ? 32'd0 :
                              uf_round_overflow ? {sign_large, 8'd1, 23'd0} :
                              {sign_large, 8'd0, uf_frac};

    // =========================================================================
    // SPEC: Normal-path result — handle zero, overflow, underflow, normal
    // =========================================================================

    // Real normal-path output computation
    reg [31:0] normal_out;
    always @(*) begin
        normal_out = 32'd0;
        // Exact zero from computation
        if (sum_is_zero) begin
            normal_out = 32'd0;  // +0 for roundTiesToEven (cancellation of opposite signs)
        end
        // Underflow
        else if (is_underflow) begin
            normal_out = underflow_result;
        end
        // Overflow
        else if (final_eff_exp > 10'sd127) begin
            normal_out = {sign_large, 8'hFF, 23'd0}; // +/- Infinity
        end
        // Normal result
        else begin
            normal_out = {sign_large, (final_eff_exp[7:0] + 8'd127), final_frac};
        end
    end

    // =========================================================================
    // SPEC: Final result selection — special cases have priority over normal path
    // =========================================================================
    always @(*) begin
        if (is_special)
            result = special_out;
        else
            result = normal_out;
    end

endmodule
