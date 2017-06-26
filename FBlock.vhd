library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  F Block (ALU)
--
--  This is an implementation of an FBlock. It implements different types
--  of logical operations through the use of a mux. The inputs are used assert
--  the select signal, so any 2 bit function can be implemented by chosing the 
--  ALUOp input accordingly. 

--  Inputs:
--      ALUOp         - 4-bit Vector encodes the logic function to perform.
--      A             - Operand 1 used in the logical function
--      B             - Operand 2 used in the logical function
--
--  Outputs:
--      Q             - Result of the logical operation
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------
entity FBlock is
    port(
        ALUOp: in  std_logic_vector(3 downto 0);
        A:     in  std_logic_vector(7 downto 0);
        B:     in  std_logic_vector(7 downto 0);
        
        Q:     out std_logic_vector(7 downto 0)
    );
end FBlock; 
---------------------------------------------
architecture ControlFlow of FBlock is   
begin
   -- Generate 8 4:1 muxes that use the opcodes as inputs and 
   -- the inputs as the select signals. 
   GEN_MUX: 
   for I in 0 to 7 generate
    Q(I) <= ALUOp(0) when A(I) = '0' and B(I) = '0' else
            ALUOp(1) when A(I) = '0' and B(I) = '1' else
            ALUOp(2) when A(I) = '1' and B(I) = '0' else
            ALUOp(3) when A(I) = '1' and B(I) = '1';
   end generate GEN_MUX;
end architecture;