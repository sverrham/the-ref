library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity the_ref_top is
    port (
        clk_i: in std_logic;
        pps_i: in std_logic;
        rgb_o: out std_logic_vector(2 downto 0)
        );
end the_ref_top;

architecture rtl of the_ref_top is

    signal count : unsigned(31 downto 0);
    signal count_vld : std_logic;
    signal error_ppb : integer range -10000 to 10000;
    signal error_ppb_vld : std_logic;

    signal pps_meta : std_logic_vector(1 downto 0) := (others => '0');

    constant c_one_point_five_seconds : integer := 36000000;
    signal pps_count : integer range 0 to c_one_point_five_seconds;
    signal no_pps_received : std_logic := '0';
    signal high_offset : std_logic := '0';
begin

    -- Metastability pps
    meta_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            pps_meta(0) <= pps_i;
            pps_meta(1) <= pps_meta(0);
        end if;
    end process;

    pps_counter : entity work.pps_counter
    port map(
        clk_i => clk_i,
        pps_i => pps_meta(1),
        last_count_o => count,
        last_count_vld_o => count_vld
    );
    
    dut : entity work.freq_offset_from_count
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
            if pps_count = 0 then
                no_pps_received <= '1';
                pps_count <= c_one_point_five_seconds;
            elsif pps_meta(1) = '1' then
                pps_count <= c_one_point_five_seconds;
            end if;
        end if;
    end process;

    error_ppb_proc : process(clk_i)
    begin
        if  rising_edge(clk_i) then
            if error_ppb_vld = '1' then
                if (error_ppb > 100 or error_ppb < -100) then
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

end rtl;