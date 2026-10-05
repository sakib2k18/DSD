`timescale 1ns / 1ps
module timer_module (
    input  wire       clk,
    input  wire       reset,
    input  wire       slow_tick,
    input  wire       load,
    input  wire       enable,
    input  wire [7:0] load_value,
    output reg  [7:0] count,
    output wire       done
);

assign done = (count == 8'd0);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= 8'd0;
    end else if (load) begin
        count <= load_value;
    end else if (enable && slow_tick && count != 8'd0) begin
        count <= count - 1'b1;
    end
end

endmodule