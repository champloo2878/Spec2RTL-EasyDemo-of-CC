`timescale 1ns / 1ps

module fadd_tb;
    // === DUT Inputs ===
    reg  [31:0] a;
    reg  [31:0] b;

    // === DUT Output ===
    wire [31:0] result;

    // === Test Tracking ===
    integer test_num;
    integer pass_count;
    integer fail_count;
    reg [31:0] expected_result;

    // === DUT Instantiation ===
    fadd dut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        pass_count = 0;
        fail_count = 0;

        // ========== Test Vectors ==========

        // Test 1: zero+zero = +0
        test_num = 1;
        a = 32'h00000000;
        b = 32'h00000000;
        expected_result = 32'h00000000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: zero+zero = +0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: zero+zero = +0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 2: 1.0+0.0 = 1.0
        test_num = 2;
        a = 32'h3f800000;
        b = 32'h00000000;
        expected_result = 32'h3f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.0+0.0 = 1.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.0+0.0 = 1.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 3: 1.0+2.0 = 3.0
        test_num = 3;
        a = 32'h3f800000;
        b = 32'h40000000;
        expected_result = 32'h40400000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.0+2.0 = 3.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.0+2.0 = 3.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 4: -1.0+2.0 = 1.0
        test_num = 4;
        a = 32'hbf800000;
        b = 32'h40000000;
        expected_result = 32'h3f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: -1.0+2.0 = 1.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: -1.0+2.0 = 1.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 5: 1.5+2.5 = 4.0
        test_num = 5;
        a = 32'h3fc00000;
        b = 32'h40200000;
        expected_result = 32'h40800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.5+2.5 = 4.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.5+2.5 = 4.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 6: 100.0+0.5 = 100.5
        test_num = 6;
        a = 32'h42c80000;
        b = 32'h3f000000;
        expected_result = 32'h42c90000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 100.0+0.5 = 100.5", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 100.0+0.5 = 100.5 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 7: -3.5+1.5 = -2.0
        test_num = 7;
        a = 32'hc0600000;
        b = 32'h3fc00000;
        expected_result = 32'hc0000000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: -3.5+1.5 = -2.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: -3.5+1.5 = -2.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 8: 1.5+(-0.5) = 1.0
        test_num = 8;
        a = 32'h3fc00000;
        b = 32'hbf000000;
        expected_result = 32'h3f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.5+(-0.5) = 1.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.5+(-0.5) = 1.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 9: 65536.0+1.0 = 65537.0
        test_num = 9;
        a = 32'h47800000;
        b = 32'h3f800000;
        expected_result = 32'h47800080;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 65536.0+1.0 = 65537.0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 65536.0+1.0 = 65537.0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 10: min_normal+min_normal = next_normal
        test_num = 10;
        a = 32'h00800000;
        b = 32'h00800000;
        expected_result = 32'h01000000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: min_normal+min_normal = next_normal", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: min_normal+min_normal = next_normal — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 11: max_normal+1.0 = max_normal (1.0 negligible)
        test_num = 11;
        a = 32'h7f7fffff;
        b = 32'h3f800000;
        expected_result = 32'h7f7fffff;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: max_normal+1.0 = max_normal (1.0 negligible)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: max_normal+1.0 = max_normal (1.0 negligible) — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 12: 2^{127}+2^{127}=overflow_to_+Inf
        test_num = 12;
        a = 32'h7f000000;
        b = 32'h7f000000;
        expected_result = 32'h7f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 2^{127}+2^{127}=overflow_to_+Inf", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 2^{127}+2^{127}=overflow_to_+Inf — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 13: QNaN+normal = NaN (propagate first NaN)
        test_num = 13;
        a = 32'h7fc00000;
        b = 32'h3f800000;
        expected_result = 32'h7fc00000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: QNaN+normal = NaN (propagate first NaN)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: QNaN+normal = NaN (propagate first NaN) — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 14: +Inf+normal = +Inf
        test_num = 14;
        a = 32'h7f800000;
        b = 32'h3f800000;
        expected_result = 32'h7f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: +Inf+normal = +Inf", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: +Inf+normal = +Inf — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 15: -Inf+normal = -Inf
        test_num = 15;
        a = 32'hff800000;
        b = 32'h3f800000;
        expected_result = 32'hff800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: -Inf+normal = -Inf", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: -Inf+normal = -Inf — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 16: +Inf+(+Inf) = +Inf
        test_num = 16;
        a = 32'h7f800000;
        b = 32'h7f800000;
        expected_result = 32'h7f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: +Inf+(+Inf) = +Inf", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: +Inf+(+Inf) = +Inf — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 17: +Inf+(-Inf) = NaN
        test_num = 17;
        a = 32'h7f800000;
        b = 32'hff800000;
        expected_result = 32'h7fc00000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: +Inf+(-Inf) = NaN", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: +Inf+(-Inf) = NaN — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 18: 1.0+(-1.0) = +0 (exact cancellation)
        test_num = 18;
        a = 32'h3f800000;
        b = 32'hbf800000;
        expected_result = 32'h00000000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.0+(-1.0) = +0 (exact cancellation)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.0+(-1.0) = +0 (exact cancellation) — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 19: 8.0+(-7.0) = 1.0 (cancellation)
        test_num = 19;
        a = 32'h41000000;
        b = 32'hc0e00000;
        expected_result = 32'h3f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 8.0+(-7.0) = 1.0 (cancellation)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 8.0+(-7.0) = 1.0 (cancellation) — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 20: -0+(-0) = -0
        test_num = 20;
        a = 32'h80000000;
        b = 32'h80000000;
        expected_result = 32'h80000000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: -0+(-0) = -0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: -0+(-0) = -0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 21: 1.0+2^{-24} = 1.0 (RNE tie LSB_even=donot_round)
        test_num = 21;
        a = 32'h3f800000;
        b = 32'h33800000;
        expected_result = 32'h3f800000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.0+2^{-24} = 1.0 (RNE tie LSB_even=donot_round)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.0+2^{-24} = 1.0 (RNE tie LSB_even=donot_round) — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 22: 1.0+2^{-23}+2^{-24} = 1.0+2^{-22} (RNE tie LSB_odd=round_to_even)
        test_num = 22;
        a = 32'h3f800001;
        b = 32'h33800000;
        expected_result = 32'h3f800002;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: 1.0+2^{-23}+2^{-24} = 1.0+2^{-22} (RNE tie LSB_odd=round_to_even)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: 1.0+2^{-23}+2^{-24} = 1.0+2^{-22} (RNE tie LSB_odd=round_to_even) — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 23: NaN+Inf = NaN
        test_num = 23;
        a = 32'h7fc00000;
        b = 32'h7f800000;
        expected_result = 32'h7fc00000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: NaN+Inf = NaN", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: NaN+Inf = NaN — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 24: min_subnormal+min_subnormal = 2*min_subnormal
        test_num = 24;
        a = 32'h00000001;
        b = 32'h00000001;
        expected_result = 32'h00000002;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: min_subnormal+min_subnormal = 2*min_subnormal", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: min_subnormal+min_subnormal = 2*min_subnormal — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 25: min_subnormal+min_normal = normal_with_LSB_set
        test_num = 25;
        a = 32'h00000001;
        b = 32'h00800000;
        expected_result = 32'h00800001;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: min_subnormal+min_normal = normal_with_LSB_set", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: min_subnormal+min_normal = normal_with_LSB_set — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // Test 26: -0+(+0) = +0
        test_num = 26;
        a = 32'h80000000;
        b = 32'h00000000;
        expected_result = 32'h00000000;
        #10;
        if (result === expected_result) begin
            $display("[PASS] Test %0d: -0+(+0) = +0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: -0+(+0) = +0 — expected %h, got %h", test_num, expected_result, result);
            fail_count = fail_count + 1;
        end

        // ========== Summary ==========
        $display("---");
        $display("Summary: %0d/%0d passed, %0d failed", pass_count, pass_count + fail_count, fail_count);
        $finish;
    end
endmodule
