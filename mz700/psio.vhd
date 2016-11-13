--
-- psio.vhd
--
-- Printer and Tape Interface module
-- for MZ-700 on FPGA
--
-- Printer : MZ-1P01 compatible but only color change code
-- Tape : *.mzt format data capable, XMODEM protocol
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

entity psio is
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
end psio;

architecture Behavioral of psio is

--
-- KCPSM
--
signal PADDR : std_logic_vector(11 downto 0);
signal PINST : std_logic_vector(17 downto 0);
signal XRST : std_logic;
signal IRST : std_logic;
signal PID : std_logic_vector(7 downto 0);
signal PO : std_logic_vector(7 downto 0);
signal PI : std_logic_vector(7 downto 0);
signal WS : std_logic;
signal RS : std_logic;
signal IREQ : std_logic;
signal IACK : std_logic;
signal EN : std_logic;
signal SLEEP : std_logic;
--
-- Printer
--
signal RDP : std_logic;
signal RD : std_logic_vector(7 downto 0);
--
-- Serial port
--
signal TDAT0 : std_logic_vector(7 downto 0);
signal TDAT : std_logic_vector(8 downto 0);
signal TBFULL : std_logic;
signal TBUSY : std_logic;
signal TCTR : std_logic_vector(9 downto 0);
signal TBCTR : std_logic_vector(3 downto 0);
signal RXIN : std_logic_vector(2 downto 0);
signal RXEN : std_logic;
signal RDAT0 : std_logic_vector(7 downto 0);
signal RDAT : std_logic_vector(9 downto 0);
signal RCTR : std_logic_vector(9 downto 0);
--
-- SHARP PWM
--
signal BCTR : std_logic_vector(11 downto 0);
signal BP : std_logic;
signal BBUSY : std_logic;
--
-- Buffer
--
signal WADDR : std_logic_vector(10 downto 0);
signal XWADDR : std_logic_vector(10 downto 0);
signal WEN : std_logic;
signal RADDR : std_logic_vector(10 downto 0);
signal XRADDR : std_logic_vector(10 downto 0);
signal REN : std_logic;
signal BUFO : std_logic_vector(7 downto 0);
--
-- for Debug
--

--
-- Components
--
component kcpsm6
    Port (      address : out std_logic_vector(11 downto 0);
            instruction : in std_logic_vector(17 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
          interrupt_ack : out std_logic;
                  sleep : in std_logic;
                  reset : in std_logic;
                    clk : in std_logic);
end component;

component prom
  Port (      address : in std_logic_vector(11 downto 0);
          instruction : out std_logic_vector(17 downto 0);
               enable : in std_logic;
                  rdl : out std_logic;                    
                  clk : in std_logic);
end component;

begin

	--
	-- Instantiation
	--
	scpu : kcpsm6 port map(
	           address => PADDR,
            instruction => PINST,
                port_id => PID,
           write_strobe => WS,
               out_port => PO,
            read_strobe => RS,
                in_port => PI,
              interrupt => IREQ,
          interrupt_ack => IACK,
		          sleep => SLEEP,
--                reset => IRST,
                  reset => XRST,
                    clk => CLK);

	rom : prom port map(
                address => PADDR,
            instruction => PINST,
			     enable => EN,
--           proc_reset => IRST,
                    clk => CLK);

	--
	-- KCPSM's peripheral
	--
	PI<=RDAT0 			 when PID=X"00" else -- Serial port
	    PRTSW&"000000"&RDP	 when PID=X"01" else -- Printer Strobe
	    RD				 when PID=X"02" else -- Print data
	    "000000"&TBUSY&TBFULL when PID=X"03" else -- Serial TX status
	    MOTOR&PLYSW&"00000"&BBUSY	 when PID=X"04" else -- TAPE status
	    BUFO				 when PID=X"05" else -- Buffer data
	    "0000"&RADDR(10 downto 7) when PID=X"06" else -- Read Buffer block
	    "0000"&WADDR(10 downto 7) when PID=X"07" else -- Write Buffer block
	    (others=>'0');
	XRST<=not RST;

	process( CLK ) begin
		if( CLK'event and CLK='1' ) then
			if( WS='1' ) then
				if( PID=X"06" ) then
					TADDR(7 downto 0)<=PO;
				elsif( PID=X"07" ) then
					TADDR(15 downto 8)<=PO;
				elsif( PID=X"08" ) then
					LDDAT<=PO;
				end if;
			end if;
		end if;
	end process;

	--
	-- Printer
	--
	process( WR ) begin
		if( WR'event and WR='1' ) then
			if( CS='0' ) then
				if( A='0' ) then
					RDP<=DI(7); -- STROBE
				else
					RD<=DI; -- Print Data
				end if;
			end if;
		end if;
	end process;

	DO(7 downto 1)<=(others=>'0');
	process( CLK, RST ) begin
		if( RST='0' ) then
			DO(0)<='0';
		elsif( CLK'event and CLK='1' ) then
			if( WS='1' and PID=X"01" ) then
				DO(0)<=PO(0); -- RDA(BUSY)
			end if;
		end if;
	end process;

	--
	-- Transfer to Serial port
	--
	TXD<=TDAT(0);
	process( CLK, RST ) begin
		if( RST='0' ) then
			TBFULL<='0'; -- double buffer status ('1' means full)
			TBUSY<='0'; -- transfer status ('1' means busy)
		elsif( CLK'event and CLK='1' ) then
			if( WS='1' and PID=X"00" ) then -- tx data from kcpsm
				TDAT0<=PO;
				TBFULL<='1';
			end if;
			if( TBFULL='1' and TBUSY='0' ) then -- set Shift Reg
				TDAT<=TDAT0&'0';
				TBFULL<='0';
				TBUSY<='1';
				TCTR<=(others=>'0');
				TBCTR<=(others=>'0');
			end if;
			if( TBUSY='1' ) then -- data transfer
				if( TCTR=715 ) then -- 4800bps
					TCTR<=(others=>'0');
					TDAT<='1'&TDAT(8 downto 1);
					TBCTR<=TBCTR+1;
				else
					TCTR<=TCTR+1;
					if( TBCTR=10 ) then -- the end of transfer
						TBUSY<='0';
					end if;
				end if;
			end if;
		end if;
	end process;

	--
	-- Recieve from Serial port
	--
	process( CLK, RST ) begin
		if( RST='0' ) then
			IREQ<='0';
			RXEN<='0';
		elsif( CLK'event and CLK='1' ) then
			if( IACK='1' ) then
				IREQ<='0';
			end if;
			RXIN<=RXIN(1 downto 0)&(not RXD);
			if( RXIN="111" and RXEN='0' ) then
				RXEN<='1';
				RCTR<=(others=>'0');
				RDAT<="0111111111"; -- start bit
			elsif( RXEN='1' ) then
				if( RCTR=715 ) then -- 4800bps for 48Mhz not 50Mhz 744
					RCTR<=(others=>'0');
					RDAT<=RXD&RDAT(9 downto 1);
				else
					RCTR<=RCTR+1;
					if( RDAT(0)='0' and RDAT(9)='1' ) then
						RXEN<='0';
						IREQ<='1';
						RDAT0<=RDAT(8 downto 1);
					end if;
				end if;
			end if;
		end if;
	end process;

	--
	-- Genarate bit by SHARP PWM
	--
	process( CLK, RST ) begin
		if( RST='0' ) then
			BP<='0';
			BBUSY<='0';
		elsif( CLK'event and CLK='1' ) then
			if( WS='1' ) then
				if( PID=X"02" ) then -- set '0'/'1' from kcpsm
					BP<=PO(7);
					BBUSY<='1';
					BCTR<=(others=>'0');
				elsif( PID=X"04" ) then -- reset counter
					BBUSY<='0';
					BCTR<=(others=>'0');
				end if;
			end if;
			if( BBUSY='1' and MOTOR='1' ) then
				if( BCTR=0 ) then
					RBIT<='1';
				elsif( BCTR=766 and BP='0' ) then
					RBIT<='0';
				elsif( BCTR=1507 and BP='1' ) then
					RBIT<='0';
				end if;
				if( ( BCTR=1533 and BP='0' ) or ( BCTR=3040 and BP='1' ) ) then
					BCTR<=(others=>'0');
					BBUSY<='0';
				else
					BCTR<=BCTR+1;
				end if;
			end if;
		end if;
	end process;

	--
	-- Buffer RAM
	--
	WEN<='1' when WS='1' and PID=X"05" else '0';
	process( CLK, RST ) begin
		if( RST='0' ) then
			WADDR<=(others=>'0');
			RADDR<=(others=>'0');
		elsif( CLK'event and CLK='1' ) then
			if( WS='1' ) then
				if( PID=X"05" ) then
					WADDR<=WADDR+1;
				elsif( PID=X"04" ) then
					WADDR<=(others=>'0');
					RADDR<=(others=>'0');
				end if;
			elsif( RS='1' and PID=X"05" ) then
				RADDR<=RADDR+1;
			end if;
		end if;
	end process;
	XWADDR<=WADDR(10 downto 5)&(not WADDR(4 downto 0));
	XRADDR<=RADDR(10 downto 5)&(not RADDR(4 downto 0));

   RAMB16_S9_S9_inst : RAMB16_S9_S9
   generic map (
      INIT_A => X"000", --  Value of output RAM registers on Port A at startup
      INIT_B => X"000", --  Value of output RAM registers on Port B at startup
      SRVAL_A => X"000", --  Port A ouput value upon SSR assertion
      SRVAL_B => X"000", --  Port B ouput value upon SSR assertion
      WRITE_MODE_A => "READ_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      WRITE_MODE_B => "READ_FIRST"  --  WRITE_FIRST, READ_FIRST or NO_CHANGE
   )
   port map (
      DOA => open,      -- Port A 8-bit Data Output
      DOB => BUFO,      -- Port B 8-bit Data Output
      DOPA => open,    -- Port A 1-bit Parity Output
      DOPB => open,    -- Port B 1-bit Parity Output
      ADDRA => XWADDR,  -- Port A 11-bit Address Input
      ADDRB => XRADDR,  -- Port B 11-bit Address Input
      CLKA => CLK,    -- Port A Clock
      CLKB => CLK,    -- Port B Clock
      DIA => PO,      -- Port A 8-bit Data Input
      DIB => (others=>'0'),      -- Port B 8-bit Data Input
      DIPA => (others=>'0'),    -- Port A 1-bit parity Input
      DIPB => (others=>'0'),    -- Port-B 1-bit parity Input
      ENA => '1',      -- Port A RAM Enable Input
      ENB => '1',      -- PortB RAM Enable Input
      SSRA => '0',    -- Port A Synchronous Set/Reset Input
      SSRB => '0',    -- Port B Synchronous Set/Reset Input
      WEA => WEN,      -- Port A Write Enable Input
      WEB => '0'       -- Port B Write Enable Input
   );

end Behavioral;
