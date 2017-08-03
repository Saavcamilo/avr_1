library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;

----------------------------------------------------------------------------
--
--  Registers
--
--  This is an implementation of the Registers in an AVR CPU. The CPU has 
--  32 8-bit general purpose registers. Thus, this block encodes a select 
--  signal that choses which register and the two possible buses it can
--  output. A 32bit mux select is used to drive the enable line, and then 
--  2 32-byte muxes are used to select the 2 byte output from the 32 
--  array register. The functionality for the XYZ reg is also coded,
--  with these double registers used for memory accessing. Thus,
--  there is another output of these special registers, along 
--  with a separate select, so that the system can access these
--  registers and normal registers at the same time.
--
--  Inputs:
--      Clock                   - System Clock
--      Enable                  - Bit that enables the 32-bit mux.
--      Selects                 - Encodes which registers to enable to overwrite
--      RegIn                   - Byte input is sent to each of the 32 registers
--      RegASel                 - Selects which registers to output in the A bus 
--      RegBSel                 - Selects which registers to output in the B bus
--      RegIn                   - Input Data to write to register
--      RegXYZEn                - enables usage of x, y, z bus line
--      RegXYZSel               - select register x, y, or z to put on bus
--
--  Outputs:
--      RegAOut                 - Output of first selected Register
--      RegBOut                 - Output of second selected Register
--      RegXYZOut               - Output of X, Y, or Z register
--
--  Revision History:
--     25 Jan 17  Camilo Saavedra     Initial revision.
--     6  May 17  Camilo Saavedra     Added memory access register functionality
--
----------------------------------------------------------------------------
entity  RegisterArray  is

    port(
        clock    :  in  std_logic;                          -- system clock
        Enable   :  in  std_logic;       							-- Enables the registers 
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
end  RegisterArray;

----------------------------------------------------------------------------

architecture Registers of RegisterArray is    
-- Select line is the 32 enable signals sent to the registers, and 
-- Qn is the output of the nth register.
    signal    SelectLine              :  std_logic_vector(31 downto 0); 
    signal    Q0, Q1, Q2, Q3, Q4, Q5  :  std_logic_vector(7 downto 0);
    signal    Q6, Q7, Q8, Q9, Q10     :  std_logic_vector(7 downto 0);
    signal    Q11, Q12, Q13, Q14, Q15 :  std_logic_vector(7 downto 0);
    signal    Q16, Q17, Q18, Q19, Q20 :  std_logic_vector(7 downto 0);
    signal    Q21, Q22, Q23, Q24, Q25 :  std_logic_vector(7 downto 0);
    signal    Q26, Q27, Q28, Q29, Q30 :  std_logic_vector(7 downto 0);
    signal    Q31                     :  std_logic_vector(7 downto 0);
    signal    RegIn                   :  std_logic_vector(7 downto 0);
    signal    RegInLow                :  std_logic_vector(7 downto 0);
    signal    RegInHigh               :  std_logic_vector(7 downto 0);
    signal    SelXLow : std_logic;
    signal    SelXHigh: std_logic;
    signal    SelYLow : std_logic;
    signal    SelYHigh: std_logic;
    signal    SelZLow : std_logic;
    signal    SelZHigh: std_logic;
    
    -- Each register is an 8 bit register
    component Register8Bit is
    port(
        D:     std_logic_vector(7 downto 0);
        Q:     out std_logic_vector(7 downto 0);
        En:    std_logic;
        Clock: std_logic
    );
    end component;

    -- Mux selects a byte from 32 input bytes, used to select outputA/B    
    component Mux8Bit is
    port(
        D0, D1, D2, D3, D4, D5:    std_logic_vector(7 downto 0);
        D6, D7, D8, D9, D10:       std_logic_vector(7 downto 0);
        D11, D12, D13, D14, D15:   std_logic_vector(7 downto 0);
        D16, D17, D18, D19, D20:   std_logic_vector(7 downto 0);
        D21, D22, D23, D24, D25:   std_logic_vector(7 downto 0);
        D26, D27, D28, D29, D30:   std_logic_vector(7 downto 0);
        D31:                       std_logic_vector(7 downto 0);
        Q:                        out std_logic_vector(7 downto 0);
        Sel:                      in std_logic_vector(4 downto 0)
    );
    end component;
    
	 -- Parallel mux choses X, Y, or Z dual register in order to
	 -- output to the DMA
    component MuxXYZ is
    port(
        D26, D27, D28, D29, D30:   std_logic_vector(7 downto 0);
        D31:                       std_logic_vector(7 downto 0);
        Sel:                      in std_logic_vector(1 downto 0);
        En:                       in std_logic;
        Q:                        out std_logic_vector(15 downto 0)
        
    );
    end component;

    -- Decoder takes in 5 bits and decodes into a 32 bit signal used to 
    -- generate the select signal for each of the 32 bit mux. 
    component Decoder32Bit is
    port(
        En:      std_logic;
        Q:       out std_logic_vector(31 downto 0);
        Sel:     std_logic_vector(4  downto 0)
    );
    end component;

begin 
    -- Following statements are the logic that drive the 
	 -- select signal when a RegXYZ select signal is 
	 -- performed. If none of these are performed, the 
	 -- signal is the normal register access select 
	 -- line
    with RegXYZSel select SelXLow  <=
        '1'            when "00",
        SelectLine(26) when "01",
        SelectLine(26) when "10",
        SelectLine(26) when "11";

    with RegXYZSel select SelXHigh  <=
        '1'            when "00",
        SelectLine(27) when "01",
        SelectLine(27) when "10",
        SelectLine(27) when "11";

    with RegXYZSel select SelYLow  <=
        SelectLine(28) when "00",
        '1'            when "01",
        SelectLine(28) when "10",
        SelectLine(28) when "11";

    with RegXYZSel select SelYHigh  <=
        SelectLine(29) when "00",
        '1'            when "01",
        SelectLine(29) when "10",
        SelectLine(29) when "11";

    with RegXYZSel select SelZLow  <=
        SelectLine(30) when "00",
        SelectLine(30) when "01",
        '1'            when "10",
        SelectLine(30) when "11";

    with RegXYZSel select SelZHigh  <=
        SelectLine(31) when "00",
        SelectLine(31) when "01",
        '1'            when "10",
        SelectLine(31) when "11";

    with WriteXYZ select RegInLow <=
        InputXYZ(7 downto 0) when '1',
        RegIn     when '0';

    with WriteXYZ select RegInHigh <=
        InputXYZ(15 downto 8) when '1',
        RegIn     when '0';

    -- Chose which register input is used
    with UseImmed select RegIn <=
        Immediate when '1',
        Input     when '0';
        
    -- Select decoder generates 32 select lines from the 5 bit input.
    Sel_Decoder: Decoder32Bit PORT MAP(
        En => Enable,
        Q => SelectLine,
        Sel => Selects);

    -- Muxes will select the output from the 32 bytes the register outputs.
    A_Mux : Mux8Bit PORT MAP( 
        D0  => Q0,   D1  => Q1,   D2  => Q2,   D3  => Q3,   D4 => Q4,  D5 => Q5,       
        D6  => Q6,   D7  => Q7,   D8  => Q8,   D9  => Q9,   D10 => Q10,          
        D11 => Q11,  D12 => Q12,  D13 => Q13,  D14 => Q14,  D15 => Q15,      
        D16 => Q16,  D17 => Q17,  D18 => Q18,  D19 => Q19,  D20 => Q20,      
        D21 => Q21,  D22 => Q22,  D23 => Q23,  D24 => Q24,  D25 => Q25,      
        D26 => Q26,  D27 => Q27,  D28 => Q28,  D29 => Q29,  D30 => Q30,      
        D31 => Q31,  
        
        Q => RegAOut,
        Sel => RegASel 
    );
  
    B_Mux : Mux8Bit PORT MAP (
        D0  => Q0,   D1  => Q1,   D2  => Q2,   D3  => Q3,   D4 => Q4,  D5 => Q5,       
        D6  => Q6,   D7  => Q7,   D8  => Q8,   D9  => Q9,   D10 => Q10,          
        D11 => Q11,  D12 => Q12,  D13 => Q13,  D14 => Q14,  D15 => Q15,      
        D16 => Q16,  D17 => Q17,  D18 => Q18,  D19 => Q19,  D20 => Q20,      
        D21 => Q21,  D22 => Q22,  D23 => Q23,  D24 => Q24,  D25 => Q25,      
        D26 => Q26,  D27 => Q27,  D28 => Q28,  D29 => Q29,  D30 => Q30,      
        D31 => Q31,  
        
        Q => RegBOut,
        Sel => RegBSel 
    );      

	 -- XYZ Mux performs the muxing of the address registers.
    XYZ_Mux : MuxXYZ PORT MAP (    
        D26 => Q26,  D27 => Q27,  D28 => Q28,  D29 => Q29,  D30 => Q30,      
        D31 => Q31,  
        
        En => RegXYZEn,
        Q => RegXYZOut,
        Sel => RegXYZSel 
    );     
    
    -- Map each of the 32 bit registers to its corresponding select 
    -- line and output. The input of each register is RegIn, so 
    -- whether it is written to only depends on the select line. 
    Register_0: Register8Bit PORT MAP (
        D => RegIn, Q => Q0, En => SelectLine(0), Clock => clock
    );
    
    Register_1: Register8Bit PORT MAP (
        D => RegIn, Q => Q1, En => SelectLine(1), Clock => clock
    );
    
    Register_2: Register8Bit PORT MAP (
        D => RegIn, Q => Q2, En => SelectLine(2), Clock => clock
    );
    
    Register_3: Register8Bit PORT MAP (
        D => RegIn, Q => Q3, En => SelectLine(3), Clock => clock
    );
    
    Register_4: Register8Bit PORT MAP (
        D => RegIn, Q => Q4, En => SelectLine(4), Clock => clock
    );
    
    Register_5: Register8Bit PORT MAP (
        D => RegIn, Q => Q5, En => SelectLine(5), Clock => clock
    );
    
    Register_6: Register8Bit PORT MAP (
        D => RegIn, Q => Q6, En => SelectLine(6), Clock => clock
    );
    
    Register_7: Register8Bit PORT MAP (
        D => RegIn, Q => Q7, En => SelectLine(7), Clock => clock
    );
    
    Register_8: Register8Bit PORT MAP (
        D => RegIn, Q => Q8, En => SelectLine(8), Clock => clock
    );
    
    Register_9: Register8Bit PORT MAP (
        D => RegIn, Q => Q9, En => SelectLine(9), Clock => clock
    );
    
    Register_10: Register8Bit PORT MAP (
        D => RegIn, Q => Q10, En => SelectLine(10), Clock => clock
    );
    
    Register_11: Register8Bit PORT MAP (
        D => RegIn, Q => Q11, En => SelectLine(11), Clock => clock
    );
    
    Register_12: Register8Bit PORT MAP (
        D => RegIn, Q => Q12, En => SelectLine(12), Clock => clock
    );
    
    Register_13: Register8Bit PORT MAP (
        D => RegIn, Q => Q13, En => SelectLine(13), Clock => clock
    );
    
    Register_14: Register8Bit PORT MAP (
        D => RegIn, Q => Q14, En => SelectLine(14), Clock => clock
    );
    
    Register_15: Register8Bit PORT MAP (
        D => RegIn, Q => Q15, En => SelectLine(15), Clock => clock
    );
    
    Register_16: Register8Bit PORT MAP (
        D => RegIn, Q => Q16, En => SelectLine(16), Clock => clock
    );
    
    Register_17: Register8Bit PORT MAP (
        D => RegIn, Q => Q17, En => SelectLine(17), Clock => clock
    );
    
    Register_18: Register8Bit PORT MAP (
        D => RegIn, Q => Q18, En => SelectLine(18), Clock => clock
    );
    
    Register_19: Register8Bit PORT MAP (
        D => RegIn, Q => Q19, En => SelectLine(19), Clock => clock
    );
    
    Register_20: Register8Bit PORT MAP (
        D => RegIn, Q => Q20, En => SelectLine(20), Clock => clock
    );
    
    Register_21: Register8Bit PORT MAP (
        D => RegIn, Q => Q21, En => SelectLine(21), Clock => clock
    );
    
    Register_22: Register8Bit PORT MAP (
        D => RegIn, Q => Q22, En => SelectLine(22), Clock => clock
    );
    
    Register_23: Register8Bit PORT MAP (
        D => RegIn, Q => Q23, En => SelectLine(23), Clock => clock
    );
    
    Register_24: Register8Bit PORT MAP (
        D => RegIn, Q => Q24, En => SelectLine(24), Clock => clock
    );
    
    Register_25: Register8Bit PORT MAP (
        D => RegIn, Q => Q25, En => SelectLine(25), Clock => clock
    );    
    -- Final registers mapped to the special XYZ signals.
    Register_26: Register8Bit PORT MAP (
        D => RegInLow, Q => Q26, En => SelXLow, Clock => clock
    );

    Register_27: Register8Bit PORT MAP (
        D => RegInHigh, Q => Q27, En => SelXHigh, Clock => clock
    );

    Register_28: Register8Bit PORT MAP (
        D => RegInLow, Q => Q28, En => SelYLow, Clock => clock
    );

    Register_29: Register8Bit PORT MAP (
        D => RegInHigh, Q => Q29, En => SelYHigh, Clock => clock
    );

    Register_30: Register8Bit PORT MAP (
        D => RegInLow, Q => Q30, En => SelZLow, Clock => clock
    );

    Register_31: Register8Bit PORT MAP (
        D => RegInHigh, Q => Q31, En => SelZHigh, Clock => clock
    );
end architecture; 