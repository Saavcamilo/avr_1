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
USE ieee.numeric_std.ALL;

library opcodes;
use opcodes.opcodes.all;


entity AVR_tb is
end AVR_tb;

architecture TB_ARCHITECTURE of AVR_tb is
    -- Component declaration of the tested unit
Component AVR is
    port(
        clk     :  in     std_logic;                        -- system clock
        RST     :  in     std_logic;                         -- Reset
		DataDB  :  inout  std_logic_vector(7 downto 0);
		ProgDB  :  in     opcode_word;
		ProgAB  :  out    std_logic_vector(15 downto 0);
		DataAB  :  out    std_logic_vector(15 downto 0);
		DataWr  :  out    std_logic;
		DataRd  :  out    std_logic
		  
    );
end Component;

    -- Stimulus signals - signals mapped to the input and inout ports of tested entity    
	 signal  clk      :  std_logic;
    signal  RST      :  std_logic;
    signal  DataDB   :  std_logic_vector(7 downto 0);
    signal  ProgDB   :  opcode_word;
	 signal  ProgAB   :  std_logic_vector(15 downto 0);
    -- Observed signals - signals mapped to the output ports of tested entity    
	 signal  DataRd   :  std_logic;
    signal  DataWr   :  std_logic;
    signal  DataAB   :  std_logic_vector(15 downto 0);

    signal  Counter  :  integer := 0;
    --Signal used to stop clock signal generators    signal  END_SIM  :  BOOLEAN := FALSE;

    -- test value types    
	 type  byte_array    is array (natural range <>) of std_logic_vector(7 downto 0);
    type  addr_array    is array (natural range <>) of std_logic_vector(15 downto 0);
	 type  prog_array    is array (natural range <>) of std_logic_vector(15 downto 0);
	 

-- expected data bus write signal for each instruction  
    signal DataWrTestVals  :  std_logic_vector(0 to 17) := "111111111111111110";

-- expected data bus read signal for each instructionsignal  
    signal DataRdTestVals  :  std_logic_vector(0 to 17) := "111111111111111101";

    signal  ProgDBVals      :  prog_array(0 to 17) := (
	 "1110000000000001", "1110000000011000", "1110000000101001", "1110000000111010", "1110000001001011",
	 "1110000001011100", "1110000001101101", "1110000001111110", "1110000010001111", "1110000110010000",
	 "1110000010100000", "1110000010110000", "1110000111000011", "1110000111010100", "1110000111100101",
	 "1110000111110110", "1001001100001100", "1001000000001100");

	 
-- supplied data bus values for each instruction (for read operations)
    signal  DataDBVals      :  byte_array(0 to 17) := (
    "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", 
    "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", 
    "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ", 
    "ZZZZZZZZ", "ZZZZZZZZ", "ZZZZZZZZ" );

-- expected data bus output values for each instruction (only has a value on writes)
    signal  DataDBTestVals  :  byte_array(0 to 17) := (
    "--------", "--------", "--------", "--------", "--------", 
    "--------", "--------", "--------", "--------", "--------", 
    "--------", "--------", "--------", "--------", "--------", 
    "--------", "00000001",      "--------" );

-- expected data addres bus values for each instruction
    signal  DataABTestVals  :  addr_array(0 to 17) := (
    "----------------", "----------------", "----------------", "----------------", "----------------", 
    "----------------", "----------------", "----------------", "----------------", "----------------", 
    "----------------", "----------------", "----------------", "----------------", "----------------", 
    "----------------", "0000000000000000", "0000000000000000" );
	 
begin

    
    -- Unit Under Test port map
    UUT : AVR        port map  (
        clk => clk, RST => RST, DataDB => DataDB, ProgDB => ProgDB,
		ProgAB => ProgAB, DataAB => DataAB, DataWr => DataWr, DataRd => DataRd
        );
    
	 clock: process
    begin
        clk <= '1';
        wait for 5 ns; -- define a clock
        clk <= '0';
        wait for 5 ns;
    end process clock;
	 counter <= to_integer(unsigned(ProgAB));
	 main: process
	 begin
	     RST <= '0';
		  wait for 11 ns;
		  RST <= '1';
		  while counter < 18 loop
            ProgDB <= ProgDBVals(counter);
            if counter > 1 then 
            wait for 1 ns;
			assert (std_match(DataDB, DataDBTestVals(counter-1))) report "DataDB " & INTEGER'IMAGE(counter-1);
		    assert (std_match(DataAB, DataABTestVals(counter-1))) report "DataAB " & INTEGER'IMAGE(counter-1);
			assert (std_match(DataWr, DataWrTestVals(counter-1))) report "DataWr " & INTEGER'IMAGE(counter-1);
            assert (std_match(DataRd, DataRdTestVals(counter-1))) report "DataRd " & INTEGER'IMAGE(counter-1);
            end if;
            wait until counter'event or DataWr'Event or DataRd'Event;
		  end loop;
		    ProgDB <= "0000000000000000";
          wait for 10000 ns;
    end process;
end architecture;