`timescale 1ns / 1ps
module led_state_indicator (
    input  wire [2:0] state,
    output reg  [6:0] state_leds
);

localparam IDLE       = 3'd0,
           FILL_WATER = 3'd1,
           WASH       = 3'd2,
           RINSE      = 3'd3,
           SPIN       = 3'd4,
           DRAIN      = 3'd5,
           COMPLETE   = 3'd6;

always @(*) begin
    case (state)
        IDLE:       state_leds = 7'b0000001;
        FILL_WATER: state_leds = 7'b0000010;
        WASH:       state_leds = 7'b0000100;
        RINSE:      state_leds = 7'b0001000;
        SPIN:       state_leds = 7'b0010000;
        DRAIN:      state_leds = 7'b0100000;
        COMPLETE:   state_leds = 7'b1000000;
        default:    state_leds = 7'b0000001;
    endcase
end

endmodule