library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : positive := 87
    );
    port (
        i_sys_clk   : in  std_logic;
        i_Tx_DV     : in  std_logic;
        i_Tx_Byte   : in  std_logic_vector(7 downto 0);
        o_Tx_Serial : out std_logic;
        o_Tx_Done   : out std_logic
    );
end uart_tx;

architecture rtl of uart_tx is
    type state_t is (s_IDLE, s_TX_START_BIT, s_TX_DATA_BITS, s_TX_STOP_BIT, s_CLEANUP);
    signal r_SM_Main     : state_t := s_IDLE;

    signal r_Clock_Count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index   : integer range 0 to 7 := 0;
    signal r_Tx_Data     : std_logic_vector(7 downto 0) := (others => '0');
    signal r_Tx_Done     : std_logic := '0';
    signal r_Tx_Active   : std_logic := '0';
begin

    process (i_sys_clk) begin
        if rising_edge(i_sys_clk) then
            case r_SM_Main is
                when s_IDLE =>
                    o_Tx_Serial   <= '1';
                    r_Tx_Done     <= '0';
                    r_Clock_Count <= 0;
                    r_Bit_Index   <= 0;
                    if i_Tx_DV = '1' then
                        r_Tx_Data <= i_Tx_Byte;
                        r_SM_Main <= s_TX_START_BIT;
                    end if;

                when s_TX_START_BIT =>
                    o_Tx_Serial <= '0';
                    if r_Clock_Count < CLKS_PER_BIT - 1 then
                        r_Clock_Count <= r_Clock_Count + 1;
                    else
                        r_Clock_Count <= 0;
                        r_SM_Main     <= s_TX_DATA_BITS;
                    end if;

                when s_TX_DATA_BITS =>
                    o_Tx_Serial <= r_Tx_Data(r_Bit_Index);
                    if r_Clock_Count < CLKS_PER_BIT - 1 then
                        r_Clock_Count <= r_Clock_Count + 1;
                    else
                        r_Clock_Count <= 0;
                        if r_Bit_Index < 7 then
                            r_Bit_Index <= r_Bit_Index + 1;
                        else
                            r_Bit_Index <= 0;
                            r_SM_Main   <= s_TX_STOP_BIT;
                        end if;
                    end if;

                when s_TX_STOP_BIT =>
                    o_Tx_Serial <= '1';
                    if r_Clock_Count < CLKS_PER_BIT - 1 then
                        r_Clock_Count <= r_Clock_Count + 1;
                    else
                        r_Tx_Done     <= '1';
                        r_Clock_Count <= 0;
                        r_SM_Main     <= s_CLEANUP;
                    end if;

                when s_CLEANUP =>
                    r_Tx_Done <= '1';
                    r_SM_Main <= s_IDLE;
            end case;
        end if;
    end process;

    o_Tx_Done <= r_Tx_Done;

end rtl;
