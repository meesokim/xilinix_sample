--
-- vgaout.vhd
--
-- VGA display signal generator 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity vgaout is
    Port ( RST : in std_logic;
-- for sim
--		HC : out std_logic_vector(9 downto 0);
--		VC : out std_logic_vector(9 downto 0);
--		HEN : out std_logic;
--		VEN : out std_logic;
--		SD : out std_logic_vector(7 downto 0);
-- for sim
    	   CLK : in std_logic;
           RED : out std_logic;
           GRN : out std_logic;
           BLUE : out std_logic;
           HS : out std_logic;
           VS : out std_logic;
		   VBLNK : out std_logic;
           VADR : out std_logic_vector(10 downto 0);
           FDAT : in std_logic_vector(7 downto 0);
           ADAT : in std_logic_vector(7 downto 0);
           FADR : out std_logic_vector(2 downto 0);
		   CSEL : out std_logic
		);
end vgaout;

architecture Behavioral of vgaout is

--
-- SYNC timing
--
signal HCOUNT : std_logic_vector(8 downto 0);
signal VCOUNT : std_logic_vector(9 downto 0);
signal HDISPEN : std_logic;
signal VDISPEN : std_logic;
--
-- CGROM/VRAM access
--
signal SDAT : std_logic_vector(7 downto 0);
signal VADRL : std_logic_vector(10 downto 0);
signal VADRC : std_logic_vector(10 downto 0);
--
-- forward/back color
--
signal FCOLR : std_logic;
signal FCOLG : std_logic;
signal FCOLB : std_logic;
signal BCOLR : std_logic;
signal BCOLG : std_logic;
signal BCOLB : std_logic;

begin

     --
	-- Timing counter
	--
	process( RST, CLK, HCOUNT, VCOUNT ) begin

		if( RST='0' ) then
			HCOUNT<="111111011"; -- -4
			VCOUNT<=(others=>'0'); 
			VS<='1';
			VDISPEN<='0';
			HS<='1';
			HDISPEN<='0';
			SDAT<=(others=>'0');
			VADRL<=(others=>'0');
			VADRC<=(others=>'0');
			FCOLR<='0';
			FCOLG<='0';
			FCOLB<='0';
			BCOLR<='0';
			BCOLG<='0';
			BCOLB<='0';
		elsif( CLK'event and CLK='1' ) then
			if( HCOUNT=393 ) then
				HCOUNT<="111111011"; -- -4
				VADRC<=VADRL;
				if( VCOUNT=520 ) then
					VCOUNT<=(others=>'0');
					VADRL<=(others=>'0');
					VADRC<=(others=>'0');
				else
					VCOUNT<=VCOUNT+'1';
				end if;
			else
				HCOUNT<=HCOUNT+'1';
			end if;

			--
			-- Vertical sync
			--
			if( VCOUNT=0 ) then
				VDISPEN<='1';
			elsif( VCOUNT=400 ) then
				VDISPEN<='0';
			elsif( VCOUNT=450 ) then
				VS<='0';
			elsif( VCOUNT=452 ) then
				VS<='1';
			end if;

			--
			-- Horizontal sync
			--
			if( HCOUNT=1 and VDISPEN='1' ) then
				HDISPEN<='1';
			elsif( HCOUNT=320 and VCOUNT(3 downto 0)="1111" ) then
				VADRL<=VADRC;
			elsif( HCOUNT=321 ) then
				HDISPEN<='0';
			elsif( HCOUNT=329 ) then
				HS<='0';
			elsif( HCOUNT=377 ) then
				HS<='1';
			end if;

			if( HCOUNT(2 downto 0)="000" ) then
				VADRC<=VADRC+'1';
			end if;

			--
			-- Color
			--
			if( HCOUNT(2 downto 0)="001" ) then
				SDAT<=FDAT;
				FCOLR<=ADAT(5);
				FCOLG<=ADAT(6);
				FCOLB<=ADAT(4);
				BCOLR<=ADAT(1);
				BCOLG<=ADAT(2);
				BCOLB<=ADAT(0);
			else
				SDAT<=SDAT(6 downto 0)&'0';
			end if;

		end if;

	end process;
		   
	--
	-- Output
	--
	VADR<=VADRC;
	FADR<=VCOUNT(3 downto 1);
	CSEL<=ADAT(7);
	RED<=FCOLR when HDISPEN='1' and SDAT(7)='1' else
		BCOLR when HDISPEN='1' else '0';
	GRN<=FCOLG when HDISPEN='1' and SDAT(7)='1' else
		BCOLG when HDISPEN='1' else '0';
	BLUE<=FCOLB when HDISPEN='1' and SDAT(7)='1' else
		 BCOLB when HDISPEN='1' else '0';
	VBLNK<=VDISPEN;

-- for sim
--	HC<=HCOUNT;
--	VC<=VCOUNT;
--	HEN<=HDISPEN;
--	VEN<=VDISPEN;
--	SD<=SDAT;
-- for sim

end Behavioral;
