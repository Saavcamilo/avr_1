library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Incrementer (Incrementer)
--
--  This is an implementation of an incrementer. It takes in a 15 bit input
--  and a single bit input and adds it to the 15 bits.
--
--  Inputs:
--      A                - 15 bit operand
--      B                - Single bit operand.
--
--  Outputs:
--      LogicAddress     - Result of the operation 
--
--  Revision History:
--     11 Aug 17  Anant Desai     Initial revision.
--
----------------------------------------------------------------------------
entity Incrementer is
    port(
        A:   in  std_logic_vector(15 downto 0);
        B:   in  std_logic;
        
        LogicAddress: out std_logic_vector(15 downto 0)
    );
end Incrementer; 
---------------------------------------------
architecture ControlFlow of Incrementer is
    -- Carry bus will store the output for the nth bit addition.
    Signal CarryBus: std_logic_vector(16 downto 0);
begin
    CarryBus(0) <= '0'; --Generate the lowest carry to be CarryIn.
    --Generate the 8 bit adders to create the adders,
    GEN_ADDER: 
    for I in 0 to 15 generate
        Lower_Bits: if I <1 Generate
            LogicAddress(I) <= A(I) xor B xor CarryBus(I);
            CarryBus(I+1) <=  ((A(I) and B) or (A(I) and CarryBus(I))
                                or (B and CarryBus(I)));
        end generate Lower_bits;  
        
        Higher_Bits: if I > 0 Generate
            LogicAddress(I) <= A(I) xor CarryBus(I);
            CarryBus(I+1) <=  (A(I) and CarryBus(I));
        end generate Higher_Bits;            
		  
    end generate GEN_ADDER;
end architecture;