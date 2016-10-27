--
-- exrom.vhd
--
-- Extended ROM module
-- for MZ-700 on FPGA
--
-- Color Attribute Initialize (forward=white, back=blue)
--
-- Nibbles Lab. 2005
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity exrom is
    Port ( A : in std_logic_vector(4 downto 0);
           DO : out std_logic_vector(7 downto 0);
           CS : in std_logic);
end exrom;

architecture Behavioral of exrom is

begin

	--
	-- Color Attibute fill routine
	--
	process( CS, A ) begin
		if( CS='0' ) then
			case A is
				when "00000" => DO<=X"3E";
				when "00001" => DO<=X"71";
				when "00010" => DO<=X"21";
				when "00011" => DO<=X"00";
				when "00100" => DO<=X"D8";
				when "00101" => DO<=X"77";
				when "00110" => DO<=X"11";
				when "00111" => DO<=X"01";
				when "01000" => DO<=X"D8";
				when "01001" => DO<=X"01";
				when "01010" => DO<=X"E7";
				when "01011" => DO<=X"03";
				when "01100" => DO<=X"ED";
				when "01101" => DO<=X"B0";
				when "01110" => DO<=X"C3";
				when "01111" => DO<=X"4A";
				when "10000" => DO<=X"00";
				when others => DO<=X"FF";
			end case;
		end if;
	end process;

end Behavioral;
