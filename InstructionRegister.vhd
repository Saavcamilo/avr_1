library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Stack Pointer Register (SP)
--
--  This is an implementation of the stack pointer for an AVR CPU. It 
--  holds the current address of the stack pointer and controls whether
--  the stack pointer should be incremented or decremented based on 
--  the StackOp input, which is driven by a pushPop signal.
--
--  Inputs:
--      Clock            - the system clock
--      IRin
--      En
--  Outputs:
--      IRout            - contains the address of the program counter after 
--                         the branch or skip instruction
--
--  Revision History:
--     7  Aug 17  Anant Desai     Initial revision.
--
----------------------------------------------------------------------------
entity InstructionRegister is                  --entity declaration  
    port(
        Clock          :     in   std_logic;   -- System Clock 
        En             :     in   std_logic;
        IRin           :     in   std_logic_vector(15 downto 0);
        IRout          :     out  std_logic_vector(15 downto 0)
    );
end InstructionRegister; 
---------------------------------------------
architecture ControlFlow of InstructionRegister is

signal output: std_logic_vector(15 downto 0) := "0000000000000000";

begin 

    process(Clock)
    begin
        if rising_edge(Clock) and (En = '1') then --Rising edge and enable 
            Output <= IRin;                               -- signal is asserted
        end if;
    end process;
    IRout <= Output;


end architecture;