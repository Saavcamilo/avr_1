library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;

----------------------------------------------------------------------------
--
--  AVR.vhd
--
--  This is the system implementation of the AVR CPU. It interconnects the
--  main CPU components, like the ALU and the Register Array in order to 
--  create the AVR. 
--
--  Revision History:
--     25 Jan 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------
entity AVR is

    port(
        Clock: in  std_logic;
        IRIn:  in  opcode_word
    );
end AVR; 
----------------------------------------------------------------------------
architecture CPU of AVR is    
	component ALU is
		 port(
			  OperandSel:  in  std_logic_vector(9 downto 0);      -- Operand select
			  Flag      :  in  std_logic_vector(7 downto 0);      -- Flag inputs                                                        -- (size unclear)
			  FlagMask  :  in  std_logic_vector(7 downto 0);      -- Flag Mask
			  OperandA  :  in  std_logic_vector(7 downto 0);      -- first operand
			  OperandB  :  in  std_logic_vector(7 downto 0);      -- second operand

           Immediate :  in  std_logic_vector(7 downto 0);
			  Output    :  out std_logic_vector(7 downto 0);      -- ALU result
			  StatReg   :  out std_logic_vector(7 downto 0)       -- status register
		 );
    end component;
	component RegisterArray is
   port(
        clock    :  in  std_logic;                          -- system clock
        Enable   :  in  std_logic;       							-- Enables the registers 
        Selects  :  in  std_logic_vector(4 downto 0);       -- Selects output register
        RegIn    :  in  std_logic_vector(7 downto 0);       -- input register bus
        RegASel  :  in  std_logic_vector(4 downto 0);
        RegBSel  :  in  std_logic_vector(4 downto 0);
        RegAOut  :  inout std_logic_vector(7 downto 0);       -- register bus A out
        RegBOut  :  inout std_logic_vector(7 downto 0)        -- register bus B out
    );
	end  component;
	
    component ControlUnit is
    port (
        clock            :  in  std_logic;
        InstructionOpCode :  in  opcode_word; 
        Flags            :  in  std_logic_vector(7 downto 0);	
        IRQ 			 :  in  std_logic_vector(7 downto 0);	

        StackOperation   : out    std_logic_vector(7 downto 0);
        RegisterEn       : out    std_logic;
		RegisterSel	 : out 	  std_logic_vector(4 downto 0);
        RegisterASel     : out    std_logic_vector(4 downto 0);
		RegisterBSel     : out    std_logic_vector(4 downto 0);
        OpSel	    	 : out    std_logic_vector(9 downto 0);
        FlagMask         : out    std_logic_vector(7 downto 0);
        Immediate        : out    std_logic_vector(7 downto 0);
        ReadWrite 	     : out    std_logic	        );
    end component;
	 
	 component StatusRegister is 
    port(
        Clock     :     in   std_logic;
        StatusIn  :     in   std_logic_vector(7 downto 0);
        FlagsOut  :     out  std_logic_vector(7 downto 0)
		  );
    end component; 
    signal OperandSel: std_logic_vector(9 downto 0);
    signal Flags : std_logic_vector(7 downto 0);
    signal FlagMask: std_logic_vector(7 downto 0);
    signal OperandA: std_logic_vector(7 downto 0);
    signal OperandB: std_logic_vector(7 downto 0);
    signal ALU_Out: std_logic_vector(7 downto 0);
    signal StatReg: std_logic_vector(7 downto 0);    
    signal IRQ: std_logic_vector(7 downto 0);
    signal StackOperation: std_logic_vector(7 downto 0);
    signal RegisterEn: std_logic;
    signal RegisterSel: std_logic_vector(4 downto 0);
    signal RegisterASel: std_logic_vector(4 downto 0);
    signal RegisterBSel: std_logic_vector(4 downto 0);
    signal OpSel: std_logic_vector(8 downto 0);
    signal Immediate: std_logic_vector(7 downto 0);  
    signal ReadWrite: std_logic;
    
    begin
    ALU_1: ALU PORT MAP(
        OperandSel => OperandSel,
        Flag => Flags,
        FlagMask => FlagMask,
        OperandA => OperandA,
        OperandB => OperandB,
		  Immediate => Immediate,
        Output => ALU_Out,
        StatReg => StatReg);  

    ControlUnit_1: ControlUnit PORT MAP(
        Clock => Clock,
        InstructionOpCode => IRIn,
        Flags => Flags,
        IRQ => IRQ,
        StackOperation => StackOperation,
        RegisterEn => RegisterEn,
        RegisterSel => RegisterSel,
		  RegisterASel => RegisterASel,
        RegisterBSel => RegisterBSel,
        OpSel => OperandSel,
        FlagMask => FlagMask,
        Immediate => Immediate,
        ReadWrite => ReadWrite);

    RegisterArray_1: RegisterArray PORT MAP(
        clock    => Clock,                       -- system clock
        Enable   => RegisterEn,     							-- Enables the registers 
        Selects  => RegisterSel,       -- Selects output register
        RegIn    => ALU_Out,           -- input register bus
        RegASel  => RegisterASel,  
        RegBSel  => RegisterBSel,  
        RegAOut  => OperandA,       -- register bus A out
        RegBOut  => OperandB);        -- register bus B out
		  
    StatusRegister_1: StatusRegister PORT MAP(
	     clock => Clock,
		  StatusIn => StatReg,
		  FlagsOut => Flags
		  );
		  
end architecture;