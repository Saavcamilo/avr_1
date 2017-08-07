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
entity ProgramMemoryAccessUnit is
    port(
        InputAddress:   in   std_logic_vector(15 downto 0);
        Clock     :     in   std_logic; 
        CondOffset:     in   std_logic_vector(5 downto 0);
        AddrOpSel :     in   std_logic_vector(2 downto 0);
        ProgDB    :     inout   std_logic_vector(7 downto 0);
        
        ProgAB    :     out   std_logic_vector(15 downto 0);
        NewAddr   :     out   std_logic_vector(15 downto 0)        );
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
ProgAB  <=    AddedAddr when AddrOpSel(2) = '1' else
			  ConstAddr when AddrOpSel(1) = '1' else
			  AddedAddr when AddrOpSel(0) = '1' else
              InputAddress; 
-- THe NewAddr is always the address post arithmetic.              
NewAddr <=    AddedAddr;              
    
end architecture;