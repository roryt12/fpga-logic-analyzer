library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity logic_analyzer is
    generic (
        DATA_WIDTH : positive := 32;
        MEM_DEPTH  : positive := 8192
    );
    port (
        i_sys_clk      : in  std_logic;
        i_rstn         : in  std_logic;
        i_raw_sig      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        i_rx           : in  std_logic;
        o_triggered_led : out std_logic;
        o_enabled      : out std_logic;
        o_tx           : out std_logic;
        o_jp2_test     : out std_logic_vector(15 downto 0)
    );
end logic_analyzer;

architecture rtl of logic_analyzer is
    signal w_clk       : std_logic;
    signal w_pll_locked : std_logic;

    signal r_pll_lock_sync : std_logic_vector(1 downto 0) := (others => '0');

    signal w_rstn_raw : std_logic;
    signal w_rstn     : std_logic;

    signal r_rst1 : std_logic;
    signal r_rst2 : std_logic;

    signal w_channels : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal w_rx_dv    : std_logic;
    signal w_rx_byte  : std_logic_vector(7 downto 0);
    signal w_tx_dv    : std_logic;
    signal w_tx_byte  : std_logic_vector(7 downto 0);
    signal w_tx_done  : std_logic;

    signal w_sump_tx_dv   : std_logic;
    signal w_sump_tx_byte : std_logic_vector(7 downto 0);
    signal w_sump_enable  : std_logic;
    signal w_sump_readout_active : std_logic;

    constant STRETCH_MAX : unsigned(23 downto 0) := x"989680"; -- 10,000,000
    signal r_capture_stretch  : unsigned(23 downto 0) := (others => '0');
    signal r_readout_stretch  : unsigned(23 downto 0) := (others => '0');

    signal r_test_cnt : unsigned(39 downto 0) := (others => '0');
begin

    PLL : entity work.pll_wrapper
        port map (
            i_clk_50 => i_sys_clk,
            o_clk_100 => w_clk,
            o_locked  => w_pll_locked
        );

    process (w_clk) begin
        if rising_edge(w_clk) then
            r_pll_lock_sync <= r_pll_lock_sync(0) & w_pll_locked;
        end if;
    end process;

    process (w_clk, i_rstn) begin
        if i_rstn = '0' then
            r_rst1       <= '0';
            r_rst2       <= '0';
            w_rstn_raw    <= '0';
        elsif rising_edge(w_clk) then
            r_rst1       <= '1';
            r_rst2       <= r_rst1;
            w_rstn_raw    <= r_rst2;
        end if;
    end process;

    w_rstn <= w_rstn_raw and r_pll_lock_sync(1);

    process (w_clk) begin
        if rising_edge(w_clk) then
            w_channels <= i_raw_sig;
        end if;
    end process;

    process (w_clk, w_rstn) begin
        if w_rstn = '0' then
            r_test_cnt <= (others => '0');
        elsif rising_edge(w_clk) then
            r_test_cnt <= r_test_cnt + 1;
        end if;
    end process;

    o_jp2_test <= std_logic_vector(r_test_cnt(15 downto 0));

    SUMP : entity work.sump_core
        generic map (DATA_WIDTH => DATA_WIDTH, MEM_DEPTH => MEM_DEPTH)
        port map (
            i_clk            => w_clk,
            i_rstn           => w_rstn,
            i_rx_dv          => w_rx_dv,
            i_rx_byte        => w_rx_byte,
            o_tx_dv          => w_sump_tx_dv,
            o_tx_byte        => w_sump_tx_byte,
            i_tx_done        => w_tx_done,
            i_channels       => w_channels,
            o_enable         => w_sump_enable,
            o_readout_active => w_sump_readout_active
        );

    USB : entity work.uart
        generic map (CLKS_PER_BIT => 50)
        port map (
            i_sys_clk   => w_clk,
            i_Rx_Serial => i_rx,
            i_Tx_DV     => w_sump_tx_dv,
            i_Tx_Byte   => w_sump_tx_byte,
            o_Tx_Serial => o_tx,
            o_Rx_DV     => w_rx_dv,
            o_Rx_Byte   => w_rx_byte,
            o_Tx_Done   => w_tx_done
        );

    process (w_clk) begin
        if rising_edge(w_clk) then
            if w_sump_enable = '1' then
                r_capture_stretch <= STRETCH_MAX;
            elsif r_capture_stretch /= 0 then
                r_capture_stretch <= r_capture_stretch - 1;
            end if;
        end if;
    end process;

    process (w_clk) begin
        if rising_edge(w_clk) then
            if w_sump_readout_active = '1' then
                r_readout_stretch <= STRETCH_MAX;
            elsif r_readout_stretch /= 0 then
                r_readout_stretch <= r_readout_stretch - 1;
            end if;
        end if;
    end process;

    o_triggered_led <= '0' when r_capture_stretch /= 0 else '1';
    o_enabled       <= '0' when r_readout_stretch /= 0 else '1';

end rtl;