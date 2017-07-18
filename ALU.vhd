library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.all;

----------------------------------------------------------------------------
--
--  Arithmetic Logic Unit (ALU)
--
--  This is an implementation of the Arithmetic Logic Unit of an AVR CPU.  
--  This entity performs arithmetic and logical operations on two operands
--  that are passed in. It outputs the flags to the status register and the 
--  output of the operation. The ALU choses the operation to perform based 
--  on the value of the OperandSel signal.
--
--  Inputs:
--      OperandSel              - 8-bit instruction is operation the ALU will execute
--      Flag                    - Current status of the 8 flags input to ALU 
--      FlagMask                - 8-bit register masks flag changes for operation
--      OperandA                - First operand of the given operation
--      OperandB                - Second operand of the given operation.
--      Immediate               - Value that can act as the input to the ALU, use 
--                              - as input for certain instructions. 
--
--  Outputs:
--      Output                  - Result of the operation from the ALU operation
--      StatReg                 - New flag values from the operation
--
--  Revision History:
--     25 Jan 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------

entity  ALU  is

    port(
        OperandSel:  in  std_logic_vector(9 downto 0);      -- Operand select
        Flag      :  in  std_logic_vector(7 downto 0);      -- Flag inputs                                                        -- (size unclear)
        FlagMask  :  in  std_logic_vector(7 downto 0);      -- Flag Mask
        OperandA  :  in  std_logic_vector(7 downto 0);      -- first operand
        OperandB  :  in  std_logic_vector(7 downto 0);      -- second operand
		Immediate :  in  std_logic_vector(7 downto 0);      -- 8bit value can use
                                                            -- as input 
        Output    :  out std_logic_vector(7 downto 0);      -- ALU result
        StatReg   :  out std_logic_vector(7 downto 0)       -- status register
    );

end  ALU;
----------------------------------------------------------------------------
Architecture ControlFlow of ALU is
-- Actual operands are either OperandA/B, or an immediate value depending 
-- on the instruction.
signal Operand1: std_logic_vector(7 downto 0); 
signal Operand2: std_logic_vector(7 downto 0);
-- Output of the three blocks are muxed to create the actual ALU output
signal FBlockOutput: std_logic_vector(7 downto 0);
signal ShiftBlockOutput: std_logic_vector(7 downto 0);
signal AdderBlockOutput: std_logic_vector(7 downto 0);
signal Result:   std_logic_vector(7 downto 0);
-- Calc Flag is intermediate flag results that will then be masked with 
-- the flag mask to determine which masks are changed.
signal CalcFlag: std_logic_vector(7 downto 0);-- Flags that change depending on the block that calculated them.
signal ShiftCarry: std_logic;
signal AdderCarry: std_logic;
signal AdderOverflow: std_logic;
-- Negated mask is used to mask off flags that don't change.
signal NegatedMask: std_logic_vector(7 downto 0);

Component FBlock is
    port(
        ALUOp: in  std_logic_vector(3 downto 0);
        A:     in  std_logic_vector(7 downto 0);
        B:     in  std_logic_vector(7 downto 0);
        Q:     out std_logic_vector(7 downto 0)
    );
    end Component; 

Component ShiftBlock is
    port(
        ALUOp:     in  std_logic_vector(1 downto 0);
        A:         in  std_logic_vector(7 downto 0);
        CarryIn:   in std_logic;
        CarryOut:  out std_logic;
        Q:         out std_logic_vector(7 downto 0)
    );
    end Component;
    
Component AdderBlock is
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
end Component;
signal CinSum: std_logic;
begin
-- Mux the operands with Immediate or an input Operand.
CinSum     <= Flag(0) and OperandSel(1);
Operand1 <= Immediate  when OperandSel(0) = '1' and OperandSel(7) = '0' else
            Flag      when OperandSel(0) = '1' and OperandSel(7) = '1' else
            OperandA;

Operand2 <= Immediate  when OperandSel(7) = '1' else
            OperandB;

FBlock_1: FBlock PORT MAP(
    ALUOp => OperandSel(5 downto 2), A => Operand1,
    B => Operand2, Q => FBlockOutput);
   
ShiftBlock_1: ShiftBlock PORT MAP(
    ALUOp => OperandSel(3 downto 2), A => Operand1,
    CarryIn => Flag(0), CarryOut => ShiftCarry, Q => ShiftBlockOutput);

AdderBlock_1: AdderBlock PORT MAP(
    Cin => CinSum,  Subtract => OperandSel(6),
    A => Operand1, B => Operand2, Sum => AdderBlockOutput,
    Cout => AdderCarry, HalfCarry => CalcFlag(5), Overflow => AdderOverflow);
	 
-- Mux the Result depending on the OperandSel
Result <=       FBlockOutput     when OperandSel(9 downto 8) = "01" else
				ShiftBlockOutput when OperandSel(9 downto 8) = "10" else
				AdderBlockOutput when OperandSel(9 downto 8) = "11" else
				OperandA;
				
-- Mux flags that change depending on the block                 
CalcFlag(0) <= ShiftCarry when OperandSel(8) = '0' else
               '1'        when OperandSel = "0100001100" else --Calc flag is set to 0
              AdderCarry;                                     -- for COM instruction.
              
-- Zero flag is set when result is 0. It maintains its value for the second cycle of SBIW/ADIW, and of CPC if it is zero.
CalcFlag(1) <= Flag(1) when OperandSel(9 downto 8) = "11" and OperandSel(2) = '1' and Result = "00000000" else    
              '1'      when Result = "00000000" else
              '0';
              
-- Sign flag is the MSB of the result
CalcFlag(2) <= Result(7);
-- Overflow is adderoverflow when addition block is used, 0 when FBlock is used, 
-- or Carry XOR with the sign bit for shift operations.
CalcFlag(3) <= AdderOverflow when OperandSel(9 downto 8) = "11" else
              '0'            when OperandSel(9 downto 8) = "01" else
              ShiftCarry xor Result(7);
-- Negative Flag is Overflow XOR with sign bit, or just sign bit for shift.
CalcFlag(4) <= Result(7) xor AdderOverflow when OperandSel(9 downto 8) = "11" else
              Result(7)                   when OperandSel(9 downto 8) = "01" else
              ShiftCarry;
CalcFlag(6) <= '0' when OperandSel(9 downto 8) = "01" and OperandSel(0) = '0' and Result = "00000000" else
               '1' when OperandSel(9 downto 8) = "01" and OperandSel(0) = '0' else
               Flag(6);
               
CalcFlag(7) <= Flag(7);
-- Only change the flags that should be changed by masking with the FlagMask.              
NegatedMask <= not FlagMask; 
StatReg <= FBlockOutput when OperandSel(0) = '1' and OperandSel(7) = '1' else
          (FlagMask and CalcFlag) or (NegatedMask and Flag);           
Output <= Result;
end architecture;