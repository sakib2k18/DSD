`timescale 1ns / 1ps
module fsm_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire       start_button,
    input  wire       cancel_button,      // 1-clock pulse: abort current cycle
    input  wire       water_level_full,
    input  wire       wash_timer_done,
    input  wire       rinse_timer_done,
    input  wire       spin_timer_done,
    input  wire       drain_timer_done,
    input  wire [7:0] rinse_count,
    input  wire [7:0] rinse_counter,
    output reg  [2:0] current_state,
    output reg  [2:0] next_state
);

localparam IDLE       = 3'd0,
           FILL_WATER = 3'd1,
           WASH       = 3'd2,
           RINSE      = 3'd3,
           SPIN       = 3'd4,
           DRAIN      = 3'd5,
           COMPLETE   = 3'd6;

// State register
always @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// Next-state logic.
// cancel_button (as a 1-clock pulse from the top module) immediately forces
// the machine back to IDLE from any non-IDLE state - this is the Cancel
// button requested in the hardware spec.
always @(*) begin
    next_state = current_state;

    if (cancel_button && current_state != IDLE) begin
        next_state = IDLE;
    end else begin
        case (current_state)
            IDLE: begin
                if (start_button)
                    next_state = FILL_WATER;
            end

            FILL_WATER: begin
                if (water_level_full)
                    next_state = WASH;
            end

            WASH: begin
                if (wash_timer_done)
                    next_state = RINSE;
            end

            RINSE: begin
                if (rinse_timer_done) begin
                    // Check if more rinse cycles are needed
                    if (rinse_counter < rinse_count)
                        next_state = RINSE;  // Repeat rinse
                    else
                        next_state = SPIN;   // Move to spin
                end
            end

            SPIN: begin
                if (spin_timer_done)
                    next_state = DRAIN;
            end

            DRAIN: begin
                if (drain_timer_done)
                    next_state = COMPLETE;
            end

            COMPLETE: begin
                next_state = COMPLETE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
end

endmodule
