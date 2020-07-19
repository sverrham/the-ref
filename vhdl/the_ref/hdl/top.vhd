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

    -- signal osc_clk : std_logic;

    signal tx_ena : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_busy : std_logic;
    signal rx_error : std_logic;
    signal rx_data : std_logic_vector(7 downto 0);
    signal rx_vld : std_logic;
    signal tx_busy : std_logic;

    signal pps_meta : std_logic_vector(1 downto 0) := (others => '0');
    signal rx_meta : std_logic_vector(1 downto 0) := (others => '0');

    constant c_one_point_five_seconds : integer := 36000000;
    signal pps_count : integer range 0 to c_one_point_five_seconds;
    signal no_pps_received : std_logic := '0';
    signal glitch_on_pps : std_logic := '0';
    -- signal no_pps_received_debug : std_logic := '0';
    -- signal high_offset : std_logic := '0';
    signal last_pps : std_logic := '0';


    signal msg_req:  std_logic;
    signal msg_busy:  std_logic;
    signal msg_data :  std_logic_vector(7 downto 0);
    signal msg_data_vld :  std_logic;

    component Gowin_OSC
    port (
        oscout: out std_logic
    );
    end component;

begin

    
    -- your_instance_name: Gowin_OSC
    -- port map (
    --     oscout => osc_clk
    -- );

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

    -- tx_ena <= rx_vld;
    -- tx_data <= rx_data;


    -- com_arbiter: process(clk_i)
    -- begin
    --     if rising_edge(clk_i) then

    --     end if;
    -- end process;

    -- Arbiter missing
    msg_busy <= tx_busy;
    tx_data  <= msg_data;
    tx_ena   <= msg_data_vld;

    freq_measure_wrapper: entity reference_lib.freq_measure_wrapper
    generic map (
        g_frequency => 24.0e6
    )
    port map (
        clk_i => clk_i,
        pps_i => pps_meta(1),
        msg_req_o => msg_req,
        msg_busy_i => msg_busy,
        msg_data_o => msg_data,
        msg_data_vld_o => msg_data_vld
    );

    -- Debug
    debug_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Check if pps pulses once pr ~1.5 sec
            last_pps <= pps_meta(1);
            pps_count <= pps_count + 1;
            -- no_pps_received_debug <= '0';
            if pps_count = c_one_point_five_seconds then
                no_pps_received <= '1';
                -- no_pps_received_debug <= '1';
                pps_count <= 0;
            elsif pps_meta(1) = '1' and last_pps = '0' then
                no_pps_received <= '0';
                pps_count <= 0;

                glitch_on_pps <= '0';
                if pps_count < 1024 then
                    glitch_on_pps <= '1';
                end if;
            end if;
        end if;
    end process;

    led_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            rgb_o <= "101"; --Inverted 1 off 0 on led.architecture
            if glitch_on_pps = '1' then
                rgb_o <= "110";
            elsif no_pps_received = '1' then
                rgb_o <= "011";
            end if;
        end if;
    end process;

    -- debug_message_block : block is
    --     type state_t is (idle, no_pps_type, no_pps_length, no_pps_value, new_line, car_return);
    --     signal state : state_t := idle;
    -- begin

    -- debug_info_proc : process(clk_i)
    -- begin
    --     if rising_edge(clk_i) then
    --         -- Send debug info over uart.
    --         tx_ena <= '0';
            
    --         case state is
    --             when idle =>
    --                 if no_pps_received_debug = '1' then
    --                     state <= no_pps_type;
    --                 end if;
    --             when no_pps_type =>
    --                 if tx_busy = '0' and tx_ena = '0' then
    --                     tx_data <= x"00";
    --                     tx_ena <= '1';
    --                     state <= no_pps_length;
    --                 end if;

    --             when no_pps_length =>
    --                 if tx_busy = '0' and tx_ena = '0' then
    --                     tx_data <= x"03";
    --                     tx_ena <= '1';
    --                     state <= no_pps_value;
    --                 end if;
                    
    --             when no_pps_value =>
    --                 if tx_busy = '0' and tx_ena = '0' then
    --                     tx_data <= x"30";
    --                     tx_ena <= '1';
    --                     state <= car_return;
    --                 end if;

    --             when car_return =>
    --                 if tx_busy = '0' and tx_ena = '0' then
    --                     tx_data <= x"0D";
    --                     tx_ena <= '1';
    --                     state <= new_line;
    --                 end if;

    --             when new_line =>
    --                 if tx_busy = '0' and tx_ena = '0' then
    --                     tx_data <= x"0A";
    --                     tx_ena <= '1';
    --                     state <= idle;
    --                 end if;

                
    --         end case;

    --     end if;
    -- end process;
    -- end block;
end rtl;