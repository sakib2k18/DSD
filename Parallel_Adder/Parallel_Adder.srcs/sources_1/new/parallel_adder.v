module parallel_adder (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);

    wire [3:0] g, p;
    wire [4:1] c;

    // Generate & Propagate
    gp_generator GP (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );

    // Carry Look-Ahead Generator
    cla_generator CLG (
        .g(g),
        .p(p),
        .c0(cin),
        .c(c)
    );

    // Full Adders
    full_adder FA0 (
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .sum(sum[0]),
        .cout()
    );

    full_adder FA1 (
        .a(a[1]),
        .b(b[1]),
        .cin(c[1]),
        .sum(sum[1]),
        .cout()
    );

    full_adder FA2 (
        .a(a[2]),
        .b(b[2]),
        .cin(c[2]),
        .sum(sum[2]),
        .cout()
    );

    full_adder FA3 (
        .a(a[3]),
        .b(b[3]),
        .cin(c[3]),
        .sum(sum[3]),
        .cout()
    );

    assign cout = c[4];

endmodule
