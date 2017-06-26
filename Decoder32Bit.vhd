---------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

----------------------------------------------------------------------------
--
--  32 Bit Decoder
--
--  This is an implementation of a 32 bit decoder. It takes as input a 
--  5 bit bus and decodes it into a 32 bit bus, with the value of the 
--  input determining which bit is set. The decoder also has an enable
--  signal. If the enable signal is not active, then the decoder 
--  outputs all zeroes. 
--
--  Inputs:
--      En            - Bit must be high to enable decoding
--      Sel           - 5 bit bus determines which bit is active
--
--  Outputs:
--      Q             - 32 bit output with the selected bit set 
--                    - high and all other bits set low.
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------

entity Decoder32Bit is
    port(
        En:      in  std_logic;
        Sel:     in  std_logic_vector(4  downto 0);
        
        Q:       out std_logic_vector(31 downto 0)
        );
end entity;
----------------------------------------------------------------    
architecture DataFlow of Decoder32Bit is
begin
    process(Sel, En)
    begin
        Q <= "00000000000000000000000000000000";
        if (En = '1') then
            case Sel is 
                when "00000" =>  Q  <= "00000000000000000000000000000001";
                when "00001" =>  Q  <= "00000000000000000000000000000010";
                when "00010" =>  Q  <= "00000000000000000000000000000100";
                when "00011" =>  Q  <= "00000000000000000000000000001000";
                when "00100" =>  Q  <= "00000000000000000000000000010000";
                when "00101" =>  Q  <= "00000000000000000000000000100000";
                when "00110" =>  Q  <= "00000000000000000000000001000000";
                when "00111" =>  Q  <= "00000000000000000000000010000000";
                when "01000" =>  Q  <= "00000000000000000000000100000000";
                when "01001" =>  Q  <= "00000000000000000000001000000000";
                when "01010" =>  Q  <= "00000000000000000000010000000000";
                when "01011" =>  Q  <= "00000000000000000000100000000000";
                when "01100" =>  Q  <= "00000000000000000001000000000000";
                when "01101" =>  Q  <= "00000000000000000010000000000000";
                when "01110" =>  Q  <= "00000000000000000100000000000000";
                when "01111" =>  Q  <= "00000000000000001000000000000000";
                when "10000" =>  Q  <= "00000000000000010000000000000000";
                when "10001" =>  Q  <= "00000000000000100000000000000000";
                when "10010" =>  Q  <= "00000000000001000000000000000000";
                when "10011" =>  Q  <= "00000000000010000000000000000000";
                when "10100" =>  Q  <= "00000000000100000000000000000000";
                when "10101" =>  Q  <= "00000000001000000000000000000000";
                when "10110" =>  Q  <= "00000000010000000000000000000000";
                when "10111" =>  Q  <= "00000000100000000000000000000000";
                when "11000" =>  Q  <= "00000001000000000000000000000000";
                when "11001" =>  Q  <= "00000010000000000000000000000000";
                when "11010" =>  Q  <= "00000100000000000000000000000000";
                when "11011" =>  Q  <= "00001000000000000000000000000000";
                when "11100" =>  Q  <= "00010000000000000000000000000000";
                when "11101" =>  Q  <= "00100000000000000000000000000000";
                when "11110" =>  Q  <= "01000000000000000000000000000000";
                when "11111" =>  Q  <= "10000000000000000000000000000000";
                when others  =>  Q  <= "00000000000000000000000000000000";
				end case;
			end if;
    end process;
end architecture;