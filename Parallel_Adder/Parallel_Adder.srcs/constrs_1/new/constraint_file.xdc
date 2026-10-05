## =====================================================
## 4-bit Carry Look-Ahead Adder Constraints
## Matches Verilog port names EXACTLY
## =====================================================

## ---------------- a inputs (SW0 - SW3, right to left) ----------------
set_property PACKAGE_PIN V17 [get_ports {a[0]}]
set_property PACKAGE_PIN V16 [get_ports {a[1]}]
set_property PACKAGE_PIN W16 [get_ports {a[2]}]
set_property PACKAGE_PIN W17 [get_ports {a[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {a[*]}]

## ---------------- b inputs (SW4 - SW7) ----------------
set_property PACKAGE_PIN W15 [get_ports {b[0]}]
set_property PACKAGE_PIN V15 [get_ports {b[1]}]
set_property PACKAGE_PIN W14 [get_ports {b[2]}]
set_property PACKAGE_PIN W13 [get_ports {b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {b[*]}]

## ---------------- Carry-in (SW8) ----------------
set_property PACKAGE_PIN V2 [get_ports {cin}]
set_property IOSTANDARD LVCMOS33 [get_ports {cin}]

## ---------------- Sum outputs (LED0 - LED3, right to left) ----------------
set_property PACKAGE_PIN U16 [get_ports {sum[0]}]
set_property PACKAGE_PIN E19 [get_ports {sum[1]}]
set_property PACKAGE_PIN U19 [get_ports {sum[2]}]
set_property PACKAGE_PIN V19 [get_ports {sum[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sum[*]}]

## ---------------- Carry-out (LED4) ----------------
set_property PACKAGE_PIN W18 [get_ports {cout}]
set_property IOSTANDARD LVCMOS33 [get_ports {cout}]
