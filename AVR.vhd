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

entity  AVR  is
    port (
        clk     :  in     std_logic;                        -- system clock
        RST     :  in     std_logic;                         -- Reset
		  DataDB  :  inout  std_logic_vector(7 downto 0);
		  ProgDB  :  in     opcode_word;
		  ProgAB  :  out    std_logic_vector(15 downto 0);
		  DataAB  :  out    std_logic_vector(15 downto 0);
		  DataWr  :  out    std_logic;
		  DataRd  :  out    std_logic		 
    );
end entity;

architecture System of AVR is
Component ControlUnit is
    port (
        clk               :  in    std_logic;
        InstructionOpCode :  in    opcode_word; 
        Flags             :  in    std_logic_vector(7 downto 0);    
        ZeroFlag          :  in    std_logic;
        TransferFlag      :  in    std_logic;
        IRQ               :  in    std_logic_vector(7 downto 0);
        ProgDB            :  in    std_logic_vector(15 downto 0);

        FetchIR           : out    std_logic; 
        PushPop           : out    std_logic_vector(1 downto 0);
        RegisterEn        : out    std_logic;
        RegisterSel       : out    std_logic_vector(4 downto 0);
        RegisterASel      : out    std_logic_vector(4 downto 0);
        RegisterBSel      : out    std_logic_vector(4 downto 0);
        RegisterXYZEn     : out    std_logic;
        RegisterXYZSel    : out    std_logic_vector(1 downto 0);
        RegMux            : out    std_logic_vector(2 downto 0);
        DMAOp             : out    std_logic_vector(2 downto 0);
        PMAOp             : out    std_logic_vector(2 downto 0);
        OpSel             : out    std_logic_vector(9 downto 0);
        LDRImmed          : out    std_logic;
        FlagMask          : out    std_logic_vector(7 downto 0);
        Immediate         : out    std_logic_vector(7 downto 0);
        PCoffset          : out    std_logic_vector(11 downto 0);
        Read_Mem          : out    std_logic;
        Write_Mem         : out    std_logic
        );

end component;
component DataMemoryAccessUnit is
    port(
        InputAddress:   in   std_logic_vector(15 downto 0);
        clk       :     in   std_logic;
        WrIn      :     in   std_logic;
        RdIn      :     in   std_logic; 
        Offset    :     in   std_logic_vector(5 downto 0);
        ProgAB    :     in   std_logic_vector(15 downto 0);
        ProgDB    :     in   std_logic_vector(15 downto 0);
        RegIn     :     in   std_logic_vector(7 downto 0);
        RegInEn   :     in   std_logic;
        RegMux    :     in   std_logic_vector(2 downto 0);
        AddrOpSel :     in   std_logic_vector(2 downto 0);
        StackOp   :     in   std_logic_vector(1 downto 0);
        SP        :     in   std_logic_vector(7 downto 0);

        DataDB    :     inout std_logic_vector(7 downto 0);
        DataAB    :     out   std_logic_vector(15 downto 0);
        NewAddr   :     out   std_logic_vector(15 downto 0);
        DataWr    :     out   std_logic;
        DataRd    :     out   std_logic
        );
end component;

component ProgramMemoryAccessUnit is
    port(
        RegZ      :     in   std_logic_vector(15 downto 0);
        clk       :     in   std_logic;
        Reset     :     in   std_logic;
        Offset    :     in   std_logic_vector(11 downto 0);
        PMAOpSel  :     in   std_logic_vector(2 downto 0);
        DataDB    :     in   std_logic_vector(7 downto 0); -- needed for RET, RETI
        ProgDB    :     in   std_logic_vector(15 downto 0);
        ProgAB    :     out  std_logic_vector(15 downto 0) -- PC value
    );
end component;

Component  RegisterArray  is
    port(
        clk             :  in  std_logic;                       -- system clock
        Enable          :  in  std_logic;                       -- Enables the registers 
        RegMux          :  in  std_logic_vector(2 downto 0);
        Selects         :  in  std_logic_vector(4 downto 0);    -- Selects output register
        RegASel         :  in  std_logic_vector(4 downto 0);
        RegBSel         :  in  std_logic_vector(4 downto 0);
        ALUInput        :  in  std_logic_vector(7 downto 0);    -- input register bus
        MemInput        :  in  std_logic_vector(7 downto 0);
        
        Immediate       :  in  std_logic_vector(7 downto 0);
        RegXYZEn        :  in  std_logic;
        RegXYZSel       :  in  std_logic_vector(1 downto 0);
        InputXYZ        :  in  std_logic_vector(15 downto 0);
        WriteXYZ        :  in  std_logic;

        RegAOut         :  out std_logic_vector(7 downto 0);    -- register bus A out
        RegBOut         :  out std_logic_vector(7 downto 0);    -- register bus B out
        RegXYZOut       :  out std_logic_vector(15 downto 0)
    );
end component;

Component ALU is
    port(
        OperandSel      :  in  std_logic_vector(9 downto 0);      -- Operand select
        Flag            :  in  std_logic_vector(7 downto 0);      -- Flag inputs                                                        -- (size unclear)
        FlagMask        :  in  std_logic_vector(7 downto 0);      -- Flag Mask
        OperandA        :  in  std_logic_vector(7 downto 0);      -- first operand
        OperandB        :  in  std_logic_vector(7 downto 0);      -- second operand
        Immediate       :  in  std_logic_vector(7 downto 0);      -- 8bit value can use
                                                            -- as input 
        Output          :  out std_logic_vector(7 downto 0);      -- ALU result
        StatReg         :  out std_logic_vector(7 downto 0);      -- status register
        ZeroFlag        :  out std_logic;
        TransferFlag    :  out std_logic
    );
end Component;

Component StatusRegister is                  --entity declaration  
    port(
        clk             :     in   std_logic;   -- System Clock 
        StatusIn        :     in   std_logic_vector(7 downto 0);
        FlagsOut        :     out  std_logic_vector(7 downto 0)
    );
end component;

Component InstructionRegister is                  --entity declaration  
    port(
        clk             :     in   std_logic;   -- System Clock 
        En              :     in   std_logic;
        IRin            :     in   opcode_word;
        IRout           :     out  opcode_word
    );
end component; 

Component StackPointer is               
    port(
        clk             :     in   std_logic;   -- System Clock 
        StackOp         :     in   std_logic_vector(1 downto 0);
        Reset           :     in   std_logic;
        SPout           :     out  std_logic_vector(7 downto 0)
    );
end Component;
--  ALU Signals Inputs
    signal IROutput     :    opcode_word;
    signal Flags        :    std_logic_vector(7 downto 0);
    signal ZeroFlag     :    std_logic;
    signal TransferFlag :    std_logic;
    signal IRQ          :    std_logic_vector(7 downto 0);
    signal ProgDB_in    :    std_logic_vector(7 downto 0);
    
-- Control unit signal outputs
    signal FetchIR      :    std_logic; 
    signal PushPop      :    std_logic_vector(1 downto 0);
    signal RegisterEn   :    std_logic;
    signal RegSel       :    std_logic_vector(4 downto 0);
    signal RegASel      :    std_logic_vector(4 downto 0);
    signal RegBSel      :    std_logic_vector(4 downto 0);
    signal RegXYZEn     :    std_logic;
    signal RegXYZSel    :    std_logic_vector(1 downto 0);
    signal RegMux       :    std_logic_vector(2 downto 0);
    signal LDRImmed     :    std_logic;
    
    signal DMAOp        :    std_logic_vector(2 downto 0);
    signal PMAOp        :    std_logic_vector(2 downto 0);
    signal ALUOp        :    std_logic_vector(9 downto 0);
    
    signal FlagMask     :    std_logic_vector(7 downto 0);
    signal Constants    :    std_logic_vector(7 downto 0);
    signal PCoffset     :    std_logic_vector(11 downto 0);
    signal RdIn         :    std_logic;
    signal WrIn         :    std_logic;    
    
    -- ALU Inputs
    signal ResultA      :    std_logic_vector(7 downto 0);   
    signal ResultB      :    std_logic_vector(7 downto 0);   
    -- ALU Outputs 
    signal ALUoutput    :    std_logic_vector(7 downto 0);   
    signal StatRegIn    :    std_logic_vector(7 downto 0);
    
	 -- Register Inputs
	 signal InputXYZ     :    std_logic_vector(15 downto 0);
    -- Register Outputs
    signal ResultXYZ    :    std_logic_vector(15 downto 0); 

	-- Stack Pointer
	 signal SPoutput     :    std_logic_vector(7 downto 0);
    -- Internal Buses
    signal ProgAB_int   :    std_logic_vector(15 downto 0); 
    signal ProgDB_int   :    opcode_word;
    signal DataAB_int   :    std_logic_vector(7 downto 0);
    signal DataDB_int   :    std_logic_vector(7 downto 0);
    begin
     
    StatusReg  : StatusRegister  port map (
        clk => clk, StatusIn => StatRegIn, FlagsOut => Flags
    );
    IR : InstructionRegister port map (
        clk => clk, En => FetchIR, IRin => ProgDB_int, IRout => IROutput
    ); 
    Controller : ControlUnit  port map (
        --Inputs
        clk => clk, InstructionOpcode => IROutput, Flags => Flags,
        ZeroFlag => ZeroFlag, TransferFlag => TransferFlag, 
        IRQ => IRQ, ProgDB => ProgDB_int, 
        -- Outputs
        FetchIR => FetchIR, PushPop => PushPop, RegisterEn => RegisterEn,
        RegisterSel => RegSel, RegisterASel => RegASel, 
        RegisterBSel => RegBSel, RegisterXYZEn => RegXYZEn,
        RegisterXYZSel => RegXYZSel, RegMux => RegMux, DMAOp => DMAOp, PMAOp => PMAOp, 
        OpSel => ALUop, LDRImmed => LDRImmed, FlagMask => FlagMask,
        Immediate => Constants, PCoffset => pcOffset, Read_Mem => RdIn,
        Write_Mem => WrIn
    );
    
    ALU_Unit : ALU        port map  (
        OperandSel =>  ALUop, Flag => Flags, FlagMask => FlagMask,
        OperandA => ResultA, OperandB => ResultB, Immediate => Constants,
        Output => ALUoutput, StatReg => StatRegIn, ZeroFlag => ZeroFlag, 
        TransferFlag => TransferFlag
    );
    
    Registers : RegisterArray       port map  (
        clk => clk, Enable => RegisterEn, RegMux => RegMux, 
        Selects => RegSel, RegASel => RegASel, RegBSel => RegBSel, 
        ALUInput => ALUoutput, MemInput => DataDB, Immediate => Constants, 
        RegXYZEn => RegXYZEn, 
        RegXYZSel => RegXYZSel, InputXYZ => InputXYZ, WriteXYZ => RegXYZEn,
        RegAOut => ResultA, RegBOut => ResultB, RegXYZOut => ResultXYZ
    );
    
    PMAUnit     : ProgramMemoryAccessUnit port map (
        clk => clk, RegZ => ResultXYZ, Reset => RST, Offset => pcOffset,
        PMAOpSel => PMAOp, DataDB => DataDB, ProgDB => ProgDB_int, ProgAB => ProgAB
    );


    DMAUnit : DataMemoryAccessUnit   port map  (
        clk => clk, InputAddress => ResultXYZ, WrIn => WrIn, RdIn => RdIn, 
        Offset => Constants(5 downto 0), ProgAB => ProgAB_int, ProgDB => ProgDB_int,
        RegIn => ResultA, RegInEn => RegisterEn, RegMux => RegMux, 
        AddrOpSel => DMAOp, StackOp => PushPop, SP => SPoutput,
        DataDB => DataDB, DataAB => DataAB, NewAddr => InputXYZ, DataWr => DataWr,
        DataRd => DataRd);

    Stack : StackPointer     port map  (
        clk => clk, StackOp => PushPop, 
        Reset => RST, SPout => SPoutput
    );
end architecture;