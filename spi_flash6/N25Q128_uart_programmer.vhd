--
-- KCPSM6 reference design - PicoBlaze performing programming of SPI Flash Memory
-- type N25Q128 from Micron.
--
-- Design tested on the Spartan-6 MicroBoard (Revision B)
--
-- Original design for the Spartan-3E starter kit using a M25P16
-- Ken Chapman - Xilinx Ltd - 2nd November 2005
--
-- The JTAG loader utility is also available for rapid program development.
--
-- The design is set up for a 66.67MHz system clock and UART communications of 115200 baud
-- 8-bit, no parity, 1 stop-bit. IMPORTANT note: Soft flow control XON/XOFF is used.
--
-- Kees van Egmond - Silica - 20th December 2011
-- Modified design for Spartan-6
-- Developed and tested with ISE 13.3
-- Comunication tested on LX9 MicroBoard
-- SPI erasing / programming / reading tested using Tera Term 4.69
------------------------------------------------------------------------------------
--
-- NOTICE:
--
-- Copyright Xilinx, Inc. 2005.   This code may be contain portions patented by other 
-- third parties.  By providing this core as one possible implementation of a standard,
-- Xilinx is making no representation that the provided implementation of this standard 
-- is free from any claims of infringement by any third party.  Xilinx expressly 
-- disclaims any warranty with respect to the adequacy of the implementation, including 
-- but not limited to any warranty or representation that the implementation is free 
-- from claims of any third party.  Furthermore, Xilinx is providing this core as a 
-- courtesy to you and suggests that you contact all third parties to obtain the 
-- necessary rights to use this implementation.
--
------------------------------------------------------------------------------------
--
-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
-- The module defines some of the logic using Xilinx primitives.
-- These ensure predictable synthesis results and maximise the density of the implementation. 
-- The Unisim Library is used to define Xilinx primitives. It is also used during
-- simulation. The source can be viewed at %XILINX%\vhdl\src\unisims\unisim_VCOMP.vhd
-- 
library unisim;
use unisim.vcomponents.all;
--
------------------------------------------------------------------------------------
--
--
entity spi_N25Q128_programmer is
    Port (              tx : out std_logic;
                        rx : in std_logic;
                   spi_sck : out std_logic;
                   spi_sdo : in std_logic;
                   spi_sdi : out std_logic;
				  spi_hold : out std_logic;
                spi_rom_cs : out std_logic;
                       clk : in std_logic);
    end spi_N25Q128_programmer;
--
------------------------------------------------------------------------------------
--
-- Start of test architecture
--
architecture Behavioral of spi_N25Q128_programmer is
--
------------------------------------------------------------------------------------

--
-- declaration of KCPSM6
--
  component kcpsm6 
    generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                    interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
             scratch_pad_memory_size : integer := 64);
    port (                   address : out std_logic_vector(11 downto 0);
                         instruction : in std_logic_vector(17 downto 0);
                         bram_enable : out std_logic;
                             in_port : in std_logic_vector(7 downto 0);
                            out_port : out std_logic_vector(7 downto 0);
                             port_id : out std_logic_vector(7 downto 0);
                        write_strobe : out std_logic;
                      k_write_strobe : out std_logic;
                         read_strobe : out std_logic;
                           interrupt : in std_logic;
                       interrupt_ack : out std_logic;
                               sleep : in std_logic;
                               reset : in std_logic;
                                 clk : in std_logic);
  end component;

--
-- declaration of program memory
--

  component spi_prog                             
    generic(             C_FAMILY : string := "S6"; 
                C_RAM_SIZE_KWORDS : integer := 1;
             C_JTAG_LOADER_ENABLE : integer := 0);
    Port (      address : in std_logic_vector(11 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                 enable : in std_logic;
                    rdl : out std_logic;                    
                    clk : in std_logic);
  end component;
	 
--
-- declaration of UART transmitter with integral 16 byte FIFO buffer
-- supports the XON/XOFF flow control through signal buffer_data_present.
--  
  component uart_tx6
    Port (              data_in : in std_logic_vector(7 downto 0);
                   buffer_write : in std_logic;
                   buffer_reset : in std_logic;
                   en_16_x_baud : in std_logic;
                     serial_out : out std_logic;
            buffer_data_present : out std_logic;
                    buffer_full : out std_logic;
               buffer_half_full : out std_logic;
                            clk : in std_logic);
    end component;
--
-- declaration of UART Receiver with integral 16 byte FIFO buffer
--
  component uart_rx6
    Port (            serial_in : in std_logic;
                       data_out : out std_logic_vector(7 downto 0);
                    buffer_read : in std_logic;
                   buffer_reset : in std_logic;
                   en_16_x_baud : in std_logic;
            buffer_data_present : out std_logic;
                    buffer_full : out std_logic;
               buffer_half_full : out std_logic;
                            clk : in std_logic);
  end component;
--
------------------------------------------------------------------------------------
--
-- Signals used to connect KCPSM6 to program ROM and I/O logic
--
signal  address         : std_logic_vector(11 downto 0);
signal  instruction     : std_logic_vector(17 downto 0);
signal  port_id         : std_logic_vector(7 downto 0);
signal  out_port        : std_logic_vector(7 downto 0);
signal  in_port         : std_logic_vector(7 downto 0);
signal  write_strobe    : std_logic;
signal  read_strobe     : std_logic;
signal  bram_enable     : std_logic;
signal  interrupt       : std_logic :='0';
signal  interrupt_ack   : std_logic;
signal  rdl             : std_logic;
--
-- Signals for connection of peripherals
--
signal      status_port : std_logic_vector(7 downto 0);
--
--
-- Signals for UART connections
--
signal       baud_count : integer range 0 to 35 :=0;
signal     en_16_x_baud : std_logic;
signal    write_to_uart : std_logic;
signal  tx_data_present : std_logic;
signal          tx_full : std_logic;
signal     tx_half_full : std_logic;
signal   read_from_uart : std_logic;
signal          rx_data : std_logic_vector(7 downto 0);
signal  rx_data_present : std_logic;
signal          rx_full : std_logic;
signal     rx_half_full : std_logic;
--
--
-- Signals used to generate interrupt 
--
signal previous_rx_half_full : std_logic;
signal    rx_half_full_event : std_logic;
--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Start of circuit description
--
begin
--
------------------------------------------------------------------------------------------------------------------------------------
-- KCPSM6 and the program memory 
----------------------------------------------------------------------------------------------------------------------------------
--
processor: kcpsm6
  generic map (                 hwbuild => X"00", 
                       interrupt_vector => X"3FF",
                scratch_pad_memory_size => 64)
  port map(      address => address,
             instruction => instruction,
             bram_enable => bram_enable,
                 port_id => port_id,
            write_strobe => write_strobe,
          k_write_strobe => open,
                out_port => out_port,
             read_strobe => read_strobe,
                 in_port => in_port,
               interrupt => interrupt,
           interrupt_ack => interrupt_ack,
                   sleep => '0',
                   reset => rdl,
                     clk => clk);

  program_rom: spi_prog                          --Name to match the PSM file
    generic map(             C_FAMILY => "S6",   --Family 'S6', 'V6' or '7S'
                    C_RAM_SIZE_KWORDS => 1,      --Program size '1', '2' or '4'
                 C_JTAG_LOADER_ENABLE => 0)      --Include JTAG Loader when set to '1' 
    port map(      address => address,      
               instruction => instruction,
                    enable => bram_enable,
                       rdl => rdl,
                       clk => clk);

--
-----------------------------------------------------------------
-- Always set the hold pin high to bring the flash device out of 
-- tri-state HOLD mode.
   spi_hold <= '1';

--
----------------------------------------------------------------------------------------------------------------------------------
-- Interrupt 
----------------------------------------------------------------------------------------------------------------------------------
--
--
-- Interrupt is used to detect when the UART receiver FIFO reaches half full and this is 
-- then used to send XON and XOFF flow control characters back to the PC.
--
-- If 'rx_half_full' goes High, an interrupt is generated and the subsequent ISR will transmit
-- an XOFF character to stop the flow of new characters from the PC and allow the FIFO to start to empty.
--
-- If 'rx_half_full' goes Low, an interrupt is generated and the subsequent ISR will transmit
-- an XON character which will allow the PC to send new characters and allow the FIFO to start to fill.
--

  interrupt_control: process(clk)
  begin
    if clk'event and clk='1' then

      -- detect change in state of the 'rx_half_full' flag.
      previous_rx_half_full <= rx_half_full; 
      rx_half_full_event <= previous_rx_half_full xor rx_half_full; 

      -- processor interrupt waits for an acknowledgement
      if interrupt_ack='1' then
         interrupt <= '0';
        elsif rx_half_full_event='1' then
         interrupt <= '1';
        else
         interrupt <= interrupt;
      end if;

    end if; 
  end process interrupt_control;

--
----------------------------------------------------------------------------------------------------------------------------------
-- KCPSM6 input ports 
----------------------------------------------------------------------------------------------------------------------------------
--
--
-- UART FIFO status signals to form a bus
--

  status_port <= "00" & rx_full & rx_half_full & rx_data_present & tx_full & tx_half_full & tx_data_present;

--
-- The inputs connect via a pipelined multiplexer
--

  input_ports: process(clk)
  begin
    if clk'event and clk='1' then

      case port_id(1 downto 0) is

        
        -- read status signals at address 00 hex
        when "00" =>    in_port <= status_port;

        -- read UART receive data at address 01 hex
        when "01" =>    in_port <= rx_data;

        -- read SPI data input SDO at address 02 hex
        -- called SDO because it connects to the data outputs of the slave device (bit 7) 
        when "10" =>    in_port <= spi_sdo & "0000000";

        -- Don't care used for all other addresses to ensure minimum logic implementation
        when others =>    in_port <= "XXXXXXXX";  

      end case;

      -- Form read strobe for UART receiver FIFO buffer at address 01 hex.
      -- The fact that the read strobe will occur after the actual data is read by 
      -- the KCPSM6 is acceptable because it is really means 'I have read you'!
 
      if (read_strobe='1' and port_id(1 downto 0)="01") then 
        read_from_uart <= '1';
       else 
        read_from_uart <= '0';
      end if;

    end if;

  end process input_ports;


--
----------------------------------------------------------------------------------------------------------------------------------
-- KCPSM6 output ports 
----------------------------------------------------------------------------------------------------------------------------------
--

-- adding the output registers to the processor
   
  output_ports: process(clk)
  begin

    if clk'event and clk='1' then
      if write_strobe='1' then

        -- Write to SPI data output at address 04 hex.
        -- called SDI because it connects to the data inputs of all the slave devices

        if port_id(2)='1' then
          spi_sdi <= out_port(7);
        end if;

        -- Write to SPI control at address 08 hex.

        if port_id(3)='1' then
          spi_sck <= out_port(0);
          spi_rom_cs <= out_port(1);
        end if;

      end if;

    end if; 

  end process output_ports;

--
-- write to UART transmitter FIFO buffer at address 10 hex.
-- This is a combinatorial decode because the FIFO is the 'port register'.
--

  write_to_uart <= '1' when (write_strobe='1' and port_id(4)='1') else '0';


--
----------------------------------------------------------------------------------------------------------------------------------
-- UART  
----------------------------------------------------------------------------------------------------------------------------------
--
-- Connect the 8-bit, 1 stop-bit, no parity transmit and receive macros.
-- Each contains an embedded 16-byte FIFO buffer.
--

  transmit: uart_tx6 
  port map (              data_in => out_port, 
                     buffer_write => write_to_uart,
                     buffer_reset => '0',
                     en_16_x_baud => en_16_x_baud,
                       serial_out => tx,
              buffer_data_present => tx_data_present,
                      buffer_full => tx_full,
                 buffer_half_full => tx_half_full,
                              clk => clk );

  receive: uart_rx6
  port map (            serial_in => rx,
                         data_out => rx_data,
                      buffer_read => read_from_uart,
                     buffer_reset => '0',
                     en_16_x_baud => en_16_x_baud,
              buffer_data_present => rx_data_present,
                      buffer_full => rx_full,
                 buffer_half_full => rx_half_full,
                              clk => clk );  
--
-----------------------------------------------------------------------------------------
-- RS232 (UART) baud rate 
-----------------------------------------------------------------------------------------  
--
-- To set serial communication baud rate to 115,200 then en_16_x_baud must pulse 
-- High at 1,843,200Hz which is every 26.04 cycles at 66.67MHz. In this implementation 
-- a pulse is generated every 26 cycles resulting is a baud rate of 115,741 baud which
-- is only 0.47% high and well within limits.
--

  baud_rate: process(clk)
  begin
    if clk'event and clk = '1' then
      if baud_count = 26 then                    -- counts 35 states including zero
        baud_count <= 0;
        en_16_x_baud <= '1';                     -- single cycle enable pulse
      else
        baud_count <= baud_count + 1;
        en_16_x_baud <= '0';
      end if;
    end if;
  end process baud_rate;

--
----------------------------------------------------------------------------------------------------------------------------------

end Behavioral;

------------------------------------------------------------------------------------------------------------------------------------
--
-- END OF FILE N25Q128_uart_programmer.vhd
--
------------------------------------------------------------------------------------------------------------------------------------

