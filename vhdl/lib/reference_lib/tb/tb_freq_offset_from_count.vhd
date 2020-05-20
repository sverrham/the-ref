

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity tb_freq_offset_from_count is
end tb_freq_offset_from_count;

architecture rtl of tb_freq_offset_from_count is

    signal i_clk : std_logic := '0';
    signal runing : std_logic := '1';

    signal i_count : unsigned(31 downto 0) := (others => '0');
    signal i_count_vld : std_logic := '0';
    signal o_error_ppb : integer range -10000 to 10000;
    signal o_error_ppb_vld: std_logic;
begin

    i_clk <= not i_clk after 10 ns when runing = '1' else '0';

    stimuli : process
    begin
        report "Start of test" severity note;
     
        wait for 10 us;
        wait until rising_edge(i_clk);
        i_count <= to_unsigned(10000100, 32);
        i_count_vld <= '1';
        wait until rising_edge(i_clk);
        i_count <= to_unsigned(0, 32);
        i_count_vld <= '0';
        wait for 1 us;
        wait until rising_edge(i_clk);
        i_count <= to_unsigned(10000001, 32);
        i_count_vld <= '1';
        wait until rising_edge(i_clk);
        i_count <= to_unsigned(0, 32);
        i_count_vld <= '0';
        wait for 1 us;
        
        runing <= '0';
        assert false report "End of test" severity note;
        wait;
    end process;


    check_output: process
    begin
        wait until rising_edge(o_error_ppb_vld);
        assert o_error_ppb = 10000 report "Unexpected error " & integer'image(o_error_ppb) & " ppm" severity error;
        wait until rising_edge(o_error_ppb_vld);
        assert o_error_ppb = 100 report "Unexpected error " & integer'image(o_error_ppb) & " ppm" severity error;
    end process;


    dut : entity work.freq_offset_from_count
    generic map(
        g_frequency => 10.0e6
    )
    port map(
        i_clk => i_clk,
        i_count => i_count,
        i_count_vld => i_count_vld,
        o_error_ppb => o_error_ppb,
        o_error_ppb_vld => o_error_ppb_vld
    );

end rtl;