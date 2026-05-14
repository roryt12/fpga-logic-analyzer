library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        CLKS_PER_BIT : positive := 87
    );
    port (
        i_sys_clk   : in  std_logic;
        i_Rx_Serial : in  std_logic;
        o_Rx_DV     : out std_logic;
        o_Rx_Byte   : out std_logic_vector(7 downto 0)
    );
end uart_rx;

architecture rtl of uart_rx is
    type state_t is (s_IDLE, s_RX_START_BIT, s_RX_DATA_BITS, s_RX_STOP_BIT, s_CLEANUP);
    signal r_SM_Main     : state_t := s_IDLE;

    signal r_Rx_Data_R   : std_logic := '1';
    signal r_Rx_Data     : std_logic := '1';
    signal r_Clock_Count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index   : integer range 0 to 7 := 0;
    signal r_Rx_Byte     : std_logic_vector(7 downto 0) := (others => '0');
    signal r_Rx_DV       : std_logic := '0';
begin

    process (i_sys_clk) begin
        if rising_edge(i_sys_clk) then
            r_Rx_Data_R <= i_Rx_Serial;
            r_Rx_Data   <= r_Rx_Data_R;
        end if;
    end process;

    process (i_sys_clk) begin
        if rising_edge(i_sys_clk) then
            case r_SM_Main is
                when s_IDLE =>
                    r_Rx_DV       <= '0';
                    r_Clock_Count <= 0;
                    r_Bit_Index   <= 0;
                    if r_Rx_Data = '0' then
                        r_SM_Main <= s_RX_START_BIT;
                    end if;

                when s_RX_START_BIT =>
                    if r_Clock_Count = (CLKS_PER_BIT - 1) / 2 then
                        if r_Rx_Data = '0' then
                            r_Clock_Count <= 0;
                            r_SM_Main     <= s_RX_DATA_BITS;
                        else
                            r_SM_Main <= s_IDLE;
                        end if;
                    else
                        r_Clock_Count <= r_Clock_Count + 1;
                    end if;

                when s_RX_DATA_BITS =>
                    if r_Clock_Count < CLKS_PER_BIT - 1 then
                        r_Clock_Count <= r_Clock_Count + 1;
                    else
                        r_Clock_Count <= 0;
                        r_Rx_Byte(r_Bit_Index) <= r_Rx_Data;
                        if r_Bit_Index < 7 then
                            r_Bit_Index <= r_Bit_Index + 1;
                        else
                            r_Bit_Index <= 0;
                            r_SM_Main   <= s_RX_STOP_BIT;
                        end if;
                    end if;

                when s_RX_STOP_BIT =>
                    if r_Clock_Count < CLKS_PER_BIT - 1 then
                        r_Clock_Count <= r_Clock_Count + 1;
                    else
                        r_Rx_DV       <= '1';
                        r_Clock_Count <= 0;
                        r_SM_Main     <= s_CLEANUP;
                    end if;

                when s_CLEANUP =>
                    r_SM_Main <= s_IDLE;
                    r_Rx_DV   <= '0';
            end case;
        end if;
    end process;

    o_Rx_DV   <= r_Rx_DV;
    o_Rx_Byte <= r_Rx_Byte;

end rtl;
