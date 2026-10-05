## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Buttons (Basys 3 has 5 push-buttons arranged as up/down/left/right/center)
## btnC (center) -> start_button
set_property PACKAGE_PIN U18 [get_ports start_button]
set_property IOSTANDARD LVCMOS33 [get_ports start_button]

## btnU (up)     -> reset
set_property PACKAGE_PIN T18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## btnR (right)  -> confirm_button (lock the mode selection in place)
set_property PACKAGE_PIN T17 [get_ports confirm_button]
set_property IOSTANDARD LVCMOS33 [get_ports confirm_button]

## btnL (left)   -> cancel_button  (abort current cycle, return to IDLE)
set_property PACKAGE_PIN W19 [get_ports cancel_button]
set_property IOSTANDARD LVCMOS33 [get_ports cancel_button]

## Switches
set_property PACKAGE_PIN V17 [get_ports door_closed]
set_property IOSTANDARD LVCMOS33 [get_ports door_closed]

set_property PACKAGE_PIN V16 [get_ports water_level_full]
set_property IOSTANDARD LVCMOS33 [get_ports water_level_full]

set_property PACKAGE_PIN W16 [get_ports {mode_select[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode_select[0]}]

set_property PACKAGE_PIN W17 [get_ports {mode_select[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode_select[1]}]

## 7-segment display segments
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]

set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]

set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]

set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]

set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]

set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]

set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## 7-segment display anodes
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]

set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]

set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]

set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## Additional LEDs for State and Outputs
set_property PACKAGE_PIN U16 [get_ports {state_leds[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[0]}]
set_property PACKAGE_PIN E19 [get_ports {state_leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[1]}]
set_property PACKAGE_PIN U19 [get_ports {state_leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[2]}]
set_property PACKAGE_PIN V19 [get_ports {state_leds[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[3]}]
set_property PACKAGE_PIN W18 [get_ports {state_leds[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[4]}]
set_property PACKAGE_PIN U15 [get_ports {state_leds[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[5]}]
set_property PACKAGE_PIN U14 [get_ports {state_leds[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_leds[6]}]

set_property PACKAGE_PIN L1 [get_ports done_led]
set_property IOSTANDARD LVCMOS33 [get_ports done_led]

set_property PACKAGE_PIN V13 [get_ports buzzer_signal]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer_signal]

set_property PACKAGE_PIN V3 [get_ports drain_pump]
set_property IOSTANDARD LVCMOS33 [get_ports drain_pump]

set_property PACKAGE_PIN W3 [get_ports motor_dir]
set_property IOSTANDARD LVCMOS33 [get_ports motor_dir]

set_property PACKAGE_PIN U3 [get_ports motor_on]
set_property IOSTANDARD LVCMOS33 [get_ports motor_on]

set_property PACKAGE_PIN P3 [get_ports water_valve]
set_property IOSTANDARD LVCMOS33 [get_ports water_valve]

## I2C LCD Display (on PMOD JA)
## SCL (Serial Clock) on PMOD JA Pin 1
set_property PACKAGE_PIN C17 [get_ports scl]
set_property IOSTANDARD LVCMOS33 [get_ports scl]
set_property DRIVE 12 [get_ports scl]
set_property SLEW SLOW [get_ports scl]

## SDA (Serial Data) on PMOD JA Pin 2
set_property PACKAGE_PIN D18 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports sda]
set_property DRIVE 12 [get_ports sda]
set_property SLEW SLOW [get_ports sda]