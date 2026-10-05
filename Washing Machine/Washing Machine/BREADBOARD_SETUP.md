# Breadboard Configuration Guide - External Hardware Setup

## 📋 Hardware Components Needed

### For 7 State LEDs:
- **7× LED (any color)** - Standard 5mm LEDs
- **7× Resistor (220Ω - 330Ω)** - Current limiting resistors
- **Breadboard** - Standard solderless breadboard (830 holes minimum)
- **Jumper wires** - Male-to-male dupont wires
- **Basys 3 Power** - GND connection

### For I2C LCD Display (Optional):
- **1× 16x2 I2C LCD Display** - With I2C module (address 0x27)
- **Breadboard** - Additional space or same board
- **4× Jumper wires** - For I2C connection
- **Pull-up resistors** - 4.7kΩ (optional, usually onboard)
- **Power supply** - 5V for LCD

---

## 🔌 Resistor Calculations for LEDs

### Led Specifications (Typical)
- **Forward Voltage (Vf):** 2.0V (red) to 2.2V (green/yellow)
- **Typical Current (If):** 20mA
- **Max Current:** 30mA

### Resistor Formula:
```
R = (FPGA Voltage - LED Vf) / Current
R = (3.3V - 2.0V) / 0.020A = 65Ω (minimum)
```

### Recommended Resistor Values:
| Resistor | Voltage Drop | LED Current | Safe |
|----------|-------------|------------|------|
| **220Ω** | 1.3V | 14.5mA | ✅ BEST |
| **330Ω** | 1.3V | 10mA | ✅ BEST |
| **470Ω** | 1.3V | 7mA | ✅ Dimmer |
| **1kΩ** | 1.3V | 3.3mA | ✅ Very Dim |

**Recommendation:** Use **220Ω or 330Ω** resistors for optimal brightness

---

## 🎯 Wiring Diagram - 7 LEDs on Breadboard

### Basys 3 Pins to LEDs:
```
FPGA Output Pins:
├─ U16 (state_leds[0]) → LED 1 (IDLE - Red)
├─ E19 (state_leds[1]) → LED 2 (FILL_WATER - Orange)
├─ U19 (state_leds[2]) → LED 3 (WASH - Yellow)
├─ V19 (state_leds[3]) → LED 4 (RINSE - Green)
├─ W18 (state_leds[4]) → LED 5 (SPIN - Blue)
├─ U15 (state_leds[5]) → LED 6 (DRAIN - Purple)
└─ U14 (state_leds[6]) → LED 7 (COMPLETE - White)
```

---

## 📐 Breadboard Layout (Physical Wiring)

```
STEP 1: Connect FPGA GND to Breadboard
├─ Any GND pin from Basys3 → Breadboard negative rail (column marked -)
└─ Connect power rail across breadboard (—— — — — — ——)

STEP 2: For Each of 7 LEDs (Example for LED 1):
│
├─ PMOD JA Pin (or GPIO) [U16] 
│   └─ Jumper wire → Breadboard Top Row
│       └─ Connect to: Resistor (220Ω)
│           └─ Resistor other end → Breadboard
│               └─ Connect to: LED Anode (longer leg)
│                   └─ LED Cathode (shorter leg)
│                       └─ Jumper wire → GND Rail
│
└─ Repeat for all 7 LEDs

EXAMPLE FOR ONE LED:
┌─────────────────────────────────────────┐
│  BASYS3 PMOD or GPIO                   │
│  [Pin U16] (+3.3V when state = IDLE)   │
│     │                                   │
│     ├─ Jumper wire                     │
│     │                                   │
│  ┌──────────────────────────────────┐  │
│  │ BREADBOARD                       │  │
│  │ ┌──────────────────────────────┐ │  │
│  │ │ A B C D E F G H ...          │ │  │
│  │ │1[U16]═R220Ω═[LED+]           │ │  │
│  │ │                 [LED-]═══════┤ │  │
│  │ │                             GND│ │  │
│  │ └──────────────────────────────┘ │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📍 Detailed Connection Table

| LED # | State | FPGA Pin | Pin Package | Resistor | LED Color |
|-------|-------|----------|------------|----------|-----------|
| 1 | IDLE | U16 | A8 | 220Ω | Red |
| 2 | FILL | E19 | D8 | 220Ω | Orange |
| 3 | WASH | U19 | C8 | 220Ω | Yellow |
| 4 | RINSE | V19 | C7 | 220Ω | Green |
| 5 | SPIN | W18 | B7 | 220Ω | Blue |
| 6 | DRAIN | U15 | A6 | 220Ω | Purple |
| 7 | COMPLETE | U14 | A5 | 220Ω | White |

---

## 🔧 Step-by-Step Wiring Instructions

### PART 1: Prepare Breadboard

```
1. Place breadboard on work surface
2. Identify the two long power rails:
   ├─ Red Line (+ Rail) - Generally left
   └─ Blue/Black Line (- Rail / GND) - Generally right

3. Connect Basys3 GND:
   └─ Use a GND pin (any available GND on Basys3)
   └─ Connect jumper wire from GND → Blue rail (GND on breadboard)
   └─ This completes the GND return path for all LEDs
```

### PART 2: Install First LED (IDLE State)

```
FPGA Pin: U16 → LED 1 (Red) + Resistor

Connections:
1. Take jumper wire from FPGA pin U16 (or PMOD JA Pin)
2. Insert into breadboard (any column, e.g., column A, row 1)
3. Insert 220Ω resistor leg 1:
   └─ Next to pin U16 wire (same row, column B)
4. Insert resistor leg 2:
   └─ 2-3 rows down (column B, row 3)
5. Insert LED Anode (long leg):
   └─ Next to resistor leg 2 (same row, column C)
6. Insert LED Cathode (short leg):
   └─ Extend to GND rail
   └─ Use jumper wire: column C → GND rail (blue rail)
```

### PART 3: Repeat for Remaining 6 LEDs

```
LED 2 (FILL_WATER): E19 → Orange
LED 3 (WASH): U19 → Yellow
LED 4 (RINSE): V19 → Green
LED 5 (SPIN): W18 → Blue
LED 6 (DRAIN): U15 → Purple
LED 7 (COMPLETE): U14 → White

For each:
├─ FPGA pin → Breadboard
├─ → 220Ω Resistor
├─ → LED Anode (+)
└─ → LED Cathode (-) → GND Rail
```

---

## 🎨 Visual ASCII Breadboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                   BREADBOARD LAYOUT                             │
│                                                                 │
│  + Rail    A    B    C    D    E    F    G    H    I    J  GND │
│  ─────────────────────────────────────────────────────────────  │
│     ■      ■    ■    ■    ■    ■    ■    ■    ■    ■    ■    ■ │
│  [U16]             [LED1]                                    GND │
│     •    [R220]    •                                         ─ ─ │
│     •      •      ─•─  (Red LED)                            ─ ─ │
│     •      •       ─                                        ─ ─ │
│  ─────────────────────────────────────────────────────────────  │
│  [E19]            [LED2]                                        │
│     •    [R220]   •                                         GND │
│     •      •     ─•─   (Orange LED)                        ─ ─ │
│     •      •      ─                                        ─ ─ │
│  ─────────────────────────────────────────────────────────────  │
│  [U19]            [LED3]                          GND           │
│     •    [R220]    •                            ─ ─             │
│     •      •     ─•─    (Yellow LED)           ─ ─             │
│     •      •      ─                           ─ ─              │
│  ─────────────────────────────────────────── GND ───────────── │
│  ... (continue for LEDs 4-7)                                   │
│  + Rail                                              - Rail   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 💡 I2C LCD Display Wiring (Optional)

### LCD Pinout (16x2 I2C Module at Address 0x27)
```
LCD I2C Module Pins:
├─ VCC → +5V (Basys3 or external supply)
├─ GND → GND
├─ SDA → FPGA/PMOD (I2C Data)
└─ SCL → FPGA/PMOD (I2C Clock)
```

### Basys3 PMOD Connection for LCD
```
PMOD JA Pins on Basys3:
┌─ Pin 1 (C17) → SCL (I2C Clock)
├─ Pin 2 (D18) → SDA (I2C Data)
├─ Pin 3 (E18) → GND
└─ Pin 4 (E17) → +3.3V (or external PSU)

LCD Connection:
├─ SCL → PMOD JA Pin 1 (C17)
├─ SDA → PMOD JA Pin 2 (D18)
├─ GND → PMOD JA Pin 3 (E18) or Basys3 GND
└─ VCC → +5V (external supply recommended)
```

---

## ✅ Verification Checklist

- [ ] All 7 LEDs inserted correctly (Anode/Cathode orientation)
- [ ] All 220Ω resistors in series with LEDs
- [ ] GND rail properly connected to Basys3 GND
- [ ] No short circuits (anode directly to GND)
- [ ] All jumper wires securely inserted
- [ ] FPGA pins connected correctly to breadboard
- [ ] Brightness is sufficient (not too dim, not flickering)
- [ ] LCD I2C pins connected (if using LCD)
- [ ] No loose jumper wires

---

## 🧪 Testing Procedure

### Test 1: Visual Inspection
```
1. Power on Basys3
2. Press RESET button
3. Observe if any LED is on (should be minimal)
4. Press START button
5. Observe LEDs changing as states change
```

### Test 2: LED State Verification
```
| Expected State | LED That Should Be ON |
|---|---|
| IDLE | LED 1 (Red) |
| FILL_WATER | LED 2 (Orange) |
| WASH | LED 3 (Yellow) |
| RINSE | LED 4 (Green) |
| SPIN | LED 5 (Blue) |
| DRAIN | LED 6 (Purple) |
| COMPLETE | LED 7 (White) |
```

### Test 3: Brightness Test
```
If LEDs are:
├─ TOO BRIGHT:
│  └─ Increase resistor value (try 330Ω or 470Ω)
├─ TOO DIM:
│  └─ Decrease resistor value (try 150Ω or 180Ω)
└─ PERFECT:
   └─ Keep 220Ω resistors
```

---

## 🔩 Component Part Numbers (Optional)

| Component | Part Number | Supplier |
|-----------|------------|----------|
| LED (5mm Red) | L-93FF | Digi-Key |
| LED (5mm Green) | C503B-GGN | Amazon |
| Resistor 220Ω | CFR-25JB-220R | Mouser |
| Resistor 1/4W 5% | MFR-12FT52-220R | Any |
| Breadboard 830pt | BB830 | Amazon |
| Jumper Wires Set | PB-JUMPWIRE | Various |
| I2C LCD 16x2 | LCD2004 | Amazon |

---

## ⚠️ Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| LED won't light | Resistor too high | Use 220Ω instead |
| LED burns out | No resistor | Always use 220-330Ω |
| Wrong LED blinks | Pin mapping wrong | Check XDC file |
| Flickering | Loose connection | Reinsert wires firmly |
| Display blank | No power | Check VCC connection |
| I2C not working | Pull-ups missing | Add 4.7kΩ to SCL/SDA |

---

## 📞 Quick Reference

**For 7 State LEDs:**
- Use **220Ω resistors** (safer, brighter)
- Connect **Cathode to GND** (very important!)
- One **GND wire** from Basys3 to breadboard
- **One wire per state pin** from FPGA

**For I2C LCD:**
- Connect **SCL to PMOD JA Pin 1 (C17)**
- Connect **SDA to PMOD JA Pin 2 (D18)**
- Use **5V power supply for LCD**
- Optional: Add **4.7kΩ pull-up resistors**

---

**Status:** ✅ Ready to Build  
**Difficulty:** Easy (Beginner-Friendly)  
**Time Required:** 15-20 minutes for assembly
