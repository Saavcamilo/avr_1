library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
--
--  Stack Pointer Register (SP)
--
--  This is an implementation of the status register for an AVR CPU. It 
--  holds the current status of the system by storing the flags. The 
--  implementation is an 8 bit register that updates the flags.
--
--  Inputs:
--      Clock            - the system clock
--      StackOp          - encodes whether we want to push or pop
--      Reset            - sets the pointer to FFFFFFFF
--  Outputs:
--      FlagsOut         - The status of the system is stored in 
--                         the flags from the status register. Sent 
--                         to other blocks in the system.
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
		StackPointer   :     out  std_logic_vector(7 downto 0);
        SPout          :     out  std_logic_vector(7 downto 0);
        
    );
end StackPointer; 
---------------------------------------------
architecture ControlFlow of StackPointer is
    signal CurrPointer : std_logic_vector(7 downto 0);
    signal NextPointer : std_logic_vector(7 downto 0);
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
begin --8 bit register will simply store the value of flags.

    Stack_Adder: AdderBlock PORT MAP (
        Cin => '0', Subtract => StackOp(1), A => CurrPointer, 
        B => "00000001", Sum => NextPointer, Cout => '0'
    );


    process(Clock, Reset)
    begin
        if Reset = '0' then
            StackPointer <= "11111111";
            CurrPointer <= "11111111";
            SPout <= "11111111"
        elsif rising_edge(Clock) and StackOp(0) = '1' then --Rising edge and enable 
            StackPointer <= NextPointer;             -- signal is asserted
            if StackOp(1) = '0' then    -- when popping
                SPout <= NextPointer;
            else                        -- when pushing
                SPout <= CurrPointer;
        elseif rising_edge(Clock) and StackOp(0) = '0' then
            CurrPointer <= StackPointer;
        end if;
    end process;






end architecture;