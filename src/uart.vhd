library ieee;
use ieee.std_logic_1164.all;

entity uart is
    generic (
        CLKS_PER_BIT : positive := 87
    );
    port (
        i_sys_clk   : in  std_logic;
        i_Rx_Serial : in  std_logic;
        i_Tx_DV     : in  std_logic;
        i_Tx_Byte   : in  std_logic_vector(7 downto 0);
        o_Tx_Serial : out std_logic;
        o_Rx_DV     : out std_logic;
        o_Rx_Byte   : out std_logic_vector(7 downto 0);
        o_Tx_Done   : out std_logic
    );
end uart;

architecture structural of uart is
begin

    URX : entity work.uart_rx
        generic map (CLKS_PER_BIT => CLKS_PER_BIT)
        port map (
            i_sys_clk   => i_sys_clk,
            i_Rx_Serial => i_Rx_Serial,
            o_Rx_DV     => o_Rx_DV,
            o_Rx_Byte   => o_Rx_Byte
        );

    UTX : entity work.uart_tx
        generic map (CLKS_PER_BIT => CLKS_PER_BIT)
        port map (
            i_sys_clk   => i_sys_clk,
            i_Tx_DV     => i_Tx_DV,
            i_Tx_Byte   => i_Tx_Byte,
            o_Tx_Serial => o_Tx_Serial,
            o_Tx_Done   => o_Tx_Done
        );

end structural;
