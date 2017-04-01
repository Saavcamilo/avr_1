library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  AdderBlock (ALU)
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
entity AdderBlock is
    port(
        Cin  :     in  std_logic;
        Subtract:  in  std_logic;
        A:         in  std_logic_vector(7 downto 0);
        B:         in  std_logic_vector(7 downto 0);
        
        Sum:       out std_logic_vector(7 downto 0);
        Cout :     out std_logic;
		HalfCarry: out std_logic;
        Overflow:  out std_logic
    );
end AdderBlock; 
---------------------------------------------
architecture ControlFlow of AdderBlock is
    -- Carry bus will store the output for the nth bit addition.
    Signal CarryBus: std_logic_vector(8 downto 0);
begin
    CarryBus(0) <= Cin; --Generate the lowest carry to be CarryIn.
    --Generate the 8 bit adders to create the adders,
    GEN_ADDER: 
    for I in 0 to 7 generate
        Sum(I) <= A(I) xor B(I) xor CarryBus(I);
        CarryBus(I+1) <=  (((A(I) xor Subtract) and B(I)) or ((A(I) xor Subtract) and CarryBus(I))
                          or (B(I) and CarryBus(I)));		  
    end generate GEN_ADDER;
    Cout <= CarryBus(8);  --Carryout is the last carry calculated
	HalfCarry <= CarryBus(4); --Half carry is carry out of output 3 into bit 4 
    Overflow <= CarryBus(8) xor CarryBus(7); --Overflow is carry of highbit xor with carry
                                             -- of bit 7
end architecture;