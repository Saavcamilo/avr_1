----------------------------------------------------------------------------
--
--  Test Bench for BCD2Binary8
--
--  This is a test bench for the BCD2Binary8 entity.  The test bench
--  thoroughly tests the entity by exercising it and checking the outputs.
--  All possible valid 8-bit BCD values are generated and tested.  The test
--  bench entity is called bcd2binary8_tb and it is currently defined to test
--  the DataFlow architecture of the BCD2Binary8 entity.
--
--  Revision History:
--      4/4/00   Automated/Active-VHDL    Initial revision.
--      4/4/00   Glen George              Modified to add documentation and
--                                           more extensive testing.
--     11/21/05  Glen George              Updated comments and formatting.
--
----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;


entity AVR_tb_reg is
end AVR_tb_reg;

architecture TB_ARCHITECTURE of AVR_tb_reg is

    -- Component declaration of the tested unit

Component  RegisterArray  is

    port(
        clock    :  in  std_logic;                          -- system clock
        Enable   :  in  std_logic;                          -- Enables the registers 
        UseImmed :  in  std_logic;

        Selects  :  in  std_logic_vector(4 downto 0);       -- Selects output register
        RegASel  :  in  std_logic_vector(4 downto 0);
        RegBSel  :  in  std_logic_vector(4 downto 0);
        Input    :  in  std_logic_vector(7 downto 0);       -- input register bus
        Immediate:  in  std_logic_vector(7 downto 0);

        RegAOut  :  inout std_logic_vector(7 downto 0);       -- register bus A out
        RegBOut  :  inout std_logic_vector(7 downto 0)        -- register bus B out
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
    

    signal clock     :  std_logic;
    signal FetchedInstruction : opcode_word;
    signal IRQ       :  std_logic_vector(7 downto 0);   
    signal Fetch     :  std_logic;
    signal StackOperation : std_logic_vector(7 downto 0);
    signal RegisterEn     : std_logic;
    signal RegisterSel    : std_logic_vector(4 downto 0);
    signal RegisterASel   : std_logic_vector(4 downto 0);
    signal RegisterBSel   : std_logic_vector(4 downto 0);
    signal ReadWrite      : std_logic;

    signal RegVal    :  std_logic_vector(7 downto 0);
    signal ResultA   :  std_logic_vector(7 downto 0);     
    signal ResultB   :  std_logic_vector(7 downto 0);


begin

    -- Unit Under Test port map
    UUT : RegisterArray       port map  (
				clock => clock, Enable => RegisterEn, UseImmed => '0', Selects => RegisterSel,
				RegASel => RegisterASel, RegBSel => RegisterBSel, Input => RegVal,
            Immediate => Constants,
            RegAOut => ResultA, RegBOut => ResultB
        );

    Controller : ControlUnit  port map (
            clock => clock, InstructionOpcode => FetchedInstruction, Flags => Flag,
            IRQ => IRQ, FetchIR => Fetch, StackOperation => StackOperation, RegisterEn => RegisterEn,
            RegisterSel => RegisterSel, RegisterASel => RegisterASel, 
            RegisterBSel => RegisterBSel, OpSel => OperandSel, FlagMask => FlagMask,
            Immediate => Constants, ReadWrite => ReadWrite
    );

    CLK: process
    begin
        clock <= '1';
        wait for 5 ns; -- define a clock
        clock <= '0';
        wait for 5 ns;
    end process CLK;
	  		  
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
    RegVal <= "01110001";
    FetchedInstruction <= "1001010110100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 119 in r27
    RegVal <= "01110111";
    FetchedInstruction <= "1001010110110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 44 in r28
    RegVal <= "00101100";
    FetchedInstruction <= "1001010111000101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 45 in r29
    RegVal <= "00101101";
    FetchedInstruction <= "1001010111010101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 111 in r30
    RegVal <= "01101111";
    FetchedInstruction <= "1001010111100101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;

    -- put 112 in r31
    RegVal <= "01110000";
    FetchedInstruction <= "1001010111110101";
    wait for 25 ns;
    FetchedInstruction <= "0001010000000001";
    wait for 15 ns;
	 
	 -- test instruction ASR
        FetchedInstruction <= "1001010000000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000000")) report "ASR Result 1"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

		  FetchedInstruction <= "1001010000010101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000001")) report "ASR Result 2"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000100101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "ASR Result 3"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000110101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000011")) report "ASR Result 4"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

		
        -- test instruction LSR
        FetchedInstruction <= "1001010001000110";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "LSR Result 1"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010001010110";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00001000")) report "LSR Result 2"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010001100110";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00001010")) report "LSR Result 3"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010001110110";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000000")) report "LSR Result 4"; -- check alu shift result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

		  
		  -- test instruction ROR
        FetchedInstruction <= "1001010010000111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00001111")) report "ROR Result 1"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010010010111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00010000")) report "ROR Result 2"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010010100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00100000")) report "ROR Result 3"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010010110111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01000000")) report "ROR Result 4"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction SWAP
        FetchedInstruction <= "1001010011000010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10000000")) report "SWAP Result 1"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010011010010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "SWAP Result 2"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010011100010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000000")) report "SWAP Result 3"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010011110010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000001")) report "SWAP Result 4"; -- check alu rotate result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;



        -- test instruction ADC
        FetchedInstruction <= "0001111100000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "ADC Result 1"; -- check alu ADC result
        assert (std_match(ResultB, "00000011")) report "ADC Result 2"; -- check alu ADC result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001111100100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "ADC Result 3"; -- check alu ADC result
        assert (std_match(ResultB, "10101010")) report "ADC Result 4"; -- check alu ADC result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001111101000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "ADC Result 5"; -- check alu ADC result
        assert (std_match(ResultB, "11110000")) report "ADC Result 6"; -- check alu ADC result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001111101100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10100000")) report "ADC Result 7"; -- check alu ADC result
        assert (std_match(ResultB, "10000000")) report "ADC Result 8"; -- check alu ADC result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction ADD
        FetchedInstruction <= "0000111100000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "ADD Result 1"; -- check alu ADD result
        assert (std_match(ResultB, "00000011")) report "ADD Result 2"; -- check alu ADD result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000111100100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "ADD Result 3"; -- check alu ADD result
        assert (std_match(ResultB, "10101010")) report "ADD Result 4"; -- check alu ADD result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000111101000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "ADD Result 5"; -- check alu ADD result
        assert (std_match(ResultB, "11110000")) report "ADD Result 6"; -- check alu ADD result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000111101100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10100000")) report "ADD Result 7"; -- check alu ADD result
        assert (std_match(ResultB, "10000000")) report "ADD Result 8"; -- check alu ADD result
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction CP
        FetchedInstruction <= "0001011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "CP Result 1"; 
        assert (std_match(ResultB, "00110100")) report "CP Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "CP Result 3"; 
        assert (std_match(ResultB, "01110111")) report "CP Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "CP Result 5"; 
        assert (std_match(ResultB, "00101101")) report "CP Result 6"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "CP Result 7"; 
        assert (std_match(ResultB, "01110000")) report "CP Result 8"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction CPC
        FetchedInstruction <= "0000011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "CPC Result 1"; 
        assert (std_match(ResultB, "00110100")) report "CPC Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "CPC Result 3"; 
        assert (std_match(ResultB, "01110111")) report "CPC Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "CPC Result 5"; 
        assert (std_match(ResultB, "00101101")) report "CPC Result 6"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "CPC Result 7"; 
        assert (std_match(ResultB, "01110000")) report "CPC Result 8"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction CPI
        FetchedInstruction <= "0011011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "CPI Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0011011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "CPI Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0011011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "CPI Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0011011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "CPI Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction DEC
        FetchedInstruction <= "1001010000001010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000000")) report "DEC Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000011010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000001")) report "DEC Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000101010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "DEC Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000111010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000011")) report "DEC Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction INC
        FetchedInstruction <= "1001010000000011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000000")) report "DEC Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000010011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000001")) report "DEC Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "DEC Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010000110011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000011")) report "DEC Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction SBC
        FetchedInstruction <= "0000101100000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "SBC Result 1"; 
        assert (std_match(ResultB, "00000011")) report "SBC Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000101100100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "SBC Result 3"; 
        assert (std_match(ResultB, "10101010")) report "SBC Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000101101000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "SBC Result 5"; 
        assert (std_match(ResultB, "11110000")) report "SBC Result 6"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0000101101100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10100000")) report "SBC Result 7"; 
        assert (std_match(ResultB, "10000000")) report "SBC Result 8";
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;



        -- test instruction SBCI
        FetchedInstruction <= "0100011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "SBCI Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0100011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "SBCI Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0100011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "SBCI Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0100011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "SBCI Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction SUB
        FetchedInstruction <= "0001101100000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "SUB Result 1";
        assert (std_match(ResultB, "00000011")) report "SUB Result 2";
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001101100100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "SUB Result 3";
        assert (std_match(ResultB, "10101010")) report "SUB Result 4";
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001101101000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "SUB Result 5";
        assert (std_match(ResultB, "11110000")) report "SUB Result 6";
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0001101101100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10100000")) report "SUB Result 7";
        assert (std_match(ResultB, "10000000")) report "SUB Result 8";
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;



        -- test instruction SUBI
        FetchedInstruction <= "0101011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "SUBI Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0101011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "SUBI Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0101011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "SUBI Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0101011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "SUBI Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction NEG
        FetchedInstruction <= "1001010011000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultB, "10000000")) report "NEG Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010011010001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultB, "11111111")) report "NEG Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010011100001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultB, "00000000")) report "NEG Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010011110001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultB, "00000001")) report "NEG Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction AND
        FetchedInstruction <= "0010001110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "AND Result 1"; 
        assert (std_match(ResultB, "00110100")) report "AND Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010001110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "AND Result 3"; 
        assert (std_match(ResultB, "01110111")) report "AND Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010001111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "AND Result 5"; 
        assert (std_match(ResultB, "00101101")) report "AND Result 6"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010001111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "AND Result 7"; 
        assert (std_match(ResultB, "01110000")) report "AND Result 8"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;



        -- test instruction ANDI
        FetchedInstruction <= "0111011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "ANDI Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0111011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "ANDI Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0111011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "ANDI Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0111011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "ANDI Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction COM
        FetchedInstruction <= "1001010010000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00001111")) report "COM Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010010010000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00010000")) report "COM Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010010100000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00100000")) report "COM Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "1001010010110000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01000000")) report "COM Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;


        -- test instruction EOR
        FetchedInstruction <= "0010011100000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "EOR Result 1"; 
        assert (std_match(ResultB, "00000011")) report "EOR Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010011100100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "EOR Result 3"; 
        assert (std_match(ResultB, "10101010")) report "EOR Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010011101000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "EOR Result 5"; 
        assert (std_match(ResultB, "11110000")) report "EOR Result 6"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010011101100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10100000")) report "EOR Result 7"; 
        assert (std_match(ResultB, "10000000")) report "EOR Result 8"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;



        -- test instruction OR
        FetchedInstruction <= "0010101100000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000010")) report "OR Result 1"; 
        assert (std_match(ResultB, "00000011")) report "OR Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010101100100011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00000100")) report "OR Result 3"; 
        assert (std_match(ResultB, "10101010")) report "OR Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010101101000101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "11111111")) report "OR Result 5"; 
        assert (std_match(ResultB, "11110000")) report "OR Result 6"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0010101101100111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "10100000")) report "OR Result 7"; 
        assert (std_match(ResultB, "10000000")) report "OR Result 8"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;



        -- test instruction ORI
        FetchedInstruction <= "0110011110001001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00110011")) report "ORI Result 1"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0110011110101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01110001")) report "ORI Result 2"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0110011111001101";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "00101100")) report "ORI Result 3"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;

        FetchedInstruction <= "0110011111101111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(ResultA, "01101111")) report "ORI Result 4"; 
		  FetchedInstruction <= "0001010000000001";
        wait for 5 ns;
        
		  

        end process; -- end of stimulus process
	 
end TB_ARCHITECTURE;