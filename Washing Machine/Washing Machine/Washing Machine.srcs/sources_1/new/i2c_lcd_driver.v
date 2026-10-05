`timescale 1ns / 1ps
//==============================================================================
// i2c_lcd_driver.v - Smart 16x2 LCD Display for Washing Machine Controller
//
// Drives a 16x2 HD44780 character LCD through a PCF8574 I2C I/O-expander
// backpack (standard "LCD1602 I2C" module).  Default I2C address = 0x27.
//
// ┌────────────────┐   ← Line 1 (16 chars): Primary status message
// │ WASHING        │
// │ IN PROCESS 23s │
// └────────────────┘   ← Line 2 (16 chars): Mode + sensor status
//
// DISPLAY LAYOUT PER STATE
// ─────────────────────────────────────────────────────────────────────────────
//  STATE        │ LINE 1 (16 chars)     │ LINE 2 (16 chars)
// ─────────────────────────────────────────────────────────────────────────────
//  IDLE,!locked │ "WASHING MACHINE  "   │ "MODE:Qck  SET?  "
//  IDLE, locked │ "WASHING MACHINE  "   │ "MODE:Nrm  READY "  (or Hvy)
//  FILL_WATER   │ "FILLING WATER    "   │ "MODE:Xxx FILLING"
//  WASH         │ "WASHING         "    │ "MODE:Xxx  MT:ON "  + NNNs timer
//  RINSE (1/2)  │ "RINSING  [1/N]  "   │ "MODE:Xxx  MT:ON "  + NNNs timer
//  SPIN         │ "SPINNING        "    │ "MODE:Xxx  MT:ON "  + NNNs timer
//  DRAIN        │ "DRAINING        "    │ "MODE:Xxx  MT:OFF"  + NNNs timer
//  COMPLETE     │ "WASH COMPLETE!  "    │ "MODE:Xxx   DONE!"
// ─────────────────────────────────────────────────────────────────────────────
//
// FULL Line-1 breakdown (column positions 0-15):
//   IDLE/!locked:  "WASHING MACHINE "
//   IDLE/locked:   "WASHING MACHINE "
//   FILL_WATER:    "FILLING WATER   "
//   WASH:          "WASHING       XXs"   (XXX = 3-digit countdown)
//   RINSE:         "RINSING N/M   XXs"   (N = rinse#, M = total, XXX = countdown)
//   SPIN:          "SPINNING      XXs"
//   DRAIN:         "DRAINING      XXs"
//   COMPLETE:      "WASH COMPLETE!  "
//
// FULL Line-2 breakdown:
//   IDLE/!locked:  "MODE:Qck    SET?"
//   IDLE/locked:   "MODE:Qck   RDY! "   (mode = Qck / Nrm / Hvy)
//   FILL_WATER:    "D:x W:x FILLING "   (x = sensor value 0/1)
//   WASH/RINSE/SPIN: "D:x W:x  MOTOR ON"
//   DRAIN:         "D:x W:x   MOTOR-  "
//   COMPLETE:      "PRESS RESET KEY "
//
// Hardware (Basys 3 + PMOD JA):
//   SCL → PMOD JA Pin 1 (FPGA package pin C17)
//   SDA → PMOD JA Pin 2 (FPGA package pin D18)
//   GND → PMOD JA Pin 5 (or any PMOD GND pin)
//   VCC → PMOD JA Pin 6 (+3.3 V) — see power notes below
//
// Power note for 5 V LCD modules:
//   The PCF8574 backpack accepts 2.5–6 V supply.  The Basys 3 3.3 V PMOD
//   supply is enough to power the PCF8574 and most HD44780 LCDs (many run
//   fine at 3.3 V even if rated 5 V).  If the LCD contrast is too low, use
//   an external 5 V supply on VCC but keep GND common with the board.
//
// PCF8574 byte layout (MSB..LSB sent over I2C):
//   bit 7..4 : D7..D4   (LCD data nibble)
//   bit 3    : BL       (backlight – always 1 = ON)
//   bit 2    : EN       (LCD Enable strobe)
//   bit 1    : RW       (0 = write, always)
//   bit 0    : RS       (0 = command, 1 = character data)
//==============================================================================

module i2c_lcd_driver (
    input  wire       clk,              // 100 MHz system clock
    input  wire       reset,
    input  wire [2:0] fsm_state,        // FSM state: 0=IDLE..6=COMPLETE
    input  wire [7:0] timer_count,      // Active countdown value (seconds)
    input  wire [1:0] mode_select,      // 00=Quick / 01=Normal / 10=Heavy
    input  wire       motor_on,         // Motor running flag
    input  wire       door_closed,      // Door sensor (1 = closed)
    input  wire       water_level_full, // Water level sensor (1 = full)
    input  wire       mode_locked,      // 1 = user confirmed the mode
    input  wire [7:0] rinse_counter,    // Current rinse cycle index (0-based)
    input  wire [7:0] rinse_total,      // Total rinse cycles configured
    output wire       scl,              // I2C clock (open-drain)
    output wire       sda               // I2C data  (open-drain)
);

    //--------------------------------------------------------------------------
    // FSM state encoding (must match top_module)
    //--------------------------------------------------------------------------
    localparam IDLE       = 3'd0,
               FILL_WATER = 3'd1,
               WASH       = 3'd2,
               RINSE      = 3'd3,
               SPIN       = 3'd4,
               DRAIN      = 3'd5,
               COMPLETE   = 3'd6;

    //--------------------------------------------------------------------------
    // I2C / LCD timing (100 MHz input clock)
    //--------------------------------------------------------------------------
    localparam [7:0]  I2C_ADDR_W    = 8'h4E;       // 0x27 << 1, write bit
    localparam integer Q_CYCLES     = 250;          // 2.5 us → 100 kHz I2C
    localparam integer D_POWER_ON   = 5_000_000;    // 50 ms power-on delay
    localparam integer D_LONG       =   500_000;    //  5 ms
    localparam integer D_SHORT      =    25_000;    // 250 us
    localparam integer D_REFRESH    = 20_000_000;   // 200 ms between full refreshes

    //--------------------------------------------------------------------------
    // Open-drain tri-state outputs
    //   '1' releases the line (external pull-ups take it high)
    //   '0' drives it low
    //--------------------------------------------------------------------------
    reg scl_drv;
    reg sda_drv;
    assign scl = scl_drv ? 1'bz : 1'b0;
    assign sda = sda_drv ? 1'bz : 1'b0;

    //==========================================================================
    // ── DISPLAY CONTENT GENERATION ──────────────────────────────────────────
    //==========================================================================

    //--- Timer ASCII digits (3 decimal digits, handles 0..255) ---------------
    wire [7:0] d_hund = 8'h30 + (timer_count / 8'd100);
    wire [7:0] d_tens = 8'h30 + ((timer_count % 8'd100) / 8'd10);
    wire [7:0] d_ones = 8'h30 + (timer_count % 8'd10);

    //--- Rinse cycle # (1-based, 1 digit) ------------------------------------
    wire [7:0] rinse_num   = 8'h30 + rinse_counter + 8'd1; // "1".."9"
    wire [7:0] rinse_total_d = 8'h30 + rinse_total;        // "1".."9"

    //--- Mode label (3 chars) ------------------------------------------------
    reg [23:0] mode_label; // "Qck" / "Nrm" / "Hvy"
    always @(*) begin
        case (mode_select)
            2'b00:   mode_label = "Qck";
            2'b01:   mode_label = "Nrm";
            2'b10:   mode_label = "Hvy";
            default: mode_label = "Qck";
        endcase
    end

    //--------------------------------------------------------------------------
    // BUILD THE 32-CHARACTER DISPLAY BUFFER
    //
    // disp_char[disp_idx]:  indices 0..15 = Line 1,  16..31 = Line 2
    //
    // We keep the combinational lookup so the content is always up-to-date;
    // the sequencer reads it character-by-character during a refresh pass.
    //--------------------------------------------------------------------------
    reg  [5:0] disp_idx;
    reg  [7:0] disp_char;

    // ── Line 1 ──────────────────────────────────────────────────────────────
    // The 16-char buffer is assembled per-state.  We use a named
    // 128-bit (16 × 8-bit) register so the case statement is compact.
    reg [127:0] line1_buf;  // [127:120] = char 0 .. [7:0] = char 15
    always @(*) begin
        case (fsm_state)
            // "WASHING MACHINE "  (space-padded to 16 chars)
            IDLE:      line1_buf = "WASHING MACHINE ";

            // "FILLING WATER   "
            FILL_WATER:line1_buf = "FILLING WATER   ";

            // "WASHING       XXs"  → positions 0..6 = "WASHING", 7..12 = spaces,
            //                        13..15 = "XXs"
            WASH: begin
                line1_buf[127:120] = "W";
                line1_buf[119:112] = "A";
                line1_buf[111:104] = "S";
                line1_buf[103: 96] = "H";
                line1_buf[ 95: 88] = "I";
                line1_buf[ 87: 80] = "N";
                line1_buf[ 79: 72] = "G";
                line1_buf[ 71: 64] = " ";
                line1_buf[ 63: 56] = " ";
                line1_buf[ 55: 48] = " ";
                line1_buf[ 47: 40] = " ";
                line1_buf[ 39: 32] = " ";
                line1_buf[ 31: 24] = d_hund;
                line1_buf[ 23: 16] = d_tens;
                line1_buf[ 15:  8] = d_ones;
                line1_buf[  7:  0] = "s";
            end

            // "RINSING N/M   XXs"
            RINSE: begin
                line1_buf[127:120] = "R";
                line1_buf[119:112] = "I";
                line1_buf[111:104] = "N";
                line1_buf[103: 96] = "S";
                line1_buf[ 95: 88] = "I";
                line1_buf[ 87: 80] = "N";
                line1_buf[ 79: 72] = "G";
                line1_buf[ 71: 64] = " ";
                line1_buf[ 63: 56] = rinse_num;    // "1"/"2"/...
                line1_buf[ 55: 48] = "/";
                line1_buf[ 47: 40] = rinse_total_d;
                line1_buf[ 39: 32] = " ";
                line1_buf[ 31: 24] = d_hund;
                line1_buf[ 23: 16] = d_tens;
                line1_buf[ 15:  8] = d_ones;
                line1_buf[  7:  0] = "s";
            end

            // "SPINNING      XXs"
            SPIN: begin
                line1_buf[127:120] = "S";
                line1_buf[119:112] = "P";
                line1_buf[111:104] = "I";
                line1_buf[103: 96] = "N";
                line1_buf[ 95: 88] = "N";
                line1_buf[ 87: 80] = "I";
                line1_buf[ 79: 72] = "N";
                line1_buf[ 71: 64] = "G";
                line1_buf[ 63: 56] = " ";
                line1_buf[ 55: 48] = " ";
                line1_buf[ 47: 40] = " ";
                line1_buf[ 39: 32] = " ";
                line1_buf[ 31: 24] = d_hund;
                line1_buf[ 23: 16] = d_tens;
                line1_buf[ 15:  8] = d_ones;
                line1_buf[  7:  0] = "s";
            end

            // "DRAINING      XXs"
            DRAIN: begin
                line1_buf[127:120] = "D";
                line1_buf[119:112] = "R";
                line1_buf[111:104] = "A";
                line1_buf[103: 96] = "I";
                line1_buf[ 95: 88] = "N";
                line1_buf[ 87: 80] = "I";
                line1_buf[ 79: 72] = "N";
                line1_buf[ 71: 64] = "G";
                line1_buf[ 63: 56] = " ";
                line1_buf[ 55: 48] = " ";
                line1_buf[ 47: 40] = " ";
                line1_buf[ 39: 32] = " ";
                line1_buf[ 31: 24] = d_hund;
                line1_buf[ 23: 16] = d_tens;
                line1_buf[ 15:  8] = d_ones;
                line1_buf[  7:  0] = "s";
            end

            // "WASH COMPLETE!  "
            COMPLETE:  line1_buf = "WASH COMPLETE!  ";

            default:   line1_buf = "WASHING MACHINE ";
        endcase
    end

    // ── Line 2 ──────────────────────────────────────────────────────────────
    reg [127:0] line2_buf;
    wire [7:0] door_ch  = door_closed      ? "1" : "0";
    wire [7:0] water_ch = water_level_full ? "1" : "0";

    always @(*) begin
        case (fsm_state)
            // "MODE:Qck    SET?"  or  "MODE:Qck   RDY! "
            IDLE: begin
                line2_buf[127:120] = "M";
                line2_buf[119:112] = "O";
                line2_buf[111:104] = "D";
                line2_buf[103: 96] = "E";
                line2_buf[ 95: 88] = ":";
                line2_buf[ 87: 80] = mode_label[23:16];  // e.g. 'Q'/'N'/'H'
                line2_buf[ 79: 72] = mode_label[15: 8];  // 'c'/'r'/'v'
                line2_buf[ 71: 64] = mode_label[ 7: 0];  // 'k'/'m'/'y'
                line2_buf[ 63: 56] = " ";
                line2_buf[ 55: 48] = " ";
                line2_buf[ 47: 40] = " ";
                line2_buf[ 39: 32] = " ";
                if (!mode_locked) begin
                    // "SET?"
                    line2_buf[ 31: 24] = "S";
                    line2_buf[ 23: 16] = "E";
                    line2_buf[ 15:  8] = "T";
                    line2_buf[  7:  0] = "?";
                end else begin
                    // "RDY!"
                    line2_buf[ 31: 24] = "R";
                    line2_buf[ 23: 16] = "D";
                    line2_buf[ 15:  8] = "Y";
                    line2_buf[  7:  0] = "!";
                end
            end

            // "D:0 W:0 FILLING "
            FILL_WATER: begin
                line2_buf[127:120] = "D";
                line2_buf[119:112] = ":";
                line2_buf[111:104] = door_ch;
                line2_buf[103: 96] = " ";
                line2_buf[ 95: 88] = "W";
                line2_buf[ 87: 80] = ":";
                line2_buf[ 79: 72] = water_ch;
                line2_buf[ 71: 64] = " ";
                line2_buf[ 63: 56] = "F";
                line2_buf[ 55: 48] = "I";
                line2_buf[ 47: 40] = "L";
                line2_buf[ 39: 32] = "L";
                line2_buf[ 31: 24] = "I";
                line2_buf[ 23: 16] = "N";
                line2_buf[ 15:  8] = "G";
                line2_buf[  7:  0] = " ";
            end

            // "D:1 W:1 MOTOR:ON" or "D:1 W:1 MOTOROFF" (WASH, RINSE, SPIN)
            WASH, RINSE, SPIN: begin
                line2_buf[127:120] = "D";
                line2_buf[119:112] = ":";
                line2_buf[111:104] = door_ch;
                line2_buf[103: 96] = " ";
                line2_buf[ 95: 88] = "W";
                line2_buf[ 87: 80] = ":";
                line2_buf[ 79: 72] = water_ch;
                line2_buf[ 71: 64] = " ";
                // chars 8-15: "MOTR:ON " when on, "MOTR:OFF" when off
                line2_buf[ 63: 56] = "M";
                line2_buf[ 55: 48] = "O";
                line2_buf[ 47: 40] = "T";
                line2_buf[ 39: 32] = "R";
                line2_buf[ 31: 24] = ":";
                line2_buf[ 23: 16] = motor_on ? "O" : "O";
                line2_buf[ 15:  8] = motor_on ? "N" : "F";
                line2_buf[  7:  0] = motor_on ? " " : "F";
            end


            // "D:1 W:x DRAINING"
            DRAIN: begin
                line2_buf[127:120] = "D";
                line2_buf[119:112] = ":";
                line2_buf[111:104] = door_ch;
                line2_buf[103: 96] = " ";
                line2_buf[ 95: 88] = "W";
                line2_buf[ 87: 80] = ":";
                line2_buf[ 79: 72] = water_ch;
                line2_buf[ 71: 64] = " ";
                line2_buf[ 63: 56] = "D";
                line2_buf[ 55: 48] = "R";
                line2_buf[ 47: 40] = "A";
                line2_buf[ 39: 32] = "I";
                line2_buf[ 31: 24] = "N";
                line2_buf[ 23: 16] = "I";
                line2_buf[ 15:  8] = "N";
                line2_buf[  7:  0] = "G";
            end

            // "PRESS RESET KEY "
            COMPLETE: begin
                line2_buf = "PRESS RESET KEY ";
            end

            default: begin
                line2_buf = "                ";
            end
        endcase
    end

    //--- Combine the two line buffers into a single disp_char lookup ---------
    always @(*) begin
        if (disp_idx < 6'd16) begin
            // Line 1: disp_idx 0..15 maps to bits [127:120]..[7:0]
            case (disp_idx)
                6'd0:  disp_char = line1_buf[127:120];
                6'd1:  disp_char = line1_buf[119:112];
                6'd2:  disp_char = line1_buf[111:104];
                6'd3:  disp_char = line1_buf[103: 96];
                6'd4:  disp_char = line1_buf[ 95: 88];
                6'd5:  disp_char = line1_buf[ 87: 80];
                6'd6:  disp_char = line1_buf[ 79: 72];
                6'd7:  disp_char = line1_buf[ 71: 64];
                6'd8:  disp_char = line1_buf[ 63: 56];
                6'd9:  disp_char = line1_buf[ 55: 48];
                6'd10: disp_char = line1_buf[ 47: 40];
                6'd11: disp_char = line1_buf[ 39: 32];
                6'd12: disp_char = line1_buf[ 31: 24];
                6'd13: disp_char = line1_buf[ 23: 16];
                6'd14: disp_char = line1_buf[ 15:  8];
                6'd15: disp_char = line1_buf[  7:  0];
                default: disp_char = " ";
            endcase
        end else begin
            // Line 2: disp_idx 16..31 maps to bits [127:120]..[7:0]
            case (disp_idx)
                6'd16: disp_char = line2_buf[127:120];
                6'd17: disp_char = line2_buf[119:112];
                6'd18: disp_char = line2_buf[111:104];
                6'd19: disp_char = line2_buf[103: 96];
                6'd20: disp_char = line2_buf[ 95: 88];
                6'd21: disp_char = line2_buf[ 87: 80];
                6'd22: disp_char = line2_buf[ 79: 72];
                6'd23: disp_char = line2_buf[ 71: 64];
                6'd24: disp_char = line2_buf[ 63: 56];
                6'd25: disp_char = line2_buf[ 55: 48];
                6'd26: disp_char = line2_buf[ 47: 40];
                6'd27: disp_char = line2_buf[ 39: 32];
                6'd28: disp_char = line2_buf[ 31: 24];
                6'd29: disp_char = line2_buf[ 23: 16];
                6'd30: disp_char = line2_buf[ 15:  8];
                6'd31: disp_char = line2_buf[  7:  0];
                default: disp_char = " ";
            endcase
        end
    end

    //==========================================================================
    // ── LEVEL-1 FSM : BIT-BANGED I2C BYTE TRANSMITTER ───────────────────────
    // Emits:  START | addr(8 bits) | ACK | data(8 bits) | ACK | STOP
    // ACK bits from the slave are not checked (master-only / blind).
    // i2c_done pulses for one clock when the transaction finishes.
    //==========================================================================
    reg  [7:0] i2c_data;
    reg        i2c_req;
    reg        i2c_done;
    reg        i2c_busy;

    reg [4:0]  i2c_state;
    reg [3:0]  i2c_bitcnt;
    reg [8:0]  i2c_tcnt;
    reg [7:0]  i2c_shift;
    reg        i2c_phase;   // 0 = addr byte, 1 = data byte

    wire i2c_tick = (i2c_tcnt == Q_CYCLES - 1);

    localparam I2C_IDLE   = 5'd0;
    localparam I2C_START1 = 5'd1;
    localparam I2C_START2 = 5'd2;
    localparam I2C_START3 = 5'd3;
    localparam I2C_BIT_A  = 5'd4;
    localparam I2C_BIT_B  = 5'd5;
    localparam I2C_BIT_C  = 5'd6;
    localparam I2C_BIT_D  = 5'd7;
    localparam I2C_ACK_A  = 5'd8;
    localparam I2C_ACK_B  = 5'd9;
    localparam I2C_ACK_C  = 5'd10;
    localparam I2C_ACK_D  = 5'd11;
    localparam I2C_STOP1  = 5'd12;
    localparam I2C_STOP2  = 5'd13;
    localparam I2C_STOP3  = 5'd14;
    localparam I2C_FINISH = 5'd15;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i2c_state  <= I2C_IDLE;
            i2c_tcnt   <= 9'd0;
            i2c_bitcnt <= 4'd0;
            i2c_shift  <= 8'd0;
            i2c_phase  <= 1'b0;
            i2c_busy   <= 1'b0;
            i2c_done   <= 1'b0;
            scl_drv    <= 1'b1;
            sda_drv    <= 1'b1;
        end else begin
            i2c_done <= 1'b0;

            if (i2c_state == I2C_IDLE || i2c_tick)
                i2c_tcnt <= 9'd0;
            else
                i2c_tcnt <= i2c_tcnt + 1'b1;

            case (i2c_state)
                I2C_IDLE: begin
                    scl_drv  <= 1'b1;
                    sda_drv  <= 1'b1;
                    i2c_busy <= 1'b0;
                    if (i2c_req) begin
                        i2c_shift  <= I2C_ADDR_W;
                        i2c_phase  <= 1'b0;
                        i2c_bitcnt <= 4'd0;
                        i2c_busy   <= 1'b1;
                        i2c_state  <= I2C_START1;
                    end
                end
                I2C_START1: begin scl_drv <= 1'b1; sda_drv <= 1'b1; if (i2c_tick) i2c_state <= I2C_START2; end
                I2C_START2: begin scl_drv <= 1'b1; sda_drv <= 1'b0; if (i2c_tick) i2c_state <= I2C_START3; end
                I2C_START3: begin scl_drv <= 1'b0; sda_drv <= 1'b0; if (i2c_tick) i2c_state <= I2C_BIT_A; end
                I2C_BIT_A:  begin scl_drv <= 1'b0; sda_drv <= i2c_shift[7]; if (i2c_tick) i2c_state <= I2C_BIT_B; end
                I2C_BIT_B:  begin scl_drv <= 1'b1; sda_drv <= i2c_shift[7]; if (i2c_tick) i2c_state <= I2C_BIT_C; end
                I2C_BIT_C:  begin scl_drv <= 1'b1; sda_drv <= i2c_shift[7]; if (i2c_tick) i2c_state <= I2C_BIT_D; end
                I2C_BIT_D: begin
                    scl_drv <= 1'b0; sda_drv <= i2c_shift[7];
                    if (i2c_tick) begin
                        i2c_shift  <= {i2c_shift[6:0], 1'b0};
                        i2c_bitcnt <= i2c_bitcnt + 1'b1;
                        if (i2c_bitcnt == 4'd7) i2c_state <= I2C_ACK_A;
                        else                    i2c_state <= I2C_BIT_A;
                    end
                end
                I2C_ACK_A: begin scl_drv <= 1'b0; sda_drv <= 1'b1; if (i2c_tick) i2c_state <= I2C_ACK_B; end
                I2C_ACK_B: begin scl_drv <= 1'b1; sda_drv <= 1'b1; if (i2c_tick) i2c_state <= I2C_ACK_C; end
                I2C_ACK_C: begin scl_drv <= 1'b1; sda_drv <= 1'b1; if (i2c_tick) i2c_state <= I2C_ACK_D; end
                I2C_ACK_D: begin
                    scl_drv <= 1'b0; sda_drv <= 1'b1;
                    if (i2c_tick) begin
                        if (i2c_phase == 1'b0) begin
                            i2c_shift  <= i2c_data;
                            i2c_bitcnt <= 4'd0;
                            i2c_phase  <= 1'b1;
                            i2c_state  <= I2C_BIT_A;
                        end else begin
                            i2c_state <= I2C_STOP1;
                        end
                    end
                end
                I2C_STOP1: begin scl_drv <= 1'b0; sda_drv <= 1'b0; if (i2c_tick) i2c_state <= I2C_STOP2; end
                I2C_STOP2: begin scl_drv <= 1'b1; sda_drv <= 1'b0; if (i2c_tick) i2c_state <= I2C_STOP3; end
                I2C_STOP3: begin scl_drv <= 1'b1; sda_drv <= 1'b1; if (i2c_tick) i2c_state <= I2C_FINISH; end
                I2C_FINISH: begin
                    scl_drv   <= 1'b1; sda_drv <= 1'b1;
                    i2c_done  <= 1'b1;
                    i2c_busy  <= 1'b0;
                    i2c_state <= I2C_IDLE;
                end
                default: i2c_state <= I2C_IDLE;
            endcase
        end
    end

    //==========================================================================
    // ── LEVEL-2 FSM : LCD NIBBLE SENDER ─────────────────────────────────────
    // Each LCD byte needs 4 I2C writes (upper nibble EN=1/0, lower EN=1/0).
    // During initialisation some commands are sent as upper-nibble only
    // (lcd_init_only = 1).
    //==========================================================================
    reg [7:0] lcd_byte;
    reg       lcd_rs;
    reg       lcd_init_only;
    reg       lcd_req;
    reg       lcd_done;
    reg       lcd_busy;

    reg [2:0] lcd_state;
    localparam L_IDLE   = 3'd0;
    localparam L_UP_HI  = 3'd1;
    localparam L_UP_LO  = 3'd2;
    localparam L_LO_HI  = 3'd3;
    localparam L_LO_LO  = 3'd4;
    localparam L_FINISH = 3'd5;

    reg [7:0] lcd_byte_r;
    reg       lcd_rs_r;
    reg       lcd_init_only_r;

    // Combinational nibble → I2C byte builder
    reg       l_issue_req;
    reg [7:0] l_next_i2c_data;
    always @(*) begin
        l_issue_req     = 1'b0;
        l_next_i2c_data = 8'h00;
        case (lcd_state)
            // {D7..D4, BL=1, EN, RW=0, RS}
            L_UP_HI: begin l_issue_req = 1'b1; l_next_i2c_data = {lcd_byte_r[7:4], 1'b1, 1'b1, 1'b0, lcd_rs_r}; end
            L_UP_LO: begin l_issue_req = 1'b1; l_next_i2c_data = {lcd_byte_r[7:4], 1'b1, 1'b0, 1'b0, lcd_rs_r}; end
            L_LO_HI: begin l_issue_req = 1'b1; l_next_i2c_data = {lcd_byte_r[3:0], 1'b1, 1'b1, 1'b0, lcd_rs_r}; end
            L_LO_LO: begin l_issue_req = 1'b1; l_next_i2c_data = {lcd_byte_r[3:0], 1'b1, 1'b0, 1'b0, lcd_rs_r}; end
            default: ;
        endcase
    end

    reg [1:0] l_sub;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lcd_state       <= L_IDLE;
            lcd_byte_r      <= 8'd0;
            lcd_rs_r        <= 1'b0;
            lcd_init_only_r <= 1'b0;
            lcd_done        <= 1'b0;
            lcd_busy        <= 1'b0;
            i2c_req         <= 1'b0;
            i2c_data        <= 8'd0;
            l_sub           <= 2'd0;
        end else begin
            lcd_done <= 1'b0;
            i2c_req  <= 1'b0;

            case (lcd_state)
                L_IDLE: begin
                    lcd_busy <= 1'b0;
                    l_sub    <= 2'd0;
                    if (lcd_req) begin
                        lcd_byte_r      <= lcd_byte;
                        lcd_rs_r        <= lcd_rs;
                        lcd_init_only_r <= lcd_init_only;
                        lcd_busy        <= 1'b1;
                        lcd_state       <= L_UP_HI;
                    end
                end

                L_UP_HI, L_UP_LO, L_LO_HI, L_LO_LO: begin
                    case (l_sub)
                        2'd0: begin
                            i2c_req  <= 1'b1;
                            i2c_data <= l_next_i2c_data;
                            l_sub    <= 2'd1;
                        end
                        2'd1: if (i2c_busy) l_sub <= 2'd2;
                        2'd2: begin
                            if (i2c_done) begin
                                l_sub <= 2'd0;
                                case (lcd_state)
                                    L_UP_HI: lcd_state <= L_UP_LO;
                                    L_UP_LO: lcd_state <= lcd_init_only_r ? L_FINISH : L_LO_HI;
                                    L_LO_HI: lcd_state <= L_LO_LO;
                                    L_LO_LO: lcd_state <= L_FINISH;
                                    default: lcd_state <= L_FINISH;
                                endcase
                            end
                        end
                        default: l_sub <= 2'd0;
                    endcase
                end

                L_FINISH: begin
                    lcd_done  <= 1'b1;
                    lcd_busy  <= 1'b0;
                    lcd_state <= L_IDLE;
                end
                default: lcd_state <= L_IDLE;
            endcase
        end
    end

    //==========================================================================
    // ── LEVEL-3 FSM : MASTER SEQUENCER ──────────────────────────────────────
    // Runs the initialisation sequence once, then loops refreshing the 32-char
    // display buffer at ~5 Hz (200 ms inter-refresh delay).
    //
    // Step map:
    //   0        : power-on delay (50 ms)
    //   1..8     : HD44780 initialisation (function-set pulses + commands)
    //   9..13    : display on, clear, entry mode, position cursor line 1
    //   14..29   : write 16 chars of Line 1
    //   30       : set DDRAM address for Line 2
    //   31..46   : write 16 chars of Line 2
    //   47       : refresh delay (200 ms) → wrap back to step 9
    //==========================================================================
    reg [7:0] step;

    reg        want_send;
    reg [7:0]  byte_val;
    reg        rs_val;
    reg        init_only_val;
    reg [31:0] delay_target;
    reg [5:0]  disp_idx_for_step;

    always @(*) begin
        want_send         = 1'b0;
        byte_val          = 8'h00;
        rs_val            = 1'b0;
        init_only_val     = 1'b0;
        delay_target      = 32'd0;
        disp_idx_for_step = 6'd0;

        // ---- Initialisation ----
        if      (step == 8'd0) delay_target  = D_POWER_ON;              // 50 ms
        else if (step == 8'd1) begin want_send = 1'b1; byte_val = 8'h30; init_only_val = 1'b1; end
        else if (step == 8'd2) delay_target  = D_LONG;                  //  5 ms
        else if (step == 8'd3) begin want_send = 1'b1; byte_val = 8'h30; init_only_val = 1'b1; end
        else if (step == 8'd4) delay_target  = D_SHORT;                 // 250 us
        else if (step == 8'd5) begin want_send = 1'b1; byte_val = 8'h30; init_only_val = 1'b1; end
        else if (step == 8'd6) delay_target  = D_SHORT;
        else if (step == 8'd7) begin want_send = 1'b1; byte_val = 8'h20; init_only_val = 1'b1; end // → 4-bit
        else if (step == 8'd8) delay_target  = D_SHORT;

        // ---- LCD configuration commands ----
        else if (step == 8'd9)  begin want_send = 1'b1; byte_val = 8'h28; end // 4-bit, 2 lines
        else if (step == 8'd10) begin want_send = 1'b1; byte_val = 8'h0C; end // display on, cursor off
        else if (step == 8'd11) begin want_send = 1'b1; byte_val = 8'h01; end // clear display
        else if (step == 8'd12) delay_target  = D_LONG;                       // clear needs ~5 ms
        else if (step == 8'd13) begin want_send = 1'b1; byte_val = 8'h06; end // entry mode: cursor right

        // ---- Refresh start: position cursor at line 1 ----
        else if (step == 8'd14) begin want_send = 1'b1; byte_val = 8'h80; end // DDRAM addr = 0x00

        // ---- Write 16 characters of line 1 (steps 15..30) ----
        else if (step >= 8'd15 && step <= 8'd30) begin
            want_send         = 1'b1;
            rs_val            = 1'b1;
            disp_idx_for_step = step - 8'd15;   // 0..15
            byte_val          = disp_char;
        end

        // ---- Position cursor at line 2 ----
        else if (step == 8'd31) begin want_send = 1'b1; byte_val = 8'hC0; end // DDRAM addr = 0x40

        // ---- Write 16 characters of line 2 (steps 32..47) ----
        else if (step >= 8'd32 && step <= 8'd47) begin
            want_send         = 1'b1;
            rs_val            = 1'b1;
            disp_idx_for_step = step - 8'd32 + 8'd16; // 16..31
            byte_val          = disp_char;
        end

        // ---- Inter-refresh delay ----
        else if (step == 8'd48) delay_target = D_REFRESH;
    end

    // Feed disp_idx from the sequencer so disp_char is correct
    always @(*) begin
        disp_idx = disp_idx_for_step;
    end

    //--- Sequencer (run send OR delay, then advance step) --------------------
    reg [31:0] delay_ctr;
    reg        delay_active;
    reg [1:0]  m_sub;

    localparam [7:0] STEP_LAST    = 8'd48;
    localparam [7:0] STEP_REFRESH = 8'd14;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            step         <= 8'd0;
            delay_ctr    <= 32'd0;
            delay_active <= 1'b0;
            lcd_req      <= 1'b0;
            lcd_byte     <= 8'd0;
            lcd_rs       <= 1'b0;
            lcd_init_only<= 1'b0;
            m_sub        <= 2'd0;
        end else begin
            lcd_req <= 1'b0;

            if (want_send) begin
                case (m_sub)
                    2'd0: begin
                        if (!lcd_busy) begin
                            lcd_byte      <= byte_val;
                            lcd_rs        <= rs_val;
                            lcd_init_only <= init_only_val;
                            lcd_req       <= 1'b1;
                            m_sub         <= 2'd1;
                        end
                    end
                    2'd1: if (lcd_busy) m_sub <= 2'd2;
                    2'd2: begin
                        if (lcd_done) begin
                            m_sub <= 2'd0;
                            step  <= (step == STEP_LAST) ? STEP_REFRESH : step + 1'b1;
                        end
                    end
                    default: m_sub <= 2'd0;
                endcase
            end else begin
                if (!delay_active) begin
                    delay_active <= 1'b1;
                    delay_ctr    <= 32'd0;
                end else if (delay_ctr >= delay_target) begin
                    delay_active <= 1'b0;
                    delay_ctr    <= 32'd0;
                    step         <= (step == STEP_LAST) ? STEP_REFRESH : step + 1'b1;
                end else begin
                    delay_ctr <= delay_ctr + 1'b1;
                end
            end
        end
    end

endmodule
