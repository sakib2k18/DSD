`timescale 1ns / 1ps

module simulate_parallel_adder;

    reg  [3:0] a;
    reg  [3:0] b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;

    // Instantiate the DUT (Device Under Test)
    parallel_adder DUT (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        // Monitor values
        $monitor("Time=%0t | A=%b B=%b Cin=%b -> Sum=%b Cout=%b",
                  $time, a, b, cin, sum, cout);

        // Test case 1
        a = 4'b0000; b = 4'b0000; cin = 0;
        #10;

        // Test case 2
        a = 4'b0011; b = 4'b0101; cin = 0;
        #10;

        // Test case 3
        a = 4'b0111; b = 4'b0001; cin = 0;
        #10;

        // Test case 4 (carry in)
        a = 4'b1010; b = 4'b0101; cin = 1;
        #10;

        // Test case 5 (overflow)
        a = 4'b1111; b = 4'b1111; cin = 0;
        #10;

        // End simulation
        $finish;
    end

endmodule
