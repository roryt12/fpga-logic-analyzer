library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram is
    generic (
        ADDR_WIDTH : positive := 8;
        DATA_WIDTH : positive := 8;
        DEPTH      : positive := 256
    );
    port (
        i_sys_clk : in  std_logic;
        i_wr_adr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        i_rd_adr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        i_wr_en   : in  std_logic;
        i_data    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        o_data    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end sram;

architecture rtl of sram is
    type mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memory_array : mem_t;
begin

    process (i_sys_clk) begin
        if rising_edge(i_sys_clk) then
            if i_wr_en = '1' then
                memory_array(to_integer(unsigned(i_wr_adr))) <= i_data;
            end if;
            o_data <= memory_array(to_integer(unsigned(i_rd_adr)));
        end if;
    end process;

end rtl;
