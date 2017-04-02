----------------------------------------------------------------------------
--
--  Atmel AVR Data Memory Test Entity Declaration
--
--  This is the entity declaration which must be used for building the data
--  memory access portion of the AVR design for testing.
--
--  Revision History:
--     24 Apr 98  Glen George       Initial revision.
--     25 Apr 00  Glen George       Fixed entity name and updated comments.
--      2 May 02  Glen George       Updated comments.
--      3 May 02  Glen George       Fixed Reset signal type.
--     23 Jan 06  Glen George       Updated comments.
--     21 Jan 08  Glen George       Updated comments.
--      1 Apr 17  Anant Desai       Added test vectors.
--
----------------------------------------------------------------------------


--
--  MEM_TEST
--
--  This is the data memory access testing interface.  It just brings all
--  the important data memory access signals out for testing along with the
--  Instruction Register and Program Data Bus.
--
--  Inputs:
--    IR     - Instruction Register (16 bits)
--    ProgDB - program memory data bus (16 bits)
--    Reset  - active low reset signal
--    clock  - the system clock
--
--  Outputs:
--    DataAB - data memory address bus (16 bits)
--    DataDB - data memory data bus (8 bits)
--    DataRd - data read (active low)
--    DataWr - data write (active low)
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;


entity  MEM_TEST  is

    port (
        IR      :  in     opcode_word;                      -- Instruction Register
        ProgDB  :  in     std_logic_vector(15 downto 0);    -- second word of instruction
        Reset   :  in     std_logic;                        -- system reset signal (active low)
        clock   :  in     std_logic;                        -- system clock
        DataAB  :  out    std_logic_vector(15 downto 0);    -- data address bus
        DataDB  :  inout  std_logic_vector(7 downto 0);     -- data data bus
        DataRd  :  out    std_logic;                        -- data read (active low)
        DataWr  :  out    std_logic                         -- data write (active low)
    );
end entity;

architecture TB_ARCHITECTURE of MEM_TEST is
component DMA is
    port(
        InputAddress:   in   std_logic_vector(7 downto 0);
        Clock     :     in   std_logic;
        WrIn      :     in   std_logic;
        RdIn      :     in   std_logic; 
        Offset    :     in   std_logic_vector(5 downto 0);
        ProgDB    :     in   std_logic_vector(15 downto 0);
        AddrOpSel :     in   std_logic_vector(1 downto 0);
        DataDB    :     inout   std_logic_vector(7 downto 0);
        
        DataAB    :     out   std_logic_vector(15 downto 0);
        NewAddr   :     out   std_logic_vector(15 downto 0);
        DataWr    :     out   std_logic;
        DataRd    :     out   std_logic
        );
end component;

Component ControlUnit is
    port (
        clock            :  in  std_logic;
        InstructionOpCode :  in  opcode_word; 
        Flags            :  in  std_logic_vector(7 downto 0);   
        IRQ              :  in  std_logic_vector(7 downto 0);   
        FetchIR          :  out std_logic; 

        PushPop          : out    std_logic_vector(1 downto 0);
        RegisterEn       : out    std_logic;
        RegisterSel      : out    std_logic_vector(4 downto 0);
        RegisterASel     : out    std_logic_vector(4 downto 0);
        RegisterBSel     : out    std_logic_vector(4 downto 0);
        RegisterXYZEn    : out    std_logic;
        RegisterXYZSel   : out    std_logic_vector(1 downto 0);
        DMAOp            : out    std_logic_vector(1 downto 0);
        OpSel            : out    std_logic_vector(9 downto 0);
        FlagMask         : out    std_logic_vector(7 downto 0);
        Immediate        : out    std_logic_vector(7 downto 0);
        ImmediateM       : out    std_logic_vector(15 downto 0);
        Read             : out    std_logic;
        Write            : out    std_logic
        );
end component;

Component  RegisterArray  is
    port(
        clock    :  in  std_logic;                          -- system clock
        Enable   :  in  std_logic;                                  -- Enables the registers 
        UseImmed :  in  std_logic;
        Selects  :  in  std_logic_vector(4 downto 0);       -- Selects output register
        RegASel  :  in  std_logic_vector(4 downto 0);
        RegBSel  :  in  std_logic_vector(4 downto 0);
        Input    :  in  std_logic_vector(7 downto 0);       -- input register bus
        Immediate:  in  std_logic_vector(7 downto 0);
        RegXYZEn :  in  std_logic;
        RegXYZSel:  in  std_logic_vector(1 downto 0);
        InputXYZ :  in  std_logic_vector(15 downto 0);
        WriteXYZ :  in  std_logic;

        RegAOut  :  out std_logic_vector(7 downto 0);       -- register bus A out
        RegBOut  :  out std_logic_vector(7 downto 0);       -- register bus B out
        RegXYZOut:  out std_logic_vector(15 downto 0)
    );
end  Component;
    
    signal OperandSel : std_logic_vector(9 downto 0);
    signal Flag      :  std_logic_vector(7 downto 0);      -- Flag inputs    
    signal FlagMask  :  std_logic_vector(7 downto 0);      -- Flag Mask
    signal Constants :  std_logic_vector(7 downto 0);      -- Immediate value
    signal ImmediateM : std_logic_vector(15 downto 0);     -- immediate value of
                                                              address for STS, LDS
    

    signal clock     :  std_logic;
    signal FetchedInstruction : opcode_word;
    signal IRQ       :  std_logic_vector(7 downto 0);   
    signal Fetch     :  std_logic;
    signal PushPop : std_logic_vector(7 downto 0);
    signal RegisterEn     : std_logic;
    signal RegisterSel    : std_logic_vector(4 downto 0);
    signal RegisterASel   : std_logic_vector(4 downto 0);
    signal RegisterBSel   : std_logic_vector(4 downto 0);
    signal RegisterXYZEn  : std_logic;
    signal RegisterXYZSel : std_logic_vector(1 downto 0);
    signal Read           : std_logic;
    signal Write          : std_logic;

    signal DMAOp     :  std_logic_vector(1 downto 0);
    signal PushPop   :  std_logic_vector(1 downto 0);

    signal RegVal    :  std_logic_vector(7 downto 0);
    signal ResultA   :  std_logic_vector(7 downto 0);     
    signal ResultB   :  std_logic_vector(7 downto 0);
    signal ResultXYZ :  std_logic_vector(15 downto 0);
    signal InputXYZ  :  std_logic_vector(15 downto 0);
    signal WriteXYZ  :  std_logic;


begin

    -- Unit Under Test port map
    UUT : DMA   port map  (
        InputAddress => ResultA, Clock => clock, WrIn => Write, RdIn => Read, 
        Offset => Constants(5 downto 0), ProgDB => ProgDB, AddrOpSel => DMAOp,
        DataDB => DataDB, DataAB => DataAB, NewAddr => InputXYZ, DataWr => DataWr
        DataRd => DataRd);

    Controller : ControlUnit  port map (
            clock => clock, InstructionOpcode => IR, Flags => Flag,
            IRQ => IRQ, FetchIR => Fetch, PushPop => PushPop, 
            RegisterEn => RegisterEn,
            RegisterSel => RegisterSel, RegisterASel => RegisterASel, 
            RegisterBSel => RegisterBSel, RegisterXYZEn => RegisterXYZEn,
            RegisterXYZSel => RegisterXYZSel, DMAOp => DMAOp, 
            OpSel => OperandSel, FlagMask => FlagMask,
            Immediate => Constants, ImmediateM => ImmediateM, Read => Read,
            Write => Write
    );

    Registers : RegisterArray       port map  (
        clock => clock, Enable => RegisterEn, UseImmed => OperandSel(0), 
        Selects => RegisterSel, RegASel => RegisterASel, RegBSel => RegisterBSel, 
        Input => RegVal, Immediate => Constants, RegXYZEn => RegisterXYZEn, 
        RegXYZSel => RegisterXYZSel, InputXYZ => InputXYZ, WriteXYZ => WriteXYZ,
        RegAOut => ResultA, RegBOut => ResultB, RegXYZOut => ResultXYZ
    );


    CLK: process
    begin
        clock <= '1';
        wait for 5 ns; -- define a clock
        clock <= '0';
        wait for 5 ns;
    end process CLK;

end  MEM_TEST;