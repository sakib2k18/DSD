# LCD Display Integration Guide — Washing Machine Controller

## Overview

The washing machine controller drives a **16×2 character LCD** through an **I2C module (PCF8574 backpack)**,
giving real-time, human-readable feedback for every stage of the wash cycle.

---

## What Is Shown on the LCD

### State-by-State Display

```
╔══════════════════╗
║ WASHING MACHINE  ║  ← Line 1
║ MODE:Qck    SET? ║  ← Line 2
╚══════════════════╝
    IDLE (mode not confirmed yet)

╔══════════════════╗
║ WASHING MACHINE  ║
║ MODE:Nrm    RDY! ║
╚══════════════════╝
    IDLE (mode confirmed, waiting for START)

╔══════════════════╗
║ FILLING WATER    ║
║ D:0 W:0 FILLING  ║
╚══════════════════╝
    FILL_WATER state
    D:0 = door sensor (0=open, 1=closed)
    W:0 = water level (0=not full, 1=full)

╔══════════════════╗
║ WASHING      010s║
║ D:1 W:1 MOTOR ON ║
╚══════════════════╝
    WASH state — timer counts down live

╔══════════════════╗
║ RINSING 1/2  005s║
║ D:1 W:1 MOTOR ON ║
╚══════════════════╝
    RINSE state — shows current rinse # / total
    (e.g. 1/2 = first of two rinse cycles)

╔══════════════════╗
║ SPINNING     008s║
║ D:1 W:1 MOTOR ON ║
╚══════════════════╝
    SPIN state

╔══════════════════╗
║ DRAINING     004s║
║ D:1 W:x DRAINING ║
╚══════════════════╝
    DRAIN state

╔══════════════════╗
║ WASH COMPLETE!   ║
║ PRESS RESET KEY  ║
╚══════════════════╝
    COMPLETE state
```

### Line-by-Line Key

| Column | Line 1 content | Line 2 content |
|--------|---------------|----------------|
| 0–7    | State verb ("WASHING", "RINSING", "SPINNING"…) | Sensor info ("D:x W:x …") |
| 8–11   | Rinse index "N/M" (RINSE only), spaces otherwise | Motor status ("MOTOR ON"/"DRAINING") |
| 12–15  | Countdown timer "NNNs" in active states; info hint elsewhere | Status word ("SET?" / "RDY!" / "FILLING") |

---

## Hardware Connections

### Required Parts

| Part | Specification |
|------|--------------|
| LCD panel | 16×2 HD44780-compatible character LCD |
| I2C backpack | PCF8574 I/O expander (pre-soldered to LCD) |
| I2C address | **0x27** (default; check your module—some use 0x3F) |
| Supply voltage | 3.3 V (from FPGA PMOD) — acceptable for most modules; use 5 V external if contrast is poor |

### Pin Connections

Connect the LCD I2C module to the **Basys 3 PMOD JA** header:

```
 PMOD JA Header (top view, USB side to the left)
 ┌───────────────────────────────┐
 │  Pin 4   Pin 3   Pin 2   Pin 1│  ← Top row (signals)
 │  E17     E18     D18     C17  │
 │─────────────────────────────── │
 │  Pin 8   Pin 7   Pin 6   Pin 5│  ← Bottom row
 │  GND     GND     VCC(3.3V) GND│
 └───────────────────────────────┘
```

| PMOD JA Pin | FPGA Package Pin | Connect to LCD |
|:-----------:|:----------------:|:--------------|
| **Pin 1**   | **C17**          | **SCL** (I2C clock) |
| **Pin 2**   | **D18**          | **SDA** (I2C data)  |
| **Pin 5**   | GND              | **GND**             |
| **Pin 6**   | +3.3 V           | **VCC** (or external 5 V) |

> **Important:** The I2C backpack has its own 4.7 kΩ pull-up resistors on SCL and SDA, so **no external resistors are needed**.

### Wiring Diagram

```
  Basys 3 PMOD JA                 16×2 I2C LCD Module
  ┌──────────────┐                 ┌──────────────────┐
  │ Pin 1 (C17)  │──── SCL ───────►│ SCL              │
  │ Pin 2 (D18)  │──── SDA ───────►│ SDA              │
  │ Pin 5 (GND)  │──── GND ───────►│ GND              │
  │ Pin 6 (3.3V) │──── VCC ───────►│ VCC              │
  └──────────────┘                 └──────────────────┘
```

> **Note on 5 V modules:** If the backlight appears dim or characters are faint, power VCC from an external 5 V supply; keep GND shared with the Basys 3 GND.  The PCF8574 I2C signals are 3.3 V compatible even when the chip itself runs at 5 V.

---

## I2C Address Configuration

The driver is hard-coded to address **0x27** (`localparam I2C_ADDR_W = 8'h4E`).

If your module uses address **0x3F**, change that line in `i2c_lcd_driver.v`:

```verilog
localparam [7:0] I2C_ADDR_W = 8'h7E;   // 0x3F << 1, write bit
```

---

## Module Interface

```verilog
module i2c_lcd_driver (
    input  wire       clk,              // 100 MHz system clock
    input  wire       reset,
    input  wire [2:0] fsm_state,        // 0=IDLE … 6=COMPLETE
    input  wire [7:0] timer_count,      // Active-phase countdown (seconds)
    input  wire [1:0] mode_select,      // 00=Quick / 01=Normal / 10=Heavy
    input  wire       motor_on,         // 1 = motor running
    input  wire       door_closed,      // 1 = door sensor closed
    input  wire       water_level_full, // 1 = water-level sensor triggered
    input  wire       mode_locked,      // 1 = user confirmed mode selection
    input  wire [7:0] rinse_counter,    // Current rinse cycle (0-based index)
    input  wire [7:0] rinse_total,      // Total rinse cycles (e.g. 2)
    output wire       scl,              // I2C clock (open-drain)
    output wire       sda               // I2C data  (open-drain)
);
```

---

## Internal Architecture

```
top_module
    │
    └── i2c_lcd_driver
          │
          ├── Display content generator (combinational)
          │     ├── line1_buf: 16-char message buffer (per FSM state)
          │     └── line2_buf: 16-char sensor/mode buffer
          │
          ├── Level-1 FSM: bit-banged I2C byte transmitter (100 kHz)
          │     Emits: START → addr(0x27) → ACK → data byte → ACK → STOP
          │
          ├── Level-2 FSM: LCD nibble sender
          │     Converts one LCD byte into 4 I2C writes
          │     (upper nibble EN=1, upper nibble EN=0,
          │      lower nibble EN=1, lower nibble EN=0)
          │
          └── Level-3 FSM: master sequencer / "program counter"
                Step 0:     50 ms power-on delay
                Steps 1–8:  HD44780 initialisation (8-bit→4-bit transition)
                Steps 9–13: configure display (4-bit, 2-line, cursor off, clear)
                Step  14:   set cursor to Line 1 (DDRAM 0x00)
                Steps 15–30: write 16 chars of Line 1
                Step  31:   set cursor to Line 2 (DDRAM 0x40)
                Steps 32–47: write 16 chars of Line 2
                Step  48:   200 ms inter-refresh delay → loop back to step 14
```

---

## Refresh Rate

- Display refreshes at **~5 Hz** (every 200 ms).
- The timer countdown visible on Line 1 therefore lags by at most 200 ms — imperceptible to a user.
- The refresh interval can be changed via the `D_REFRESH` parameter inside `i2c_lcd_driver.v`.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| LCD blank, backlight off | VCC not connected | Check Pin 6 → VCC wiring |
| Backlight on, no characters | I2C address mismatch | Try changing `I2C_ADDR_W` to `8'h7E` (0x3F) |
| Garbled characters | Floating SDA/SCL | Ensure pull-up resistors are present on backpack; check wiring |
| Display freezes | I2C bus locked up | Toggle RESET on Basys 3 |
| "MOTOR OF" on line 2 | Normal — "OFF" uses "OF" + "F" in the same slot | Not a bug; intentional 8-char split |
| Timer always shows "000s" | Module is in IDLE/FILL/COMPLETE | Timer only counts in WASH/RINSE/SPIN/DRAIN |

---

## XDC Constraint Summary

The following constraints are already present in `basys3_washing_machine.xdc`:

```xdc
## I2C LCD (PMOD JA)
set_property PACKAGE_PIN C17 [get_ports scl]
set_property IOSTANDARD LVCMOS33 [get_ports scl]
set_property DRIVE 12 [get_ports scl]
set_property SLEW SLOW [get_ports scl]

set_property PACKAGE_PIN D18 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports sda]
set_property DRIVE 12 [get_ports sda]
set_property SLEW SLOW [get_ports sda]
```

No changes to the XDC file are needed.

---

## Hardware Checklist

- [ ] LCD module acquired (16×2, HD44780, with PCF8574 I2C backpack)
- [ ] PMOD JA Pin 1 (C17) → SCL
- [ ] PMOD JA Pin 2 (D18) → SDA
- [ ] PMOD JA Pin 5 (GND) → GND
- [ ] PMOD JA Pin 6 (3.3 V) → VCC  *(or external 5 V)*
- [ ] Bitstream synthesised and programmed to Basys 3
- [ ] LCD shows "WASHING MACHINE" at power-on (IDLE state)
- [ ] Timer counts down live during WASH / RINSE / SPIN / DRAIN
- [ ] "RINSING 1/2" / "RINSING 2/2" shown for multi-rinse mode
- [ ] "WASH COMPLETE!" shown at end of cycle
- [ ] "PRESS RESET KEY" on Line 2 after completion

---

**Status:** ✅ Ready for hardware integration
