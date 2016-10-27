--
-- dpram2k.vhd
--
-- Dual port RAM module for VRAM
-- for MZ-700 on FPGA
--
-- Nibbles Lab. 2005
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
library UNISIM;
use UNISIM.VComponents.all;

entity dpram2k is
    Port ( AA : in std_logic_vector(10 downto 0);
           DAI : in std_logic_vector(7 downto 0);
           DAO : out std_logic_vector(7 downto 0);
           CSA : in std_logic;
           WRA : in std_logic;
		 CLKA : in std_logic;
           AB : in std_logic_vector(10 downto 0);
           DBO : out std_logic_vector(7 downto 0);
		 CLKB : in std_logic);
end dpram2k;

architecture Behavioral of dpram2k is

--
-- signals
--
signal net_gnd : std_logic_vector(7 downto 0);
signal net_vcc : std_logic;
signal ENA : std_logic;
signal WEA : std_logic;

begin

	--
	-- fixed signals
	--
	net_gnd<=(others=>'0');
	net_vcc<='1';

	--
	-- signal treating
	--
	ENA <= not CSA;
	WEA <= not WRA;

	--
	-- RAM
	--
   RAMB16_S9_S9_inst : RAMB16_S9_S9
   generic map (
      INIT_A => X"000", --  Value of output RAM registers on Port A at startup
      INIT_B => X"000", --  Value of output RAM registers on Port B at startup
      SRVAL_A => X"000", --  Port A ouput value upon SSR assertion
      SRVAL_B => X"000", --  Port B ouput value upon SSR assertion
      WRITE_MODE_A => "READ_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      WRITE_MODE_B => "READ_FIRST") --  WRITE_FIRST, READ_FIRST or NO_CHANGE
   port map (
      DOA => DAO,      -- Port A 8-bit Data Output
      DOB => DBO,      -- Port B 8-bit Data Output
      DOPA => open,    -- Port A 1-bit Parity Output
      DOPB => open,    -- Port B 1-bit Parity Output
      ADDRA => AA,  -- Port A 11-bit Address Input
      ADDRB => AB,  -- Port B 11-bit Address Input
      CLKA => CLKA,    -- Port A Clock
      CLKB => CLKB,    -- Port B Clock
      DIA => DAI,      -- Port A 8-bit Data Input
      DIB => net_gnd,      -- Port B 8-bit Data Input
      DIPA => net_gnd(0 downto 0),    -- Port A 1-bit parity Input
      DIPB => net_gnd(0 downto 0),    -- Port-B 1-bit parity Input
      ENA => ENA,      -- Port A RAM Enable Input
      ENB => net_vcc,      -- PortB RAM Enable Input
      SSRA => net_gnd(0),    -- Port A Synchronous Set/Reset Input
      SSRB => net_gnd(0),    -- Port B Synchronous Set/Reset Input
      WEA => WEA,      -- Port A Write Enable Input
      WEB => net_gnd(0)       -- Port B Write Enable Input
   );


end Behavioral;
