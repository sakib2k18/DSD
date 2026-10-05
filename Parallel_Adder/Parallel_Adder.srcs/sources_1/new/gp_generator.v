module gp_generator (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] g,
    output wire [3:0] p
);

    assign g = a & b;    // Generate
    assign p = a ^ b;    // Propagate

endmodule
