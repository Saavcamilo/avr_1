-----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------
--
--  32 Byte Mux
--
--  This is an implementation of a 32 bit decoder. It takes 32 bytes as 
--  input and a select signal to chose which byte to output. 
--
--  Inputs:
--      D0-D31        - 32 bytes are passed as input, and the mux 
--                    - selects one of the bytes to output. 
--      Sel           - 5 bit bus determines which byte to output
--
--  Outputs:
--      Q             - One of the input bytes is output from the 
--                      Mux.
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--      5 Feb 17  Camilo Saavedra     Updated comments
----------------------------------------------------------------------------

entity Mux8Bit is
    port(
    -- 32 8 bit inputs
        D0, D1, D2, D3, D4, D5:      in  std_logic_vector(7 downto 0);
        D6, D7, D8, D9, D10:         in  std_logic_vector(7 downto 0);
        D11, D12, D13, D14, D15:     in  std_logic_vector(7 downto 0);
        D16, D17, D18, D19, D20:     in  std_logic_vector(7 downto 0);
        D21, D22, D23, D24, D25:     in  std_logic_vector(7 downto 0);
        D26, D27, D28, D29, D30:     in  std_logic_vector(7 downto 0);
        D31:                         in  std_logic_vector(7 downto 0);
        Sel:                         in  std_logic_vector(4 downto 0);
 
        Q:                           out std_logic_vector(7 downto 0)
    );
end Mux8Bit; 

architecture ControlFlow of Mux8Bit is 
begin
    -- Mux is a large when/else statement that will chose which 
    -- byte to output depending on the 5 bit input select signal.
    Q <=    D0  when Sel = "00000" else
            D1  when Sel = "00001" else
            D2  when Sel = "00010" else
            D3  when Sel = "00011" else
            D4  when Sel = "00100" else
            D5  when Sel = "00101" else
            D6  when Sel = "00110" else
            D7  when Sel = "00111" else
            D8  when Sel = "01000" else
            D9  when Sel = "01001" else
            D10 when Sel = "01010" else
            D11 when Sel = "01011" else
            D12 when Sel = "01100" else
            D13 when Sel = "01101" else
            D14 when Sel = "01110" else
            D15 when Sel = "01111" else
            D16 when Sel = "10000" else
            D17 when Sel = "10001" else
            D18 when Sel = "10010" else
            D19 when Sel = "10011" else
            D20 when Sel = "10100" else
            D21 when Sel = "10101" else
            D22 when Sel = "10110" else
            D23 when Sel = "10111" else
            D24 when Sel = "11000" else
            D25 when Sel = "11001" else
            D26 when Sel = "11010" else
            D27 when Sel = "11011" else
            D28 when Sel = "11100" else
            D29 when Sel = "11101" else
            D30 when Sel = "11110" else
            D31 when Sel = "11111";
end architecture;
---------------------------------------------------------------