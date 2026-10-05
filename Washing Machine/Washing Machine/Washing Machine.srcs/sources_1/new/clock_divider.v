`timescale 1ns / 1ps
module clock_divider #(
    parameter DIVISOR = 100_000_000  // 1-second pulse at 100 MHz
)(
    input  wire clk,
    input  wire reset,
    output reg  slow_tick
);

reg [31:0] count;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        count     <= 32'd0;
        slow_tick <= 1'b0;
    end else begin
        if (count == DIVISOR - 1) begin
            count     <= 32'd0;
            slow_tick <= 1'b1;
        end else begin
            count     <= count + 1'b1;
            slow_tick <= 1'b0;
        end
    end
end

endmodule