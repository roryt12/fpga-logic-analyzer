library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sump_core is
    generic (
        DATA_WIDTH : positive := 32;
        MEM_DEPTH  : positive := 8192
    );
    port (
        i_clk            : in  std_logic;
        i_rstn           : in  std_logic;
        i_rx_dv          : in  std_logic;
        i_rx_byte        : in  std_logic_vector(7 downto 0);
        o_tx_dv          : out std_logic;
        o_tx_byte        : out std_logic_vector(7 downto 0);
        i_tx_done        : in  std_logic;
        i_channels       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        o_enable         : out std_logic;
        o_readout_active : out std_logic
    );
end sump_core;

architecture rtl of sump_core is
    function clog2(n : positive) return integer is
        variable r : integer := 0;
    begin
        while 2**r < n loop r := r + 1; end loop;
        return r;
    end function;

    constant ADDR_W    : integer := clog2(MEM_DEPTH);
    constant MEM_BYTES : integer := MEM_DEPTH * (DATA_WIDTH / 8);

    type state_t is (ST_IDLE, ST_CAPTURE, ST_DONE, ST_READOUT);
    signal r_state : state_t := ST_IDLE;

    type cmd_state_t is (CMD_IDLE, CMD_ACCUM, CMD_EXEC);
    signal r_cmd_state : cmd_state_t := CMD_IDLE;

    type resp_state_t is (RESP_IDLE, RESP_SEND, RESP_WAIT);
    signal r_resp_state : resp_state_t := RESP_IDLE;

    signal r_cmd_opcode : std_logic_vector(7 downto 0) := (others => '0');
    signal r_cmd_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal r_cmd_need   : integer range 1 to 5 := 1;
    signal r_cmd_count  : integer range 1 to 5 := 1;

    signal r_divider      : std_logic_vector(19 downto 0) := (others => '0');
    signal r_read_count   : std_logic_vector(15 downto 0) := (others => '0');
    signal r_delay_count  : std_logic_vector(15 downto 0) := (others => '0');
    signal r_auto_trigger : std_logic_vector(15 downto 0) := (others => '0');
    signal r_auto_cnt     : unsigned(15 downto 0) := (others => '0');
    signal r_flags        : std_logic_vector(7 downto 0) := (others => '0');

    type trig_mask_t is array(0 to 3) of std_logic_vector(31 downto 0);
    signal r_trigger_mask   : trig_mask_t := (others => (others => '0'));
    signal r_trigger_value  : trig_mask_t := (others => (others => '0'));

    type trig_config_t is array(0 to 3) of std_logic_vector(7 downto 0);
    signal r_trigger_config : trig_config_t := (others => (others => '0'));

    signal r_wr_adr       : unsigned(ADDR_W-1 downto 0) := (others => '0');
    signal r_rd_adr       : unsigned(ADDR_W-1 downto 0) := (others => '0');
    signal r_last_adr     : unsigned(ADDR_W-1 downto 0) := (others => '0');
    signal r_total_written : unsigned(ADDR_W downto 0) := (others => '0');
    signal r_post_cnt     : unsigned(15 downto 0) := (others => '0');
    signal r_readout_cnt  : unsigned(15 downto 0) := (others => '0');
    signal r_byte_sel     : unsigned(1 downto 0) := (others => '0');
    signal r_triggered    : std_logic := '0';
    signal r_prev_sample  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal r_stage_armed  : std_logic_vector(3 downto 0) := "0001";
    signal r_wr_en        : std_logic := '0';
    signal r_sample_clk   : std_logic := '0';
    signal r_divider_cnt  : unsigned(19 downto 0) := (others => '0');
    signal r_readout_active_reg : std_logic := '0';
    signal r_readout_done : std_logic := '0';
    signal r_readout_delay : std_logic := '0';
    signal r_stop         : std_logic := '0';
    signal r_pending_run  : std_logic := '0';

    signal r_resp_len     : integer range 0 to 31 := 0;
    signal r_resp_idx     : integer range 0 to 31 := 0;

    signal w_ram_out : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal w_level_match : std_logic_vector(3 downto 0);
    signal w_edge_match  : std_logic_vector(3 downto 0);
    signal w_stage_match : std_logic_vector(3 downto 0);
    signal w_stage_fire  : std_logic_vector(3 downto 0);
    signal w_trigger_fire : std_logic;

    signal r_stage_fire_p   : std_logic_vector(3 downto 0) := (others => '0');
    signal r_trigger_fire_p : std_logic := '0';

    type resp_data_t is array(0 to 31) of std_logic_vector(7 downto 0);
    signal r_resp_data : resp_data_t;
    signal r_tx_dv     : std_logic := '0';
begin

    o_tx_dv <= r_tx_dv;
    o_readout_active <= r_readout_active_reg;

    ram : entity work.sram
        generic map (ADDR_WIDTH => ADDR_W, DATA_WIDTH => DATA_WIDTH, DEPTH => MEM_DEPTH)
        port map (
            i_sys_clk => i_clk,
            i_wr_en   => r_wr_en,
            i_wr_adr  => std_logic_vector(r_wr_adr),
            i_rd_adr  => std_logic_vector(r_rd_adr),
            i_data    => i_channels,
            o_data    => w_ram_out
        );

    gen_trig : for i in 0 to 3 generate
        signal w_masked_sample : std_logic_vector(DATA_WIDTH-1 downto 0);
        signal w_masked_prev   : std_logic_vector(DATA_WIDTH-1 downto 0);
        signal w_masked_value  : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        w_masked_sample <= i_channels and r_trigger_mask(i);
        w_masked_prev   <= r_prev_sample and r_trigger_mask(i);
        w_masked_value  <= r_trigger_value(i) and r_trigger_mask(i);

        w_level_match(i) <= '1' when w_masked_sample = w_masked_value else '0';

        w_edge_match(i) <= '1' when
            (r_trigger_config(i)(2) = '1' and w_masked_prev = w_masked_value and w_masked_sample /= w_masked_value) or
            (r_trigger_config(i)(2) = '0' and w_masked_prev /= w_masked_value and w_masked_sample = w_masked_value)
            else '0';

        w_stage_match(i) <= '1' when r_trigger_config(i)(0) = '1' and (
            (r_trigger_config(i)(1) = '1' and w_edge_match(i) = '1') or
            (r_trigger_config(i)(1) = '0' and w_level_match(i) = '1'))
            else '0';

        w_stage_fire(i) <= r_stage_armed(i) and w_stage_match(i);
    end generate;

    w_trigger_fire <= w_stage_fire(0) or w_stage_fire(1) or w_stage_fire(2) or w_stage_fire(3);

    stage_pipe : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            r_stage_fire_p   <= w_stage_fire;
            r_trigger_fire_p <= w_trigger_fire;
        end if;
    end process stage_pipe;

    process (i_clk, i_rstn) begin
        if i_rstn = '0' then
            r_state            <= ST_IDLE;
            r_cmd_state        <= CMD_IDLE;
            r_resp_state       <= RESP_IDLE;
            o_enable           <= '0';
            r_tx_dv            <= '0';
            r_divider          <= (others => '0');
            r_read_count       <= (others => '0');
            r_delay_count      <= (others => '0');
            r_auto_trigger     <= (others => '0');
            r_auto_cnt         <= (others => '0');
            r_flags            <= (others => '0');
            r_trigger_mask     <= (others => (others => '0'));
            r_trigger_value    <= (others => (others => '0'));
            r_trigger_config   <= (others => (others => '0'));
            r_wr_adr           <= (others => '0');
            r_rd_adr           <= (others => '0');
            r_last_adr         <= (others => '0');
            r_total_written    <= (others => '0');
            r_post_cnt         <= (others => '0');
            r_readout_cnt      <= (others => '0');
            r_byte_sel         <= (others => '0');
            r_triggered        <= '0';
            r_prev_sample      <= (others => '0');
            r_stage_armed      <= "0001";
            r_wr_en            <= '0';
            r_sample_clk       <= '0';
            r_divider_cnt      <= (others => '0');
            r_readout_active_reg <= '0';
            r_readout_done     <= '0';
            r_readout_delay    <= '0';
            r_stop             <= '0';
            r_cmd_count        <= 1;
            r_resp_len         <= 0;
            r_resp_idx         <= 0;
            r_pending_run      <= '0';

        elsif rising_edge(i_clk) then

            r_sample_clk <= '0';
            if r_divider_cnt >= unsigned(r_divider) then
                r_divider_cnt <= (others => '0');
                r_sample_clk <= '1';
            else
                r_divider_cnt <= r_divider_cnt + 1;
            end if;

            if i_tx_done = '1' and r_tx_dv = '1' then
                r_tx_dv <= '0';
                if r_resp_state = RESP_WAIT then
                    if r_resp_idx >= r_resp_len - 1 then
                        r_resp_state <= RESP_IDLE;
                    else
                        r_resp_idx <= r_resp_idx + 1;
                        r_resp_state <= RESP_SEND;
                    end if;
                end if;
                if r_readout_done = '1' then
                    r_readout_active_reg <= '0';
                    r_readout_done <= '0';
                    if r_pending_run = '1' then
                        r_pending_run <= '0';
                        r_state       <= ST_CAPTURE;
                        o_enable      <= '1';
                        r_wr_adr      <= (others => '0');
                        r_total_written <= (others => '0');
                        r_post_cnt    <= (others => '0');
                        r_triggered   <= '0';
                        r_prev_sample <= (others => '0');
                        r_stage_armed <= "0001";
                        r_auto_cnt    <= (others => '0');
                    else
                        r_state <= ST_IDLE;
                    end if;
                end if;
            end if;

            r_stop <= '0';
            if r_triggered = '1' and r_post_cnt = unsigned(r_delay_count) then
                r_stop <= '1';
            elsif r_triggered = '0' and r_total_written >= MEM_DEPTH then
                r_stop <= '1';
            elsif r_triggered = '0' and r_auto_trigger /= x"0000" and r_auto_cnt >= unsigned(r_auto_trigger) then
                r_stop <= '1';
            end if;

            if i_rx_dv = '1' then
                if i_rx_byte = x"00" then
                    r_state            <= ST_IDLE;
                    o_enable           <= '0';
                    r_wr_en            <= '0';
                    r_triggered        <= '0';
                    r_readout_active_reg <= '0';
                    r_readout_done     <= '0';
                    r_cmd_state        <= CMD_IDLE;
                    r_resp_state       <= RESP_IDLE;
                    r_tx_dv            <= '0';
                elsif r_state = ST_IDLE or r_state = ST_DONE or r_state = ST_READOUT then
                    case r_cmd_state is
                        when CMD_IDLE =>
                            r_cmd_opcode <= i_rx_byte;
                            r_cmd_count  <= 1;
                            r_cmd_data   <= (others => '0');
                            case i_rx_byte is
                                when x"01" | x"02" | x"04" =>
                                    r_cmd_need  <= 1;
                                    r_cmd_state <= CMD_EXEC;
                                when x"03" =>
                                    r_cmd_need  <= 3;
                                    r_cmd_state <= CMD_ACCUM;
                                when x"82" =>
                                    r_cmd_need  <= 2;
                                    r_cmd_state <= CMD_ACCUM;
                                when x"80" | x"81" =>
                                    r_cmd_need  <= 5;
                                    r_cmd_state <= CMD_ACCUM;
                                when others =>
                                    if i_rx_byte >= x"C0" and i_rx_byte <= x"CB" then
                                        if i_rx_byte >= x"C8" then
                                            r_cmd_need <= 2;
                                        else
                                            r_cmd_need <= 5;
                                        end if;
                                        r_cmd_state <= CMD_ACCUM;
                                    else
                                        r_cmd_need  <= 1;
                                        r_cmd_state <= CMD_EXEC;
                                    end if;
                            end case;

                        when CMD_ACCUM =>
                            r_cmd_count <= r_cmd_count + 1;
                            r_cmd_data(31 downto 24) <= r_cmd_data(23 downto 16);
                            r_cmd_data(23 downto 16) <= r_cmd_data(15 downto 8);
                            r_cmd_data(15 downto 8)  <= r_cmd_data(7 downto 0);
                            r_cmd_data(7 downto 0)   <= i_rx_byte;
                            if r_cmd_count + 1 = r_cmd_need then
                                r_cmd_state <= CMD_EXEC;
                            end if;

                        when others =>
                            null;
                    end case;
                end if;
            end if;

            if r_cmd_state = CMD_EXEC and r_resp_state = RESP_IDLE then
                r_cmd_state <= CMD_IDLE;
                case r_cmd_opcode is
                    when x"01" =>
                        if r_readout_active_reg = '1' then
                            r_pending_run <= '1';
                        elsif r_state = ST_IDLE or r_state = ST_DONE then
                            r_state       <= ST_CAPTURE;
                            o_enable      <= '1';
                            r_wr_adr      <= (others => '0');
                            r_total_written <= (others => '0');
                            r_post_cnt    <= (others => '0');
                            r_triggered   <= '0';
                            r_prev_sample <= (others => '0');
                            r_stage_armed <= "0001";
                            r_auto_cnt    <= (others => '0');
                        end if;

                    when x"02" =>
                        if r_readout_active_reg = '0' then
                            r_resp_data(0) <= x"31"; -- '1'
                            r_resp_data(1) <= x"41"; -- 'A'
                            r_resp_data(2) <= x"4C"; -- 'L'
                            r_resp_data(3) <= x"53"; -- 'S'
                            r_resp_len  <= 4;
                            r_resp_idx  <= 0;
                            r_resp_state <= RESP_SEND;
                        end if;

                    when x"04" =>
                        if r_readout_active_reg = '0' then
                            r_resp_data(0)  <= x"01";
                            r_resp_data(1)  <= x"52"; -- 'R'
                            r_resp_data(2)  <= x"6F"; -- 'o'
                            r_resp_data(3)  <= x"72"; -- 'r'
                            r_resp_data(4)  <= x"79"; -- 'y'
                            r_resp_data(5)  <= x"74"; -- 't'
                            r_resp_data(6)  <= x"4C"; -- 'L'
                            r_resp_data(7)  <= x"41"; -- 'A'
                            r_resp_data(8)  <= x"00";
                            r_resp_data(9)  <= x"02";
                            r_resp_data(10) <= x"31"; -- '1'
                            r_resp_data(11) <= x"2E"; -- '.'
                            r_resp_data(12) <= x"30"; -- '0'
                            r_resp_data(13) <= x"00";
                            r_resp_data(14) <= x"21";
                            r_resp_data(15) <= std_logic_vector(to_unsigned(MEM_BYTES / 2**24, 8));
                            r_resp_data(16) <= std_logic_vector(to_unsigned((MEM_BYTES / 2**16) mod 256, 8));
                            r_resp_data(17) <= std_logic_vector(to_unsigned((MEM_BYTES / 2**8) mod 256, 8));
                            r_resp_data(18) <= std_logic_vector(to_unsigned(MEM_BYTES mod 256, 8));
                            r_resp_data(19) <= x"23";
                            r_resp_data(20) <= x"08";
                            r_resp_data(21) <= x"F5";
                            r_resp_data(22) <= x"E1";
                            r_resp_data(23) <= x"00";
                            r_resp_data(24) <= x"40";
                            r_resp_data(25) <= std_logic_vector(to_unsigned(DATA_WIDTH, 8));
                            r_resp_data(26) <= x"41";
                            r_resp_data(27) <= x"02";
                            r_resp_data(28) <= x"00";
                            r_resp_len  <= 29;
                            r_resp_idx  <= 0;
                            r_resp_state <= RESP_SEND;
                        end if;

                    when x"80" =>
                        r_divider(19 downto 16) <= r_cmd_data(11 downto 8);
                        r_divider(15 downto 8)  <= r_cmd_data(23 downto 16);
                        r_divider(7 downto 0)   <= r_cmd_data(31 downto 24);

                    when x"81" =>
                        r_read_count <= r_cmd_data(21 downto 16) & r_cmd_data(31 downto 24) & "00";
                        r_delay_count <= r_cmd_data(7 downto 0) & r_cmd_data(15 downto 8);

                    when x"82" =>
                        r_flags <= r_cmd_data(7 downto 0);

                    when x"03" =>
                        r_auto_trigger <= r_cmd_data(7 downto 0) & r_cmd_data(15 downto 8);

                    when others =>
                        if r_cmd_opcode >= x"C0" and r_cmd_opcode <= x"C3" then
                            r_trigger_mask(to_integer(unsigned(r_cmd_opcode)) - 16#C0#) <=
                                r_cmd_data(7 downto 0) & r_cmd_data(15 downto 8) &
                                r_cmd_data(23 downto 16) & r_cmd_data(31 downto 24);
                        elsif r_cmd_opcode >= x"C4" and r_cmd_opcode <= x"C7" then
                            r_trigger_value(to_integer(unsigned(r_cmd_opcode)) - 16#C4#) <=
                                r_cmd_data(7 downto 0) & r_cmd_data(15 downto 8) &
                                r_cmd_data(23 downto 16) & r_cmd_data(31 downto 24);
                        elsif r_cmd_opcode >= x"C8" and r_cmd_opcode <= x"CB" then
                            r_trigger_config(to_integer(unsigned(r_cmd_opcode)) - 16#C8#) <=
                                r_cmd_data(7 downto 0);
                        end if;
                end case;
            end if;

            if r_resp_state = RESP_SEND then
                r_tx_dv    <= '1';
                o_tx_byte  <= r_resp_data(r_resp_idx);
                r_resp_state <= RESP_WAIT;
            end if;

            if r_sample_clk = '1' then
                if r_state = ST_CAPTURE then
                    if r_stop = '1' then
                        r_wr_en   <= '0';
                        if r_wr_adr = 0 then
                            r_last_adr <= to_unsigned(MEM_DEPTH - 1, ADDR_W);
                        else
                            r_last_adr <= r_wr_adr - 1;
                        end if;
                        r_state  <= ST_DONE;
                        o_enable <= '0';
                    else
                        r_wr_en <= '1';
                        if r_wr_adr = MEM_DEPTH - 1 then
                            r_wr_adr <= (others => '0');
                        else
                            r_wr_adr <= r_wr_adr + 1;
                        end if;
                        r_total_written <= r_total_written + 1;
                        r_prev_sample   <= i_channels;

                        if r_stage_fire_p(0) = '1' then r_stage_armed(1) <= '1'; end if;
                        if r_stage_fire_p(1) = '1' then r_stage_armed(2) <= '1'; end if;
                        if r_stage_fire_p(2) = '1' then r_stage_armed(3) <= '1'; end if;

                        if r_triggered = '0' and r_trigger_fire_p = '1' then
                            r_triggered <= '1';
                            r_post_cnt  <= (others => '0');
                        end if;

                        if r_triggered = '1' then
                            r_post_cnt <= r_post_cnt + 1;
                        end if;

                        if r_triggered = '0' then
                            r_auto_cnt <= r_auto_cnt + 1;
                        end if;
                    end if;
                else
                    r_wr_en <= '0';
                end if;
            end if;

            if r_state = ST_DONE and r_readout_active_reg = '0' and r_readout_delay = '0' and r_resp_state = RESP_IDLE then
                r_rd_adr       <= r_last_adr;
                r_readout_delay <= '1';
                r_byte_sel     <= (others => '0');
                if r_read_count = x"0000" or unsigned(r_read_count) >= MEM_DEPTH then
                    r_readout_cnt <= to_unsigned(MEM_DEPTH, 16);
                else
                    r_readout_cnt <= unsigned(r_read_count);
                end if;
                r_state <= ST_READOUT;
            end if;

            if r_readout_delay = '1' then
                r_readout_active_reg <= '1';
                r_readout_delay      <= '0';
            end if;

            if r_readout_active_reg = '1' and r_tx_dv = '0' then
                r_tx_dv <= '1';
                case r_byte_sel is
                    when "00"   => o_tx_byte <= w_ram_out(7 downto 0);
                    when "01"   => o_tx_byte <= w_ram_out(15 downto 8);
                    when "10"   => o_tx_byte <= w_ram_out(23 downto 16);
                    when others => o_tx_byte <= w_ram_out(31 downto 24);
                end case;
                if r_byte_sel = 3 then
                    r_byte_sel <= (others => '0');
                    if r_readout_cnt = 1 then
                        r_readout_done <= '1';
                    else
                        r_readout_cnt <= r_readout_cnt - 1;
                        if r_rd_adr = 0 then
                            r_rd_adr <= to_unsigned(MEM_DEPTH - 1, ADDR_W);
                        else
                            r_rd_adr <= r_rd_adr - 1;
                        end if;
                    end if;
                else
                    r_byte_sel <= r_byte_sel + 1;
                end if;
            end if;

        end if;
    end process;

end rtl;
