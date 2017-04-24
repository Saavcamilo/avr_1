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

--include this library for file handling in VHDL.
library std;
use std.textio.all;  --include package textio.vhd


entity  MEM_TEST  is

    port (
        IR      :  in     opcode_word;                      -- Instruction Register
        ProgDB  :  in     std_logic_vector(15 downto 0);    -- second word of instruction
        Reset   :  in     std_logic;                        -- system reset signal (active low)
        clk   :  in     std_logic;                        -- system clock
        DataAB  :  out    std_logic_vector(15 downto 0);    -- data address bus
        DataDB  :  inout  std_logic_vector(7 downto 0);     -- data data bus
        DataRd  :  out    std_logic;                        -- data read (active low)
        DataWr  :  out    std_logic                         -- data write (active low)
    );
end entity;

architecture TB_ARCHITECTURE of MEM_TEST is
component DataMemoryAccessUnit is
    port(
        InputAddress:   in   std_logic_vector(15 downto 0);
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
        Read_Mem         : out    std_logic;
        Write_Mem        : out    std_logic
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
    signal Clock: std_logic;
    signal OperandSel : std_logic_vector(9 downto 0);
    signal Flag      :  std_logic_vector(7 downto 0);      -- Flag inputs    
    signal FlagMask  :  std_logic_vector(7 downto 0);      -- Flag Mask
    signal Constants :  std_logic_vector(7 downto 0);      -- Immediate value
    signal ImmediateM : std_logic_vector(15 downto 0);     -- immediate value of
                                                             
    signal FetchedInstruction : opcode_word;
    signal IRQ       :  std_logic_vector(7 downto 0);   
    signal Fetch     :  std_logic;
    signal RegisterEn     : std_logic;
    signal RegisterSel    : std_logic_vector(4 downto 0);
    signal RegisterASel   : std_logic_vector(4 downto 0);
    signal RegisterBSel   : std_logic_vector(4 downto 0);
    signal RegisterXYZEn  : std_logic;
    signal RegisterXYZSel : std_logic_vector(1 downto 0);
    signal Read_Mem       : std_logic;
    signal Write_Mem      : std_logic;
	 signal Data_AB1  :  std_logic_vector(15 downto 0);
    signal DMAOp     :  std_logic_vector(1 downto 0);
    signal PushPop   :  std_logic_vector(1 downto 0);

    signal RegVal    :  std_logic_vector(7 downto 0);
    signal ResultA   :  std_logic_vector(7 downto 0);     
    signal ResultB   :  std_logic_vector(7 downto 0);
    signal ResultXYZ :  std_logic_vector(15 downto 0);
    signal InputXYZ  :  std_logic_vector(15 downto 0);
    signal WriteXYZ  :  std_logic;


    --period of clock,bit for indicating end of file.
    signal endoffile : bit := '0';
    --data read from the file.
    signal    dataread : std_logic_vector(31 downto 0);
    --line number of the file read or written.
    signal    linenumber : integer:=1; 
	signal    read_file  : std_logic := '0';
    signal   DataRd1 : std_logic;


begin
	DataAB <= Data_AB1;
	DataRd <= DataRd1;
    -- Unit Under Test port map
    UUT : DataMemoryAccessUnit   port map  (
        InputAddress => ResultXYZ, Clock => clock, WrIn => Write_Mem, RdIn => Read_Mem, 
        Offset => Constants(5 downto 0), ProgDB => ProgDB, AddrOpSel => DMAOp,
        DataDB => DataDB, DataAB => Data_AB1, NewAddr => InputXYZ, DataWr => DataWr,
        DataRd => DataRd1);

    Controller : ControlUnit  port map (
            clock => clock, InstructionOpcode => FetchedInstruction, Flags => Flag,
            IRQ => IRQ, FetchIR => Fetch, PushPop => PushPop, 
            RegisterEn => RegisterEn,
            RegisterSel => RegisterSel, RegisterASel => RegisterASel, 
            RegisterBSel => RegisterBSel, RegisterXYZEn => RegisterXYZEn,
            RegisterXYZSel => RegisterXYZSel, DMAOp => DMAOp, 
            OpSel => OperandSel, FlagMask => FlagMask,
            Immediate => Constants, ImmediateM => ImmediateM, Read_Mem => Read_Mem,
            Write_Mem => Write_Mem
    );

    Registers : RegisterArray       port map  (
        clock => clock, Enable => RegisterEn, UseImmed => OperandSel(0), 
        Selects => RegisterSel, RegASel => RegisterASel, RegBSel => RegisterBSel, 
        Input => RegVal, Immediate => Constants, RegXYZEn => RegisterXYZEn, 
        RegXYZSel => RegisterXYZSel, InputXYZ => InputXYZ, WriteXYZ => RegisterXYZEn,
        RegAOut => ResultA, RegBOut => ResultB, RegXYZOut => ResultXYZ
    );

    CLK_Drive: process
    begin
        clock <= '1';
        wait for 5 ns; -- define a clock
        clock <= '0';
        wait for 5 ns;
    end process CLK_Drive;
              
    reading :
    process
        file   infile    : text is in  "memInput.txt";   --declare input file
        variable  inline    : line; --line number declaration
        variable  dataread1    : bit_vector(31 downto 0);
	      

    begin
    wait until clock = '1' and clock'event and read_file = '1';
    if (not endfile(infile)) then   --checking the "END OF FILE" is not reached.
    readline(infile, inline);       --reading a line from the file.
      --reading the data from the line and putting it in a real type variable.
    read(inline, dataread1);
    dataread <= To_stdlogicvector(dataread1);   --put the value available in variable in a signal.
    else
    endoffile <='1';         --set signal to tell end of file read file is reached.
    end if;

    end process reading;






    -- now generate the stimulus and test it
    process
    begin  -- of stimulus process


    -- fill registers with values

    -- put 0 in r0
    RegVal <= "00000000";
    FetchedInstruction <= "1001010000000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 1 in r1
    RegVal <= "00000001";
    FetchedInstruction <= "1001010000010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 2 in r2
    RegVal <= "00000010";
    FetchedInstruction <= "1001010000100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 3 in r3
    RegVal <= "00000011";
    FetchedInstruction <= "1001010000110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;


     -- put 4 in r4
    RegVal <= "00000100";
    FetchedInstruction <= "1001010001000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 8 in r5
    RegVal <= "00001000";
    FetchedInstruction <= "1001010001010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 10 in r6
    RegVal <= "00001010";
    FetchedInstruction <= "1001010001100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 0 in r7
    RegVal <= "00000000";
    FetchedInstruction <= "1001010001110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;
     
     -- put 15 in r8
    RegVal <= "00001111";
    FetchedInstruction <= "1001010010000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 16 in r9
    RegVal <= "00010000";
    FetchedInstruction <= "1001010010010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 32 in r10
    RegVal <= "00100000";
    FetchedInstruction <= "1001010010100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 64 in r11
    RegVal <= "01000000";
    FetchedInstruction <= "1001010010110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 128 in r12
    RegVal <= "10000000";
    FetchedInstruction <= "1001010011000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 255 in r13
    RegVal <= "11111111";
    FetchedInstruction <= "1001010011010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 0 in r14
    RegVal <= "00000000";
    FetchedInstruction <= "1001010011100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 1 in r15
    RegVal <= "00000001";
    FetchedInstruction <= "1001010011110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 2 in r16
    RegVal <= "00000010";
    FetchedInstruction <= "1001010100000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 3 in r17
    RegVal <= "00000011";
    FetchedInstruction <= "1001010100010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 4 in r18
    RegVal <= "00000100";
    FetchedInstruction <= "1001010100100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 170 in r19
    RegVal <= "10101010";
    FetchedInstruction <= "1001010100110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 255 in r20
    RegVal <= "11111111";
    FetchedInstruction <= "1001010101000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 240 in r21
    RegVal <= "11110000";
    FetchedInstruction <= "1001010101010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 160 in r22
    RegVal <= "10100000";
    FetchedInstruction <= "1001010101100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 128 in r23
    RegVal <= "10000000";
    FetchedInstruction <= "1001010101110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 51 in r24
    RegVal <= "00110011";
    FetchedInstruction <= "1001010110000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 52 in r25
    RegVal <= "00110100";
    FetchedInstruction <= "1001010110010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 113 in r26
    RegVal <= "00000000";
    FetchedInstruction <= "1001010110100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 119 in r27
    RegVal <= "00000000";
    FetchedInstruction <= "1001010110110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 44 in r28
    RegVal <= "00000000";
    FetchedInstruction <= "1001010111000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 45 in r29
    RegVal <= "00000001";
    FetchedInstruction <= "1001010111010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 111 in r30
    RegVal <= "00000000";
    FetchedInstruction <= "1001010111100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 112 in r31
    RegVal <= "10000000";
    FetchedInstruction <= "1001010111110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    read_file <= '1';
    wait for 10 ns;
    for i in 0 to 1 loop

        FetchedInstruction <= dataread(31 downto 16);
        read_file <= '0';
        wait for 15 ns;
        read_file <= '1';
		  wait for 10 ns;
        assert (std_match(Data_AB1, dataread(15 downto 0))) report "LD" & INTEGER'IMAGE(i); -- check load instructions
        wait for 5 ns;
    end loop;





	end process;
end  architecture;