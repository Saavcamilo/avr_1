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
--     10 Aug 17  Anant Desai         Began implementing PC functionality
--     13 Aug 17  Anant Desai         Created State Machine for RET, RETI
--                                    instruction outputs
----------------------------------------------------------------------------
entity ProgramMemoryAccessUnit is
    port(
        RegZ      :     in   std_logic_vector(15 downto 0);
        Clock     :     in   std_logic;
        Reset     :     in   std_logic;
        
        Offset    :     in   std_logic_vector(11 downto 0);
        PMAOpSel  :     in   std_logic_vector(2 downto 0);

        DataDB    :     inout std_logic_vector(7 downto 0); -- needed for RET, RETI

        ProgDB    :     in   std_logic_vector(15 downto 0);
        
        ProgAB    :     out   std_logic_vector(15 downto 0) -- PC value
         
        );
end ProgramMemoryAccessUnit; 
---------------------------------------------

architecture Control_Flow of ProgramMemoryAccessUnit is

-- Need to keep tract of the different address sources to 
-- mux them depending on the desired operation. 
signal ProgramCounter : std_logic_vector(15 downto 0);
signal IncrementedPC  : std_logic_vector(15 downto 0);
signal OffsetPC       : std_logic_vector(15 downto 0);
signal NewPC          : std_logic_vector(15 downto 0);

-- An Address Adder is used to perform address arithmetic 
Component PCAddrAdder is
    port(
        A:   in  std_logic_vector(15 downto 0);
        B:   in  std_logic_vector(11 downto 0);
        
        LogicAddress: out std_logic_vector(15 downto 0)
		  
    );
end Component;

-- An Incrementer is used to increment PC by 1
Component Incrementer is
    port(
        A:   in  std_logic_vector(15 downto 0);
        B:   in  std_logic;
        
        LogicAddress: out std_logic_vector(15 downto 0)
          
    );
end Component;    


-- States of the FSM simply store the state of the access
    type state is (
        CLK1,
        CLK2
    );     
    signal CurrentState, NextState: state;


begin

PCIncrementer: Incrementer PORT MAP(
    A => ProgramCounter, B => '1', 
    LogicAddress => IncrementedPC);

PCAdder: PCAddrAdder PORT MAP(
    A => IncrementedPC, B => Offset, 
    LogicAddress => OffsetPC);


-- Mux the actual address output depending on the bits in 
-- AddrOpSel
NewPC   <=    ProgDB when PMAOpSel(2 downto 1) = "00" else
			  RegZ when PMAOpSel(2 downto 1) = "01" else
			  OffsetPC when PMAOpSel(2 downto 1) = "10" else
              -- DataDB when PMAOpSel(2 downto 1) = "11" else
              ProgramCounter; 


ProgAB <= ProgramCounter;


    transition: process(CurrentState, Clock, Reset)
    begin
        case CurrentState is
            when CLK1 =>
                IF PMAOpSel = "111" then
                    NextState <= CLK2; -- only if using RET, RETI then we need 2 
                                       -- cycles to put things on the PC
                ELSE
                    NextState <= CLK1;
                END IF;
                
            when CLK2 =>
                NextState <= CLK1;

            when others =>
                NextState <= CLK1;

        end case;
    end process transition;

    outputs: process (Clock, CurrentState, Reset)
    begin
        case CurrentState is
            when CLK1 =>
                IF Reset = '0' then -- reset ProgramCounter, IncrementedPC, OffsetPC, and NewPC
                                    -- to lowest value
                    ProgramCounter <= "0000000000000000";
                    IncrementedPC <= "0000000000000000";
                    OffsetPC <= "0000000000000000";
                    NewPC <= "0000000000000000";
                ELSIF PMAOpSel = "111" then
                    ProgramCounter(7 downto 0) <= DataDB;
                ELSIF rising_edge(Clock) and PMAOpSel(0) = '1' then
                    ProgramCounter <= NewPC;
                END IF;

            when CLK2 =>    
                ProgramCounter(15 downto 8) <= DataDB;

            when others =>
                     
        end case;
    end process outputs;

    storage: process (Clock)
    begin
        if (rising_edge(Clock)) then
            CurrentState <= NextState;
        end if;
    end process storage;



    
end architecture;