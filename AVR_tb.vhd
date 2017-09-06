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

    type ProgMem is array (0 to 65535) of opcode_word;
    type DataMem is array (0 to 65535) of std_logic_vector (7 downto 0);
    signal Data_Memory  : DataMem := ((others=> (others=>'0')));
    signal Prog_Memory  : ProgMem:= ((others=> (others=>'0')));
    signal clk          : std_logic;
    signal RST          : std_logic;
    signal DataDB       : std_logic_vector(7 downto 0);
    signal ProgDB       : opcode_word;
    signal ProgAB       : std_logic_vector(15 downto 0);
    signal DataAB       : std_logic_vector(15 downto 0);
    signal DataWr       : std_logic;
    signal DataRd       : std_logic;
	 
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
    mem: process(DataRd, DataWr, ProgAB)
    begin
        if (DataRd = '0') then
            DataDB <= Data_Memory(to_integer(unsigned(DataAB)));
        elsif (DataWr = '0') then
            Data_Memory(to_integer(unsigned(DataAB))) <= DataDB;
        end if;
		  ProgDB <= Prog_Memory(to_integer(unsigned(ProgAB)));
    end process;
	 main: process
	 begin
	     RST <= '1';
		  wait for 10 ns;
		  RST <= '0';
		  wait for 100000 ns;
    end process;
end architecture;