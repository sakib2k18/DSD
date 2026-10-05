`timescale 1ns / 1ps
module seven_segment_driver (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] display_value,
    output reg  [6:0]  seg,
    output reg  [3:0]  an
);

reg [17:0] refresh_count;
reg [1:0]  digit_sel;
reg [3:0]  digit;

wire [3:0] state_ones;
wire [3:0] state_tens;
wire [3:0] timer_ones;
wire [3:0] timer_tens;

assign state_ones = display_value[7:0] % 10;
assign state_tens = display_value[7:0] / 10;
assign timer_ones = display_value[15:8] % 10;
assign timer_tens = display_value[15:8] / 10;

// Refresh counter for multiplexing (18-bit for ~380Hz refresh rate)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        refresh_count <= 18'd0;
    end else begin
        refresh_count <= refresh_count + 1'b1;
    end
end

always @(*) begin
    digit_sel = refresh_count[17:16];
end

always @(*) begin
    case (digit_sel)
        2'b00: begin
            an    = 4'b1110; // Rightmost digit (State Ones)
            digit = state_ones;
        end
        2'b01: begin
            an    = 4'b1101; // Second digit (State Tens)
            digit = state_tens;
        end
        2'b10: begin
            an    = 4'b1011; // Third digit (Timer Ones)
            digit = timer_ones;
        end
        2'b11: begin
            an    = 4'b0111; // Leftmost digit (Timer Tens)
            digit = timer_tens;
        end
    endcase
end

// Common-anode 7-seg decoder (active low)
always @(*) begin
    case (digit)
        4'd0: seg = 7'b1000000;
        4'd1: seg = 7'b1111001;
        4'd2: seg = 7'b0100100;
        4'd3: seg = 7'b0110000;
        4'd4: seg = 7'b0011001;
        4'd5: seg = 7'b0010010;
        4'd6: seg = 7'b0000010;
        4'd7: seg = 7'b1111000;
        4'd8: seg = 7'b0000000;
        4'd9: seg = 7'b0010000;
        default: seg = 7'b1111111;
    endcase
end

endmodule