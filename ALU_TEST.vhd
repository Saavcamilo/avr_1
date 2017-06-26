----------------------------------------------------------------------------
--
--  Atmel AVR ALU Test Entity Declaration
--
--  This is the entity declaration which must be used for building the ALU
--  portion of the AVR design for testing.
--
--  Revision History:
--     17 Apr 98  Glen George       Initial revision.
--     20 Apr 98  Glen George       Fixed minor syntax bugs.
--     18 Apr 04  Glen George       Updated comments and formatting.
--     21 Jan 06  Glen George       Updated comments.
--     14 Feb 17  Anant Desai 		Added Control Unit and ALU components
--
----------------------------------------------------------------------------


--
--  ALU_TEST
--
--  This is the ALU testing interface.  It just brings all the important
--  ALU signals out for testing along with the Instruction Register.
--
--  Inputs:
--    IR       - Instruction Register (16 bits)
--    OperandA - first operand to ALU (8 bits) - looks like the output
--               of the register array
--    OperandB - second operand to ALU (8 bits) - looks like the output
--               of the register array
--    clock    - the system clock
--
--  Outputs:
--    Result   - result of the ALU operation selected by the Instruction
--               Register (8 bits)
--    StatReg  - Status Register contents (8 bits)
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;


entity  ALU_TEST  is


end  ALU_TEST;




architecture TB_ARCHITECTURE of ALU_TEST is

    -- Component declaration of the tested unit
Component ALU is
    port(
        OperandSel:  in  std_logic_vector(9 downto 0);      -- Operand select
        Flag      :  in  std_logic_vector(7 downto 0);      -- Flag inputs  
        FlagMask  :  in  std_logic_vector(7 downto 0);      -- Flag Mask
        OperandA  :  in  std_logic_vector(7 downto 0);      -- first operand
        OperandB  :  in  std_logic_vector(7 downto 0);      -- second operand
        Immediate :  in  std_logic_vector(7 downto 0);

        Output    :  out std_logic_vector(7 downto 0);      -- ALU result
        StatReg   :  out std_logic_vector(7 downto 0)       -- status register
    );
end Component;

Component ControlUnit is
    port(
        clock            :  in  std_logic;
        InstructionOpCode :  in  opcode_word; 
        Flags            :  in  std_logic_vector(7 downto 0);	
        IRQ 			 :  in  std_logic_vector(7 downto 0);	
        FetchIR          :  out std_logic; 

        StackOperation   : out    std_logic_vector(7 downto 0);
        RegisterEn       : out    std_logic;
		RegisterSel	 : out 	  std_logic_vector(4 downto 0);
        RegisterASel     : out    std_logic_vector(4 downto 0);
		RegisterBSel     : out    std_logic_vector(4 downto 0);
        OpSel	    	 : out    std_logic_vector(9 downto 0);
        FlagMask         : out    std_logic_vector(7 downto 0);
        Immediate        : out    std_logic_vector(7 downto 0);
        ReadWrite 	     : out    std_logic	
    );
end component;

  Component StatusRegister is
	port(
        Clock     :     in   std_logic;
        StatusIn  :     in   std_logic_vector(7 downto 0) := "00000000";
        FlagsOut  :     out  std_logic_vector(7 downto 0)
    );
end Component;

    signal clock : std_logic;
    signal OperandSel : std_logic_vector(9 downto 0);
	signal Flag      :  std_logic_vector(7 downto 0) := "00000000";  -- Flag inputs    
    signal FlagMask  :  std_logic_vector(7 downto 0);      -- Flag Mask
    signal Constants :  std_logic_vector(7 downto 0);      -- Immediate value
	signal StatRegOut : std_logic_vector(7 downto 0);
    signal IRQ       :  std_logic_vector(7 downto 0);   
    signal Fetch     :  std_logic;
    signal StackOperation : std_logic_vector(7 downto 0);
    signal RegisterEn     : std_logic;
    signal RegisterSel    : std_logic_vector(4 downto 0);
    signal RegisterASel   : std_logic_vector(4 downto 0);
    signal RegisterBSel   : std_logic_vector(4 downto 0);
    signal ReadWrite      : std_logic;

    signal OperandA : std_logic_vector(7 downto 0);
    signal OperandB : std_logic_vector(7 downto 0);
    signal IR : opcode_word;   
    signal Result : std_logic_vector(7 downto 0); 
    signal StatReg : std_logic_vector(7 downto 0);


begin

    -- Unit Under Test port map
    UUT : ALU        port map  (
				OperandSel => OperandSel, Flag => Flag, FlagMask => FlagMask,
				OperandA => OperandA, OperandB => OperandB, Immediate => Constants,
                Output => Result, StatReg => StatRegOut
        );

    Controller : ControlUnit  port map (
            clock => clock, InstructionOpcode => IR, Flags => Flag,
            IRQ => IRQ, FetchIR => Fetch, StackOperation => StackOperation, RegisterEn => RegisterEn,
            RegisterSel => RegisterSel, RegisterASel => RegisterASel, 
            RegisterBSel => RegisterBSel, OpSel => OperandSel, FlagMask => FlagMask,
            Immediate => Constants, ReadWrite => ReadWrite
    );
	
	  StatRegister : StatusRegister port map (
	 	Clock => clock, StatusIn => StatRegOut, FlagsOut => Flag
	  );

    CLK: process
    begin
        clock <= '1';
        wait for 5 ns; -- define a clock
        clock <= '0';
        wait for 5 ns;
    end process CLK;

    process
    begin

        -- wait a little for propagation delays

  end process;
    StatReg <= Flag;


end TB_ARCHITECTURE;










