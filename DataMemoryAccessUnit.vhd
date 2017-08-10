library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Data Memory Access Unit (DMA U)
--
--  This is an implementation of the data memory access unit in a AVR CPU.
--  It generates the waveforms necessary to access external memory, and 
--  it translates logical addresses to physical address, which are then
--  output. The regular read and write take 2 cycles, with some constant
--  operations taking 3 clocks. The timin is managed by a finite state
--  machine to ensure the necessary waveforms to access memory.
--
--  Inputs:
--      Clock            - System Clock.
--      InputAddress     - Logical address which CPU is trying to access
--                       - which is 16 bits
--      WrIn             - Write signal, active low
--      RdIn             - Read signal, active low
--      Offset           - Address offset from input address used in 
--                         certain operations.
--      ProgDB           - Data bus containing full address in STS and
--                       - LDS instructions.
--      AddrOpSel        - 3 bit code used to determine which operation
--                         the DMA is performing.
--      DataDB           - 8 bit data bus
--
--  Outputs:
--      DataAB           - Data address bus that is output
--      NewAddr          - Updated address for post/pre increment
--                       - instructions.
--      DataWr           - The write signal that is actually output
--                       - to the physical memory
--      DataRd           - The read signal that is output to the 
--                         actual memory.
--
--  Revision History:
--     31 Mar 17  Camilo Saavedra     Initial revision.
--     4  Jun 17  Camilo Saavedra     Fixed error with the FSM that controls 
--                                    the signals
--     5  Jul 17  Camilo Saavedra     Fixed bug
----------------------------------------------------------------------------
entity DataMemoryAccessUnit is
    port(
        InputAddress:   in   std_logic_vector(15 downto 0);
        Clock     :     in   std_logic;
        WrIn      :     in   std_logic;
        RdIn      :     in   std_logic; 
        Offset    :     in   std_logic_vector(5 downto 0);
        ProgDB    :     in   std_logic_vector(15 downto 0);
        AddrOpSel :     in   std_logic_vector(2 downto 0);
        StackOp   :     in   std_logic_vector(1 downto 0);
        SP        :     in   std_logic_vector(7 downto 0);
        DataDB    :     inout   std_logic_vector(7 downto 0);
        
        DataAB    :     out   std_logic_vector(15 downto 0);
        NewAddr   :     out   std_logic_vector(15 downto 0);
        DataWr    :     out   std_logic;
        DataRd    :     out   std_logic
        );
end DataMemoryAccessUnit; 
---------------------------------------------

architecture state_machine of DataMemoryAccessUnit is

-- An Address Adder is used to perform address arithmetic 
Component AddressAdder is
    port(
        Subtract:  in  std_logic;
        A:   in  std_logic_vector(15 downto 0);
        B:    in  std_logic_vector(5 downto 0);
        
        LogicAddress: out std_logic_vector(15 downto 0)
		  
    );
end Component;
-- States of the FSM simply store the state of the access
    type state is (
        CLK1,
        CLK2,
        CLK3
    );     
    signal CurrentState, NextState: state;
-- Need to keep tract of the different address sources to 
-- mux them depending on the desired operation. 
	 signal ConstAddr: std_logic_vector(15 downto 0);
    signal AddedAddr: std_logic_vector(15 downto 0);
begin

AddrAdder: AddressAdder PORT MAP(
    Subtract => AddrOpSel(0), A => InputAddress, B => Offset, 
    LogicAddress => AddedAddr);
-- Mux the actual address output depending on the bits in 
-- AddrOpSel
DataAB  <=    AddedAddr when AddrOpSel(2) = '1' else
			  ConstAddr when AddrOpSel(1) = '1' else
			  AddedAddr when AddrOpSel(0) = '1' else
              InputAddress; 
-- THe NewAddr is always the address post arithmetic.              
NewAddr <=    AddedAddr;              
    
    transition: process(CurrentState, WrIn, RdIn, Clock)
    begin
        case CurrentState is
		      -- CLK1 acts as the idle state, transition 
				-- only when wrin or rdin signal is
				-- asserted
            when CLK1 =>
                if (WrIn = '0' or RdIn = '0') then
                    NextState <= CLK2;
                else
                    NextState <= CLK1;
                end if;
				-- Most operations are 2 clks, else, 
				-- AddrOpSel(1) is asserted
            when CLK2 =>
                if (AddrOpSel(1) = '1') then
                    NextState <= CLK3;
                else
                    NextState <= CLK1; 
                end if;
				-- Only other state is Clk3, which
				-- always transitions back to Idle
			   when others =>
				    NextState <= CLK1;
        end case;
    end process transition;

    outputs: process (Clock, CurrentState)
    begin
        case CurrentState is
		  -- DataWr/DataRd are never asserted
		  -- on the first clock, but on hte 
		  -- second half of the last clock
            when CLK1 =>
				ConstAddr <= ProgDB;
                    DataWr <= '1';
						  DataRd <= '1';
            when CLK2 =>
				    --ConstAddr is manipulated for the three cycle
					 -- instructions 
				    ConstAddr <= ConstAddr;
					 -- If clk = 0 and it is a two cycle instruction,
					 -- then we assert the wanted DataW/R signal
                if ((Clock = '0') and (AddrOpSel(1) = '0')) then 
                    DataWr <= WrIn;
                    DataRd <= RdIn;
				    else
					 -- else it is a 3 clock cycle or we are still in
					 -- the first half of the clock
                    DataWr <= '1';
						  DataRd <= '1';					 
                end if;
				when CLK3 =>
					 --ConstAddr is manipulated for the three cycle
					 -- instructions 
					 ConstAddr <= ConstAddr;
                if (Clock = '0') then 
                    DataWr <= WrIn;
                    DataRd <= RdIn;
				    else
                    DataWr <= '1';
						  DataRd <= '1';					 
                end if;		
        end case;
    end process outputs;

    storage: process (Clock)
    begin
        if (rising_edge(Clock)) then
            CurrentState <= NextState;
        end if;
    end process storage;
end architecture;