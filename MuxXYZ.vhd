-----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------
--
--  XYZ register Mux
--
--  This is an implementation of a 2 bit decoder. It takes 4 bytes as 
--  input and a select signal to chose which 2 bytes to output of registers X, Y
--  or Z. 
--
--  Inputs:
--      D0-D3         - 4 bytes are passed as input, and the mux 
--                    - selects one of the XYZ registers to output. 
--      Sel           - 2 bit bus determines which byte to output
--      En            - indicates whether output bus should be updated with new
--                      register or not
--
--  Outputs:
--      Q             - One of the input bytes is output from the 
--                      Mux.
--
--  Revision History:
--      6 Mar 17  Anant Desai     Initial revision.
----------------------------------------------------------------------------

entity MuxXYZ is
    port(
    -- 6 8 bit inputs
        D26, D27, D28, D29, D30:     in  std_logic_vector(7 downto 0);
        D31:                         in  std_logic_vector(7 downto 0);
        Sel:                         in  std_logic_vector(1 downto 0);
        En:                          in  std_logic;
        Q:                           out std_logic_vector(15 downto 0)
    );
end MuxXYZ; 

architecture ControlFlow of MuxXYZ is 
begin
    process(Sel, En)
    begin
    -- Mux is a large when/else statement that will chose which 
    -- byte to output depending on the 2 bit input select signal.

    if (En = '1') then
        case Sel is 

            when "00" => Q(7 downto 0) <= D26
            when "01" => Q(7 downto 0) <= D28
            when "10" => Q(7 downto 0) <= D30
            when others => Q(7 downto 0) <= "UUUUUUUU";

            when "00" => Q(15 downto 8) <= D27
            when "01" => Q(15 downto 8) <= D29
            when "10" => Q(15 downto 8) <= D31
            when others => Q(15 downto 8) <= "UUUUUUUU";

    end if;
    end process;

            
end architecture;
---------------------------------------------------------------