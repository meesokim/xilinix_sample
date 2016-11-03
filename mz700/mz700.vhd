--
-- mz700.vhd
--
-- SHARP MZ-700 compatible logic, main module
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

entity mz700 is
    Port ( VRED : out std_logic_vector(4 downto 0);
           VGRN : out std_logic_vector(5 downto 0);
           VBLUE : out std_logic_vector(4 downto 0);
           HS : out std_logic;
           VS : out std_logic;
           GCK0 : in std_logic;
		   LED : out std_logic_vector(3 downto 0);
--		 TA : out std_logic_vector(15 downto 0);
--		 TCS00 : out std_logic;
--		 TCSD0 : out std_logic;
--		 TCSD8 : out std_logic;
--		 TRD : out std_logic;
--		 TWR : out std_logic;
--		 TM1 : out std_logic;
--		 TRFSH : out std_logic;
--		 TDI : out std_logic_vector(7 downto 0);
--		 TDO : out std_logic_vector(7 downto 0);
--		 TCLK : out std_logic;
--		 TURST : out std_logic;
--		 BTN0 : in std_logic;
		 BTN3 : in std_logic;
		 PS2C : in std_logic;
		 PS2D : in std_logic;
		 SPKOUT : out std_logic;
		 RXD : in std_logic;
		 TXD : out std_logic;
		 SW : in std_logic_vector(7 downto 0);
--		 A : out std_logic_vector(15 downto 0);
--		 IO : inout std_logic_vector(7 downto 0);
--		 CE1 : out std_logic;
--		 UB1 : out std_logic;
--		 LB1 : out std_logic;
--		 WE : out std_logic;
--		 OE : out std_logic;
--		 CE2 : out std_logic;
--		 UB2 : out std_logic;
--		 LB2 : out std_logic;
		 CE1 : in std_logic;
         SDRAM_CKE : out std_logic;
		 SDRAM_CS_N : out std_logic;
		 SDRAM_RAS_N : out std_logic;
		 SDRAM_CAS_N : out std_logic;
		 SDRAM_WE_N : out std_logic;
		 SDRAM_BA : out std_logic_vector(1 downto 0);
		 SDRAM_A : out std_logic_vector(12 downto 0);
		 SDRAM_DQ : inout std_logic_vector(15 downto 0);
		 SDRAM_DQM : out std_logic_vector(1 downto 0);
		 SDRAM_CLK : out std_logic;
		 --LED : out std_logic_vector(3 downto 0);
		 SEG : out std_logic_vector(7 downto 0);
		 --LD : out std_logic_vector(7 downto 0);
		 DS : out std_logic_vector(7 downto 0);
		 DSEN : out std_logic_vector(3 downto 0)
	);
end mz700;

architecture Behavioral of mz700 is

--
-- SDRAM
--
signal cmd_address     : std_logic_vector(20 downto 0) := (others => '0');
signal cmd_wr          : std_logic := '1';
signal cmd_enable      : std_logic;
signal cmd_byte_enable : std_logic_vector(3 downto 0);
signal cmd_data_in     : std_logic_vector(31 downto 0);
signal cmd_ready       : std_logic;
signal data_out        : std_logic_vector(31 downto 0);
signal data_out_ready  : std_logic;
--
-- T80
--
signal MREQ : std_logic;
signal IORQ : std_logic;
signal WR : std_logic;
signal RD : std_logic;
signal M1 : std_logic;
signal RFSH : std_logic;
signal A16 : std_logic_vector(15 downto 0);
signal DO : std_logic_vector(7 downto 0);
signal DI : std_logic_vector(7 downto 0);
signal URST : std_logic;
--
-- Clocks
--
signal CLK50M : std_logic;
signal DCLK : std_logic;
signal CLK45M : std_logic;
signal LOCKDCM1 : std_logic;
signal XLOCKDCM1 : std_logic;
signal NTSCCLK : std_logic;
signal CLK : std_logic;
signal CLK2X : std_logic;
signal XCLK : std_logic;
signal SCLK : std_logic;
signal HCLK : std_logic;
signal DIV8 : std_logic_vector(4 downto 0);
signal CASCADE : std_logic;
signal GCK1 : std_logic;
--
-- Decodes, misc
--
signal CS1 : std_logic;
signal CS00 : std_logic;
signal CS367 : std_logic;
signal MRDI : std_logic_vector(7 downto 0);
signal DO367 : std_logic_vector(7 downto 0);
signal CSPRT : std_logic;
signal DOPRT : std_logic_vector(7 downto 0);
signal BUF : std_logic_vector(9 downto 0);
--
-- Video
--
signal HSPLS : std_logic;
signal CSD0 : std_logic;
signal CVDI : std_logic_vector(7 downto 0);
signal CSD8 : std_logic;
signal AVDI : std_logic_vector(7 downto 0);
signal VADR : std_logic_vector(10 downto 0);
signal DCODE : std_logic_vector(7 downto 0);
signal CGADR : std_logic_vector(10 downto 0);
signal CSEL : std_logic;
signal FADR : std_logic_vector(2 downto 0);
signal CGDAT : std_logic_vector(7 downto 0);
signal ATDAT : std_logic_vector(7 downto 0);
signal VBLNK : std_logic;
signal CSPCG : std_logic;
--
-- PPI
--
signal CSPPI : std_logic;
signal DOPPI : std_logic_vector(7 downto 0);
signal TXDi : std_logic;
signal RBIT : std_logic;
signal MOTOR : std_logic;
signal INTMSK : std_logic;
--
-- PIT
--
signal CSPIT : std_logic;
signal DOPIT : std_logic_vector(7 downto 0);
signal SOUNDEN : std_logic;
signal XSPKOUT : std_logic;
signal INT : std_logic;
signal INTX : std_logic;
--
-- Extend ROM
--
signal CSE8 : std_logic;
signal EMDI : std_logic_vector(7 downto 0);
--
-- for Debug
--
--signal DET0 : std_logic;
--signal DET1 : std_logic;
--signal DET2 : std_logic;
--signal DET3 : std_logic;
--signal DET4 : std_logic;
signal LDDAT : std_logic_vector(7 downto 0);
signal TADDR : std_logic_vector(15 downto 0);
signal TMG : std_logic_vector(1 downto 0);
signal DDAT : std_logic_vector(3 downto 0);
signal DNUM : std_logic_vector(15 downto 0);
signal CENB1 : std_logic;
signal CENB2 : std_logic;
signal DIG : std_logic_vector(1 downto 0);
signal AA : std_logic_vector(3 downto 0);

--
-- Components
--
constant sdram_address_width : natural := 22;
constant sdram_column_bits   : natural := 8;
constant sdram_startup_cycles: natural := 10100; -- 100us, plus a little more
constant test_width          : natural := sdram_address_width-1; -- each 32-bit word is two 16-bit SDRAM addresses 
constant cycles_per_refresh  : natural := (64000*100)/4096-1;

	COMPONENT SDRAM_Controller
    generic (
      sdram_address_width : natural;
      sdram_column_bits   : natural;
      sdram_startup_cycles: natural;
      cycles_per_refresh  : natural
    );
    PORT(
		clk             : IN std_logic;
		reset           : IN std_logic;
      
      -- Interface to issue commands
		cmd_ready       : OUT std_logic;
		cmd_enable      : IN std_logic;
		cmd_wr          : IN std_logic;
        cmd_address     : in  STD_LOGIC_VECTOR(sdram_address_width-2 downto 0); -- address to read/write
		cmd_byte_enable : IN std_logic_vector(3 downto 0);
		cmd_data_in     : IN std_logic_vector(31 downto 0);    
      
      -- Data being read back from SDRAM
		data_out        : OUT std_logic_vector(31 downto 0);
		data_out_ready  : OUT std_logic;

      -- SDRAM signals
		SDRAM_CLK       : OUT   std_logic;
		SDRAM_CKE       : OUT   std_logic;
		SDRAM_CS        : OUT   std_logic;
		SDRAM_RAS       : OUT   std_logic;
		SDRAM_CAS       : OUT   std_logic;
		SDRAM_WE        : OUT   std_logic;
		SDRAM_DQM       : OUT   std_logic_vector(1 downto 0);
		SDRAM_ADDR      : OUT   std_logic_vector(12 downto 0);
		SDRAM_BA        : OUT   std_logic_vector(1 downto 0);
		SDRAM_DATA      : INOUT std_logic_vector(15 downto 0)     
		);
	END COMPONENT;

component T80s
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port(
		RESET_n		: in std_logic;
		CLK_n		: in std_logic;
		WAIT_n		: in std_logic;
		INT_n		: in std_logic;
		NMI_n		: in std_logic;
		BUSRQ_n		: in std_logic;
		M1_n		: out std_logic;
		MREQ_n		: out std_logic;
		IORQ_n		: out std_logic;
		RD_n		: out std_logic;
		WR_n		: out std_logic;
		RFSH_n		: out std_logic;
		HALT_n		: out std_logic;
		BUSAK_n		: out std_logic;
		A			: out std_logic_vector(15 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0)
	);
end component;

component my_dcm1
   port ( CLKIN_IN        : in    std_logic; 
          CLKDV_OUT       : out   std_logic; 
          CLKFX_OUT       : out   std_logic; 
          CLKIN_IBUFG_OUT : out   std_logic; 
          CLK0_OUT        : out   std_logic;
		  CLK2X_OUT       : out   std_logic;
          LOCKED_OUT      : out   std_logic);
end component;

component my_dcm2
   port ( CLKIN_IN        : in    std_logic; 
          RST_IN          : in    std_logic; 
          CLKFX_OUT       : out   std_logic; 
          CLKIN_IBUFG_OUT : out   std_logic; 
          LOCKED_OUT      : out   std_logic);
end component;

component memsel
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
end component;	 

component mrom
    Port ( A : in std_logic_vector(11 downto 0);
           CS : in std_logic;
           D : out std_logic_vector(7 downto 0);
		 CLK : in std_logic);
end component;

component vgaout
    Port ( RST : in std_logic;
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
end component;

component cgrom
    Port ( ROMA : in std_logic_vector(10 downto 0);
           CSEL : in std_logic;
           ROMD : out std_logic_vector(7 downto 0);
		 PCGSW : in std_logic;
		 CSPCG : in std_logic;
		 WR : in std_logic;
           RAMA : in std_logic_vector(1 downto 0);
           RAMD : in std_logic_vector(7 downto 0);
		 MCLK : in std_logic;
		 DCLK : in std_logic);
end component;

component dpram2k
    Port ( AA : in std_logic_vector(10 downto 0);
           DAI : in std_logic_vector(7 downto 0);
           DAO : out std_logic_vector(7 downto 0);
           CSA : in std_logic;
           WRA : in std_logic;
		 CLKA : in std_logic;
           AB : in std_logic_vector(10 downto 0);
           DBO : out std_logic_vector(7 downto 0);
		 CLKB : in std_logic);
end component;

component ls367
    Port ( RST : in std_logic;
           CLKIN : in std_logic;
           CLKOUT : out std_logic;
		 GATE : out std_logic;
		 CS : in std_logic;
		 WR : in std_logic;
		 DI : in std_logic_vector(7 downto 0);
           DO : out std_logic_vector(7 downto 0));
end component;

component i8255
    Port ( RST : in std_logic;
           A : in std_logic_vector(1 downto 0);
           CS : in std_logic;
           WR : in std_logic;
           DI : in std_logic_vector(7 downto 0);
           DO : out std_logic_vector(7 downto 0);
		 LDDAT : out std_logic_vector(7 downto 0);
--		 LDDAT2 : out std_logic;
--		 LDSNS : out std_logic;
           CLKIN : in std_logic;
		 KCLK : in std_logic;
--		 FCLK : in std_logic;
		 VBLNK : in std_logic;
		 INTMSK : out std_logic;
           RBIT : in std_logic;
		 SENSE : in std_logic;
		 MOTOR : out std_logic;
		 PS2CK : in std_logic;
		 PS2DT : in std_logic);
end component;

component psio
    Port ( RST : in std_logic;
           CLK : in std_logic;
		 TADDR : out std_logic_vector(15 downto 0);
           RXD : in std_logic;
           TXD : out std_logic;
		 PRTSW : in std_logic;
		 PLYSW : in std_logic;
		 RBIT : out std_logic;
		 MOTOR : in std_logic;
		 LDDAT : out std_logic_vector(7 downto 0);
           DI : in std_logic_vector(7 downto 0);
           DO : out std_logic_vector(7 downto 0);
		 CS : in std_logic;
		 A : in std_logic;
           WR : in std_logic);
end component;

component i8253
    Port ( RST : in std_logic;
    		 CLK : in std_logic;
           A : in std_logic_vector(1 downto 0);
		 DI : in std_logic_vector(7 downto 0);
           DO : out std_logic_vector(7 downto 0);
           CS : in std_logic;
           WR : in std_logic;
		 RD : in std_logic;
           CLK0 : in std_logic;
           GATE0 : in std_logic;
           OUT0 : out std_logic;
           CLK1 : in std_logic;
           GATE1 : in std_logic;
           OUT1 : out std_logic;
           CLK2 : in std_logic;
           GATE2 : in std_logic;
           OUT2 : out std_logic);
end component;

component exrom
    Port ( A : in std_logic_vector(4 downto 0);
           DO : out std_logic_vector(7 downto 0);
           CS : in std_logic);
end component;

component BUFG
      port ( I : in    std_logic; 
             O : out   std_logic);
end component;

begin

	--
	-- Instantiation
	--
	
Inst_SDRAM_Controller: SDRAM_Controller GENERIC MAP (
      sdram_address_width => sdram_address_width,
      sdram_column_bits   => sdram_column_bits,
      sdram_startup_cycles=> sdram_startup_cycles,
      cycles_per_refresh  => cycles_per_refresh
   ) PORT MAP(
      clk             => CLK50M,
      reset           => '0',

      cmd_address     => cmd_address,
      cmd_wr          => cmd_wr,
      cmd_enable      => cmd_enable,
      cmd_ready       => cmd_ready,
      cmd_byte_enable => cmd_byte_enable,
      cmd_data_in     => cmd_data_in,
      
      data_out        => data_out,
      data_out_ready  => data_out_ready,
   
      SDRAM_CLK       => SDRAM_CLK,
      SDRAM_CKE       => SDRAM_CKE,
      SDRAM_CS        => SDRAM_CS_N,
      SDRAM_RAS       => SDRAM_RAS_N,
      SDRAM_CAS       => SDRAM_CAS_N,
      SDRAM_WE        => SDRAM_WE_N,
      SDRAM_DQM       => SDRAM_DQM,
      SDRAM_BA        => SDRAM_BA,
      SDRAM_ADDR      => SDRAM_A,
      SDRAM_DATA      => SDRAM_DQ
   );

	CPU0 : T80s port map (
			RESET_n => URST,
			CLK_n => CLK,
			WAIT_n => '1',
--			INT_n => '1',
			INT_n => INT,
			NMI_n => '1',
			BUSRQ_n => '1',
			M1_n => M1,
			MREQ_n => MREQ,
			IORQ_n => IORQ,
			RD_n => RD,
			WR_n => WR,
			RFSH_n => RFSH,
			HALT_n => open,
			BUSAK_n => open,
			A => A16,
			DI => DI,
			DO => DO);

	DCM0 : my_dcm1 port map (
			CLKIN_IN => GCK0,
			CLK0_OUT => CLK50M,
			CLKFX_OUT => CLK45M,
			CLKDV_OUT => DCLK,
			CLKIN_IBUFG_OUT => open,
			CLK2X_OUT => CLK2X,
			LOCKED_OUT => LOCKDCM1);
--			LOCKED_OUT => open);

	XLOCKDCM1<=not LOCKDCM1;
	DCM1 : my_dcm2 port map (
			CLKIN_IN => CLK45M,
			RST_IN => XLOCKDCM1, 
--			RST_IN => '0', 
			CLKFX_OUT => NTSCCLK,
			CLKIN_IBUFG_OUT => open,
			LOCKED_OUT => open);

	DEC0 : memsel port map (
			RST => URST,
			CLK => CLK,
			MREQ => MREQ,
			IORQ => IORQ,
			WR => WR,
			A => A16,
			LED0 => LDDAT(7),
			LED1 => LDDAT(6),
			CS00 => CS00,
			CSD0 => CSD0,
			CSD8 => CSD8,
			CSE8 => CSE8,
			CSPPI => CSPPI,
			CSPIT => CSPIT,
			CS367 => CS367,
			CSPRT => CSPRT,
			CSPCG => CSPCG,
			CS1 => CS1);

	ROM0 : mrom port map (
			A => A16(11 downto 0),
			CS => CS00,
			D => MRDI,
			CLK => XCLK);

	VGA0 : vgaout port map (
			RST => URST,
			CLK => DCLK,
			RED => VRED(4),
			GRN => VGRN(5),
			BLUE => VBLUE(4),
			HS => HSPLS,
			VS => VS,
			VBLNK => VBLNK,
			FDAT => CGDAT,
			ADAT => ATDAT,
			VADR => VADR,
			FADR => FADR,
			CSEL => CSEL);

	CGROM0 : cgrom port map (
			ROMA => CGADR,
			CSEL => CSEL,
			ROMD => CGDAT,
			PCGSW => SW(7),
			CSPCG => CSPCG,
			WR => WR,
			RAMA => A16(1 downto 0),
			RAMD => DO,
			MCLK => XCLK,
			DCLK => DCLK);

	CGADR<=DCODE&FADR;

	CVRAM0 : dpram2k port map (
			AA => A16(10 downto 0),
			DAI => DO,
			DAO => CVDI,
			CSA => CSD0,
			WRA => WR,
			CLKA => XCLK,
			AB => VADR,
			DBO => DCODE,
			CLKB => DCLK);

	AVRAM0 : dpram2k port map (
			AA => A16(10 downto 0),
			DAI => DO,
			DAO => AVDI,
			CSA => CSD8,
			WRA => WR,
			CLKA => XCLK,
			AB => VADR,
			DBO => ATDAT,
			CLKB => DCLK);

	GPIO0 : ls367 port map (
			RST => URST,
			CLKIN => CLK,
			CLKOUT => SCLK,
			GATE => SOUNDEN,
			CS => CS367,
			WR => WR,
			DI => DO,
			DO => DO367);

	PPI0 : i8255 port map (
			RST => URST,
			A => A16(1 downto 0),
			CS => CSPPI,
			WR => WR,
			DI => DO,
			DO => DOPPI,
			LDDAT => open,
--			LDDAT2 => LD(5),
--			LDSNS => LD(6),
			CLKIN => SCLK,
			KCLK => CLK,
--			FCLK => NTSCCLK,
			VBLNK => VBLNK,
			INTMSK => INTMSK,
			RBIT => RBIT,
			SENSE => SW(0),
			MOTOR => MOTOR,
			PS2CK => PS2C,
			PS2DT => PS2D);

	PSIO0 : psio port map (
			RST => URST,
			CLK => CLK,
			TADDR => TADDR,
			RXD => RXD,
			TXD => TXDi,
			PRTSW => SW(4),
			PLYSW => SW(0),
			RBIT => RBIT,
			MOTOR => MOTOR,
			LDDAT => open,
			DI => DO,
			DO => DOPRT,
			CS => CSPRT,
			A => A16(0),
			WR => WR);

	PIT0 : i8253 port map (
			RST => URST,
			CLK => CLK,
			A => A16(1 downto 0),
			DI => DO,
			DO => DOPIT,
			CS => CSPIT,
			WR => WR,
			RD => RD,
			CLK0 => DIV8(4),
			GATE0 => SOUNDEN,
			OUT0 => XSPKOUT,
			CLK1 => HCLK,
			GATE1 => '1',
			OUT1 => CASCADE,
			CLK2 => CASCADE,
			GATE2 => '1',
			OUT2 => INTX);

	ROM1 : exrom port map (
			A => A16(4 downto 0),
			DO => EMDI,
			CS => CSE8);

	CLKFX_BUFG_INST : BUFG port map (
			I => DIV8(2),
               O => CLK);

	--
	-- User Reset with automatic
	--
	URST<='0' when BUF(9 downto 5)="00000" else '1';
	process( CLK50M ) begin
		if( CLK50M'event and CLK50M='1' ) then
			BUF<=BUF(8 downto 0)&(BTN3);
		end if;
	end process;

	--
	-- CPU & peripheral clock
	--
	XCLK<=not DIV8(2);
	process( NTSCCLK, URST ) begin
		if( URST='0' ) then
			DIV8<=(others=>'0');
		elsif( NTSCCLK'event and NTSCCLK='1' ) then
			DIV8<=DIV8+'1';
		end if;
	end process;

	--
	-- clock for Timer
	--
	process( HSPLS, URST ) begin
		if( URST='0' ) then
			HCLK<='0';
		elsif( HSPLS'event and HSPLS='1' ) then
			HCLK<=not HCLK;
			if (DIV8 = 0) then
--				LED(0) <= HCLK;
				LED(1) <= '0';
				LED(2) <= HCLK;
				LED(3) <= '0';
			end if;
		end if;
	end process;

	--
	-- misc.
	--
	cmd_enable <= not CS1;
	cmd_address <= "00000" & A16;
	cmd_wr<=(RD or not WR) and not MREQ;
	cmd_byte_enable <= (others =>'1');
	TXD<=TXDi;
	LED(0) <= '0';

	HS<=HSPLS;
	SPKOUT<=not XSPKOUT;
	INT<=not (INTX and INTMSK);

	--
	-- Data Bus
	--
	DI<=MRDI when CS00='0' else
	    CVDI when CSD0='0' else
	    AVDI when CSD8='0' else
	    EMDI when CSE8='0' else
	    data_out(7 downto 0) when CS1='0' and data_out_ready = '1' else
	    DO367 when CS367='0' else
	    DOPPI when CSPPI='0' else
	    DOPIT when CSPIT='0' else
	    DOPRT when CSPRT='0' else (others=>'1');
	cmd_data_in(7 downto 0)<=DO when CS1='0' and RD='1' and cmd_ready = '1' else (others=>'Z');

	--
	-- LED
	--
--	AN<=(others=>'1');
--	LED<="1110" when TMG="00" else
--	    "1101" when TMG="01" else
--	    "1011" when TMG="10" else
--	    "0111" when TMG="11" and SW(0)='0' else (others=>'1');
--	    "0111" when TMG="11" else (others=>'1');
	DNUM<=TADDR when SW(0)='0' else
		 X"0700" when SW(0)='1' else (others=>'1');
	DDAT<=DNUM(3 downto 0) when TMG="00" else
		 DNUM(7 downto 4) when TMG="01" else
		 DNUM(11 downto 8) when TMG="10" else
		 DNUM(15 downto 12) when TMG="11" else (others=>'0');
	DSEN <= "1110" when DIG = 0 else
			"1101" when DIG = 1 else
			"1011" when DIG = 2 else
			"0111" when DIG = 3 else (others=>'0');
	AA<= A16(3 downto 0) when DIG = 0 else
		 A16(7 downto 4) when DIG = 1 else
		 A16(11 downto 8) when DIG = 2 else
		 A16(15 downto 12) when DIG = 3;
	DS<="10000001" when AA="0000" else
		"11001111" when AA="0001" else
		"10010010" when AA="0010" else
		"10000110" when AA="0011" else
		"11001100" when AA="0100" else
		"10100100" when AA="0101" else
		"10100000" when AA="0110" else
		"10001111" when AA="0111" else
		"10000000" when AA="1000" else
		"10000100" when AA="1001" else
		"10001000" when AA="1010" else
		"11100000" when AA="1011" else
		"10110001" when AA="1100" else
		"11000010" when AA="1101" else
		"10110000" when AA="1110" else
		"10111000" when AA="1111" else (others=>'1');		
	process( HCLK ) begin
		if( HCLK'event and HCLK='1' ) then
			TMG<=TMG+'1';
			DIG <= DIG + 1;
	
		end if;
	end process;

--	LD<=(others=>'0');
--	LD<=LDDAT;
--	LD(0)<='0';
--	LD(1)<='0';
--	LD(2)<='0';
--	LD(3)<='0';
--	LD(4)<='0';
--	LD(5)<=CENB2;
--	LD(6)<=CENB1;
--	LD(7)<=SOUNDEN;
--	process( M1, URST ) begin
--		if( URST='0' ) then
--			DET0<='0';
--			DET1<='0';
--			DET2<='0';
--			DET3<='0';
--			DET4<='0';
--		elsif( M1'event and M1='1' ) then
--			if( A16=X"0678" ) then
--				DET0<='1';
--			elsif( A16=X"0688" ) then
--				DET1<='1';
--			elsif( A16=X"0698" ) then
--				DET2<='1';
--			elsif( A16=X"04F2" ) then
--				DET3<='1';
--			elsif( A16=X"07DD" ) then
--				DET4<='1';
--			end if;
--		end if;
--	end process;


--	TA<=A16;
--	TCS00<=CS00;
--	TCSD0<=CSD0;
--	TCSD8<=CSD8;
--	TDI<=DI;
--	TDO<=DO;
--	TRD<=RD;
--	TWR<=WR;
--	TM1<=M1;
--	TRFSH<=RFSH;
--	TCLK<=CLK;
--	TURST<=URST;

end Behavioral;
