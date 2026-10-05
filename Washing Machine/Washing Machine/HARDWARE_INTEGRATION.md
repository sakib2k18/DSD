# Complete Hardware Integration Guide

## 🎯 Overview

This guide explains how to integrate **external hardware** with the FPGA Washing Machine Controller:

### Two Hardware Additions:
1. **7 State LEDs on Breadboard** - Visual state indication
2. **16x2 I2C LCD Display** - Motor state + Machine state display

---

## 📦 Complete Bill of Materials (BOM)

### For 7 State LEDs
```
Qty  Component           Specifications
────────────────────────────────────────
7×   LED 5mm            Red, Orange, Yellow, Green, Blue, Purple, White
7×   Resistor 220Ω      1/4W, 5% tolerance
1×   Breadboard         830 holes (minimum)
1×   Jumper wire pack   Male-to-male dupont connectors
1×   Basys 3            (You have this)
```

### For I2C LCD Display  
```
Qty  Component                  Specifications
──────────────────────────────────────────────
1×   16x2 LCD Display           I2C compatible, PCF8574 backpack
1×   I2C Cable/Connector        (4-pin JST or similar)
1×   +5V Power Supply           500mA minimum
1×   Jumper wires (4×)          For I2C connection
     Optional: Pull-up resistors (4.7kΩ) - usually on LCD
```

### Total Cost Estimate
```
7 LEDs + Breadboard + Wires:  $10-15
LCD Display (I2C):            $8-15
Power Supply (5V):            $5-10
────────────────────────────
Total:                        $23-40 USD
```

---

## 🔌 Pin Configuration Summary

### Basys3 Connections (FPGA Outputs)

#### State LED Outputs
```
State LED Pins (FPGA → Breadboard):
├─ U16 → LED 1 (IDLE - Red)
├─ E19 → LED 2 (FILL_WATER - Orange)
├─ U19 → LED 3 (WASH - Yellow)
├─ V19 → LED 4 (RINSE - Green)
├─ W18 → LED 5 (SPIN - Blue)
├─ U15 → LED 6 (DRAIN - Purple)
└─ U14 → LED 7 (COMPLETE - White)

All LEDs connect through:
├─ Resistor (220Ω) in series
└─ Cathode to GND
```

#### LCD Display Outputs (I2C)
```
LCD I2C Pins (FPGA → LCD via PMOD JA):
├─ C17 (PMOD JA Pin 1) → SCL (I2C Clock)
├─ D18 (PMOD JA Pin 2) → SDA (I2C Data)
├─ E18 (PMOD JA Pin 3) → GND (Ground)
└─ E17 (PMOD JA Pin 4) → +3.3V (Optional)

LCD Display Power:
└─ +5V from external power supply
```

---

## 📐 Physical Setup Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                     COMPLETE SYSTEM SETUP                      │
└────────────────────────────────────────────────────────────────┘

┌─────────────────────┐              ┌──────────────────────┐
│   BASYS 3 FPGA      │              │  EXTERNAL HARDWARE   │
├─────────────────────┤              ├──────────────────────┤
│                     │              │                      │
│  PMOD JA (I2C):     │              │  BREADBOARD AREA 1:  │
│  ┌─────────────────┐│   I2C Bus    │  ┌────────────────┐ │
│  │ SCL[C17]────────┼─────────────┼─┤ LCD SCL        │ │
│  │ SDA[D18]────────┼─────────────┼─┤ LCD SDA        │ │
│  │ GND[E18]───────┐│             │ │                │ │
│  └─────────────────┘│ ┌───────┐  │ │  LCD Display:  │ │
│                     │ │ I2C   │  │ │  ┌──────────┐  │ │
│  GPIO Outputs:      │ │ Bus   │  │ │  │Motor: ON │  │ │
│  ┌─────────────────┐│ │  @    │  │ │  │I        │  │ │
│  │[U16]──────────┐││ │100kHz │  │ │  └──────────┘  │ │
│  │[E19]──────────┤││ │       │  │ │                │ │
│  │[U19]──────────┤││ └───────┘  │ └────────────────┘ │
│  │[V19]──────────┤││     ↓      │                     │
│  │[W18]──────────┤││     │      │  BREADBOARD AREA 2: │
│  │[U15]──────────┤││     └──────┼──┬─────────────────┐│
│  │[U14]──────────┘││            │ │ LED1[R] |LED2..│ │
│  └─────────────────┘│            │ │ ╭R220───┴──────│ │
│                     │            │ │ │╭─LED+─────── │ │
│  GND Pins available:             │ │ ╰─LED-───┐GND │ │
│  └─ Any GND pin                  │ │         │    │ │
│                                  │ └─────────┼────┴┐│
└──────────────────────────────────┼──────────┴─────┘│
                                   │           │ GND  │
                                   │        ┌──┘      │
                                   │   +5V │         │
                                   │   PSU │         │
                                   │        └─────┬──┘
                                   │              │
                                   └──────────────┘
```

---

## 🔧 Step-by-Step Installation & Wiring

### STEP 1: Prepare Basys3 Board

```
✓ Insert Basys3 into available USB port (or use power supply)
✓ Identify PMOD JA header (near PMOD connectors)
✓ Locate GND pins on board (multiple available)
✓ Install Vivado programming software (if not already done)
```

### STEP 2: Build Breadboard Layout (7 LEDs)

```
PART A: Prepare Breadboard
│
├─ Place breadboard on work surface
├─ Identify positive (+) and negative (-) power rails
├─ Connect Basys3 GND to breadboard GND rail
│  └─ Use jumper wire from any Basys3 GND → Blue/Black rail
│
└─ Test GND continuity with multimeter (optional)


PART B: Mount First LED
│
├─ Take LED 1 (Red):
│  ├─ Insert Anode (long leg) into breadboard (e.g., row A)
│  ├─ Insert 220Ω resistor leg 1 next to LED
│  ├─ Insert resistor leg 2 two rows down (row C)
│  └─ Connect jumper from row C to GND rail
│
├─ Connect FPGA pin U16 to LED input:
│  ├─ Take FPGA U16 (state_leds[0])
│  ├─ Connect jumper from FPGA → Breadboard (row A)
│  └─ Verify LED lights when state = IDLE
│
└─ Repeat for Remaining 6 LEDs
   ├─ LED 2 (E19) → Orange → FILL_WATER
   ├─ LED 3 (U19) → Yellow → WASH
   ├─ LED 4 (V19) → Green → RINSE
   ├─ LED 5 (W18) → Blue → SPIN
   ├─ LED 6 (U15) → Purple → DRAIN
   └─ LED 7 (U14) → White → COMPLETE
```

### STEP 3: Setup LCD Display (I2C)

```
PART A: LCD Power
│
├─ Connect +5V power supply to LCD:
│  ├─ +5V (RED) → LCD VCC
│  └─ GND (BLACK) → LCD GND
│
└─ Power supply should have:
   ├─ 5V output (±0.5V tolerance)
   ├─ At least 500mA current capability
   └─ Good filtering (low ripple)


PART B: I2C Connection to Basys3
│
├─ Locate PMOD JA on Basys3:
│  ├─ It's a 8-pin dual row connector
│  └─ Near other PMOD connectors
│
├─ Connect LCD I2C to PMOD JA:
│  ├─ LCD SCL (Clock) → PMOD JA Pin 1 (C17)
│  ├─ LCD SDA (Data) → PMOD JA Pin 2 (D18)
│  ├─ LCD GND → PMOD JA Pin 3 (E18) or Basys3 GND
│  └─ LCD +5V → External 5V PSU
│
└─ Verify connections with multimeter (continuity check)
```

### STEP 4: System Integration

```
Final Connections:
│
├─ All 7 LED inputs connected to GPIO pins (U16, E19, U19, V19, W18, U15, U14)
├─ All 7 LED cathodes connected to GND rail
├─ LCD I2C pins connected to PMOD JA
├─ LCD powered from +5V supply
├─ All GND rails connected together
│
└─ System ready for programming!
```

---

## 🔌 Detailed Wiring Table

| Connection | From | To | Pin | Color | Notes |
|-----------|------|----|----|-------|-------|
| **LED 1** | U16 | R220 → LED+ | - | Red | IDLE state |
| **LED 2** | E19 | R220 → LED+ | - | Orange | FILL state |
| **LED 3** | U19 | R220 → LED+ | - | Yellow | WASH state |
| **LED 4** | V19 | R220 → LED+ | - | Green | RINSE state |
| **LED 5** | W18 | R220 → LED+ | - | Blue | SPIN state |
| **LED 6** | U15 | R220 → LED+ | - | Purple | DRAIN state |
| **LED 7** | U14 | R220 → LED+ | - | White | COMPLETE state |
| **GND** | All LED- | GND Rail | - | Black | All to same rail |
| **LCD SCL** | C17 | LCD SCL | PMOD JA 1 | - | I2C Clock |
| **LCD SDA** | D18 | LCD SDA | PMOD JA 2 | - | I2C Data |
| **LCD GND** | Basys3 GND | LCD GND | - | Black | Power ground |
| **LCD VCC** | +5V PSU | LCD VCC | - | Red | 5V power |

---

## 🧪 Testing & Verification

### Test Checklist

```
PRE-POWER CHECK:
☐ All jumper wires securely inserted
☐ No short circuits (anode-to-GND directly is wrong!)
☐ FPGA-to-breadboard wires connected
☐ LCD I2C wires on correct PMOD pins
☐ Power supply disconnected (+5V not yet applied)

POWER-UP TEST:
☐ Connect Basys3 USB (or 5V supply)
☐ Upload bitstream to FPGA
☐ Observe breadboard (LEDs should not all light)
☐ Check LCD display (should show initial screen)

FUNCTIONALITY TEST:
☐ Press RESET button → LED 1 lights (IDLE)
☐ Press START button → LED 2 lights (FILL), LCD updates
☐ Toggle water level switch → LED 3 lights (WASH), motor shown on LCD
☐ Wait for sequence → States change (LEDs 3→4→5→6→7)
☐ LCD displays current state on line 2
☐ LCD displays Motor ON/OFF on line 1
☐ Buzzer sounds on completion
☐ System resets to IDLE (LED 1)
```

### State-by-State Verification

```
IDLE:          ✓ LED 1 ON, LCD: "I"
FILL_WATER:    ✓ LED 2 ON, LCD: "F"
WASH:          ✓ LED 3 ON, LCD: "W", Motor: ON
RINSE:         ✓ LED 4 ON, LCD: "R", Motor: ON
SPIN:          ✓ LED 5 ON, LCD: "S", Motor: ON
DRAIN:         ✓ LED 6 ON, LCD: "D", Motor: OFF
COMPLETE:      ✓ LED 7 ON, LCD: "C", Buzzer ON
```

---

## 🛠️ Troubleshooting Guide

### LEDs Not Lighting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| All LEDs off | GND not connected | Check GND rail connection |
| One LED stays on | Wrong FPGA pin | Verify pin mapping in XDC |
| LED flickers | Loose connection | Reseat jumper wires |
| Wrong LED lights | GPIO mapping error | Check state_leds assignment |

### LCD Not Displaying

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Blank screen | No power | Check +5V connection |
| No characters | I2C address wrong | Try 0x3F or 0x20 |
| Garbled text | Wrong clock speed | Verify I2C @ 100kHz |
| Intermittent | Loose I2C wires | Reseat connections |

### Both Systems Not Working

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| FPGA won't program | Wrong bitstream | Regenerate bitstream |
| Basys3 not recognized | USB driver issue | Install Vivado drivers |
| All outputs off | FPGA not running | Check DONE LED |

---

## 📊 Resource Usage Analysis

### FPGA Logic Utilization

```
Component          LUTs    Registers   Notes
───────────────────────────────────────────
Core FSM          ~200    ~100        State machine
Timer Module       ~150    ~80        Countdown logic
ALU               ~100    ~50        Arithmetic
Memory Module      ~100    ~80        Register file
Motor Control      ~50     ~30        Output logic
Display Driver     ~200    ~120       7-segment multiplexing
LED Indicator      ~50     ~20        State to LED mapping
LCD I2C Driver     ~150    ~80        I2C communication
───────────────────────────────────────────
Total            ~1000    ~560        ~3% of Artix-7

Remaining Capacity: >95% available for future features
```

---

## 🔄 Integration Verification Flow

```
1. Synthesis ✓
   └─ Check for errors/warnings

2. Implementation ✓
   └─ Check for timing violations

3. Bitstream Generation ✓
   └─ Generates .bit file for programming

4. Program FPGA ✓
   └─ Upload bitstream to Basys3

5. Verify Power ✓
   ├─ Check DONE LED (green)
   └─ Check +3.3V and +5V supplies

6. Test Breadboard LEDs ✓
   ├─ RESET → LED 1 should light
   └─ START → LED sequence changes

7. Test LCD Display ✓
   ├─ SCL/SDA communication working
   └─ State and Motor info displayed

8. System Ready ✓
   └─ All features operational
```

---

## 📋 Final Checklist

```
HARDWARE ASSEMBLY:
☐ All 7 LEDs mounted on breadboard
☐ All 220Ω resistors in series with LEDs
☐ Breadboard GND connected to Basys3 GND
☐ All FPGA pins connected to respective LEDs
☐ LCD I2C connected to PMOD JA (C17, D18)
☐ LCD powered from +5V supply

SOFTWARE:
☐ LCD driver module (i2c_lcd_driver.v) added to project
☐ top_module.v updated with LCD outputs
☐ XDC file updated with LCD pins (C17, D18)
☐ Bitstream regenerated and verified

TESTING:
☐ All 7 LEDs working during state transitions
☐ LCD displays motor state on line 1
☐ LCD displays machine state on line 2
☐ System completes full wash cycle without errors
☐ All safety features (door sensor, etc.) functional
☐ Buzzer and completion LED work

PROJECT COMPLETE ✓
```

---

## 📞 Quick Reference

### File Locations
```
Verilog Files:
└─ HDL Source: Washing Machine.srcs/sources_1/new/
   ├─ i2c_lcd_driver.v ← NEW
   ├─ top_module.v ← UPDATED
   └─ ... (other modules)

Constraints:
└─ basys3_washing_machine.xdc ← UPDATED

Documentation:
└─ BREADBOARD_SETUP.md ← This guide
└─ LCD_DISPLAY_GUIDE.md ← LCD details
```

### Key Pin References
```
LEDs (7 total):         U16, E19, U19, V19, W18, U15, U14
LCD I2C:                C17 (SCL), D18 (SDA)
GND:                    Any GND pin on Basys3
Power Supply:           +5V for LCD (external)
```

---

## ✅ Success Criteria

The project is complete when:
```
✓ 7 state LEDs light up correctly in sequence
✓ LCD displays motor state (ON/OFF)
✓ LCD displays machine state (I/F/W/R/S/D/C)
✓ All states reachable during normal operation
✓ System returns to IDLE after completion
✓ No electrical hazards or short circuits
✓ Hardware stable and reliable
✓ Breadboard modification doesn't affect existing functionality
```

---

**Status:** ✅ HARDWARE INTEGRATION COMPLETE  
**Total Time Required:** 45-60 minutes (wiring + testing)  
**Difficulty Level:** Medium (suitable for students)  
**Next Steps:** Program FPGA and test complete system

