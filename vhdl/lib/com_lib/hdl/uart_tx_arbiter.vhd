
library ieee;
use ieee.std_logic_1164.all;

library com_lib;
use com_lib.com_pkg.all;

entity uart_tx_arbiter is
	generic (
		g_ports : integer
	);
	port (
		clk_i : in std_logic;

		uart_busy_i : in  std_logic;
		uart_ena_o  : out std_logic;
		uart_data_o : out std_logic_vector(7 downto 0);

		tx_req_i      : in  std_logic_vector(g_ports-1 downto 0);
		tx_busy_o     : out std_logic_vector(g_ports-1 downto 0);
		tx_data_i     : in  vec8_array(g_ports-1 downto 0);
		tx_data_vld_i : in  std_logic_vector(g_ports-1 downto 0)
	);
end uart_tx_arbiter;

architecture rtl of uart_tx_arbiter is

	type state_t is (idle, grant_req);
	signal state : state_t := idle;

	signal port_cnt : integer range 0 to g_ports-1 := 0;

	function OutputBusy(cur_port : integer;
			busy : std_logic) return std_logic_vector is
		variable res : std_logic_vector(g_ports-1 downto 0) := (others => '1');
	begin
		res(cur_port) := busy;
		return res;
	end function;

begin

	-- The current evaluated port will have the busy signal passed	
	tx_busy_o <= OutputBusy(port_cnt, uart_busy_i);

	arbiter : process (clk_i)
	begin
		if rising_edge(clk_i) then
			-- go though all ports and check for requests, if request go to grant state 
			-- and fulfill that request until request signal goes low
			uart_ena_o <= '0';
			
			case state is
				when idle =>

					-- Check if current port has a request
					if tx_req_i(port_cnt) = '1' then
						state <= grant_req;
					-- If not increment or wrap port number to check next port.
					elsif port_cnt = g_ports-1 then
						port_cnt <= 0;
					else
						port_cnt <= port_cnt + 1;
					end if;

				when grant_req =>
					-- busy until request goes low, no timeout...
					-- Can lock up if upstream is bugy.
					if tx_req_i(port_cnt) = '0' then
						state <= idle;
					end if;

					uart_ena_o  <= tx_data_vld_i(port_cnt);
					uart_data_o <= tx_data_i(port_cnt);

			end case;

		end if;
	end process;


end architecture;