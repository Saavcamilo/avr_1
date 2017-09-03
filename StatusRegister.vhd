library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Status Register (ALU)
--
--  This is an implementation of the status register for an AVR CPU. It 
--  holds the current status of the system by storing the flags. The 
--  implementation is an 8 bit register that updates the flags.
--
--  Inputs:
--      Clock            - the system clock
--      StatusIn         - Change in flags from ALU to update the SR.
--      FlagsOut         - First operand of Adder/Subtractor
--      B                - Second operand of Adder/Subtractor.
--
--  Outputs:
--      FlagsOut         - The status of the system is stored in 
--                         the flags from the status register. Sent 
--                         to other blocks in the system.
--
--  Revision History:
--     5 Feb 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------
entity StatusRegister is                  --entity declaration  
    port(
        clk       :     in   std_logic;   -- System Clock 
        StatusIn  :     in   std_logic_vector(7 downto 0);
        FlagsOut  :     out  std_logic_vector(7 downto 0)

    );
end StatusRegister; 
---------------------------------------------
architecture ControlFlow of StatusRegister is
    -- 8 flags stored in an 8bit register 
    component Register8Bit is
    port(
        D: in  std_logic_vector(7 downto 0);
        Q: out std_logic_vector(7 downto 0);
        En: in std_logic;
        Clock: in std_logic
    );
    end component; 
begin --8 bit register will simply store the value of flags.
    Status_Register: Register8Bit PORT MAP (
        D => StatusIn, Q => FlagsOut, En => '1', Clock => clk);
end architecture;