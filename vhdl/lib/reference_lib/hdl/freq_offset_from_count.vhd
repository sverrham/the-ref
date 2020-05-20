
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Calculates the ppb error from expected count.
-- 
-- Input is count in the expected frequency g_frequency over one second.
-- The measurement period 1s is expected to be correct.
entity freq_offset_from_count is
    generic (
        g_frequency : in real
    );
    port (
        i_clk: in std_logic;
        i_count: in unsigned(31 downto 0);
        i_count_vld: in std_logic;
        o_error_ppb : out integer range -10000 to 10000;
        o_error_ppb_vld : out std_logic
        );
end freq_offset_from_count;

architecture rtl of freq_offset_from_count is

    constant c_expected_count : unsigned(31 downto 0) := to_unsigned(natural(g_frequency), 32);
    constant c_ppm : integer range 0 to 100 := natural(g_frequency/1.0e6);
    
    signal offset : integer range -10000 to 10000 := 0;
    signal error_ppb : integer range -10000 to 10000 := 0;

    type state_type is (idle, calc_error, output_error);
    signal state : state_type := idle;
begin

    p_error : process (i_clk)
    begin
        if rising_edge(i_clk) then
            o_error_ppb_vld <= '0';
            case state is
                when idle =>
                    if i_count_vld = '1' then
                        state <= calc_error;
                        offset <= to_integer(i_count - c_expected_count);
                    end if;

                when calc_error =>
                    state <= output_error;
                    error_ppb <= offset * 1000 / c_ppm;

                when output_error =>
                    state <= idle;
                    o_error_ppb <= error_ppb;
                    o_error_ppb_vld <= '1';
            end case;
        end if;
    end process;
    

end rtl;