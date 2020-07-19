

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library reference_lib;

entity tb_pps_counter is
end tb_pps_counter;

architecture rtl of tb_pps_counter is

    signal clk_i : std_logic := '0';
    signal pps_i : std_logic := '0';
    signal runing : std_logic := '1';

    signal last_count_o: unsigned(31 downto 0);
    signal last_count_vld_o: std_logic;
begin

    clk_i <= not clk_i after 100 ns when runing = '1' else '0';

    stimuli : process
    begin
        report "Start of test" severity note;
        for i in 0 to 10 loop
            wait for 10 ms;
            pps_i <= '1';
            wait for 1 us;
            pps_i <= '0';
        end loop;

        runing <= '0';
        assert false report "End of test" severity note;
        wait;
    end process;


    check_output: process
    begin
        wait until rising_edge(last_count_vld_o);
        assert last_count_o /= X"00000000" report "Unexpected count" severity error;
    end process;

    dut : entity reference_lib.pps_counter
    port map(
        clk_i => clk_i,
        pps_i => pps_i,
        last_count_o => last_count_o,
        last_count_vld_o => last_count_vld_o
    );

end rtl;