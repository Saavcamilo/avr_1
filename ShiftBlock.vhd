library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Shift Block (ALU)
--
--  This is an implementation of a ShiftBlock. It implements possible rotation
--  operations depending on the ALUOp passed into the block. Each bit has a 
--  mux that will select which direction to shift. Thus, a 2 bit op code 
--  corresponds to a different shift operation. Left shift operations are 
--  omitted as they correspond to a add to self operation.
--
--  Opcodes | Operation
--  "00"    | Swap Nibbles
--  "01"    | Arithmetic Shift Right
--  "10"    | Logical Shift Right 
--  "11"    | Rotate Right
--
--  Inputs:
--      ALUOp         - 2bit Vector encodes which type of shift/rotation to prfrm.
--      A             - Operand that will be shifted/rotated.
--      CarryFlag     - CarryFlag is used in several shift operations
--
--  Outputs:
--      Q             - Result of the shift/rot from the ALU operation
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--      4 Feb 17  Camilo Saavedra     Changed bit codes to match control 
--                                    control 
--     10 Feb 17  Camilo Saavedra     Updated comments
----------------------------------------------------------------------------
entity ShiftBlock is
    port(
        ALUOp:     in  std_logic_vector(1 downto 0);
        A:         in  std_logic_vector(7 downto 0);
        CarryIn:   in std_logic;
        CarryOut:  out std_logic;
        Q:         out std_logic_vector(7 downto 0)
    );
end ShiftBlock; 
---------------------------------------------
architecture ControlFlow of ShiftBlock is  
begin
    GEN_SHIFT: 
    for I in 0 to 7 generate
        
        Lower_Bit: if I = 0 Generate
    Q(I) <= A(4)      when ALUOp(1 downto 0) = "00" else
            A(1)      when ALUOp(1 downto 0) = "01" else
            A(1)      when ALUOp(1 downto 0) = "10" else
            A(1)      when ALUOp(1 downto 0) = "11";
        end generate Lower_bit;
		  
        Middle_Bits1: if I > 0 and I < 4 Generate
    Q(I) <= A(I+4) when ALUOp(1 downto 0) = "00" else
		    A(I+1) when ALUOp(1 downto 0) = "01" else
            A(I+1) when ALUOp(1 downto 0) = "10" else
            A(I+1) when ALUOp(1 downto 0) = "11";
        end generate Middle_Bits1;
        
        Middle_Bits2: if I > 3 and I < 7 Generate
    Q(I) <= A(I-4) when ALUOp(1 downto 0) = "00" else
		    A(I+1) when ALUOp(1 downto 0) = "01" else
            A(I+1) when ALUOp(1 downto 0) = "10" else
            A(I+1) when ALUOp(1 downto 0) = "11";
        end generate Middle_Bits2;
		  
        High_Bits: if I = 7 Generate
    Q(I) <= A(3)     when ALUOp = "00" else
            A(I)       when ALUOp = "01" else
            '0'       when ALUOp = "10" else
            CarryIn        when ALUOp = "11";
    End generate High_Bits;
		  
    end generate GEN_SHIFT;
    
        CarryOut  <= A(0)   when ALUOp(1 downto 0) = "01" else
                     A(0)   when ALUOp(1 downto 0) = "10" else
                     A(0)   when ALUOp(1 downto 0) = "11" else
                     CarryIn;
        
end architecture;