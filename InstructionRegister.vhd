library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Stack Pointer Register (SP)
--
--  This is an implementation of the stack pointer for an AVR CPU. It 
--  holds the current address of the stack pointer and controls whether
--  the stack pointer should be incremented or decremented based on 
--  the StackOp input, which is driven by a pushPop signal.
--
--  Inputs:
--      Clock            - the system clock
--      IROp             - encodes whether we want to change program counter
--      Reset            - sets the pointer to 00000000
--      PCimmed          - immediate passed into program counter unit
--  Outputs:
--      IRout            - contains the address of the program counter after 
--                         the branch or skip instruction
--
--  Revision History:
--     7  Aug 17  Anant Desai     Initial revision.
--     8  Aug 17  Anant Desai     
--
----------------------------------------------------------------------------
entity InstructionRegister is                  --entity declaration  
    port(
        Clock          :     in   std_logic;   -- System Clock 
        IROp           :     in   std_logic_vector(2 downto 0);
        Reset          :     in   std_logic;
        PCimmed        :     in   std_logic_vector(12 downto 0);
        SPout          :     out  std_logic_vector(7 downto 0)
        
    );
end InstructionRegister; 
---------------------------------------------
architecture ControlFlow of InstructionRegister is
	 signal InstructionRegister: std_logic_vector(7 downto 0);
    signal CurrPointer : std_logic_vector(7 downto 0);
    signal NextPointer : std_logic_vector(7 downto 0);
	 signal carry_out   : std_logic;
    -- 8 flags stored in an 8bit register 
   
    Component AdderBlock is
    port(
        Cin  :     in  std_logic;
        Subtract:  in  std_logic;
        A:         in  std_logic_vector(7 downto 0);
        B:         in  std_logic_vector(7 downto 0);
        Sum:       out std_logic_vector(7 downto 0);
        Cout :     out std_logic
    );
    
    end component; 
begin --

    -- adder increments or decrements the stack pointer depending on whether
    -- we are pushing or popping (StackOp(1))
    Stack_Adder: AdderBlock PORT MAP (
        Cin => '0', Subtract => StackOp(1), A => CurrPointer, 
        B => "00000001", Sum => NextPointer, Cout => carry_out
    );


    process(Clock, Reset)
    begin
        if Reset = '0' then -- reset InstructionRegister, CurrPointer, and SPout to highest val
            InstructionRegister <= "11111111";
            CurrPointer <= "11111111";
            SPout <= "11111111";
        elsif rising_edge(Clock) and StackOp(0) = '1' then --Rising edge and enable 
            InstructionRegister <= NextPointer;             -- signal is asserted
            if StackOp(1) = '0' then    -- when popping
                SPout <= NextPointer;
            else                        -- when pushing
                SPout <= CurrPointer;
			   end if;
        elsif rising_edge(Clock) and StackOp(0) = '0' then -- during 1st cycle of push/pop
                                                           -- (or any other clock that isn't
                                                           -- the 2nd cycle of push/pop),
                                                           -- store stack pointer in
                                                           -- currPointer
            CurrPointer <= InstructionRegister;
        end if;
    end process;
end architecture;