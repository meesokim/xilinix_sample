library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity LED1 is
	port (
		GCK0: in std_logic;
		LED: out std_logic_vector(3 downto 0)
	);
end LED1;


architecture Behavioral of LED1 is
	signal Counter: std_logic_vector(24 downto 0);
	signal cnt:  std_logic_vector(3 downto 0) := (others => '0');
	signal CLK_1Hz: std_logic;
begin

	Prescaler: process(GCK0)
	begin
		if rising_edge(GCK0) then
			if Counter < "1011111010111100001000000" then
				Counter <= Counter + 1;
			else
				CLK_1Hz <= not CLK_1Hz;
				cnt <= cnt + 1;
				LED <= not cnt;
				Counter <= (others => '0');
			end if;
		end if;
	end process Prescaler;
	




end Behavioral;