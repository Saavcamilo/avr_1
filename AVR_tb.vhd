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


entity AVR_tb is
end AVR_tb;

architecture TB_ARCHITECTURE of AVR_tb is

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
    port (
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
    signal OperandA  :  std_logic_vector(7 downto 0);      -- first operand
    signal OperandB  :  std_logic_vector(7 downto 0);      -- second operand
    signal Constants :  std_logic_vector(7 downto 0);      -- Immediate value
    signal Result    :  std_logic_vector(7 downto 0);      -- ALU result
    signal StatReg   :  std_logic_vector(7 downto 0);      -- status register

    signal clock     :  std_logic;
    signal FetchedInstruction : opcode_word;
    signal IRQ       :  std_logic_vector(7 downto 0);   
    signal Fetch     :  std_logic;
    signal StackOperation : std_logic_vector(7 downto 0);
    signal RegisterEn     : std_logic;
    signal RegisterSel    : std_logic_vector(4 downto 0);
    signal RegisterASel   : std_logic_vector(4 downto 0);
    signal RegisterBSel   : std_logic_vector(4 downto 0);
    signal DMAOp          : std_logic_vector(1 downto 0);
	 signal ImmediateM     : std_logic_vector(15 downto 0);
	 signal Read           : std_logic;
	 signal Write:           std_logic;

begin

    -- Unit Under Test port map
    UUT : ALU        port map  (
				OperandSel => OperandSel, Flag => Flag, FlagMask => FlagMask,
				OperandA => OperandA, OperandB => OperandB, Immediate => Constants,
                Output => Result, StatReg => StatReg
        );

    Controller : ControlUnit  port map (
            clock => clock, InstructionOpcode => FetchedInstruction, Flags => StatReg,
            IRQ => IRQ, FetchIR => Fetch, StackOperation => StackOperation, RegisterEn => RegisterEn,
            RegisterSel => RegisterSel, RegisterASel => RegisterASel, 
            RegisterBSel => RegisterBSel, OpSel => OperandSel, FlagMask => FlagMask,
            Immediate => Constants
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


     -- test shift block


        -- test instruction ASR
        OperandA <= "00001111"; 
        FetchedInstruction <= "1001010000000101";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000111")) report "ASR Result 1"; -- check alu shift result
        assert (std_match(StatReg, "00011001")) report "ASR Flag 1"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111"; 
        FetchedInstruction <= "1001010000000101";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11000111")) report "ASR Result 1";
        assert (std_match(StatReg, "00010101")) report "ASR Flag 1"; --check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000001"; 
        FetchedInstruction <= "1001010000000101";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ASR Result 1";
        assert (std_match(StatReg, "00011011")) report "ASR Flag 1"; --check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000"; 
        FetchedInstruction <= "1001010000000101";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ASR Result 1";
        assert (std_match(StatReg, "00000010")) report "ASR Flag 1";-- check status flag updates



        -- test instruction LSR
        OperandA <= "00001111"; 
        FetchedInstruction <= "1001010000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000111")) report "LSR Result 1"; -- check alu shift result
        assert (std_match(StatReg, "00011001")) report "LSR Flag 1"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111"; 
        FetchedInstruction <= "1001010000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01000111")) report "LSR Result 1";
        assert (std_match(StatReg, "00011001")) report "LSR Flag 1"; --check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000001"; 
        FetchedInstruction <= "1001010000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "LSR Result 1";
        assert (std_match(StatReg, "00011011")) report "LSR Flag 1"; --check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000"; 
        FetchedInstruction <= "1001010000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "LSR Result 1";
        assert (std_match(StatReg, "00000010")) report "LSR Flag 1";-- check status flag updates



        -- test instruction ROR
        OperandA <= "00001111"; 
        FetchedInstruction <= "1001010000000111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000111")) report "ROR Result 1"; -- check alu shift result
        assert (std_match(StatReg, "00011001")) report "ROR Flag 1"; -- check status flag updates

        -- now wait a bit
        OperandA <= "00001111"; 
        FetchedInstruction <= "1001010000000111";
        Flag <= "00000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000111")) report "ROR Result 2"; -- check alu shift result
        assert (std_match(StatReg, "00010101")) report "ROR Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001110"; 
        FetchedInstruction <= "1001010000000111";
        Flag <= "00000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11000111")) report "ROR Result 3";
        assert (std_match(StatReg, "00001100")) report "ROR Flag 3"; --check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000001"; 
        FetchedInstruction <= "1001010000000111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ROR Result 4";
        assert (std_match(StatReg, "00011011")) report "ROR Flag 4"; --check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000"; 
        FetchedInstruction <= "1001010000000111";
        Flag <= "00000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "ROR Result 1";
        assert (std_match(StatReg, "00001100")) report "ROR Flag 1";-- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000"; 
        FetchedInstruction <= "1001010000000111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ROR Result 1";
        assert (std_match(StatReg, "00000010")) report "ROR Flag 1";-- check status flag updates



        -- test instruction SWAP
        OperandA <= "00001111"; 
        FetchedInstruction <= "1001010000000010";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11110000")); -- check alu shift result
        assert (std_match(StatReg, "00000000")); -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111"; 
        FetchedInstruction <= "1001010000000010";
        Flag <= "10101010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111000"));
        assert (std_match(StatReg, "10101010")); --check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000001"; 
        FetchedInstruction <= "1001010000000010";
        Flag <= "00111110";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00010000"));
        assert (std_match(StatReg, "00111110")); --check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000"; 
        FetchedInstruction <= "1001010000000010";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000"));
        assert (std_match(StatReg, "11111111"));-- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111"; 
        FetchedInstruction <= "1001010000000010";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111"));
        assert (std_match(StatReg, "00000000"));-- check status flag updates



    -- test logical (F) block

        -- test instruction AND
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0010000000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000110")) report "AND Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "AND Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0010000000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000110")) report "AND Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100001")) report "AND Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010000000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "AND Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "AND Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010000000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "AND Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "AND Flag 4"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010000000000001";
        Flag <= "10101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "AND Result 5";  -- check alu logical result
        assert (std_match(StatReg, "10110101")) report "AND Flag 5"; -- check status flag updates



        -- test instruction ANDI
        OperandA <= "00001111";
        FetchedInstruction <= "0111000000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000110")) report "ANDI Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "ANDI Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        FetchedInstruction <= "0111000000000110";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000110")) report "ANDI Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100001")) report "ANDI Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        FetchedInstruction <= "0111111100000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ANDI Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "ANDI Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        FetchedInstruction <= "0111111100000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "ANDI Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "ANDI Flag 4"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11110000";
        FetchedInstruction <= "0111100000001111";
        Flag <= "10101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "ANDI Result 5"; -- check alu logical result
        assert (std_match(StatReg, "10110101")) report "ANDI Flag 5"; -- check status flag updates


        -- test instruction COM
        OperandA <= "00001111";
        FetchedInstruction <= "1001010000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11110000")) report "COM Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00010101")) report "COM Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        FetchedInstruction <= "1001010000000000";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11110000")) report "COM Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11110101")) report "COM Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "1001010000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "COM Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010101")) report "COM Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "1001010000000000";
        Flag <= "10100000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "COM Result 4";  -- check alu logical result
        assert (std_match(StatReg, "10110101")) report "COM Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        FetchedInstruction <= "1001010000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "COM Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00000011")) report "COM Flag 5"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10101010";
        FetchedInstruction <= "1001010000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01010101")) report "COM Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000001")) report "COM Flag 6"; -- check status flag updates




        -- test instruction EOR
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0010010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "EOR Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "EOR Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0010010000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "EOR Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100001")) report "EOR Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "EOR Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "EOR Flag 3"; -- check status flag updates

        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0010010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "EOR Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "EOR Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01111111")) report "EOR Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "EOR Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010010000000001";
        Flag <= "10101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01111111")) report "EOR Result 6";  -- check alu logical result
        assert (std_match(StatReg, "10100001")) report "EOR Flag 6"; -- check status flag updates



        -- test instruction OR
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0010100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001111")) report "OR Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "OR Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0010100000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001111")) report "OR Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100001")) report "OR Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "OR Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "OR Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0010100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "OR Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "OR Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0010100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "OR Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "OR Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        OperandB <= "10000000";
        FetchedInstruction <= "0010100000000001";
        Flag <= "10101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10001111")) report "OR Result 6";  -- check alu logical result
        assert (std_match(StatReg, "10110101")) report "OR Flag 6"; -- check status flag updates



        -- test instruction ORI
        OperandA <= "00001111";
        FetchedInstruction <= "0110000000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001111")) report "ORI Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "ORI Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        FetchedInstruction <= "0110000000000110";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001111")) report "ORI Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100001")) report "ORI Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        FetchedInstruction <= "0110111100000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "ORI Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "ORI Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0110000000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ORI Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "ORI Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        FetchedInstruction <= "0110111100000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "ORI Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "ORI Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10001111";
        FetchedInstruction <= "0110100000000000";
        Flag <= "10101011";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10001111")) report "ORI Result 6";  -- check alu logical result
        assert (std_match(StatReg, "10110101")) report "ORI Flag 6"; -- check status flag updates





        -- test instruction ADC
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0001110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00010101")) report "ADC Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00100000")) report "ADC Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0001110000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00010110")) report "ADC Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "ADC Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0001110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "ADC Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "ADC Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0001110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ADC Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "ADC Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        OperandB <= "11111111";
        FetchedInstruction <= "0001110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01111111")) report "ADC Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00011001")) report "ADC Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01000000";
        OperandB <= "01000000";
        FetchedInstruction <= "0001110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "ADC Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00001100")) report "ADC Flag 6"; -- check status flag updates



        -- test instruction ADD
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0000110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00010101")) report "ADD Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00100000")) report "ADD Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0000110000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00010101")) report "ADD Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "ADD Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "11110000";
        FetchedInstruction <= "0000110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "ADD Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "ADD Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0000110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "ADD Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "ADD Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        OperandB <= "11111111";
        FetchedInstruction <= "0000110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01111111")) report "ADD Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00011001")) report "ADD Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01000000";
        OperandB <= "01000000";
        FetchedInstruction <= "0000110000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "ADD Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00001100")) report "ADD Flag 6"; -- check status flag updates



        -- test instruction CP
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "CP Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "CP Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        OperandB <= "00001110";
        FetchedInstruction <= "0001010000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "CP Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "CP Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000001";
        FetchedInstruction <= "0001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "CP Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "CP Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "CP Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "CP Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "CP Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "CP Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "CP Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "CP Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        OperandB <= "01111111";
        FetchedInstruction <= "0001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "CP Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "CP Flag 7"; -- check status flag updates



        -- test instruction CPC
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0000010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "CPC Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "CPC Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        OperandB <= "00001110";
        FetchedInstruction <= "0000010000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001000")) report "CPC Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "CPC Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000001";
        FetchedInstruction <= "0000010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "CPC Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "CPC Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0000010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "CPC Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "CPC Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0000010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "CPC Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "CPC Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0000010000000001";
        Flag <= "00000010";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "CPC Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "CPC Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        OperandB <= "01111111";
        FetchedInstruction <= "0000010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "CPC Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "CPC Flag 7"; -- check status flag updates



        -- test instruction CPI
        OperandA <= "00001111";
        FetchedInstruction <= "0011000000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "CPI Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "CPI Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        FetchedInstruction <= "0011000000001110";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "CPI Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "CPI Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0011000000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "CPI Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "CPI Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0011000000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "CPI Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "CPI Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        FetchedInstruction <= "0011111100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "CPI Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "CPI Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        FetchedInstruction <= "0011111100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "CPI Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "CPI Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        FetchedInstruction <= "0011011100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "CPI Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "CPI Flag 7"; -- check status flag updates



        -- test instruction DEC
        OperandA <= "00001111";
        FetchedInstruction <= "1001010000001010";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001110")) report "DEC Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "DEC Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000001";
        FetchedInstruction <= "1001010000001010";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "DEC Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100011")) report "DEC Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000001";
        FetchedInstruction <= "1001010000001010";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "DEC Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "DEC Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        FetchedInstruction <= "1001010000001010";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01111111")) report "DEC Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00011000")) report "DEC Flag 4"; -- check status flag updates


        -- test instruction INC
        OperandA <= "00001111";
        FetchedInstruction <= "1001010000000011";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00010000")) report "INC Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "INC Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        FetchedInstruction <= "1001010000000011";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "INC Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100011")) report "INC Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        FetchedInstruction <= "1001010000000011";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000001")) report "INC Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "INC Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        FetchedInstruction <= "1001010000000011";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "INC Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00001100")) report "INC Flag 4"; -- check status flag updates



        -- test instruction SBC
        wait for 5 ns;
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0000100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "SBC Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "SBC Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        OperandB <= "00001110";
        FetchedInstruction <= "0000100000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001000")) report "SBC Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "SBC Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000001";
        FetchedInstruction <= "0000100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "SBC Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "SBC Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0000100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SBC Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SBC Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0000100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "SBC Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "SBC Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0000100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SBC Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SBC Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        OperandB <= "01111111";
        FetchedInstruction <= "0000100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "SBC Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "SBC Flag 7"; -- check status flag updates



        -- test instruction SBCI
        OperandA <= "00001111";
        FetchedInstruction <= "0100000000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "SBCI Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "SBCI Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        FetchedInstruction <= "0100000000001110";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001000")) report "SBCI Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "SBCI Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0100000000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "SBCI Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "SBCI Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0100000000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SBCI Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SBCI Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        FetchedInstruction <= "0100111100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "SBCI Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "SBCI Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        FetchedInstruction <= "0100111100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SBCI Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SBCI Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        FetchedInstruction <= "0100011100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "SBCI Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "SBCI Flag 7"; -- check status flag updates


        -- test instruction SUB
        OperandA <= "00001111";
        OperandB <= "00000110";
        FetchedInstruction <= "0001100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "SUB Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "SUB Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        OperandB <= "00001110";
        FetchedInstruction <= "0001100000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "SUB Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "SUB Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000001";
        FetchedInstruction <= "0001100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "SUB Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "SUB Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        OperandB <= "00000000";
        FetchedInstruction <= "0001100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SUB Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SUB Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0001100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "SUB Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "SUB Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        OperandB <= "11111111";
        FetchedInstruction <= "0001100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SUB Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SUB Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        OperandB <= "01111111";
        FetchedInstruction <= "0001100000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "SUB Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "SUB Flag 7"; -- check status flag updates


        -- test instruction SUBI
        OperandA <= "00001111";
        FetchedInstruction <= "0101000000000110";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "SUBI Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "SUBI Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00010111";
        FetchedInstruction <= "0101000000001110";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00001001")) report "SUBI Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11100000")) report "SUBI Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0101000000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "SUBI Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "SUBI Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "0101000000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SUBI Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SUBI Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "01111111";
        FetchedInstruction <= "0101111100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "SUBI Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00001101")) report "SUBI Flag 5"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandA <= "11111111";
        FetchedInstruction <= "0101111100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SUBI Result 6";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SUBI Flag 6"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandA <= "10000000";
        FetchedInstruction <= "0101011100001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000001")) report "SUBI Result 7";  -- check alu logical result
        assert (std_match(StatReg, "00111000")) report "SUBI Flag 7"; -- check status flag updates


        -- test instruction NEG 
        OperandB <= "00001111";
        FetchedInstruction <= "1001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11110001")) report "NEG Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "NEG Flag 1"; -- check status flag updates



        -- now wait a bit
        wait for 5 ns;
        OperandB <= "10000000";
        FetchedInstruction <= "1001010000000001";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "NEG Result 2";  -- check alu logical result
        assert (std_match(StatReg, "11001101")) report "NEG Flag 2"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandB <= "00000000";
        FetchedInstruction <= "1001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "NEG Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "NEG Flag 3"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandB <= "00000001";
        FetchedInstruction <= "1001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "NEG Result 4";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "NEG Flag 4"; -- check status flag updates


        -- now wait a bit
        wait for 5 ns;
        OperandB <= "01111111";
        FetchedInstruction <= "1001010000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000001")) report "NEG Result 5";  -- check alu logical result
        assert (std_match(StatReg, "00110101")) report "NEG Flag 5"; -- check status flag updates




		-- test instruction BCLR
        FetchedInstruction <= "1001010010001000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "00000000")) report "BCLR Flag 1"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1001010010001000";
        Flag <= "00000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "00000000")) report "BCLR Flag 2"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1001010010011000";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "11111101")) report "BCLR Flag 3"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1001010010101000";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "11111011")) report "BCLR Flag 4"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1001010011111000";
        Flag <= "10000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "00000001")) report "BCLR Flag 5"; -- check status flag updates
		
		
		
		-- test instruction BLD
        FetchedInstruction <= "1111100000000000";
		OperandA <= "10000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "BLD Result 1"; -- check status flag updates
		assert (std_match(StatReg, "00000000")) report "BLD Flag 1"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1111100000000001";
		OperandA <= "00000000";
        Flag <= "01000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000010")) report "BLD Result 2"; -- check status flag updates
		assert (std_match(StatReg, "01000001")) report "BLD Flag 2"; -- check status flag updates
		wait for 100 ns;
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1111100000000111";
		OperandA <= "00000000";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "10000000")) report "BLD Result 3"; -- check status flag updates
		assert (std_match(StatReg, "11111111")) report "BLD Flag 3"; -- check status flag updates
		
		
		
		-- test instruction BSET
        FetchedInstruction <= "1001010000001000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "00000001")) report "BSET Flag 1"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1001010000001000";
        Flag <= "00000001";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "00000001")) report "BSET Flag 2"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1001010001111000";
        Flag <= "01111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "11111111")) report "BSET Flag 3"; -- check status flag updates
		
		
		
		-- test instruction BST
        FetchedInstruction <= "1111101000000000";
		OperandA <= "10000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
		assert (std_match(StatReg, "01000000")) report "BST Flag 1"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1111101000000001";
		OperandA <= "00000111";
        Flag <= "01000001";
        -- wait a little for propagation delays
        wait for 5 ns;
		assert (std_match(StatReg, "01000001")) report "BST Flag 2"; -- check status flag updates
		
		
		-- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1111101000000111";
		OperandA <= "10000000";
        Flag <= "10111111";
        -- wait a little for propagation delays
        wait for 5 ns;
		assert (std_match(StatReg, "11111111")) report "BST Flag 3"; -- check status flag updates

        -- now wait a bit
        wait for 5 ns;
        FetchedInstruction <= "1111101000000111";
        OperandA <= "00000000";
        Flag <= "11111111";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(StatReg, "10111111")) report "BST Flag 4"; -- check status flag updates
		
		
		-- test instruction SBIW
        OperandA <= "01000000";
        FetchedInstruction <= "1001011100000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "01000000")) report "SBIW Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "SBIW Flag 1"; -- check status flag updates
		Flag <= StatReg;
		wait for 10 ns;
		assert (std_match(Result, "01000000")) report "SBIW Result 1 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "SBIW Flag 1 cycle 2"; -- check status flag updates
		
		-- now wait a bit
		wait for 5 ns;
		OperandA <= "00000000";
        FetchedInstruction <= "1001011100000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "00000000")) report "SBIW Result 2";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SBIW Flag 2"; -- check status flag updates
		Flag <= StatReg;
		wait for 10 ns;
		assert (std_match(Result, "00000000")) report "SBIW Result 2 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00000010")) report "SBIW Flag 2 cycle 2"; -- check status flag updates
		
		
		-- now wait a bit
		wait for 5 ns;
		OperandA <= "00000000";
        FetchedInstruction <= "1001011100000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 5 ns;
        assert (std_match(Result, "11111111")) report "SBIW Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00010101")) report "SBIW Flag 3"; -- check status flag updates
		Flag <= StatReg;
		wait for 10 ns;
		assert (std_match(Result, "11111111")) report "SBIW Result 3 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00010101")) report "SBIW Flag 3 cycle 2"; -- check status flag updates
		
		
		
		-- test instruction ADIW
        OperandA <= "01000000";
        FetchedInstruction <= "1001011000000000";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 6 ns;
        assert (std_match(Result, "01000000")) report "ADIW Result 1";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "ADIW Flag 1"; -- check status flag updates
		Flag <= StatReg;
		wait for 10 ns;
		assert (std_match(Result, "01000000")) report "ADIW Result 1 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "ADIW Flag 1 cycle 2"; -- check status flag updates
		
		-- now wait a bit
		wait for 4 ns;
		OperandA <= "11111111";
        FetchedInstruction <= "1001011000000001";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 6 ns;
        assert (std_match(Result, "00000000")) report "ADIW Result 2";  -- check alu logical result
        assert (std_match(StatReg, "00000011")) report "ADIW Flag 2"; -- check status flag updates
		Flag <= StatReg;
		wait for 10 ns;
		assert (std_match(Result, "00000000")) report "ADIW Result 2 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00000011")) report "ADIW Flag 2 cycle 2"; -- check status flag updates
		
		
		-- now wait a bit
		wait for 4 ns;
		OperandA <= "11100000";
        FetchedInstruction <= "1001011011001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 6 ns;
        assert (std_match(Result, "00011111")) report "ADIW Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00000001")) report "ADIW Flag 3"; -- check status flag updates
		Flag <= StatReg;
		wait for 10 ns;
		assert (std_match(Result, "11100001")) report "ADIW Result 3 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00010100")) report "ADIW Flag 3 cycle 2"; -- check status flag updates


        -- now wait a bit
        wait for 4 ns;
        OperandA <= "00000000";
        FetchedInstruction <= "1001011011001111";
        Flag <= "00000000";
        -- wait a little for propagation delays
        wait for 10 ns;
        OperandA <= "00000001";
        FetchedInstruction <= "1001011000000000";
        assert (std_match(Result, "00111111")) report "ADIW Result 3";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "ADIW Flag 3"; -- check status flag updates
        Flag <= StatReg;
        wait for 11 ns;
        assert (std_match(Result, "00000001")) report "ADIW Result 3 cycle 2";  -- check alu logical result
        assert (std_match(StatReg, "00000000")) report "ADIW Flag 3 cycle 2"; -- check status flag updates

        wait for 1000 ns;


        end process; -- end of stimulus process
	 
end TB_ARCHITECTURE;