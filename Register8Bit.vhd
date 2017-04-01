library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  8 Bit DFF
--
--  This is an implementation of an 8 bit DFF which latches the byte and 
--  is rising edge sensitive to a clock signal.
--
--  Inputs:
--      En            - Bit must be high to enable DFF
--      D             - 8 bit input to be latched 
--      Clock         - Signal that will clock the DFF
--
--  Outputs:
--      Q             - 8 bit output latched and rising edge sensitive
--                    - to the clock signal. 
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--      5 Feb 17  Camilo Saavedra     Updated comments
----------------------------------------------------------------------------
entity Register8Bit is

    port(
        D: in  std_logic_vector(7 downto 0);
        Q: out std_logic_vector(7 downto 0);
        En: in std_logic;
        Clock: in std_logic
    );
end Register8Bit; 

architecture Register8Bit of Register8Bit is 
signal output: std_logic_vector(7 downto 0) := "00000000";
begin
    process(Clock)
    begin
        if rising_edge(Clock) and (En = '1') then --Rising edge and enable 
            Output <= D;                               -- signal is asserted
        end if;
    end process;
	 Q <= Output;
end architecture;
-----------------------------------------------------------------------