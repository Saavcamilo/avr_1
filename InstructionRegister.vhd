library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Instruction Register (IR)
--
--  This is an implementation of the instruction register for an AVR CPU. It 
--  holds the instruction fetched off of the program data bus that is being 
--  executed.
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
        clk            :     in   std_logic;   -- System Clock 
        En             :     in   std_logic;
        IRin           :     in   std_logic_vector(15 downto 0);
        IRout          :     out  std_logic_vector(15 downto 0)
    );
end InstructionRegister; 
---------------------------------------------
architecture ControlFlow of InstructionRegister is

signal output: std_logic_vector(15 downto 0) := "0000000000000000";

begin 

    process(clk)
    begin
        if rising_edge(clk) and (En = '1') then --Rising edge and enable 
            Output <= IRin;                               -- signal is asserted
        end if;
    end process;
    IRout <= Output;


end architecture;