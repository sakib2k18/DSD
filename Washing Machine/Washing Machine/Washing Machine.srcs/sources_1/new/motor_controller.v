`timescale 1ns / 1ps
module motor_controller (
    input  wire [2:0] state,
    input  wire       door_closed,
    output reg        motor_on,
    output reg        motor_dir
);

localparam IDLE       = 3'd0,
           FILL_WATER = 3'd1,
           WASH       = 3'd2,
           RINSE      = 3'd3,
           SPIN       = 3'd4,
           DRAIN      = 3'd5,
           COMPLETE   = 3'd6;

always @(*) begin
    motor_on  = 1'b0;
    motor_dir = 1'b0;

    case (state)
        WASH: begin
            motor_on  = door_closed ? 1'b1 : 1'b0;
            motor_dir = 1'b1;
        end

        RINSE: begin
            motor_on  = door_closed ? 1'b1 : 1'b0;
            motor_dir = 1'b0;
        end

        SPIN: begin
            motor_on  = door_closed ? 1'b1 : 1'b0;
            motor_dir = 1'b1;
        end

        default: begin
            motor_on  = 1'b0;
            motor_dir = 1'b0;
        end
    endcase
end

endmodule