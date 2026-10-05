module cla_generator (
    input  wire [3:0] g,   // Generate
    input  wire [3:0] p,   // Propagate
    input  wire       c0,  // Input carry
    output wire [4:1] c    // Carries C1 to C4
);

    assign c[1] = g[0] | (p[0] & c0);

    assign c[2] = g[1] 
                | (p[1] & g[0]) 
                | (p[1] & p[0] & c0);

    assign c[3] = g[2] 
                | (p[2] & g[1]) 
                | (p[2] & p[1] & g[0]) 
                | (p[2] & p[1] & p[0] & c0);

    assign c[4] = g[3] 
                | (p[3] & g[2]) 
                | (p[3] & p[2] & g[1]) 
                | (p[3] & p[2] & p[1] & g[0]) 
                | (p[3] & p[2] & p[1] & p[0] & c0);

endmodule
