--
-- memsel.vhd
--
-- Memory and I/O address decode module
-- for MZ-700 on FPGA
--
-- BANK Memory : DRAM, Monitor ROM, VRAM and I/O
-- I/O mapped I/O : BANK register, Printer
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

entity memsel is
    Port ( RST : in std_logic;
    		 CLK : in std_logic;
           MREQ : in std_logic;
           IORQ : in std_logic;
           WR : in std_logic;
           A : in std_logic_vector(15 downto 0);
		 LED0 : out std_logic;
		 LED1 : out std_logic;
           CS00 : out std_logic;
           CSD0 : out std_logic;
           CSD8 : out std_logic;
           CSE8 : out std_logic;
           CSPPI : out std_logic;
           CSPIT : out std_logic;
           CS367 : out std_logic;
		 CSPRT : out std_logic;
		 CSPCG : out std_logic;
           CS1 : out std_logic);
end memsel;

architecture Behavioral of memsel is

signal reg00 : std_logic;
signal regIO : std_logic;
signal regEX : std_logic;
signal CS : std_logic;

begin
	
	--
	-- BANK registers
	--
	CS<='1' when A(7 downto 3)="11100" and IORQ='0' else '0';
	process( RST, CLK ) begin
		if( RST='0' ) then
			reg00<='0';
			regIO<='0';
			regEX<='0';
		elsif( CLK'event and CLK='0' ) then
			if( CS='1' and WR='0' ) then
				if( A(2 downto 0)="000" ) then
					reg00<='1';
				elsif( A(2 downto 0)="001" ) then
					regIO<='1';
				elsif( A(2 downto 0)="010" ) then
					reg00<='0';
				elsif( A(2 downto 0)="011" ) then
					regIO<='0';
				elsif( A(2 downto 0)="100" ) then
					reg00<='0';
					regIO<='0';
				elsif( A(2 downto 0)="101" ) then
					regEX<='1';
				elsif( A(2 downto 0)="110" ) then
					regEX<='0';
				end if;
			end if;
		end if;
	end process;
	LED0<=reg00;
	LED1<=regIO;

	--
	-- Memory decoding(not DRAM)
	--
	CS00<='0' when A(15 downto 12)="0000" and reg00='0' and MREQ='0' else '1';
	CSD0<='0' when A(15 downto 11)="11010" and regIO='0' and regEX='0' and MREQ='0' else '1';
	CSD8<='0' when A(15 downto 11)="11011" and regIO='0' and regEX='0' and MREQ='0' else '1';
	CSE8<='0' when A(15 downto 11)="11101" and regIO='0' and regEX='0' and MREQ='0' else '1';
	CSPPI<='0' when A(15 downto 11)="11100" and A(4 downto 2)="000" and regIO='0' and regEX='0' and MREQ='0' else '1';
	CSPIT<='0' when A(15 downto 11)="11100" and A(4 downto 2)="001" and regIO='0' and regEX='0' and MREQ='0' else '1';
	CS367<='0' when A(15 downto 11)="11100" and A(4 downto 2)="010" and regIO='0' and regEX='0' and MREQ='0' else '1';
	CSPCG<='0' when A(15 downto 11)="11100" and A(4 downto 2)="100" and regIO='0' and regEX='0' and MREQ='0' else '1';

	--
	-- Memory decoding(DRAM)
	--
	CS1<='0' when A(15 downto 12)/="0000" and A(15 downto 12)/="1101" and A(15 downto 13)/="111" else
		'0' when A(15 downto 12)="0000" and reg00='1' else
		'0' when A(15 downto 12)="1101" and regIO='1' and regEX='0' else
		'0' when A(15 downto 13)="111" and regIO='1' and regEX='0' else '1';

	--
	-- I/O decoding
	--
	CSPRT<='0' when A(7 downto 1)="1111111" and IORQ='0' else '1';

end Behavioral;
