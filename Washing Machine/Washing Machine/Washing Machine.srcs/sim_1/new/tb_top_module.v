`timescale 1ns/1ps

module tb_top_module;

reg clk;
reg reset;
reg start_button;
reg confirm_button;
reg cancel_button;
reg door_closed;
reg water_level_full;
reg [1:0] mode_select;

wire motor_on;
wire motor_dir;
wire water_valve;
wire drain_pump;
wire [6:0] state_leds;
wire [6:0] seg;
wire [3:0] an;
wire done_led;
wire buzzer_signal;

integer pass_count;
integer fail_count;

// state-visit flags
reg seen_idle;
reg seen_fill;
reg seen_wash;
reg seen_rinse;
reg seen_spin;
reg seen_drain;
reg seen_complete;

// cycle counters for each state
integer idle_cycles;
integer fill_cycles;
integer wash_cycles;
integer rinse_cycles;
integer spin_cycles;
integer drain_cycles;
integer complete_cycles;

// per-test markers
integer test_pass;
integer test_fail;

top_module #(
    .CLK_DIVISOR(10),
    .DRAIN_TIME(8'd4)
) dut (
    .clk(clk),
    .reset(reset),
    .start_button(start_button),
    .confirm_button(confirm_button),
    .cancel_button(cancel_button),
    .door_closed(door_closed),
    .water_level_full(water_level_full),
    .mode_select(mode_select),
    .motor_on(motor_on),
    .motor_dir(motor_dir),
    .water_valve(water_valve),
    .drain_pump(drain_pump),
    .state_leds(state_leds),
    .seg(seg),
    .an(an),
    .done_led(done_led),
    .buzzer_signal(buzzer_signal)
);

always #5 clk = ~clk;

// ------------------------------
// Count time spent in each state
// ------------------------------
always @(posedge clk) begin
    case (state_leds)
        7'b0000001: begin
            seen_idle   <= 1'b1;
            idle_cycles <= idle_cycles + 1;
        end
        7'b0000010: begin
            seen_fill   <= 1'b1;
            fill_cycles <= fill_cycles + 1;
        end
        7'b0000100: begin
            seen_wash   <= 1'b1;
            wash_cycles <= wash_cycles + 1;
        end
        7'b0001000: begin
            seen_rinse    <= 1'b1;
            rinse_cycles  <= rinse_cycles + 1;
        end
        7'b0010000: begin
            seen_spin   <= 1'b1;
            spin_cycles <= spin_cycles + 1;
        end
        7'b0100000: begin
            seen_drain   <= 1'b1;
            drain_cycles <= drain_cycles + 1;
        end
        7'b1000000: begin
            seen_complete   <= 1'b1;
            complete_cycles <= complete_cycles + 1;
        end
    endcase
end

// ------------------------------
// Utility tasks
// ------------------------------
task init_all;
begin
    clk              = 0;
    reset            = 0;
    start_button     = 0;
    confirm_button   = 0;
    cancel_button    = 0;
    door_closed      = 0;
    water_level_full = 0;
    mode_select      = 2'b00;

    pass_count = 0;
    fail_count = 0;

    seen_idle     = 0;
    seen_fill     = 0;
    seen_wash     = 0;
    seen_rinse    = 0;
    seen_spin     = 0;
    seen_drain    = 0;
    seen_complete = 0;

    idle_cycles     = 0;
    fill_cycles     = 0;
    wash_cycles     = 0;
    rinse_cycles    = 0;
    spin_cycles     = 0;
    drain_cycles    = 0;
    complete_cycles = 0;
end
endtask

task clear_seen_flags;
begin
    seen_idle     = 0;
    seen_fill     = 0;
    seen_wash     = 0;
    seen_rinse    = 0;
    seen_spin     = 0;
    seen_drain    = 0;
    seen_complete = 0;
end
endtask

task do_reset;
begin
    reset = 1;
    start_button = 0;
    confirm_button = 0;
    cancel_button = 0;
    water_level_full = 0;
    #20;
    reset = 0;
    #20;
end
endtask

// Pulse the CONFIRM button so the mode gets latched (required before
// start_button will be honoured by the FSM).
task press_confirm;
begin
    confirm_button = 1;
    #10;
    confirm_button = 0;
    #10;
end
endtask

task press_start;
begin
    // Make sure the mode is locked first - press_confirm is idempotent
    press_confirm;
    start_button = 1;
    #10;
    start_button = 0;
end
endtask

task check;
    input condition;
    input [255:0] msg;
begin
    if (condition) begin
        $display("PASS: %0s", msg);
        pass_count = pass_count + 1;
        test_pass = test_pass + 1;
    end else begin
        $display("FAIL: %0s", msg);
        fail_count = fail_count + 1;
        test_fail = test_fail + 1;
    end
end
endtask

task print_test_summary;
    input [255:0] test_name;
begin
    $display("---- %0s SUMMARY ----", test_name);
    $display("PASS in this test = %0d", test_pass);
    $display("FAIL in this test = %0d", test_fail);
end
endtask

task print_state_time_report;
begin
    $display("\n===== STATE TIME REPORT =====");
    $display("Clock period = 10 ns");
    $display("IDLE       : %0d cycles  (%0d ns)", idle_cycles,     idle_cycles*10);
    $display("FILL_WATER : %0d cycles  (%0d ns)", fill_cycles,     fill_cycles*10);
    $display("WASH       : %0d cycles  (%0d ns)", wash_cycles,     wash_cycles*10);
    $display("RINSE      : %0d cycles  (%0d ns)", rinse_cycles,    rinse_cycles*10);
    $display("SPIN       : %0d cycles  (%0d ns)", spin_cycles,     spin_cycles*10);
    $display("DRAIN      : %0d cycles  (%0d ns)", drain_cycles,    drain_cycles*10);
    $display("COMPLETE   : %0d cycles  (%0d ns)", complete_cycles, complete_cycles*10);
end
endtask

// ------------------------------
// Main test sequence
// ------------------------------
initial begin
    init_all;

    // =========================================
    // TEST 1: QUICK MODE FULL CYCLE
    // =========================================
//    test_pass = 0; test_fail = 0;
//    clear_seen_flags;
//    $display("\n===== TEST 1: QUICK MODE FULL CYCLE =====");
//    do_reset;
//    door_closed = 1;
//    mode_select = 2'b00;
//    press_start;

//    #100;
//    check(state_leds == 7'b0000010, "Entered FILL_WATER after start");

//    water_level_full = 1;
//    #50;
//    check(seen_wash, "Entered WASH in Quick mode");

//    #1200;
//    check(seen_idle,     "Visited IDLE");
//    check(seen_fill,     "Visited FILL_WATER");
//    check(seen_wash,     "Visited WASH");
//    check(seen_rinse,    "Visited RINSE");
//    check(seen_spin,     "Visited SPIN");
//    check(seen_drain,    "Visited DRAIN");
//    check(seen_complete, "Visited COMPLETE");
//    check(done_led == 1'b1, "done_led active in COMPLETE");
//    print_test_summary("TEST 1");

//    // =========================================
//    // TEST 2: NORMAL MODE FULL CYCLE
//    // =========================================
//    test_pass = 0; test_fail = 0;
//    clear_seen_flags;
//    $display("\n===== TEST 2: NORMAL MODE FULL CYCLE =====");
//    do_reset;
//    door_closed = 1;
//    mode_select = 2'b01;
//    press_start;
//    #100;
//    water_level_full = 1;
//    #1800;
//    check(seen_wash,     "Normal mode entered WASH");
//    check(seen_rinse,    "Normal mode entered RINSE");
//    check(seen_spin,     "Normal mode entered SPIN");
//    check(seen_drain,    "Normal mode entered DRAIN");
//    check(seen_complete, "Normal mode reached COMPLETE");
//    print_test_summary("TEST 2");

//    // =========================================
//    // TEST 3: HEAVY MODE FULL CYCLE
//    // =========================================
//    test_pass = 0; test_fail = 0;
//    clear_seen_flags;
//    $display("\n===== TEST 3: HEAVY MODE FULL CYCLE =====");
//    do_reset;
//    door_closed = 1;
//    mode_select = 2'b10;
//    press_start;
//    #100;
//    water_level_full = 1;
//    #2600;
//    check(seen_wash,     "Heavy mode entered WASH");
//    check(seen_rinse,    "Heavy mode entered RINSE");
//    check(seen_spin,     "Heavy mode entered SPIN");
//    check(seen_drain,    "Heavy mode entered DRAIN");
//    check(seen_complete, "Heavy mode reached COMPLETE");
//    print_test_summary("TEST 3");

    // =========================================
    // TEST 4: DOOR OPEN SAFETY
    // =========================================
    test_pass = 0; test_fail = 0;
    clear_seen_flags;
    $display("\n===== TEST 4: DOOR OPEN SAFETY =====");
    do_reset;
    door_closed = 1;
    mode_select = 2'b00;
    press_start;
    #100;
    water_level_full = 1;
    #80;
    check(motor_on == 1'b1, "Motor ON in active drum state when door closed");

    door_closed = 0;
    #20;
    check(motor_on == 1'b0, "Motor OFF when door opened");

    door_closed = 1;
    #20;
    check(motor_on == 1'b1, "Motor ON again when door closed");
    #800;
    print_test_summary("TEST 4");

    // =========================================
    // TEST 5: RESET DURING OPERATION
    // =========================================
    test_pass = 0; test_fail = 0;
    clear_seen_flags;
    $display("\n===== TEST 5: RESET DURING OPERATION =====");
    do_reset;
    door_closed = 1;
    mode_select = 2'b01;
    press_start;
    #100;
    water_level_full = 1;
    #150;
    reset = 1;
    #20;
    check(state_leds == 7'b0000001, "Reset forces IDLE");
    check(motor_on == 1'b0, "Motor OFF after reset");
    reset = 0;
    #50;
    print_test_summary("TEST 5");

    // =========================================
    // TEST 6: STAY IN FILL_WATER UNTIL SENSOR
    // =========================================
    test_pass = 0; test_fail = 0;
    clear_seen_flags;
    $display("\n===== TEST 6: HOLD IN FILL_WATER =====");
    do_reset;
    door_closed = 1;
    mode_select = 2'b00;
    press_start;
    #200;
    check(state_leds == 7'b0000010, "Stayed in FILL_WATER while water_level_full=0");
    water_level_full = 1;
    #50;
    check(seen_wash, "Moved to WASH after water_level_full became 1");
    #500;
    print_test_summary("TEST 6");

    // =========================================
    // TEST 7: NO START WITHOUT BUTTON
    // =========================================
    test_pass = 0; test_fail = 0;
    clear_seen_flags;
    $display("\n===== TEST 7: NO START WITHOUT BUTTON =====");
    do_reset;
    door_closed = 1;
    mode_select = 2'b00;
    #200;
    check(state_leds == 7'b0000001, "Remained in IDLE without start_button");
    print_test_summary("TEST 7");

    // =========================================
    // FINAL SUMMARY
    // =========================================
    $display("\n===== FINAL SUMMARY =====");
    $display("TOTAL PASS = %0d", pass_count);
    $display("TOTAL FAIL = %0d", fail_count);

    print_state_time_report;

    if (fail_count == 0)
        $display("ALL TEST CASES PASSED");
    else
        $display("SOME TEST CASES FAILED");

    $finish;
end

initial begin
    $monitor("TIME=%0t | reset=%b start=%b door=%b water=%b mode=%b | leds=%b | motor=%b dir=%b valve=%b drain=%b done=%b",
             $time, reset, start_button, door_closed, water_level_full,
             mode_select, state_leds, motor_on, motor_dir,
             water_valve, drain_pump, done_led);
end

endmodule