`timescale 1ns / 1ps
module state_output_controller (
    input  wire [2:0] state,
    input  wire       water_level_full,
    output reg        water_valve,
    output reg        drain_pump,
    output reg        done_led,
    output reg        buzzer_signal
);

localparam IDLE       = 3'd0,
           FILL_WATER = 3'd1,
           WASH       = 3'd2,
           RINSE      = 3'd3,
           SPIN       = 3'd4,
           DRAIN      = 3'd5,
           COMPLETE   = 3'd6;

always @(*) begin
    water_valve   = 1'b0;
    drain_pump    = 1'b0;
    done_led      = 1'b0;
    buzzer_signal = 1'b0;

    case (state)
        FILL_WATER: begin
            water_valve = ~water_level_full;
        end

        DRAIN: begin
            drain_pump = 1'b1;
        end

        COMPLETE: begin
            done_led      = 1'b1;
            buzzer_signal = 1'b1;
        end

        default: begin
            water_valve   = 1'b0;
            drain_pump    = 1'b0;
            done_led      = 1'b0;
            buzzer_signal = 1'b0;
        end
    endcase
end

endmodule