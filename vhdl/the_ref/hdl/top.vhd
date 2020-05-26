library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library reference_lib;
library com_lib;

entity the_ref_top is
    port (
        clk_i: in std_logic;
        pps_i: in std_logic;
        rgb_o: out std_logic_vector(2 downto 0);
        tx : out std_logic;
        rx : in std_logic
        );
end the_ref_top;

architecture rtl of the_ref_top is

    signal tx_ena : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_busy : std_logic;
    signal rx_error : std_logic;
    signal rx_data : std_logic_vector(7 downto 0);
    signal rx_vld : std_logic;
    signal tx_busy : std_logic;

    signal count : unsigned(31 downto 0);
    signal count_vld : std_logic;
    signal error_ppb : integer range -100000 to 100000;
    signal error_ppb_vld : std_logic;

    signal pps_meta : std_logic_vector(1 downto 0) := (others => '0');
    signal rx_meta : std_logic_vector(1 downto 0) := (others => '0');

    constant c_one_point_five_seconds : integer := 36000000;
    signal pps_count : integer range 0 to c_one_point_five_seconds;
    signal no_pps_received : std_logic := '0';
    signal no_pps_received_debug : std_logic := '0';
    signal high_offset : std_logic := '0';
begin

    -- Metastability pps
    meta_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            pps_meta(0) <= pps_i;
            pps_meta(1) <= pps_meta(0);

            rx_meta(0) <= rx;
            rx_meta(1) <= rx_meta(0);
        end if;
    end process;

    uart : entity com_lib.uart
    generic map(
        clk_freq => 24_000_000,
        baud_rate => 9600,
        parity => 0
    )
    port map(
        clk => clk_i,
        reset_n => '1',
        tx_ena => tx_ena,
        tx_data => tx_data,
        rx => rx_meta(1),
        rx_busy => rx_busy,
        rx_error => rx_error,
        rx_data => rx_data,
        rx_vld => rx_vld,
        tx_busy => tx_busy,
        tx => tx
    );


    pps_counter : entity reference_lib.pps_counter
    port map(
        clk_i => clk_i,
        pps_i => pps_meta(1),
        last_count_o => count,
        last_count_vld_o => count_vld
    );
    
    freq_offset_from_count : entity reference_lib.freq_offset_from_count
    generic map(
        g_frequency => 24.0e6
    )
    port map(
        clk_i => clk_i,
        count_i => count,
        count_vld_i => count_vld,
        error_ppb_o => error_ppb,
        error_ppb_vld_o => error_ppb_vld
    );

    -- Debug
    debug_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Check if pps pulses once pr ~1.5 sec
            pps_count <= pps_count - 1;
            no_pps_received_debug <= '0';
            if pps_count = 0 then
                no_pps_received <= '1';
                no_pps_received_debug <= '1';
                pps_count <= c_one_point_five_seconds;
            elsif pps_meta(1) = '1' then
                no_pps_received <= '0';
                pps_count <= c_one_point_five_seconds;
            end if;
        end if;
    end process;

    error_ppb_proc : process(clk_i)
    begin
        if  rising_edge(clk_i) then
            if error_ppb_vld = '1' then
                if (error_ppb > 10000 or error_ppb < -10000) then
                    high_offset <= '1';
                else
                    high_offset <= '0';
                end if;
            end if; 
        end if;
    end process;

    led_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            rgb_o <= "101"; --Inverted 1 off 0 on led.architecture
            if no_pps_received = '1' then
                rgb_o <= "011";
            elsif high_offset = '1' then
                rgb_o <= "110";
            end if;
        end if;
    end process;

    debug_message_block : block is
        type state_t is (idle, no_pps_type, no_pps_length, no_pps_value, new_line, car_return, 
                         count_type, count_length, count_value,
                         error_type, error_length, error_value);
        signal state : state_t := idle;
        signal cur_count : unsigned(31 downto 0);
        signal cnt : integer range 0 to 7 := 0;

        signal error_vld : std_logic := '0';
        signal cur_error_ppb : signed(31 downto 0);
    begin

    debug_info_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Send debug info over uart.
            tx_ena <= '0';

            if error_ppb_vld = '1' then
                error_vld <= '1';
                cur_error_ppb <= to_signed(error_ppb, 32);
            end if;
            
            case state is
                when idle =>
                    if no_pps_received_debug = '1' then
                        state <= no_pps_type;
                    elsif count_vld = '1' then
                        cur_count <= count;
                        cnt <= 0;
                        state <= count_type;
                    elsif error_vld = '1' then
                        cnt <= 0;
                        error_vld <= '0';
                        state <= error_type;
                    end if;
                when no_pps_type =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"00";
                        tx_ena <= '1';
                        state <= no_pps_length;
                    end if;

                when no_pps_length =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"03";
                        tx_ena <= '1';
                        state <= no_pps_value;
                    end if;
                    
                when no_pps_value =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"30";
                        tx_ena <= '1';
                        state <= car_return;
                    end if;

                when count_type =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"01";
                        tx_ena <= '1';
                        state <= count_length;
                    end if;

                when count_length =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"06";
                        tx_ena <= '1';
                        state <= count_value;
                    end if;

                when count_value =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= cur_count(8+8*cnt downto 8*cnt);
                        tx_ena <= '1';
                        cnt <= cnt + 1;
                        if cnt = 3 then
                            state <= car_return;
                        end if;
                    end if;

                when error_type =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"02";
                        tx_ena <= '1';
                        state <= error_length;
                    end if;

                when error_length =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"06";
                        tx_ena <= '1';
                        state <= error_value;
                    end if;

                when error_value =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= cur_error_ppb(8+8*cnt downto 8*cnt);
                        tx_ena <= '1';
                        cnt <= cnt + 1;
                        if cnt = 3 then
                            state <= car_return;
                        end if;
                    end if;

                when car_return =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"0D";
                        tx_ena <= '1';
                        state <= new_line;
                    end if;

                when new_line =>
                    if tx_busy = '0' and tx_ena = '0' then
                        tx_data <= x"0A";
                        tx_ena <= '1';
                        state <= idle;
                    end if;

                
            end case;

        end if;
    end process;
    end block;
end rtl;