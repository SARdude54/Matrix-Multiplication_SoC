`timescale 1ps/1ps

module mat_acc_tb;

    // DUT inputs
    logic        clk;
    logic        rst;
    logic        en;
    logic        clr;
    logic        valid_in;
    logic [7:0]  a;
    logic [7:0]  b;

    // DUT outputs
    logic [31:0] c;
    logic [7:0]  a_out;
    logic [7:0]  b_out;
    logic        valid_out;

    // Expected accumulator value
    logic [31:0] expected_acc;


    // DUT
    mat_acc dut (
        .clk       (clk),
        .rst       (rst),
        .en        (en),
        .clr       (clr),
        .valid_in  (valid_in),
        .a         (a),
        .b         (b),
        .c         (c),
        .a_out     (a_out),
        .b_out     (b_out),
        .valid_out (valid_out)
    );


    // Clock generation
    
    // Period = 10 ns = 100 MHz
    // timescale = 1 ps
    // 5000 ps = 5 ns
    initial begin
        clk = 1'b0;
        forever #5000 clk = ~clk;
    end


    // Apply DUT inputs on falling edge so they are stable
    // before the next rising edge.
    task automatic apply_inputs(
        input logic       en_t,
        input logic       clr_t,
        input logic       valid_t,
        input logic [7:0] a_t,
        input logic [7:0] b_t
    );
        begin
            @(negedge clk);

            en       = en_t;
            clr      = clr_t;
            valid_in = valid_t;
            a        = a_t;
            b        = b_t;
        end
    endtask


    // Main test sequence
    initial begin

        // Initial values
        rst          = 1'b1;
        en           = 1'b0;
        clr          = 1'b0;
        valid_in     = 1'b0;
        a            = '0;
        b            = '0;
        expected_acc = '0;


        // TEST 1: Reset

        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        @(posedge clk);
        #1;

        if (c !== 32'd0)
            $error(
                "RESET FAIL: c = %0d, expected 0",
                c
            );

        if (a_out !== 8'd0)
            $error(
                "RESET FAIL: a_out = %0d, expected 0",
                a_out
            );

        if (b_out !== 8'd0)
            $error(
                "RESET FAIL: b_out = %0d, expected 0",
                b_out
            );

        if (valid_out !== 1'b0)
            $error(
                "RESET FAIL: valid_out = %b, expected 0",
                valid_out
            );

        $display("TEST 1 PASSED: reset");


        // TEST 2: First MAC
        
        // 3 * 4 = 12
        
        // acc = 0 + 12 = 12

        apply_inputs(
            1'b1,     // en
            1'b0,     // clr
            1'b1,     // valid_in
            8'd3,
            8'd4
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd12;

        if (c !== expected_acc)
            $error(
                "MAC FAIL: c = %0d, expected %0d",
                c,
                expected_acc
            );

        if (a_out !== 8'd3)
            $error(
                "PROPAGATION FAIL: a_out = %0d, expected 3",
                a_out
            );

        if (b_out !== 8'd4)
            $error(
                "PROPAGATION FAIL: b_out = %0d, expected 4",
                b_out
            );

        if (valid_out !== 1'b1)
            $error(
                "VALID FAIL: valid_out = %b, expected 1",
                valid_out
            );

        $display(
            "TEST 2 PASSED: 3 * 4 accumulated, c = %0d",
            c
        );


        // TEST 3: Second MAC
        
        // 5 * 6 = 30
        
        // acc = 12 + 30 = 42

        apply_inputs(
            1'b1,
            1'b0,
            1'b1,
            8'd5,
            8'd6
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd42;

        if (c !== expected_acc)
            $error(
                "MAC FAIL: c = %0d, expected %0d",
                c,
                expected_acc
            );

        if (a_out !== 8'd5)
            $error(
                "PROPAGATION FAIL: a_out = %0d, expected 5",
                a_out
            );

        if (b_out !== 8'd6)
            $error(
                "PROPAGATION FAIL: b_out = %0d, expected 6",
                b_out
            );

        if (valid_out !== 1'b1)
            $error(
                "VALID FAIL: valid_out = %b, expected 1",
                valid_out
            );

        $display(
            "TEST 3 PASSED: 5 * 6 accumulated, c = %0d",
            c
        );


        // TEST 4: valid_in = 0
        
        // a and b should still propagate because en = 1
        // Accumulator should remain unchanged

        apply_inputs(
            1'b1,
            1'b0,
            1'b0,
            8'd10,
            8'd20
        );

        @(posedge clk);
        #1;

        if (c !== expected_acc)
            $error(
                "VALID_IN FAIL: c = %0d, expected %0d",
                c,
                expected_acc
            );

        if (a_out !== 8'd10)
            $error(
                "PROPAGATION FAIL: a_out = %0d, expected 10",
                a_out
            );

        if (b_out !== 8'd20)
            $error(
                "PROPAGATION FAIL: b_out = %0d, expected 20",
                b_out
            );

        if (valid_out !== 1'b0)
            $error(
                "VALID FAIL: valid_out = %b, expected 0",
                valid_out
            );

        $display(
            "TEST 4 PASSED: valid_in=0 prevented accumulation"
        );


        // TEST 5: en = 0
        
        // Entire processing element should freeze

        apply_inputs(
            1'b0,
            1'b0,
            1'b1,
            8'd100,
            8'd200
        );

        @(posedge clk);
        #1;

        if (c !== expected_acc)
            $error(
                "ENABLE FAIL: accumulator changed while en=0"
            );

        if (a_out !== 8'd10)
            $error(
                "ENABLE FAIL: a_out changed while en=0"
            );

        if (b_out !== 8'd20)
            $error(
                "ENABLE FAIL: b_out changed while en=0"
            );

        if (valid_out !== 1'b0)
            $error(
                "ENABLE FAIL: valid_out changed while en=0"
            );

        $display(
            "TEST 5 PASSED: en=0 froze the PE"
        );


        // TEST 6: Re-enable and accumulate
        
        // 2 * 7 = 14
        
        // acc = 42 + 14 = 56

        apply_inputs(
            1'b1,
            1'b0,
            1'b1,
            8'd2,
            8'd7
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd56;

        if (c !== expected_acc)
            $error(
                "MAC FAIL: c = %0d, expected %0d",
                c,
                expected_acc
            );

        if (a_out !== 8'd2)
            $error(
                "PROPAGATION FAIL: a_out = %0d, expected 2",
                a_out
            );

        if (b_out !== 8'd7)
            $error(
                "PROPAGATION FAIL: b_out = %0d, expected 7",
                b_out
            );

        if (valid_out !== 1'b1)
            $error(
                "VALID FAIL: valid_out = %b, expected 1",
                valid_out
            );

        $display(
            "TEST 6 PASSED: accumulation resumed, c = %0d",
            c
        );


        // TEST 7: Maximum unsigned operands
        
        // 255 * 255 = 65025
        
        // acc = 56 + 65025 = 65081

        apply_inputs(
            1'b1,
            1'b0,
            1'b1,
            8'd255,
            8'd255
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd65081;

        if (c !== expected_acc)
            $error(
                "MAX VALUE FAIL: c = %0d, expected %0d",
                c,
                expected_acc
            );

        $display(
            "TEST 7 PASSED: max operands accumulated, c = %0d",
            c
        );


        // TEST 8: clr = 1
        
        // Accumulator should clear to zero.
        
        // Note:
        // a, b, and valid still propagate because en = 1.
        
        // Even though valid_in = 1 and a*b is nonzero,
        // clr has priority over accumulation

        apply_inputs(
            1'b1,
            1'b1,
            1'b1,
            8'd8,
            8'd9
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd0;

        if (c !== expected_acc)
            $error(
                "CLEAR FAIL: c = %0d, expected 0",
                c
            );

        if (a_out !== 8'd8)
            $error(
                "CLEAR PROPAGATION FAIL: a_out = %0d, expected 8",
                a_out
            );

        if (b_out !== 8'd9)
            $error(
                "CLEAR PROPAGATION FAIL: b_out = %0d, expected 9",
                b_out
            );

        if (valid_out !== 1'b1)
            $error(
                "CLEAR VALID FAIL: valid_out = %b, expected 1",
                valid_out
            );

        $display(
            "TEST 8 PASSED: clr cleared accumulator"
        );


        // TEST 9: Accumulate after clear
        
        // 4 * 5 = 20
        
        // acc = 0 + 20 = 20

        apply_inputs(
            1'b1,
            1'b0,
            1'b1,
            8'd4,
            8'd5
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd20;

        if (c !== expected_acc)
            $error(
                "POST-CLEAR MAC FAIL: c = %0d, expected %0d",
                c,
                expected_acc
            );

        $display(
            "TEST 9 PASSED: accumulation after clear, c = %0d",
            c
        );


        // TEST 10: clr = 1 while en = 0
        
        // Because clr is inside "else if (en)",
        // the PE must freeze and c should remain 20

        apply_inputs(
            1'b0,
            1'b1,
            1'b1,
            8'd50,
            8'd50
        );

        @(posedge clk);
        #1;

        if (c !== expected_acc)
            $error(
                "CLEAR/ENABLE FAIL: acc changed with clr=1, en=0. c=%0d expected=%0d",
                c,
                expected_acc
            );

        if (a_out !== 8'd4)
            $error(
                "CLEAR/ENABLE FAIL: a_out changed while en=0"
            );

        if (b_out !== 8'd5)
            $error(
                "CLEAR/ENABLE FAIL: b_out changed while en=0"
            );

        if (valid_out !== 1'b1)
            $error(
                "CLEAR/ENABLE FAIL: valid_out changed while en=0"
            );

        $display(
            "TEST 10 PASSED: clr does not clear while en=0"
        );


        // TEST 11: Clear with valid_in = 0
    
        // clr should still clear because clr has priority over
        // valid_in

        apply_inputs(
            1'b1,
            1'b1,
            1'b0,
            8'd30,
            8'd40
        );

        @(posedge clk);
        #1;

        expected_acc = 32'd0;

        if (c !== expected_acc)
            $error(
                "CLEAR FAIL: clr did not clear when valid_in=0"
            );

        if (a_out !== 8'd30)
            $error(
                "PROPAGATION FAIL: a_out = %0d, expected 30",
                a_out
            );

        if (b_out !== 8'd40)
            $error(
                "PROPAGATION FAIL: b_out = %0d, expected 40",
                b_out
            );

        if (valid_out !== 1'b0)
            $error(
                "VALID FAIL: valid_out = %b, expected 0",
                valid_out
            );

        $display(
            "TEST 11 PASSED: clr works independently of valid_in"
        );

 
        // finish
        $display("");
        $display("==========================================");
        $display("ALL mat_acc TESTS COMPLETED");
        $display("Final accumulator value = %0d", c);
        $display("==========================================");
        $display("");

        #10000;
        $finish;

    end

endmodule