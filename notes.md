# FPGA Logic Analyzer



## Files

| File | Description |
|------|-------------|
| `src/logic_analyzer.vhd` | Top-level entity: PLL, reset sync, channel sync, SUMP core, UART, LEDs, test signal gen |
| `src/pll_wrapper.vhd` | MMCME2_BASE: 50MHz → 150MHz |
| `src/sram.vhd` | Circular BRAM buffer (8192×32) |
| `src/sump_core.vhd` | SUMP protocol engine |
| `src/uart.vhd` | UART wrapper (RX + TX) |
| `src/uart_rx.vhd` | UART receiver |
| `src/uart_tx.vhd` | UART transmitter |
| `wukong.xdc` | Pinout for Wukong board, JP2 test pins, CLOCK_DEDICATED_ROUTE FALSE for M21 |

## Wukong Board Pinout

| Signal | Pin | Notes |
|--------|-----|-------|
| `i_sys_clk` | M21 | 50MHz board oscillator |
| `i_rstn` | M6 | CPU reset button |
| `i_raw_sig[31:0]` | J12 (pins 3-34) | 32 probe channels |
| `i_rx` | F3 | FTDI UART RX |
| `o_tx` | E3 | FTDI UART TX |
| `o_triggered_led` | V16 | user_led0 (active-low) — acquisition indicator |
| `o_enabled` | V17 | user_led1 (active-low) — UART readout indicator |
| `o_jp2_test[15:0]` | JP2 (pins 3-18) | 16 test clocks from counter divider |

### J12 Connector Pinout (2×20 = 40 pins)

Pin 1 = GND, pin 2 = VIN (3.3V). 32 probe channels start at pin 3.

| J12 Pin | Signal | FPGA Pin | J12 Pin | Signal | FPGA Pin |
|---------|--------|----------|---------|--------|----------|
| 1  | GND   | —    | 2  | VIN  | —    |
| 3  | ch0   | AB26 | 4  | ch1  | AC26 |
| 5  | ch2   | AB24 | 6  | ch3  | AC24 |
| 7  | ch4   | AA24 | 8  | ch5  | AB25 |
| 9  | ch6   | AA22 | 10 | ch7  | AA23 |
| 11 | ch8   | Y25  | 12 | ch9  | AA25 |
| 13 | ch10  | W25  | 14 | ch11 | Y26  |
| 15 | ch12  | Y22  | 16 | ch13 | Y23  |
| 17 | ch14  | W21  | 18 | ch15 | Y21  |
| 19 | ch16  | V26  | 20 | ch17 | W26  |
| 21 | ch18  | U25  | 22 | ch19 | U26  |
| 23 | ch20  | V24  | 24 | ch21 | W24  |
| 25 | ch22  | V23  | 26 | ch23 | W23  |
| 27 | ch24  | V18  | 28 | ch25 | W18  |
| 29 | ch26  | U22  | 30 | ch27 | V22  |
| 31 | ch28  | U21  | 32 | ch29 | V21  |
| 33 | ch30  | T20  | 34 | ch31 | U20  |
| 35 | —    | —    | 36 | —    | —    |
| 37 | GND   | —    | 38 | GND  | —    |
| 39 | VCCO  | —    | 40 | VCCO | —    |

Pins 35-36 are unused. Test clock outputs on JP2 connector.

## JP2 Test Signal Outputs (2×9 = 18 pins)

Pin 1 = 3.3V, pin 2 = GND. Pins 3-18 are 16 test clocks from a 40-bit counter at 150 MHz.

| JP2 Pin | Signal | FPGA Pin | Frequency |
|---------|--------|----------|-----------|
| 1 | 3.3V | — | — |
| 2 | GND | — | — |
| 3 | `o_jp2_test[0]` | H21 | 75 MHz |
| 4 | `o_jp2_test[1]` | H22 | 37.5 MHz |
| 5 | `o_jp2_test[2]` | K21 | 18.75 MHz |
| 6 | `o_jp2_test[3]` | J21 | 9.375 MHz |
| 7 | `o_jp2_test[4]` | H26 | 4.6875 MHz |
| 8 | `o_jp2_test[5]` | G26 | 2.34375 MHz |
| 9 | `o_jp2_test[6]` | G25 | 1.171875 MHz |
| 10 | `o_jp2_test[7]` | F25 | 585.9375 kHz |
| 11 | `o_jp2_test[8]` | G20 | 292.96875 kHz |
| 12 | `o_jp2_test[9]` | G21 | 146.484375 kHz |
| 13 | `o_jp2_test[10]` | F23 | 73.2421875 kHz |
| 14 | `o_jp2_test[11]` | E23 | 36.62109375 kHz |
| 15 | `o_jp2_test[12]` | E26 | 18.310546875 kHz |
| 16 | `o_jp2_test[13]` | D26 | 9.1552734375 kHz |
| 17 | `o_jp2_test[14]` | E25 | 4.57763671875 kHz |
| 18 | `o_jp2_test[15]` | D25 | 2.288818359375 kHz |

All outputs are registered counter bits divided from the 150 MHz PLL clock (`cnt[0]` = 75 MHz, `cnt[15]` = ~2.3 kHz).

## 5V Input Protection

FPGA inputs are 3.3V only. For probing 5V signals:

```
Probe → 100Ω → 74LVC245N (DIP-20, VCC=3.3V) → FPGA
```

- **74LVC245N**: 5V-tolerant inputs at 3.3V VCC, ~3.5ns prop delay
- 4 chips needed (8 ch per chip), OE pin to tri-state during FPGA config
- Optional: PESD5V0S4UB quad TVS array for ESD

## System Clock

- 50MHz board oscillator → PLL (×18/6) → **150 MHz**
- VCO = 50 × 18 / 1 = **900 MHz** (within 600-1200 MHz range for -1 speed grade)

## UART — 3,000,000 baud (3 Mbps)

CLKS_PER_BIT = 150MHz / 3Mbps = **50** (0% error).

SUMP readout: 8192 samples × 4 bytes = 32 KB in ~**109 ms** at 3 Mbps.

### SUMP Protocol

Host → FPGA: SUMP commands (0x00-0x04, 0x80-0x82, 0xC0-0xCB)
FPGA → Host: "1ALS" (ID), metadata, or sample data (4-byte words, MSB first, reverse order).

## Memory — xc7a100tfgg676-1

| Resource | Used | Available | Util% |
|----------|------|-----------|-------|
| LUTs | ~260 | 63,400 | 0.4% |
| FFs | ~300 | 126,800 | 0.2% |
| **BRAM36** | **~1** | **135** | **0.7%** |

32-bit samples, 8192 depth = 1 BRAM36 (configured as 8192×36, using 32 data bits).

---

## SUMP Protocol

```
┌─────────────────────────────────────────────────────────────┐
│                      SUMP_Core                              │
│                                                             │
│  UART RX → Command Parser (1/2/5-byte accumulation)        │
│              ↓ opcode + data                                │
│           Command Dispatch                                   │
│         ┌─────┼─────────┬──────────┬──────────┐             │
│         ↓     ↓         ↓          ↓          ↓             │
│       ID   Metadata  Set Regs  Arm/Run   Trigger            │
│       (0x02)(0x04)   (0x80-    (0x01)    (0xC0-CB)          │
│                      0x82)               mask+value+cfg     │
│                                                             │
│  Sample Clock Gen (20-bit divider → sample_clk)             │
│       ↓                                                     │
│  Circular BRAM (8192×32, 1 BRAM36) ← i_channels             │
│       ↓ (on trigger + delay_count)                          │
│  Readout FSM (reverse order, MSB-first, 4 bytes/word)      │
│       ↓                                                     │
│  UART TX                                                    │
└─────────────────────────────────────────────────────────────┘
```

## Implemented SUMP Commands

| Command | Implementation |
|---------|---------------|
| `0x00` Reset | Aborts capture/readout, returns to IDLE |
| `0x01` Run | Starts circular buffer capture from address 0 |
| `0x02` ID | Sends `"1ALS"` (4 bytes) |
| `0x03` Auto Trigger | 3-byte cmd (opcode + 2-byte LE timeout). Counter increments each sample clock; when timeout reached with no trigger, forces stop. |
| `0x04` Metadata | 29-byte TLV response: device name `"RorytLA"`, fw `"1.0"`, memory depth (from `MEM_DEPTH`), max rate 150 MHz, 32 probes, protocol v2 |
| `0x80` Set Divider | 5-byte cmd (opcode + 4-byte LE). 20-bit divider: `f_sample = f_clk / (divider + 1)`. Byte-order: accumulation is MSB-first, LE bytes reversed on store. |
| `0x81` Set Read & Delay Count | 5-byte cmd (opcode + 4-byte LE). read_count [15:0], delay_count [31:16]. Byte-swapped on store for LE correction. |
| `0x82` Set Flags | 2-byte cmd (opcode + 1 byte). 8-bit flags register. |
| `0xC0-0xC3` Trigger Mask | 5-byte cmd (opcode + 4-byte LE mask per stage). Byte-swapped on store. |
| `0xC4-0xC7` Trigger Value | 5-byte cmd (opcode + 4-byte LE value per stage). Byte-swapped on store. |
| `0xC8-0xCB` Trigger Config | 2-byte cmd (opcode + 1 byte): bit0=enable, bit1=1=edge/0=level, bit2=edge polarity (0=rising/1=falling), bit3=reserved |


## Capture + Readout Flow

1. Host sends `0x81` (read count + delay count)
2. Host sends `0x80` (divider for sample rate)
3. Host sends `0x03` (auto-trigger timeout, optional)
4. Host sends `0xC0-0xCB` (trigger mask/value/config per stage, optional)
5. Host sends `0x01` (Run)
6. FPGA starts sampling at configured rate, writing to circular BRAM
7. On trigger match: capture position recorded
8. Continue for `delay_count` more samples, then stop
9. Auto-start readout: send `read_count` × 32-bit words in **reverse order**, MSB first
10. Return to IDLE, ready for next capture
11. If no trigger: fill entire buffer (`MEM_DEPTH` samples) or reach auto-trigger timeout, then readout

## Trigger System

### Per-Stage Match Logic

Each stage (0-3) can be configured independently:

| Config bit | Name | Function |
|------------|------|----------|
| 0 | Enable | Stage participates in trigger |
| 1 | Mode | 0 = level match, 1 = edge match |
| 2 | Polarity | Edge: 0 = rising, 1 = falling |
| 3 | (stored, unused) | Reserved — no effect on trigger behavior |

**Level match:** `(sample & mask) == (value & mask)` — fires when all masked channels match the given pattern.

**Edge match:** Compares current sample against previous sample:
- Rising edge: previous didn't match value, current does (0→1 transition)
- Falling edge: previous matched value, current doesn't (1→0 transition)

### Sequential Multi-Stage Triggering (always-on)

Stages fire in sequence 0→1→2→3:
- Stage 0 is armed at capture start
- When stage N fires, it arms stage N+1
- Trigger fires when **any** armed stage matches
- Single-stage (stage 0 only): fires on match as before
- Multi-stage: e.g. stage 0 must match first, then stage 1, then trigger fires

Parallel mode (all stages match simultaneously) is not implemented — `r_flags[4]` is stored but ignored.

## UART Readout Timing (SUMP)

| Readout | 8192 samples (32 KB) @ 3 Mbps |
|---------|-------------------------------|
| Time | ~109 ms |


## Usage

### Linux

```bash
# Scan for device
sigrok-cli --driver ols:conn=/dev/ttyUSB0:serialcomm=3000000/8n1 --scan

# Capture 8192 samples at 150 MHz
sigrok-cli --driver ols:conn=/dev/ttyUSB0:serialcomm=3000000/8n1 \
  -c samplerate=150000000 \
  --samples 8192 \
  -o capture.sr

# Capture with rising-edge trigger on channel 7
sigrok-cli --driver ols:conn=/dev/ttyUSB0:serialcomm=3000000/8n1 \
  -c samplerate=10000000 \
  --triggers 7=r \
  --samples 4096 \
  -o capture.sr
```

### Windows

```cmd
"C:\Program Files\sigrok\sigrok-cli\sigrok-cli" -d ols:conn=COM3:serialcomm=3000000/8n1 -c samplerate=10000000 --triggers 7=r --samples 4096 -o capture.sr
```

You can also connect and capture directly from PulseView without the CLI. Open the `.sr` file in PulseView for waveform visualization.

## Status

**SUMP capture verified working.** sigrok-cli successfully captures samples and writes `.sr` files:

| Test | Result |
|------|--------|
| Device scan | Detected as `ols` via stock driver ✓ |
| Metadata query | Device "RorytLA", 32 probes, 150 MHz, 32768 bytes ✓ |
| Capture 5000 samples @ 50 MHz | Completed cleanly, valid `cap_debug.sr` (20000 bytes logic data) ✓ |
| Session lifecycle | `session: Started` → data streaming → `session: Stopped` → serial close ✓ |
| Sample pattern | Channels match test signal generator (counter bits on D0-7) ✓ |
| Readout byte order | LSB-first: D0-7 in byte 0, D24-31 in byte 3 ✓ |
| Factor-of-4 read count | ×4 fix applied in 0x81 handler (left-shift 2) ✓ |
| CMD_EXEC blocking | Register writes execute during readout; 0x01 deferred via `r_pending_run` ✓ |
| LED indicators | V16 = acquisition (stretched), V17 = UART readout (stretched) ✓ |
| 150 MHz system clock | PLL ×18/6, 3Mbps UART (CLKS_PER_BIT=50) ✓ |
| Device name | Metadata reports "RorytLA" ✓ |

## What's Not Yet Tested

| Feature | Priority | Notes |
|---------|----------|-------|
| Trigger modes (edge/level) | Low | Rising, falling, level high/low |
| Flags register bits (0x82) | Low | Demux, filter, channel group, invert — stored but ignored |
| RLE compression | None | SUMP2 extension |
| Edge trigger: channel-level mask | Low | Edge detection uses full 32-bit mask |
