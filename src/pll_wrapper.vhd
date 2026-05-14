library ieee;
use ieee.std_logic_1164.all;

entity pll_wrapper is
    port (
        i_clk_50 : in  std_logic;
        o_clk_100 : out std_logic;
        o_locked  : out std_logic
    );
end pll_wrapper;

architecture structural of pll_wrapper is
    signal w_fb : std_logic;
begin

    MMCME2_BASE_inst : entity work.MMCME2_BASE
        generic map (
            BANDWIDTH          => "OPTIMIZED",
            CLKFBOUT_MULT_F    => 18.000,
            CLKFBOUT_PHASE     => 0.000,
            CLKIN1_PERIOD      => 20.000,
            CLKOUT0_DIVIDE_F   => 6.000,
            CLKOUT0_DUTY_CYCLE => 0.500,
            CLKOUT0_PHASE      => 0.000,
            CLKOUT1_DIVIDE     => 1,
            CLKOUT2_DIVIDE     => 1,
            CLKOUT3_DIVIDE     => 1,
            CLKOUT4_DIVIDE     => 1,
            CLKOUT5_DIVIDE     => 1,
            CLKOUT6_DIVIDE     => 1,
            DIVCLK_DIVIDE      => 1,
            REF_JITTER1        => 0.010,
            STARTUP_WAIT       => "FALSE"
        )
        port map (
            CLKIN1    => i_clk_50,
            CLKFBIN   => w_fb,
            RST       => '0',
            PWRDWN    => '0',
            CLKOUT0   => o_clk_100,
            CLKOUT0B  => open,
            CLKOUT1   => open,
            CLKOUT1B  => open,
            CLKOUT2   => open,
            CLKOUT2B  => open,
            CLKOUT3   => open,
            CLKOUT3B  => open,
            CLKOUT4   => open,
            CLKOUT5   => open,
            CLKOUT6   => open,
            CLKFBOUT  => w_fb,
            CLKFBOUTB => open,
            LOCKED    => o_locked
        );

end structural;
