library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  AddressAdder (AddressAdder)
--
--  This is an implementation of an 8 Bit Adder/Subtractor. It takes in the
--  two operands and a subtract signal that tells the block whether to add 
--  the two operands, or whether to subtract OperandB from OperandA. The
--  block also takes in a CarryIn, and outputs a CarryOut. 
--
--  Inputs:
--      Cin              - Possible carry bit input for the system
--      Subtract         - Bit is low for addition, high for subtraction
--      A                - First operand of Adder/Subtractor
--      B                - Second operand of Adder/Subtractor.
--
--  Outputs:
--      Sum              - Result of the operation for Adder/Subtractor
--      Cout             - Carry flag of the highest bit operation
--      HalfCarry        - Carry out of bit 3 into bit 4
--      Overflow         - Cout Xor with carry out of bit 7. 
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------
entity AddressAdder is
    port(
        Subtract:  in  std_logic;
        A:   in  std_logic_vector(15 downto 0);
        B:    in  std_logic_vector(5 downto 0);
        
        LogicAddress: out std_logic_vector(15 downto 0)
    );
end AddressAdder; 
---------------------------------------------
architecture ControlFlow of AddressAdder is
    -- Carry bus will store the output for the nth bit addition.
    Signal CarryBus: std_logic_vector(16 downto 0);
begin
    CarryBus(0) <= '0'; --Generate the lowest carry to be CarryIn.
    --Generate the 8 bit adders to create the adders,
    GEN_ADDER: 
    for I in 0 to 15 generate
        Lower_Bits: if I <6 Generate
            LogicAddress(I) <= A(I) xor B(I) xor CarryBus(I);
            CarryBus(I+1) <=  (((A(I) xor Subtract) and B(I)) or ((A(I) xor Subtract) and CarryBus(I))
                                or (B(I) and CarryBus(I)));
        end generate Lower_bits;  
        
        Higher_Bits: if I > 5 Generate
            LogicAddress(I) <= A(I) xor CarryBus(I);
            CarryBus(I+1) <=  ((A(I) xor Subtract) and CarryBus(I));
        end generate Higher_Bits;            
		  
    end generate GEN_ADDER;
end architecture;