# ============================================================================
# Wukong Board (xc7a100tfgg676-1) Pin Constraints for qmtech wukong board
# ============================================================================
# 50MHz input clock -> PLL -> 150MHz internal clock
# 32 probe channels on J12 PMOD connector (4 banks × 8)
# LEDs active-low (on when pin = 0)
# ============================================================================

# --- System Clock (50MHz from board oscillator) ---
set_property PACKAGE_PIN M21 [get_ports i_sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports i_sys_clk]
create_clock -period 20.000 -name sys_clk [get_ports i_sys_clk]

# --- Active-Low Reset (CPU reset button) ---
set_property IOSTANDARD LVCMOS33 [get_ports i_rstn]
set_property PACKAGE_PIN M6 [get_ports i_rstn]

# --- Analyzer Probe Channels (32-bit input on J12 PMOD) ---
# J12 bank 0: AB26 AC26 AB24 AC24 AA24 AB25 AA22 AA23
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[0]}]
set_property PACKAGE_PIN AB26 [get_ports {i_raw_sig[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[1]}]
set_property PACKAGE_PIN AC26 [get_ports {i_raw_sig[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[2]}]
set_property PACKAGE_PIN AB24 [get_ports {i_raw_sig[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[3]}]
set_property PACKAGE_PIN AC24 [get_ports {i_raw_sig[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[4]}]
set_property PACKAGE_PIN AA24 [get_ports {i_raw_sig[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[5]}]
set_property PACKAGE_PIN AB25 [get_ports {i_raw_sig[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[6]}]
set_property PACKAGE_PIN AA22 [get_ports {i_raw_sig[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[7]}]
set_property PACKAGE_PIN AA23 [get_ports {i_raw_sig[7]}]

# J12 bank 1: Y25 AA25 W25 Y26 Y22 Y23 W21 Y21
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[8]}]
set_property PACKAGE_PIN Y25 [get_ports {i_raw_sig[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[9]}]
set_property PACKAGE_PIN AA25 [get_ports {i_raw_sig[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[10]}]
set_property PACKAGE_PIN W25 [get_ports {i_raw_sig[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[11]}]
set_property PACKAGE_PIN Y26 [get_ports {i_raw_sig[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[12]}]
set_property PACKAGE_PIN Y22 [get_ports {i_raw_sig[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[13]}]
set_property PACKAGE_PIN Y23 [get_ports {i_raw_sig[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[14]}]
set_property PACKAGE_PIN W21 [get_ports {i_raw_sig[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[15]}]
set_property PACKAGE_PIN Y21 [get_ports {i_raw_sig[15]}]

# J12 bank 2: V26 W26 U25 U26 V24 W24 V23 W23
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[16]}]
set_property PACKAGE_PIN V26 [get_ports {i_raw_sig[16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[17]}]
set_property PACKAGE_PIN W26 [get_ports {i_raw_sig[17]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[18]}]
set_property PACKAGE_PIN U25 [get_ports {i_raw_sig[18]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[19]}]
set_property PACKAGE_PIN U26 [get_ports {i_raw_sig[19]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[20]}]
set_property PACKAGE_PIN V24 [get_ports {i_raw_sig[20]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[21]}]
set_property PACKAGE_PIN W24 [get_ports {i_raw_sig[21]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[22]}]
set_property PACKAGE_PIN V23 [get_ports {i_raw_sig[22]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[23]}]
set_property PACKAGE_PIN W23 [get_ports {i_raw_sig[23]}]

# J12 bank 3: V18 W18 U22 V22 U21 V21 T20 U20
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[24]}]
set_property PACKAGE_PIN V18 [get_ports {i_raw_sig[24]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[25]}]
set_property PACKAGE_PIN W18 [get_ports {i_raw_sig[25]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[26]}]
set_property PACKAGE_PIN U22 [get_ports {i_raw_sig[26]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[27]}]
set_property PACKAGE_PIN V22 [get_ports {i_raw_sig[27]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[28]}]
set_property PACKAGE_PIN U21 [get_ports {i_raw_sig[28]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[29]}]
set_property PACKAGE_PIN V21 [get_ports {i_raw_sig[29]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[30]}]
set_property PACKAGE_PIN T20 [get_ports {i_raw_sig[30]}]
set_property IOSTANDARD LVCMOS33 [get_ports {i_raw_sig[31]}]
set_property PACKAGE_PIN U20 [get_ports {i_raw_sig[31]}]

# --- LEDs (active-low: on when pin = 0) ---
set_property IOSTANDARD LVCMOS33 [get_ports o_triggered_led]
set_property PACKAGE_PIN V16 [get_ports o_triggered_led]

set_property IOSTANDARD LVCMOS33 [get_ports o_enabled]
set_property PACKAGE_PIN V17 [get_ports o_enabled]

# --- UART (FTDI USB-to-Serial) ---
set_property IOSTANDARD LVCMOS33 [get_ports i_rx]
set_property PACKAGE_PIN F3 [get_ports i_rx]

set_property IOSTANDARD LVCMOS33 [get_ports o_tx]
set_property PACKAGE_PIN E3 [get_ports o_tx]

# --- JP2 Test Signal Outputs (16 counter-divided clocks from PLL) ---
# Pin 1 = 3.3V, Pin 2 = GND. Pins 3-18 mapped below.
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[0]}]
set_property PACKAGE_PIN H21 [get_ports {o_jp2_test[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[1]}]
set_property PACKAGE_PIN H22 [get_ports {o_jp2_test[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[2]}]
set_property PACKAGE_PIN K21 [get_ports {o_jp2_test[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[3]}]
set_property PACKAGE_PIN J21 [get_ports {o_jp2_test[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[4]}]
set_property PACKAGE_PIN H26 [get_ports {o_jp2_test[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[5]}]
set_property PACKAGE_PIN G26 [get_ports {o_jp2_test[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[6]}]
set_property PACKAGE_PIN G25 [get_ports {o_jp2_test[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[7]}]
set_property PACKAGE_PIN F25 [get_ports {o_jp2_test[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[8]}]
set_property PACKAGE_PIN G20 [get_ports {o_jp2_test[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[9]}]
set_property PACKAGE_PIN G21 [get_ports {o_jp2_test[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[10]}]
set_property PACKAGE_PIN F23 [get_ports {o_jp2_test[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[11]}]
set_property PACKAGE_PIN E23 [get_ports {o_jp2_test[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[12]}]
set_property PACKAGE_PIN E26 [get_ports {o_jp2_test[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[13]}]
set_property PACKAGE_PIN D26 [get_ports {o_jp2_test[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[14]}]
set_property PACKAGE_PIN E25 [get_ports {o_jp2_test[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_jp2_test[15]}]
set_property PACKAGE_PIN D25 [get_ports {o_jp2_test[15]}]

# --- FPGA Configuration Flash (not related to analyzer data) ---
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# --- Required for Wukong board: M21 is not a dedicated clock-capable pin ---
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of_objects [get_ports i_sys_clk]]

# --- Configuration voltage settings ---
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
