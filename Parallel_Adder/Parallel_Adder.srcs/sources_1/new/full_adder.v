module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    wire s1;
    wire c1;
    wire c2;

    // First half adder
    half_adder HA1 (
        .a(a),
        .b(b),
        .sum(s1),
        .carry(c1)
    );

    // Second half adder
    half_adder HA2 (
        .a(s1),
        .b(cin),
        .sum(sum),
        .carry(c2)
    );

    // Final carry
    assign cout = c1 | c2;

endmodule
