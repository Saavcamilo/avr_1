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
--      StackOp          - encodes whether we want to push or pop
--      Reset            - sets the pointer to 11111111
--  Outputs:
--      SPout            - contains the address of the stack pointer after 
--                         the push or pop operation
--
--  Revision History:
--     5 Feb 17  Camilo Saavedra     Initial revision.
--     28 July 17 Anant Desai        Fixed logical errors in assiging NextPointer
--     28 July 17 Anant Desai        fixed Push/Pop functionality
--
----------------------------------------------------------------------------
entity StackPointer is                  --entity declaration  
    port(
        Clock          :     in   std_logic;   -- System Clock 
        StackOp        :     in   std_logic_vector(1 downto 0);
        Reset          :     in   std_logic;
        SPout          :     out  std_logic_vector(7 downto 0)
        
    );
end StackPointer; 
---------------------------------------------
architecture ControlFlow of StackPointer is
	 signal StackPointer: std_logic_vector(7 downto 0);
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
        if Reset = '0' then -- reset StackPointer, CurrPointer, and SPout to highest val
            StackPointer <= "11111111";
            CurrPointer <= "11111111";
            SPout <= "11111111";
        elsif rising_edge(Clock) and StackOp(0) = '1' then --Rising edge and enable 
            StackPointer <= NextPointer;             -- signal is asserted
            if StackOp(1) = '0' then    -- when popping
                SPout <= NextPointer;
            else                        -- when pushing
                SPout <= CurrPointer;
			   end if;
        elsif falling_edge(Clock) then -- during 1st cycle of push/pop
                                                           -- (or any other clock that isn't
                                                           -- the 2nd cycle of push/pop),
                                                           -- store stack pointer in
                                                           -- currPointer
            CurrPointer <= StackPointer;
        end if;
    end process;
end architecture;