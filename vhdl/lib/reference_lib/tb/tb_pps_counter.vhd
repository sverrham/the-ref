

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity tb_pps_counter is
end tb_pps_counter;

architecture rtl of tb_pps_counter is

    signal clk : std_logic := '0';
    signal pps : std_logic := '0';
    signal runing : std_logic := '1';

    signal last_count: unsigned(31 downto 0);
    signal last_count_vld: std_logic;
begin

    clk <= not clk after 100 ns when runing = '1' else '0';

    stimuli : process
    begin
        report "Start of test" severity note;
        for i in 0 to 10 loop
            wait for 10 ms;
            pps <= '1';
            wait for 1 us;
            pps <= '0';
        end loop;

        runing <= '0';
        assert false report "End of test" severity note;
        wait;
    end process;


    check_output: process
    begin
        wait until rising_edge(last_count_vld);
        assert last_count /= X"00000000" report "Unexpected count" severity error;
    end process;

    dut : entity work.pps_counter
    port map(
        clk => clk,
        pps => pps,
        last_count => last_count,
        last_count_vld => last_count_vld
    );

end rtl;