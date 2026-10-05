`timescale 1ns / 1ps
module mode_selector (
    input  wire [1:0] mode_select,
    output reg  [7:0] wash_time,
    output reg  [7:0] rinse_time,
    output reg  [7:0] spin_time
);

always @(*) begin
    case (mode_select)
        2'b00: begin // Quick
            wash_time  = 8'd5;
            rinse_time = 8'd3;
            spin_time  = 8'd4;
        end
        2'b01: begin // Normal
            wash_time  = 8'd10;
            rinse_time = 8'd5;
            spin_time  = 8'd6;
        end
        2'b10: begin // Heavy
            wash_time  = 8'd15;
            rinse_time = 8'd8;
            spin_time  = 8'd10;
        end
        default: begin // default to Quick
            wash_time  = 8'd5;
            rinse_time = 8'd3;
            spin_time  = 8'd4;
        end
    endcase
end

endmodule