library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Status Register (ALU)
--
--  This is an implementation of an 8 Bit Adder/Subtractor. It takes in the
--  two operands and a subtract signal that tells the block whether to add 
--  the two operands, or whether to subtract OperandB from OperandA. The
--  block also takes in a CarryIn, and outputs a CarryOut. 
--
--  Inputs:
--      Cin              - Possible carry bit input for the system
--      Subtract         - Bit is low for addition, high for subtraction
--      A                - First operand of Adder/Subtractor
--      B                - Second operand of Adder/Subtractor.
--
--  Outputs:
--      Sum                  - Result of the operation for Adder/Subtractor
--      Cout                 - Carry flag of the highest bit operation
--
--  Revision History:
--     31 Jan 17  Camilo Saavedra     Initial revision.
--
----------------------------------------------------------------------------
entity DataMemoryAccessUnit is
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
end DataMemoryAccessUnit; 
---------------------------------------------
architecture state_machine of DataMemoryAccessUnit is
Component AddressAdder is
    port(
        Subtract:  in  std_logic;
        A:   in  std_logic_vector(15 downto 0);
        B:    in  std_logic_vector(5 downto 0);
        
        LogicAddress: out std_logic_vector(15 downto 0)
		  
    );
end Component;
    type state is (
        Idle,
        CLK1,
        CLK2,
        CLK3
    );     
    signal CurrentState, NextState: state;
    signal AddedAddr: std_logic_vector(15 downto 0);
begin

AddrAdder: AddressAdder PORT MAP(
    Subtract => AddrOpSel(0), A => InputAddress, B => Offset, 
    LogicAddress => AddedAddr);
    
DataAB  <=    AddedAddr when AddrOpSel(1) = '1' else
              InputAddress; 
              
NewAddr <=    AddedAddr;              
    
    transition: process(CurrentState, WrIn, RdIn, Clock)
    begin
        case CurrentState is
            when Idle =>
                if (WrIn = '0' or RdIn = '0') then
                    NextState <= CLK1;
                else
                    NextState <= Idle;
                end if;
            when CLK1 =>
                NextState <= Clk2;
            when CLK2 =>
                if (AddrOpSel(1) = '1') then
                    NextState <= CLK3;
					 elsif (WrIn = '0' or RdIn = '0') then
                    NextState <= CLK1; 
                else
                    NextState <= Idle; 
                end if;
			   when others =>
				    NextState <= Idle;
        end case;
    end process transition;

    outputs: process (Clock, CurrentState)
    begin
        case CurrentState is
            when Idle =>
                    DataWr <= '1';
						  DataRd <= '1';
            when CLK1 =>
                    DataWr <= '1';
						  DataRd <= '1';
            when CLK2 =>
                if (Clock = '0') then 
                    DataWr <= WrIn;
                    DataRd <= RdIn;
				    else
                    DataWr <= '1';
						  DataRd <= '1';					 
                end if;
				when others => 
        end case;
    end process outputs;

    storage: process (Clock)
    begin
        if (falling_edge(Clock)) then
            CurrentState <= NextState;
        end if;
    end process storage;
end architecture;