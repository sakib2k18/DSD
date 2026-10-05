`timescale 1ns / 1ps
module memory_module (
    input  wire       clk,
    input  wire       reset,
    input  wire       write_enable,
    input  wire [2:0] write_addr,
    input  wire [7:0] write_data,
    input  wire [2:0] read_addr_1,
    input  wire [2:0] read_addr_2,
    output reg  [7:0] read_data_1,
    output reg  [7:0] read_data_2
);

// Memory addresses
localparam ADDR_STATE       = 3'd0,
           ADDR_WASH_TIMER = 3'd1,
           ADDR_RINSE_TIMER= 3'd2,
           ADDR_SPIN_TIMER = 3'd3,
           ADDR_DRAIN_TIMER= 3'd4,
           ADDR_RINSE_COUNTER = 3'd5,
           ADDR_MODE_REG   = 3'd6,
           ADDR_RESERVED   = 3'd7;

reg [7:0] memory [0:7];

// Initialize memory on reset
always @(posedge clk or posedge reset) begin
    if (reset) begin
        memory[ADDR_STATE]         <= 8'd0;
        memory[ADDR_WASH_TIMER]    <= 8'd0;
        memory[ADDR_RINSE_TIMER]   <= 8'd0;
        memory[ADDR_SPIN_TIMER]    <= 8'd0;
        memory[ADDR_DRAIN_TIMER]   <= 8'd0;
        memory[ADDR_RINSE_COUNTER] <= 8'd0;
        memory[ADDR_MODE_REG]      <= 8'd0;
        memory[ADDR_RESERVED]      <= 8'd0;
    end else if (write_enable) begin
        memory[write_addr] <= write_data;
    end
end

// Asynchronous read operations
always @(*) begin
    read_data_1 = memory[read_addr_1];
    read_data_2 = memory[read_addr_2];
end

endmodule
