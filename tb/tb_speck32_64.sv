`timescale 1ns/1ps

module tb_speck32_64;

    logic        clk;
    logic        rst_n;
    logic        start;
    logic [63:0] key_in;
    logic [31:0] plaintext;
    logic [31:0] ciphertext;
    logic        valid_out;

    integer pass_count;
    integer fail_count;
    integer total_count;
    integer i;

    speck32_64_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .key_in     (key_in),
        .plaintext  (plaintext),
        .ciphertext (ciphertext),
        .valid_out  (valid_out)
    );

    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Independent reference model for SPECK32/64.
    // ---------------------------------------------------------------
    function automatic [15:0] ror7(input [15:0] a);
        ror7 = {a[6:0], a[15:7]};
    endfunction

    function automatic [15:0] rol2(input [15:0] a);
        rol2 = {a[13:0], a[15:14]};
    endfunction

    function automatic [31:0] speck_reference(
        input [63:0] key,
        input [31:0] pt
    );
        reg [15:0] x, y;
        reg [15:0] rk;
        reg [15:0] l0, l1, l2;
        reg [15:0] l_new;
        reg [15:0] rk_new;
        reg [15:0] x_new;
        reg [15:0] y_new;
        integer r;

        begin
            x  = pt[31:16];
            y  = pt[15:0];

            // key = {k3,k2,k1,k0}
            rk = key[15:0];
            l0 = key[31:16];
            l1 = key[47:32];
            l2 = key[63:48];

            for (r = 0; r < 22; r = r + 1) begin
                x_new = (ror7(x) + y) ^ rk;
                y_new = rol2(y) ^ x_new;

                x = x_new;
                y = y_new;

                if (r < 21) begin
                    l_new = (ror7(l0) + rk) ^ r[15:0];
                    rk_new = rol2(rk) ^ l_new;

                    l0 = l1;
                    l1 = l2;
                    l2 = l_new;
                    rk = rk_new;
                end
            end

            speck_reference = {x, y};
        end
    endfunction

    task automatic run_test(
        input integer test_no,
        input [63:0] k,
        input [31:0] p
    );
        reg [31:0] expected;
        integer cycles;

        begin
            expected = speck_reference(k, p);

            @(negedge clk);
            key_in    = k;
            plaintext = p;
            start     = 1'b1;

            @(negedge clk);
            start = 1'b0;

            cycles = 0;
            while (!valid_out && cycles < 30) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            total_count = total_count + 1;

            if (valid_out && ciphertext === expected) begin
                pass_count = pass_count + 1;
                $display("PASS test %0d: key=%016h pt=%08h ct=%08h",
                         test_no, k, p, ciphertext);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL test %0d: key=%016h pt=%08h got=%08h expected=%08h valid=%b",
                         test_no, k, p, ciphertext, expected, valid_out);
            end

            @(negedge clk);
        end
    endtask

    reg [63:0] rand_key;
    reg [31:0] rand_pt;

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        start       = 1'b0;
        key_in      = 64'd0;
        plaintext   = 32'd0;
        pass_count  = 0;
        fail_count  = 0;
        total_count = 0;

        // Reset.
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Mandatory official vector.
        run_test(
            1,
            64'h1918_1110_0908_0100,
            32'h6574_694c
        );

        // 64 deterministic pseudo-random tests.
        // The reference model above calculates the expected value.
        for (i = 0; i < 64; i = i + 1) begin
            rand_key = {$random, $random};
            rand_pt  = $random;
            run_test(i + 2, rand_key, rand_pt);
        end

        $display("--------------------------------------------------");
        $display("SPECK32/64 SELF-CHECK SUMMARY");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("TOTAL = %0d", total_count);

        if ((fail_count == 0) && (pass_count == total_count))
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $display("--------------------------------------------------");

        $finish;
    end

endmodule
