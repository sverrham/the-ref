

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Simple counter for clock cycles between pps pulses.
--
entity pps_counter is
    port (
        clk: in std_logic;
        pps: in std_logic;
        last_count: out unsigned(31 downto 0);
        last_count_vld: out std_logic
        );
end pps_counter;

architecture rtl of pps_counter is

    signal count : unsigned(31 downto 0) := (others => '0');
    signal last_pps : std_logic := '0';
begin

    p_count : process (clk)
    begin
        if rising_edge(clk) then
            last_count_vld <= '0';

            if pps = '1' and last_pps = '0' then
                count <= (others => '0');
                last_count <= count;
                last_count_vld <= '1';
            else
                count <= count + 1;
            end if;

            last_pps <= pps;
        end if;
    end process p_count;

end rtl;