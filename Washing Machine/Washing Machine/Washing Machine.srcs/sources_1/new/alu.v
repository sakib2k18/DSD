`timescale 1ns / 1ps
module alu (
    input  wire [7:0] operand_a,
    input  wire [7:0] operand_b,
    input  wire [2:0] operation,
    output reg  [7:0] result,
    output wire       zero_flag,
    output wire       borrow_flag
);

localparam ALU_ADD  = 3'd0,
           ALU_SUB  = 3'd1,
           ALU_CMP  = 3'd2,
           ALU_INC  = 3'd3,
           ALU_DEC  = 3'd4;

wire [8:0] sub_result;

assign sub_result = {1'b0, operand_a} - {1'b0, operand_b};
assign borrow_flag = sub_result[8];
assign zero_flag = (result == 8'd0);

always @(*) begin
    case (operation)
        ALU_ADD: begin
            result = operand_a + operand_b;
        end
        ALU_SUB: begin
            result = operand_a - operand_b;
        end
        ALU_CMP: begin
            result = (operand_a == operand_b) ? 8'd1 : 8'd0;
        end
        ALU_INC: begin
            result = operand_a + 8'd1;
        end
        ALU_DEC: begin
            result = operand_a - 8'd1;
        end
        default: begin
            result = 8'd0;
        end
    endcase
end

endmodule
