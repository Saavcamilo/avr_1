library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library opcodes;
use opcodes.opcodes.all;

----------------------------------------------------------------------------
--
--  ControlUnit
--
--  This is an implementation of the Control Unit of an AVR 8 bit CPU. This 
--  entity handles all the control signals and generates them based on the 
--  instruction being executed. This is implemented through a simple FSM
--  whose outputs depend on the current opcode being executed. The control
--  signals go throughout the system execute the instruction.
--
--  Inputs:
--      Clock                   - System Clock
--      InstructionOpcode       - 16-bit opcode is instruction C.U. will execute
--      Flags                   - 8-bit register encodes current system status with flags
-- 		ZeroFlag  				- Zero Flag directly from ALU (i.e. not from stat reg)
--      IRQ                     - Interrupt request signal
--      CLK                     - clock input (active high)
--
--  Outputs:
--      StackOperation          - Encodes whether we will push or pop to the stack
--      RegisterEn              - Enables wanted register
--      RegisterSel             - Selects the register wanted from 32 register array
--      OpSel                   - Specifies to the ALU what operation to perform.
--      FlagMask                - Masks which flags to change for the ALU operation 
--      Read_MemWrite_Mem               - Signal encodes whether read_Meming or writting to 
--                              - memory access. 
--
--  Revision History:
--     25 Jan 17  Anant Desai       Initial revision.
--     31 Jan 17  Camilo Saavedra   Began implementing logic
-- 	   2  Feb 17  Anant Desai 		Completed Instruction Decoding for ALU
-- 	   5  Feb 17  Anant Desai 		Completed state machine to handle
--									two cycle instructions
--     15 May 17  Anant Desai		Completed implementing control singals for
--									DMA instructions 
--     28 Jul 17  Anant Desai 		Modified Push/Pop, MOV, LDI instructions
--     29 Jul 17  Anant Desai       Updated state machine to handle 3 cycle 
-- 									instructions
--	    7 Aug 17  Anant Desai 		Added ZeroFlag input for CPSE instruction
--      							Began instruction decoding for branching
--									instructions
--      8 Aug 17  Anant Desai 		added PMAOp output signal for program counter
--								    manipulations
-- 	    9 Aug 17  Anant Desai 		added output signal to mux register input
--									between alu output and data bus 
--	   13 Aug 17  Anant Desai 		Added Instruction Decoding for Unconditional
--									branches
--     14 Aug 17  Anant Desai 		Updated all previous instruction decoding to
--									include incrementing the PC during last
--									cycle of instruction
----------------------------------------------------------------------------

entity  ControlUnit  is

    port (
        clock            :  in  std_logic;
        InstructionOpCode :  in  opcode_word; 
        Flags            :  in  std_logic_vector(7 downto 0);	
        ZeroFlag 		 :  in  std_logic;
        IRQ 			 :  in  std_logic_vector(7 downto 0);

        FetchIR          : out 	  std_logic; 
        PushPop 		 : out    std_logic_vector(1 downto 0);
        RegisterEn       : out    std_logic;
		RegisterSel	 	 : out 	  std_logic_vector(4 downto 0);
        RegisterASel     : out    std_logic_vector(4 downto 0);
		RegisterBSel     : out    std_logic_vector(4 downto 0);
		RegisterXYZEn 	 : out    std_logic;
		RegisterXYZSel   : out    std_logic_vector(1 downto 0);
		RegMux 		     : out 	  std_logic_vector(1 downto 0);
		DMAOp 			 : out 	  std_logic_vector(2 downto 0);
		PMAOp 			 : out    std_logic_vector(2 downto 0);
        OpSel	    	 : out    std_logic_vector(9 downto 0);
        LDRImmed		 : out 	  std_logic;
        FlagMask         : out    std_logic_vector(7 downto 0);
        Immediate        : out    std_logic_vector(7 downto 0);
        PCoffset 		 : out 	  std_logic_vector(11 downto 0);
        Read_Mem 	 	 : out    std_logic;
        Write_Mem 	     : out 	  std_logic
        );

end  ControlUnit;

------------------------------------------------------------------------
architecture state_machine of ControlUnit is
    type state is (
    	STALL3, -- stall for 3 cycles
    	STALL2, -- stall for 2 cycles
        STALL, -- do not fetch new instruction
        FETCH  -- fetch new instruction
    );
    signal CurrentState, NextState: state; 
	 signal CycCounter : std_logic_vector(1 downto 0);
begin
	process(InstructionOpCode, Clock, Flags(6), CycCounter) 
	begin
		-- initialize outputs
        RegisterXYZEn <= '0'; -- "0" means xyz register is inactive, "1" means active
		RegisterXYZSel <= "11"; -- "00" xyz register is selecting x
								-- "01" xyz register is selecting y
								-- "10" xyz register is selecting z
								-- "11" xyz register is not selecting x, y, or z
		PushPop <= "00"; -- PushPop(1): "0" means pop, "1" means push
				   		 -- PushPop(0): active high enable
		DMAOp <= "000"; -- DMAOp(2): "0" continue normally, "1" need to sum constant immediately (ex. LDD, STD) and post increment isn't soon enough
						-- DMAOp(1): "0" use register, "1" use ProgDB 16 bit value
						-- DMAOp(0): "0" means add (post-inc), "1" means sub (pre-dec)
		PMAOp <= "000";  -- PMAOp(2 downto 1): "00" means set PC to immediate from ProgDB
					     --					   "01" means set PC to register Z
					     --					   "10" means add PC to PCoffset and increment
					     -- 				   "11" means set PC to DataDB (for RET and RETI)
					     --	PMAOp(0): active high enable indicates PC should be updated
		PCoffset <= "000000000000"; -- immediate offset passed into PMA unit
        Read_Mem <= '1';	-- active low read signal
		Write_Mem <= '1'; 	-- active low write signal
		RegisterEn <= '0'; -- 1 indicates write result to register, 0 indicates don't write to register
		RegisterSel <= "00000"; -- register to put result in (if applicable)
		RegisterASel <= "00000"; -- register to obtain operand A
		RegisterBSel <= "00000"; -- register to obtain operand B
		RegMux <= "000"; 	-- RegMux(2): active high enable (indicates either ALU or data bus wants to connect to register)
							-- RegMux(1): "0" means alu output goes into reg input, 
							-- 			  "1" means data bus connects to reg input/output (for load/store respectively)
							-- RegMux(0): "0" means regular register, "1" means PC
		OpSel <= "0000000000";	-- operand code to ALU
								-- OpSel(9 downto 8): "01" is logical, "10" is shift, "11" is add/sub
								-- OpSel(7): 1 if immediate passed to operand B, 0 if not
								-- OpSel(6): 1 if adding, 0 if subtracting
								-- OpSel(5 downto 2): logical block instruction type (i.e. and, or, xor, etc.)
								-- OpSel(3 downto 2): shift block instruction type ("01" is ASR, "10" is LSR, "11" is ROR, "00" is SWAP)
								-- OpSel(1): 1 include carry, 0 don't include carry
								-- OpSel(0): 1 if immediate passed to operand A, 0 if not
		LDRImmed <= '0'; 	-- indicates if loading immediately to register (i.e. ignoring alu output)
		FlagMask <= "00000000"; -- 1's indicate status register bits that can change, 0's stay the same
		Immediate <= "00000000"; -- passed in immediate value
		
		If std_match(InstructionOpCode, OpASR) then -- arithmetic shift right
			RegisterEn <= '1'; -- write_Mem output of ALU to register
			RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			RegMux <= "100"; -- ALU output goes into register input
			-- opcode to ALU 
			OpSel(9 downto 8) <= "10";
			OpSel(7 downto 2) <= InstructionOpCode(5 downto 0);
			 OpSel(1 downto 0) <= "00";
			FlagMask <= "00011111"; --indicates which bits to change in status register

			
			PMAOp <= "101"; -- increment PC by 1
			PCoffset <= "000000000000";
		 END IF;
		If (std_match(InstructionOpCode, OpLSR)) then 
			RegisterEn <= '1'; -- write_Mem output of ALU to register
			RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			RegMux <= "100"; -- ALU output goes into register input
			-- opcode to ALU 
			OpSel(9 downto 8) <= "10";
			OpSel(7 downto 2) <= InstructionOpCode(5 downto 0);
			OpSel(1 downto 0) <= "00";
			FlagMask <= "00011111"; --indicates which bits to change in status register

			PMAOp <= "101"; -- increment PC by 1
			PCoffset <= "000000000000";
		 END IF;
		If (std_match(InstructionOpCode, OpROR)) then 
			RegisterEn <= '1'; -- write_Mem output of ALU to register
			RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			RegMux <= "100"; -- ALU output goes into register input
			-- opcode to ALU 
			OpSel(9 downto 8) <= "10";
			OpSel(7 downto 2) <= InstructionOpCode(5 downto 0);
			OpSel(1 downto 0) <= "00";
			FlagMask <= "00011111"; --indicates which bits to change in status register

			PMAOp <= "101"; -- increment PC by 1
			PCoffset <= "000000000000";
		 END IF;
		If (std_match(InstructionOpCode, OpSWAP)) then 
			RegisterEn <= '1'; -- write_Mem output of ALU to register
			RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			RegMux <= "100"; -- ALU output goes into register input
			-- opcode to ALU 
			OpSel(9 downto 8) <= "10";
			OpSel(3 downto 0) <= "0000";
			FlagMask <= "00000000"; --indicates which bits to change in status register

			PMAOp <= "101"; -- increment PC by 1
			PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpADC)) then 
			  RegisterEn <= '1'; -- write_Mem output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  -- opcode to ALU 
			  OpSel <= "1100000010";
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpADD)) then
			  RegisterEn <= '1'; -- write_Mem output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1100000000"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpAND)) then 
			  RegisterEn <= '1'; -- write_Mem output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "0100100000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpANDI)) then 
			  RegisterEn <= '1'; -- write_Mem output of ALU to register
			   -- register to write_Mem output to
			  RegisterSel(4) <= '1';
			  RegisterSel(3 downto 0) <= InstructionOpCode(7 downto 4);
			   -- register to extract operand from
			  RegisterASel(4) <= '1';
			  RegisterASel(3 downto 0) <= InstructionOpCode(7 downto 4);
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(7 downto 4) <= InstructionOpCode(11 downto 8);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "0110100000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;

		 If (std_match(InstructionOpCode, OpBCLR)) then 
			  RegisterEn <= '0'; -- do not write output of ALU to register
           case InstructionOpCode(6 downto 4) is --decode which bit of stat reg to clear
					when "000" => Immediate <=  "11111110";
					when "001" => Immediate <=  "11111101";
					when "010" => Immediate <=  "11111011";
					when "011" => Immediate <=  "11110111";
					when "100" => Immediate <=  "11101111";
					when "101" => Immediate <=  "11011111";
					when "110" => Immediate <=  "10111111";
					when others => Immediate <= "01111111";
			  end case;
			  RegMux <= "000"; -- ALU output doesn't go into register
			  OpSel <= "0110100001"; -- opcode to ALU 
			  FlagMask <= "11111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpBLD)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4);  -- register to write_Mem output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			  if Flags(6) = '0' then
           	  	case InstructionOpCode(2 downto 0) is --decode which bit of register to load
					when "000" => Immediate <=  "11111110";
					when "001" => Immediate <=  "11111101";
					when "010" => Immediate <=  "11111011";
					when "011" => Immediate <=  "11110111";
					when "100" => Immediate <=  "11101111";
					when "101" => Immediate <=  "11011111";
					when "110" => Immediate <=  "10111111";
					when others => Immediate <= "01111111";
			   	end case;
                OpSel <= "0110100000"; -- opcode to ALU 
			  else
               	case InstructionOpCode(2 downto 0) is
               	when "000" => Immediate <=  "00000001"; --decode which bit of register to load
					when "001" => Immediate <=  "00000010";
					when "010" => Immediate <=  "00000100";
					when "011" => Immediate <=  "00001000";
					when "100" => Immediate <=  "00010000";
					when "101" => Immediate <=  "00100000";
					when "110" => Immediate <=  "01000000";
					when others => Immediate <= "10000000";
			  	end case;
			  OpSel <= "0110111000"; -- opcode to ALU 
			  END IF;
			  RegMux <= "100"; -- ALU output goes into register input
			  FlagMask <= "00000000"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpBSET)) then 
			  RegisterEn <= '0'; -- do not write output of ALU to register
           case InstructionOpCode(6 downto 4) is --decode which bit of stat reg to set
					when "000" => Immediate <=  "00000001";
					when "001" => Immediate <=  "00000010";
					when "010" => Immediate <=  "00000100";
					when "011" => Immediate <=  "00001000";
					when "100" => Immediate <=  "00010000";
					when "101" => Immediate <=  "00100000";
					when "110" => Immediate <=  "01000000";
					when others => Immediate <= "10000000";
			  end case;
			  RegMux <= "000"; -- ALU output does not go into register
			  OpSel <= "0110111001"; -- opcode to ALU 
			  FlagMask <= "11111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpBST)) then 
			  RegisterEn <= '0'; -- do not write output of ALU to register
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
           case InstructionOpCode(2 downto 0) is -- decode which bit of register to extract
					when "000" => Immediate <=  "00000001";
					when "001" => Immediate <=  "00000010";
					when "010" => Immediate <=  "00000100";
					when "011" => Immediate <=  "00001000";
					when "100" => Immediate <=  "00010000";
					when "101" => Immediate <=  "00100000";
					when "110" => Immediate <=  "01000000";
					when others => Immediate <= "10000000";
			  end case;
			  RegMux <= "000"; -- ALU output does not go into register
			  OpSel <= "0110100000"; -- opcode to ALU 
			  FlagMask <= "01000000"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpCOM)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write_Mem output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "0100001100"; -- opcode to ALU 
			  FlagMask <= "00011111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpCP)) then 
			  RegisterEn <= '0'; -- do not write output of ALU to register
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "000"; -- ALU output does not go into register input
			  OpSel <= "1101000000"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpCPC)) then 
			  RegisterEn <= '0'; -- do not write output of ALU to register
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "000"; -- ALU output does not go into register input
			  OpSel <= "1101000110"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpCPI)) then 
			  RegisterEn <= '0'; -- do not write output of ALU to register
			   -- register to extract operand from
			  RegisterASel(4) <= '1'; 
			  RegisterASel(3 downto 0) <= InstructionOpCode(7 downto 4);
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(7 downto 4) <= InstructionOpCode(11 downto 8);
			  RegMux <= "000"; -- ALU output does not go into register input
			  OpSel <= "1111000000"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpDEC)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			  Immediate <= "00000001";
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1111000000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpEOR)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "0100011000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpINC)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			  Immediate <= "00000001";
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1110000000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpNEG)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterBSel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1101000001"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register
              Immediate <= "00000000";

              PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpOR)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "0100111000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpORI)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			   -- register to write output to
			  RegisterSel(4) <= '1';
			  RegisterSel(3 downto 0) <= InstructionOpCode(7 downto 4);
			   -- register to extract operand from
			  RegisterASel(4) <= '1';
			  RegisterASel(3 downto 0) <= InstructionOpCode(7 downto 4);
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(7 downto 4) <= InstructionOpCode(11 downto 8);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "0110111000"; -- opcode to ALU 
			  FlagMask <= "00011110"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpSBC)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1101000010"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpSBCI)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			   -- register to write output to
			  RegisterSel(4) <= '1';
			  RegisterSel(3 downto 0) <= InstructionOpCode(7 downto 4);
			   -- register to extract operand from
			  RegisterASel(4) <= '1';
			  RegisterASel(3 downto 0) <= InstructionOpCode(7 downto 4);
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(7 downto 4) <= InstructionOpCode(11 downto 8);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1111000010"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		If (std_match(InstructionOpCode, OpSUB)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			  RegisterSel <= InstructionOpCode(8 downto 4); -- register to write_Mem output to
			  RegisterASel <= InstructionOpCode(8 downto 4); -- register to extract operand from
			   -- register to extract operand from
			  RegisterBSel(4) <= InstructionOpCode(9);
			  RegisterBSel(3 downto 0) <= InstructionOpcode(3 downto 0);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1101000000"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpSUBI)) then 
			  RegisterEn <= '1'; -- write output of ALU to register
			   -- register to write output to
			  RegisterSel(4) <= '1';
			  RegisterSel(3 downto 0) <= InstructionOpCode(7 downto 4);
			   -- register to extract operand from
			  RegisterASel(4) <= '1';
			  RegisterASel(3 downto 0) <= InstructionOpCode(7 downto 4);
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(7 downto 4) <= InstructionOpCode(11 downto 8);
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1111000000"; -- opcode to ALU 
			  FlagMask <= "00111111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpADIW)) then 
		 
			IF (cycCounter = "00") then -- first add immediate from higher num register using regular add
			  RegisterEn <= '1'; -- write output of ALU to register
			   -- register to write output to
			  RegisterSel(4 downto 3) <= "11";
			  RegisterSel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterSel(0) <= '0';
			  -- register to extract operand from
			  RegisterASel(4 downto 3) <= "11";
			  RegisterASel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterASel(0) <= '0';
			  
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(5 downto 4) <= InstructionOpCode(7 downto 6);
			  Immediate(7 downto 6) <= "00";
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1110000000"; -- opcode to ALU 
			  FlagMask <= "00011111"; --indicates which bits to change in status register

			  PMAOp <= "100"; -- set up signals to increment PC by 1
			  PCoffset <= "000000000000";
			else  -- then add 1 to higher num register if carry flag set
			
			  RegisterEn <= '1'; -- write_Mem output of ALU to register
			   -- register to write output to
			  RegisterSel(4 downto 3) <= "11";
			  RegisterSel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterSel(0) <= '1';
			   -- register to extract operand from
			  RegisterASel(4 downto 3) <= "11";
			  RegisterASel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterASel(0) <= '1';
              if Flags(0) = '0' then
					Immediate <= "00000000";
			  else
					Immediate <= "00000001";
			  END IF;
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1110000100"; -- opcode to ALU

			  FlagMask <= "00011111"; --indicates which bits to change in status register
			
			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
			END IF;

		 END IF;
		 If (std_match(InstructionOpCode, OpSBIW)) then 

			IF (cycCounter = "00") then -- first subtract immediate from lower num register using regular SUBI
			  RegisterEn <= '1'; -- write output of ALU to register
			   -- register to write_Mem output to
			  RegisterSel(4 downto 3) <= "11";
			  RegisterSel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterSel(0) <= '0';

			  RegisterASel(4 downto 3) <= "11";
			  RegisterASel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterASel(0) <= '0';

			  
			  Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
			  Immediate(5 downto 4) <= InstructionOpCode(7 downto 6);
			  Immediate(7 downto 6) <= "00";
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1111000000"; -- opcode to ALU 
			  FlagMask <= "00011111"; --indicates which bits to change in status register

			  PMAOp <= "100"; -- set up signals to increment PC by 1
			  PCoffset <= "000000000000";

			else  -- then subtract 1 from higher num register if borrow flag set
			  RegisterEn <= '1';  -- write_Mem output of ALU to register
			   -- register to write_Mem output to
			  RegisterSel(4 downto 3) <= "11";
			  RegisterSel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterSel(0) <= '1';
			   -- register to extract operand from
			  RegisterASel(4 downto 3) <= "11";
			  RegisterASel(2 downto 1) <= InstructionOpCode(5 downto 4);
			  RegisterASel(0) <= '1';
              if Flags(0) = '0' then
					Immediate <= "00000000";
			  else
					Immediate <= "00000001";
			  END IF;
			  RegMux <= "100"; -- ALU output goes into register input
			  OpSel <= "1111000100"; -- opcode to ALU

			  FlagMask <= "00011111"; --indicates which bits to change in status register

			  PMAOp <= "101"; -- increment PC by 1
			  PCoffset <= "000000000000";
			
			END IF;
		 	
		 END IF;

If (std_match(InstructionOpCode, OpLDX)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000000";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000000";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDXI)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDXD)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDYI)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDYD)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDZI)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDZD)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDDY)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDDZ)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
			    PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpLDI)) then 
		 	RegisterEn <= '1';	-- write to register
		 	RegisterSel(4) <= '1';
		 	RegisterSel(3 downto 0) <= InstructionOpCode(7 downto 4); -- register to write to
		 	RegMux <= "000"; -- don't connect register to alu output or dma output
		 	LDRImmed <= '1'; -- load immediate to register
		 	Immediate(3 downto 0) <= InstructionOpCode(3 downto 0);
		 	Immediate(7 downto 4) <= InstructionOpCode(11 downto 8);
		 	Read_Mem <= '1'; -- we are not reading (to memory)
		 	Write_Mem <= '1'; -- we are not writing (to memory)
		 	FlagMask <= "00000000"; -- don't change any flags

		 	PMAOp <= "101"; -- increment PC by 1
			PCoffset <= "000000000000";
		 END IF;
		 If (std_match(InstructionOpCode, OpLDS)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(24 downto 20); -- register to write to
		 		Immediate <= "00000000";
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "010";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSIF (cycCounter = "01") THEN -- for the second cycle
		 		RegisterEn <= '1';	-- write_Mem to register
		 		RegisterSel <= InstructionOpCode(24 downto 20); -- register to write to
		 		Immediate <= "00000000";
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "010";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSIF (cycCounter = "01") THEN -- for the third cycle 
		 		RegisterEn <= '1';	-- write_Mem to register
		 		RegisterSel <= InstructionOpCode(24 downto 20); -- register to write to
		 		Immediate <= "00000000";
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		DMAOp <= "010";
		 		Read_Mem <= '0'; -- we are reading
		 		Write_Mem <= '1'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpMOV)) then 
		 	RegisterEn <= '1'; -- write output of ALU to register
			   -- register to write result to
			RegisterSel <= InstructionOpCode(8 downto 4);
			RegisterASel(4) <= InstructionOpCode(9); 
			RegisterASel(3 downto 0) <= InstructionOpCode(3 downto 0);
			Immediate <= "11111111";
			RegMux <= "100"; -- ALU output connects to register input
			OpSel <= "0110100000"; -- opcode to ALU, AND with immediate (all 1's) and store
									-- result in new register
			FlagMask <= "00000000"; --indicates which bits to change in status register

			PMAOp <= "101"; -- increment PC by 1
			PCoffset <= "000000000000";
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTX)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000000";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000000";
		 		Read_Mem <= '1'; -- we are not read
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTXI)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not read
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are reading
		 		Write_Mem <= '0'; -- we are not writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTXD)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "00"; -- register XYZ is selecting register X
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTYI)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not read
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTYD)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTZI)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "000";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTZD)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not read
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "001";
		 		Immediate <= "00000001";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTDY)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "01"; -- register XYZ is selecting register Y
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTDZ)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "100";
		 		Immediate(2 downto 0) <= InstructionOpCode(2 downto 0);
		 		Immediate(4 downto 3) <= InstructionOpCode(11 downto 10);
		 		Immediate(5) <= InstructionOpCode(13);
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpSTS)) then 
		 	IF (cycCounter = "00") then -- for cycles 1
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(24 downto 20); -- register to write to
		 		Immediate <= "00000000";
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "010";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSIF (cycCounter = "01") THEN -- for the second cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(24 downto 20); -- register to write to
		 		Immediate <= "00000000";
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "010";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- for the third cycle
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(24 downto 20); -- register to write to
		 		Immediate <= "00000000";
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		DMAOp <= "010";
		 		Read_Mem <= '1'; -- we are not reading
		 		Write_Mem <= '0'; -- we are writing
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 
		 END IF;
		 If (std_match(InstructionOpCode, OpPOP)) then 
		 	IF (cycCounter = "00") then -- for cycles 1 (note PushPop signal isn't enabled)
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		PushPop <= "00";
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- set PushPop signal to enabled
		 		RegisterEn <= '1';	-- write to register
		 		RegisterSel <= InstructionOpCode(8 downto 4); -- register to write to
		 		RegMux <= "110"; -- DMA data bus connects to register input
		 		PushPop <= "01";
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpPUSH)) then 
		 	IF(cycCounter = "00") then -- for cycles 1 (note PushPop signal isn't enabled)
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		PushPop <= "10";
		 		FlagMask <= "00000000"; -- don't change any flags

		 		PMAOp <= "100"; -- set up signals to increment PC by 1
			    PCoffset <= "000000000000";
		 	ELSE -- set PushPop signal to enabled
		 		RegisterEn <= '0';	-- don't write to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		RegMux <= "110"; -- DMA data bus connects to register output
		 		PushPop <= "11";
		 		FlagMask <= "00000000"; -- don't change any flags
		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpJMP)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PMAOp <= "000"; -- connect PMA's NewPC to ProgDB but don't update PC
		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PMAOp <= "000"; -- connect PMA's NewPC to ProgDB but don't update PC
		 	ELSEIF(cycCounter = "10") then -- 3rd cycle
		 		PMAOp <= "001"; -- update PC to ProgDB value
		 	ELSE 	-- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpRJMP)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PMAOp <= "100"; -- set up signals for adding PC to passed immediate
		 		PCoffset <= InstructionOpCode(11 downto 0); -- passed immediate to add to PC
		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PMAOp <= "101"; -- update PC by adding passed immediate and incrementing
		 		PCoffset <= InstructionOpCode(11 downto 0);
		 	ELSE 	-- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpIJMP)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PMAOp <= "010"; -- prep signals for setting PC to value of reg Z
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PMAOp <= "011"; update PC to value in register Z
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z
		 	ELSE 	-- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpCALL)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PCoffset <= "000000000001"; -- offset PC by 1, then increment
		 		PMAOp <= "101"; -- set PC to PC+2, but since this is the 1st cycle
		 						-- of instruction, then we won't fetch, which 
		 						-- means that we won't jump to a new instruction
		 						-- yet
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "10";

		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "000"; -- disable PMAOp
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "11"; -- push (PC + 2) to stack (upper byte)

		 	ELSEIF(cycCounter = "10") then -- 3rd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "000"; -- disable PMAOp
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "11"; -- push (PC + 2) to stack (lower byte)

		 	ELSEIF(cycCounter = "11") then -- 4th cycle
		 		PCoffset <= "000000000000"; 
		 		RegMux <= "000"; -- disable databus connection to PC output
		 		PushPop <= "00"; -- disable pushpop
		 		PMAOp <= "001"; -- update PC to ProgDB value

		 	ELSE -- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpRCALL)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PCoffset <= "000000000000"; -- offset PC by 0, then increment
		 		PMAOp <= "101"; -- set PC to PC+1, but since this is the 1st cycle
		 						-- of instruction, then we won't fetch, which 
		 						-- means that we won't jump to a new instruction
		 						-- yet
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "11"; -- push (PC + 1) to stack (upper byte)

		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "000"; -- disable PMAOp
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "11"; -- push (PC + 1) to stack (lower byte)

		 	ELSEIF(cycCounter = "10") then -- 3rd cycle
		 		PCoffset <= InstructionOpCode(11 downto 0);
		 		PMAOp <= "101"; -- set PC to passed relative offset
		 		RegMux <= "000"; -- disable DMA data bus connection to PC output
		 		PushPop <= "00"; -- disable pushpop

		 	ELSE -- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpICALL)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PCoffset <= "000000000000"; -- offset PC by 0, then increment
		 		PMAOp <= "101"; -- set PC to PC+1, but since this is the 1st cycle
		 						-- of instruction, then we won't fetch, which 
		 						-- means that we won't jump to a new instruction
		 						-- yet
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "11"; -- push (PC + 1) to stack (upper byte)

		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "000"; -- disable PMAOp
		 		RegMux <= "111"; -- DMA data bus connects to PC output
		 		PushPop <= "11"; -- push (PC + 1) to stack (lower byte)

		 	ELSEIF(cycCounter = "10") then -- 3rd cycle
		 		PCoffset <= "000000000000";
		 		RegMux <= "000"; -- disable DMA data bus connection to PC output
		 		PushPop <= "00"; -- disable pushpop
		 		PMAOp <= "011"; update PC to value in register Z
		 		RegisterXYZEn <= '1'; -- register XYZ is active
		 		RegisterXYZSel <= "10"; -- register XYZ is selecting register Z

		 	ELSE -- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpRET)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "110"; -- prepare to set PC to value on DB
		 		RegMux <= "111"; -- DMA data bus connects to PC input 
		 		PushPop <= "00";

		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "111"; -- set PC to value on DB (upper byte)
		 		RegMux <= "111"; -- DMA data bus connects to PC input
		 		PushPop <= "01"; -- pop (PC + 1) off stack

		 	ELSEIF(cycCounter = "10") then -- 3rd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "111"; -- set PC to value on DB (lower byte)
		 		RegMux <= "111"; -- DMA data bus connects to PC input
		 		PushPop <= "01"; -- pop (PC + 1) off stack

		 	ELSEIF(cycCounter = "11") then -- 4th cycle
		 		PCoffset <= "000000000000"; 
		 		RegMux <= "000"; -- disable databus connection to PC output
		 		PushPop <= "00"; -- disable pushpop
		 		PMAOp <= "000"; -- disable PMAOp

		 	ELSE -- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpRETI)) then 
		 	IF(cycCounter = "00") then -- for cycle 1 
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "110"; -- prepare to set PC to value on DB
		 		RegMux <= "111"; -- DMA data bus connects to PC input 
		 		PushPop <= "00";

		 	ELSEIF(cycCounter = "01") then -- 2nd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "111"; -- set PC to value on DB (upper byte)
		 		RegMux <= "111"; -- DMA data bus connects to PC input
		 		PushPop <= "01"; -- pop (PC + 1) off stack

		 	ELSEIF(cycCounter = "10") then -- 3rd cycle
		 		PCoffset <= "000000000000"; 
		 		PMAOp <= "111"; -- set PC to value on DB (lower byte)
		 		RegMux <= "111"; -- DMA data bus connects to PC input
		 		PushPop <= "01"; -- pop (PC + 1) off stack

		 	ELSEIF(cycCounter = "11") then -- 4th cycle
		 		PCoffset <= "000000000000"; 
		 		RegMux <= "000"; -- disable databus connection to PC output
		 		PushPop <= "00"; -- disable pushpop
		 		PMAOp <= "000"; -- disable PMAOp

		 		-- set interrupt flag:
		 		RegisterEn <= '0'; -- do not write output of ALU to register
		 		Immediate <= "10000000"; (8th bit for the interrupt flag)
		 		OpSel <= "0110111001"; -- ALU op code for BSET instruction
		 		FlagMask <= "10000000"; --update interrupt flag

		 	ELSE -- this shouldn't execute
		 		
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpBRBC)) then 
		 	IF (Flags(InstructionOpCode(2 downto 0)) = '0') then -- take branch
		 		IF(cycCounter = "00") then -- for cycle 1 
			 		PMAOp <= "100"; -- set up signals for adding PC to passed immediate
			 		PCoffset(6 downto 0) <= InstructionOpCode(9 downto 3); -- passed immediate to add to PC
			 		PCoffset(11 downto 7) <= "00000";

		 		ELSEIF(cycCounter = "01") then -- 2nd cycle
			 		PMAOp <= "101"; -- update PC
			 		PCoffset(6 downto 0) <= InstructionOpCode(9 downto 3); -- passed immediate to add to PC
			 		PCoffset(11 downto 7) <= "00000";

		 	ELSE -- don't take branch, increment PC normally

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";

		 	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpBRBS)) then 
		 	IF (Flags(InstructionOpCode(2 downto 0)) = '1') then -- take branch
		 		IF(cycCounter = "00") then -- for cycle 1 
			 		PMAOp <= "100"; -- set up signals for adding PC to passed immediate
			 		PCoffset(6 downto 0) <= InstructionOpCode(9 downto 3); -- passed immediate to add to PC
			 		PCoffset(11 downto 7) <= "00000";

		 		ELSEIF(cycCounter = "01") then -- 2nd cycle
			 		PMAOp <= "101"; -- update PC
			 		PCoffset(6 downto 0) <= InstructionOpCode(9 downto 3); -- passed immediate to add to PC
			 		PCoffset(11 downto 7) <= "00000";

		 	ELSE -- don't take branch, increment PC normally

		 		PMAOp <= "101"; -- increment PC by 1
				PCoffset <= "000000000000";

		 	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpCPSE)) then 
		 	IF(cycCounter = "00") then -- for cycles 1 
		 		RegisterEn <= '0';	-- write_Mem to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		
		 		PushPop <= "10";
		 		
		 		FlagMask <= "00000000"; -- don't change any flags
		 	ELSE -- 
		 		RegisterEn <= '0';	-- write_Mem to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		
		 		PushPop <= "11";

		 		FlagMask <= "00000000"; -- don't change any flags
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpSBRC)) then 
		 	IF(cycCounter = "00") then -- for cycles 1 
		 		RegisterEn <= '0';	-- write_Mem to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		
		 		PushPop <= "10";
		 		
		 		FlagMask <= "00000000"; -- don't change any flags
		 	ELSE -- 
		 		RegisterEn <= '0';	-- write_Mem to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		
		 		PushPop <= "11";

		 		FlagMask <= "00000000"; -- don't change any flags
		  	END IF;
		 END IF;
		 If (std_match(InstructionOpCode, OpSBRS)) then 
		 	IF(cycCounter = "00") then -- for cycles 1 
		 		RegisterEn <= '0';	-- write_Mem to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		
		 		PushPop <= "10";
		 		
		 		FlagMask <= "00000000"; -- don't change any flags
		 	ELSE -- 
		 		RegisterEn <= '0';	-- write_Mem to register
		 		RegisterASel <= InstructionOpCode(8 downto 4);
		 		
		 		PushPop <= "11";

		 		FlagMask <= "00000000"; -- don't change any flags
		  	END IF;
		 END IF;

    end process;
	 
	transition: process(CurrentState, InstructionOpCode)
    begin
        case CurrentState is
        	when STALL3 =>
        		NextState <= FETCH;
        	when STALL2 =>
        		if ((std_match(InstructionOpCode, OpCALL)) or (std_match(InstructionOpCode, OpRET))
        		   or (std_match(InstructionOpCode, OpRETI))) then
            		NextState <= STALL2; -- stall for 3 states (used for 4 cycle instructions)
            	else
                	NextState <= FETCH; -- if we have been waiting
									-- then next cycle continue to fetch
				END IF;

        		NextState <= FETCH; 
            when STALL =>
            	if ((std_match(InstructionOpCode, OpLDS)) or (std_match(InstructionOpCode, OpSTS))
            	   or (std_match(InstructionOpCode, OpJMP)) or (std_match(InstructionOpCode, OpCALL))
            	   or (std_match(InstructionOpCode, OpRCALL)) or (std_match(InstructionOpCode, OpICALL))
            	   or (std_match(InstructionOpCode, OpRET)) or (std_match(InstructionOpCode, OpRETI))) then
            		NextState <= STALL2; -- stall for 2 states (used for 3 cycle instructions)
            	else
                	NextState <= FETCH; -- if we have been waiting
									-- then next cycle continue to fetch
				END IF;
            when FETCH =>
                if (	(std_match(InstructionOpCode, OpADIW)) or (std_match(InstructionOpCode, OpSBIW))
                		 or (std_match(InstructionOpCode, OpLDX)) or (std_match(InstructionOpCode, OpLDXI))
					     or (std_match(InstructionOpCode, OpLDXD)) or (std_match(InstructionOpCode, OpLDYI))
						 or (std_match(InstructionOpCode, OpLDYD)) or (std_match(InstructionOpCode, OpLDZI))
						 or (std_match(InstructionOpCode, OpLDZD)) or (std_match(InstructionOpCode, OpLDDY))
						 or (std_match(InstructionOpCode, OpLDDZ)) or (std_match(InstructionOpCode, OpSTX))
						 or (std_match(InstructionOpCode, OpSTXI)) or (std_match(InstructionOpCode, OpSTXD))
						 or (std_match(InstructionOpCode, OpSTYI)) or (std_match(InstructionOpCode, OpSTYD))
						 or (std_match(InstructionOpCode, OpSTZI)) or (std_match(InstructionOpCode, OpSTZD))
						 or (std_match(InstructionOpCode, OpSTDY)) or (std_match(InstructionOpCode, OpSTDZ))
						 or (std_match(InstructionOpCode, OpLDS))  or (std_match(InstructionOpCode, OpSTS))
						 or (std_match(InstructionOpCode, OpPUSH)) or (std_match(InstructionOpCode, OpPOP))
						 or (std_match(InstructionOpCode, OpJMP)) or (std_match(InstructionOpCode, OpRJMP))
						 or (std_match(InstructionOpCode, OpIJMP)) or (std_match(InstructionOpCode, OpCALL))
						 or (std_match(InstructionOpCode, OpRCALL)) or (std_match(InstructionOpCode, OpICALL))
						 or (std_match(InstructionOpCode, OpRET)) or (std_match(InstructionOpCode, OpRETI))) then
                    NextState <= STALL; -- if instruction is one of the two/three cycle instructions, then stall
										-- next cycle
				 elsif ((std_match(InstructionOpCode, OpBRBC) and Flags(InstructionOpCode(2 downto 0)) = '0')
				 		or (std_match(InstructionOpCode, OpBRBS) and Flags(InstructionOpCode(2 downto 0)) = '1')) then
				 	NextState <= STALL; -- conditional branch instructions have variable length cycles
				 else
					NextState <= FETCH; -- if only 1 cycle instruction, then continue fetching
                END IF;
        end case;
    end process transition;

    outputs: process (Clock, CurrentState)
    begin
        case CurrentState is
         	when FETCH =>
                FetchIR <= '1'; -- indicate whether to fetch from IR or wait
				CycCounter <= "00"; --indicate cycle number for 2 cycle instructions	
			when STALL3 =>
				FetchIR <= '0';
				CycCounter <= "11";
         	when STALL2 =>
        		FetchIR <= '0';
        		CycCounter <= "10";
         	when STALL =>
                FetchIR <= '0'; -- indicate whether to fetch from IR or wait
			    CycCounter <= "01"; --indicate cycle number for 2 cycle instructions
        end case;
    
    end process outputs;

    storage: process (Clock)
    begin
        if (rising_edge(Clock)) then
            CurrentState <= NextState; -- store present state information
        END IF;
    end process storage;


end state_machine;



