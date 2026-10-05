# LCD Hardware Wiring Guide — Basys 3 + 16×2 I2C LCD

## What You Need

| Component | Specification |
|-----------|--------------|
| FPGA Board | Digilent Basys 3 (Artix-7) |
| LCD Panel | Any 16×2 character LCD (HD44780 controller) |
| I2C Module | PCF8574-based I2C backpack (pre-soldered to LCD) |
| Jumper Wires | 4 female-to-female jumper wires |
| Power | The FPGA PMOD 3.3 V pin directly powers the module |

> **No breadboard, no resistors, no external power supply needed** — the PMOD 3.3 V supply is sufficient for the PCF8574 and most LCD panels. If the LCD contrast appears low, adjust the potentiometer on the backpack first before reaching for an external 5 V supply.

---

## PMOD JA Connector Layout

The Basys 3 PMOD JA connector is a 2×6 pin header on the **top-left side** of the board.

```
PMOD JA (top view, USB connector to the left)

   USB Side ──────────────────────────────────────── Far Side
   ┌──────────────────────────────────────────────────────────┐
   │  [JA4]   [JA3]   [JA2]   [JA1]   ↑ Top row (signals)  │
   │  E17      E18     D18     C17                            │
   │  ─────────────────────────────────────────────────────   │
   │  [JA8]   [JA7]   [JA6]   [JA5]   ↓ Bottom row         │
   │  GND      GND    3.3V     GND                           │
   └──────────────────────────────────────────────────────────┘

   (JA1 = rightmost top pin, JA5 = rightmost bottom pin)
```

---

## Wiring Table

| LCD I2C Module Pin | Connects to PMOD JA | FPGA Pin | Function |
|:-----------------:|:-------------------:|:--------:|:--------:|
| **GND** | Pin 5 (bottom-right) | GND | Ground |
| **VCC** | Pin 6 (bottom-mid-right) | +3.3 V | Power |
| **SDA** | **Pin 2** (top-mid-right) | **D18** | I2C Data |
| **SCL** | **Pin 1** (top-right) | **C17** | I2C Clock |

---

## Step-by-Step Wiring

```
Step 1: GND
  LCD module GND pin  ──────────►  PMOD JA Pin 5  (bottom-right, GND)

Step 2: VCC / Power
  LCD module VCC pin  ──────────►  PMOD JA Pin 6  (bottom, 3.3 V)
  ┌─ If the LCD contrast is too low with 3.3 V, instead connect:
  └─ LCD module VCC  ──► external 5 V supply (+), GND shared with board.

Step 3: SDA (Serial Data)
  LCD module SDA pin  ──────────►  PMOD JA Pin 2  (top-row, C17, D18)
                                   FPGA package pin: D18

Step 4: SCL (Serial Clock)
  LCD module SCL pin  ──────────►  PMOD JA Pin 1  (top-row rightmost, C17)
                                   FPGA package pin: C17
```

### Visual Connection Diagram

```
  ┌─────────────────────────────────────┐
  │         BASYS 3 FPGA BOARD          │
  │                                     │
  │  PMOD JA Header                     │
  │  ┌─────────────────────────────┐    │
  │  │ JA4  JA3  JA2  JA1         │    │  ← Top row
  │  │ E17  E18  D18  C17         │    │
  │  │  │    │    │    │          │    │
  │  │  │    │    │    └──► SCL ──┼────┼──► LCD SCL
  │  │  │    │    └───────► SDA ──┼────┼──► LCD SDA
  │  │  │    │                   │    │
  │  │ JA8  JA7  JA6  JA5        │    │  ← Bottom row
  │  │ GND  GND  3.3V  GND       │    │
  │  │              │    │        │    │
  │  │              │    └───────────────► LCD GND
  │  │              └────────────────────► LCD VCC
  │  └─────────────────────────────┘    │
  └─────────────────────────────────────┘
```

---

## LCD I2C Module Pinout (PCF8574 backpack)

The 4-pin connector on the backpack is usually labelled left-to-right:

```
  ┌─────────────────────┐
  │ [GND] [VCC] [SDA] [SCL] │
  │   ↓     ↓     ↓     ↓   │
  │  Blk   Red   Yel   Wht  │  ← suggested wire colours
  └─────────────────────────┘
```

Connect them as per the wiring table above.

---

## I2C Pull-Up Resistors

The PCF8574 backpack **already includes 4.7 kΩ pull-up resistors** on both SCL and SDA lines.
**You do NOT need to add any external resistors.**

The Basys 3 runs at 3.3 V logic. Because the Verilog driver uses open-drain outputs
(the FPGA only drives the lines LOW, never HIGH), the 3.3 V and 5V supply levels are compatible.

---

## Checking the I2C Address

The default address is **0x27** (A0=A1=A2 = 1 on the PCF8574).
Some modules ship with a different address. If nothing shows on screen after wiring:

1. Check the solder jumpers on the backpack (A0, A1, A2 pads).
2. All three open (not shorted) → address = **0x27** (default, already in the code).
3. All three shorted → address = **0x20** → change `I2C_ADDR_W = 8'h40` in `i2c_lcd_driver.v`.

| A2 | A1 | A0 | I2C Address | `I2C_ADDR_W` value |
|:--:|:--:|:--:|:-----------:|:-----------------:|
| 1  | 1  | 1  | 0x27        | `8'h4E` (default) |
| 1  | 1  | 0  | 0x26        | `8'h4C`           |
| 0  | 1  | 1  | 0x23        | `8'h46`           |
| 0  | 0  | 0  | 0x20        | `8'h40`           |

---

## Contrast Adjustment

The small blue potentiometer on the backpack controls the LCD contrast.
- Turn it **clockwise** to increase contrast (darker characters).
- Turn it **counter-clockwise** to decrease contrast.
- Set it so characters are clearly visible against the background.

---

## Quick Start Verification

After wiring and programming the bitstream:

1. **Power on Basys 3** → LCD backlight should illuminate immediately.
2. Wait ~1 second for LCD initialisation.
3. **Line 1** should show: `WASHING MACHINE `
4. **Line 2** should show: `MODE:Qck    SET?`
5. Press **btnR (CONFIRM)** to lock the mode → Line 2 changes to `MODE:Qck    RDY!`
6. Press **btnC (START)** → display changes to `FILLING WATER   `
7. Flip `SW1` (water_level_full) → display changes to `WASHING       XXs` with countdown.

---

## Troubleshooting

| Symptom | Most Likely Cause | Fix |
|---------|------------------|-----|
| Backlight off | VCC not connected | Check Pin 6 → VCC wiring |
| Backlight on, blank screen | Contrast too low | Turn potentiometer clockwise |
| Squares/blocks instead of text | I2C address wrong | Change `I2C_ADDR_W`, re-synthesise |
| Garbled text | Floating SDA/SCL | Re-seat wires; check pull-ups on backpack |
| Display freezes / hangs | I2C bus locked | Toggle RESET button (btnU) on Basys 3 |
| No change on state transition | Wrong FSM wiring | Verify `fsm_state` net in top_module.v |
