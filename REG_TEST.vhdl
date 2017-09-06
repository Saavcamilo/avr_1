----------------------------------------------------------------------------
--
--  Atmel AVR Register Array Test Entity Declaration
--
--  This is the entity declaration which must be used for building the
--  register array portion of the AVR design for testing.
--
--  Revision History:
--     17 Apr 98  Glen George       Initial revision.
--     20 Apr 98  Glen George       Fixed minor syntax bugs.
--     22 Apr 02  Glen George       Updated comments.
--     18 Apr 04  Glen George       Updated comments and formatting.
--     21 Jan 06  Glen George       Updated comments.
--     14 Feb 17  Anant Desai 		Added Control Unit and Register components
--
----------------------------------------------------------------------------


--
--  REG_TEST
--
--  This is the register array testing interface.  It just brings all the
--  important register array signals out for testing along with the
--  Instruction Register.
--
--  Inputs:
--    IR      - Instruction Register (16 bits)
--    RegIn   - input to the register array (8 bits)
--    clock   - the system clock
--
--  Outputs:
--    RegAOut - register bus A output (8 bits), eventually will connect to ALU
--    RegBOut - register bus B output (8 bits), eventually will connect to ALU
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;


entity  REG_TEST  is

    port(
        IR       :  in  opcode_word;                        -- Instruction Register
        RegIn    :  in  std_logic_vector(7 downto 0);       -- input register bus
        clock    :  in  std_logic;                          -- system clock
        RegAOut  :  out std_logic_vector(7 downto 0);       -- register bus A out
        RegBOut  :  out std_logic_vector(7 downto 0)        -- register bus B out
    );

end  REG_TEST;


architecture TB_ARCHITECTURE of REG_TEST is

    -- Component declaration of the tested unit

Component  RegisterArray  is

    port(
        clock    :  in  std_logic;                          -- system clock
        Enable   :  in  std_logic;                          -- Enables the registers 
        Selects  :  in  std_logic_vector(4 downto 0);       -- Selects output register
        RegIn    :  in  std_logic_vector(7 downto 0);       -- input register bus
        RegASel  :  in  std_logic_vector(4 downto 0);
        RegBSel  :  in  std_logic_vector(4 downto 0);
        RegAOut  :  out std_logic_vector(7 downto 0);       -- register bus A out
        RegBOut  :  out std_logic_vector(7 downto 0)        -- register bus B out
    );
end  Component;


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
    signal OperandSel : std_logic_vector(9 downto 0);
	signal Flag      :  std_logic_vector(7 downto 0);      -- Flag inputs    
    signal FlagMask  :  std_logic_vector(7 downto 0);      -- Flag Mask
    signal Constants :  std_logic_vector(7 downto 0);      -- Immediate value
    
    signal IRQ       :  std_logic_vector(7 downto 0);   
    signal Fetch     :  std_logic;
    signal StackOperation : std_logic_vector(7 downto 0);
    signal RegisterEn     : std_logic;
    signal RegisterSel    : std_logic_vector(4 downto 0);
    signal RegisterASel   : std_logic_vector(4 downto 0);
    signal RegisterBSel   : std_logic_vector(4 downto 0);
    signal ReadWrite      : std_logic;
	
	
begin

    -- Unit Under Test port map
    UUT : RegisterArray       port map  (
				clock => clock, Enable => RegisterEn, Selects => RegisterSel,
				RegIn => RegIn, RegASel => RegisterASel, RegBSel => RegisterBSel,
                RegAOut => RegAOut, RegBOut => RegBOut
        );

    Controller : ControlUnit  port map (
            clock => clock, InstructionOpcode => IR, Flags => Flag,
            IRQ => IRQ, FetchIR => Fetch, StackOperation => StackOperation, RegisterEn => RegisterEn,
            RegisterSel => RegisterSel, RegisterASel => RegisterASel, 
            RegisterBSel => RegisterBSel, OpSel => OperandSel, FlagMask => FlagMask,
            Immediate => Constants, ReadWrite => ReadWrite
    );
	
end TB_ARCHITECTURE;









