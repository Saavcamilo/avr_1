LDI 	r16, 1	; 
LDI 	r17, 8	; 
LDI 	r18, 9	; 
LDI 	r19, 10	; 
LDI 	r20, 11	; 
LDI 	r21, 12	; 
LDI 	r22, 13	; 
LDI 	r23, 14	; 
LDI 	r24, 15	; 
LDI 	r25, 0	; 
LDI 	r26, 0	; 
LDI 	r27, 0	; 
LDI 	r28, 10	; 
LDI 	r29, 0	; 
LDI 	r30, 20	; 

LDI 	r31, 0	; 
MOV 	r0, r31 ; 

LDI  	r31, 1  ; 
MOV 	r1, r31	; 

LDI 	r31, 2 	; 
MOV 	r2, r31 ; 

LDI 	r31, 4 	; 
MOV 	r3, r31 ; 

LDI 	r31, 8 	; 
MOV 	r4, r31 ; 

LDI 	r31, 16 ; 
MOV 	r5, r31 ; 

LDI 	r31, 32 ; 
MOV 	r6, r31 ; 

LDI 	r31, 64 ; 
MOV 	r7, r31	; 

LDI 	r31, 128; 
MOV 	r8, r31 ; 

LDI 	r31, $AA; 
MOV 	r9, r31 ; 

LDI 	r31, $08; 
MOV 	r10, r31; 

LDI 	r31, $80; 
MOV 	r11, r31; 

LDI 	r31, $AA; 
MOV 	r12, r31; 

LDI 	r31, $FF; 
MOV 	r13, r31; 

LDI 	r31, $0F; 
MOV 	r14, r31; 

LDI 	r31, $F0; 
MOV 	r15, r31; 


LDI 	r31, 0	; 



; test ALU instructions





; ADC 

BSET 	0 		; set carry flag
ADC 	r19, r20	; 
ST 		X+, r19 	;W160000
ADC 	r19, r20 	; 
ST 		X+, r19 	;W220001
BSET 	0 		; set carry flag
ADC 	r19, r20 	; 
ST 		X+, r19		;W2D0002



; ADD

ADD 	r21, r22 	; 
ST 		X+, r21 	;W190003
BSET 	0 		; set carry flag
ADD 	r21, r22 	; 
ST 		X+, r21 	;W260004



; ADIW 

ADIW 	r25:r24, 1 	; 
ST 		X+, r24		;W100005
ST 		X+, r25 	;W000006



; AND 

AND 	r0, r1 		; 
ST 		X+, r0 		;W000007
AND 	r2, r14 	; 
ST 		X+, r2 		;W020008



; ANDI

ANDI 	r30, $FF 	; 
ST 		X+, r30 	;W140009
ANDI 	r17, $08 	; 
ST 		Y+, r17 	;W08000A



; ASR 

ASR 	r4 			; 
ST 		Y+, r4 		;W04000B
ASR 	r4 			; 
ST 		Y+, r4 		;W02000C



; BCLR
LDI 	r16, $FF 	; 
LDI 	r17, $01 	; 
ADD 	r16, r17	; 
BCLR 	0 			; 
ADC 	r16, r17 	; 
ST 		Y+, r16 	;W01000D



; BST / BLD
BST 	r3, 3 		; 
BLD 	r7, 0 		; 
ST 		Y+, r7 		;W41000E



; BSET
BST 	r3, 0 		; 
BSET 	6 			; 
BLD 	r7, 1 		; 
ST 		Y+, r7 		;W43000F



; COM
COM 	r31 		; 
ST 		Y+, r31 	;WFF00010
COM 	r31 		; 
ST 		Y+, r31 	;W0000011



; CP
LDI 	r16, 1 		;  	
CP 		r31, r16 	; 
ST 		Y+, r31 	;W000012
ST 		Y+, r16 	;W010013



; CPC
CPC 	r31, r16 	; 
ST 		Z+, r31 	;W000014
ST 		Z+, r16 	;W010015



; CPI
CPI 	r31, $FF 	; 
ST 		Z+, r31 	;W000016



; DEC
LDI 	r29, 3 		; 
DEC 	r29 		; 
ST 		Z+, r29 	;W020017
DEC 	r29 		; 
ST 		Z+, r29 	;W010018
DEC 	r29 		; 
ST 		Z+, r29 	;W000019
DEC 	r29 		; 
ST 		Z+, r29 	;WFF001A



; EOR
LDI 	r29, $AA 	; 
LDI 	r28, $55 	; 
EOR 	r28, r29 	; 
ST 		Z+, r28 	;WFF001B
EOR 	r28, r28	; 
ST 		Z+, r28 	;W00001C


; INC 	
LDI 	r29, 0 		; 
INC 	r29 		; 
ST 		Z+, r29 	;W01001D
INC 	r29 		; 
ST 		Z+, r29 	;W02001E
INC 	r29 		; 
ST 		Z+, r29 	;W03001F



; LSR
LDI 	r29, $80 	; 
LSR 	r29 		; 
ST 		Z+, r29 	;W400020
LSR 	r29			; 
ST 		Z+, r29 	;W200021



; NEG
LDI 	r29, 25 	; 
NEG 	r29  		; 
ST 		Z+, r29 	;WE70022
NEG 	r29			; 
ST 		Z+, r29 	;W190023



; OR 
LDI 	r28, $AA 	; 
LDI 	r29, $55 	; 
OR 		r29, r28	; 
ST 		Z+, r29 	;WFF0024
OR 		r28, r28 	; 
ST 		Z+, r28 	;WAA0025



; ORI 	
LDI 	r29, 0 		; 
ORI 	r29, $F0 	; 
ST 		Z+, r29 	;WF00026
ORI 	r29, $0F 	; 
ST 		Z+, r29 	;WFF0027



; ROR
LDI 	r29, $0F 	; 
ROR 	r29 		; 
ST 		Z+, r29 	;W870028
ROR 	r29			; 
ST 		Z+, r29 	;WC30029
ROR 	r29 		; 
ST 		Z+, r29 	;WE1002A
ROR 	r29 		; 
ST 		Z+, r29 	;WF0002B



; SBC
LDI 	r28, 10 	; 
LDI 	r29, 0 		; 
BSET 	0 			; 
SBC 	r28, r29 	; 
ST 		Z+, r28 	;W09002C
BCLR 	0 			; 
SBC 	r28, r29 	; 
ST 		Z+, r28 	;W09002D



; SBCI
LDI 	r28, 10 	; 
BSET 	0 			; 
SBCI 	r28, 0 		;
ST 		Z+, r28 	;W09002E
BCLR 	0 			; 
SBCI 	r28, 0 		; 
ST 		Z+, r28 	;W09002F



; SBIW 
LDI 	r29, 0 		; 
LDI 	r28, 10 	; 
SBIW 	r29:r28, 1 	; 
ST 	 	Z+, r28 	;W090030
ST 		Z+, r29 	;W000031



; SUB
LDI 	r28, 10 	; 
LDI 	r29, 1 		; 
BSET 	0 			; 
SUB 	r28, r29 	; 
ST 		Z+, r28 	;W090032
BCLR 	0 			; 
SBC 	r28, r29 	; 
ST 		Z+, r28 	;W080033



; SUBI
LDI 	r28, 100 	; 
SUBI 	r28, 95 	; 
ST 		Z+, r28 	;W050034
SUBI 	r28, 5 		; 
ST 		Z+, r28 	;W000035



; SWAP
LDI 	r28, $0F 	; 
SWAP 	r28 		; 
ST 		Z+, r28 	;WF00036
SWAP 	r28 		; 
ST 		Z+, r28 	;W0F0037



; LD X
LDI 	r27, 0 		; 
LDI 	r26, $37 	; 
LD 		r0, X 		;R0F0037
LD 		r0, -X 		;RF00036
LD 		r0, -X 		;R000035
LD 		r0, -X 		;R050034
LD 		r0, X+		;R050034
LD 		r0, X+ 		;R000035
LD 		r0, X+ 		;RF00036



; LD Y
LDI 	r29, 0 		; 
LDI 	r28, $30 	; 
LD 		r1, Y+ 		;R090030
LD 		r1, Y+ 		;R000031
LD 		r1, Y+ 		;R090032
LDI 	r29, 0 		; 
LDI 	r28, $30 	; 
LD 		r2, -Y 		;R09002F
LD 		r2, -Y 		;R09002E
LD 		r2, -Y 		;R09002D



; LD Z
LDI 	r31, 0 		; 
LDI 	r30, $20 	; 
LD 		r3, -Z 		;R03001F
LD 		r3, -Z 		;R02001E
LD 		r3, -Z 		;R01001D
LDI 	r31, 0 		; 
LDI 	r30, $20 	; 
LD 		r4, Z+ 		;R400020
LD 		r4, Z+ 		;R200021
LD 		r4, Z+ 		;RE70022



; LDD Y
LDI 	r29, 0 		; 
LDI 	r28, 0 		; 
LDD 	r5, Y+4 	;R260004
LDD 	r5, Y+1 	;R220001



; LDD Z
LDI 	r30, 0 		; 
LDI 	r31, 0 		; 
LDD 	r6, Z+0 	;R160000
LDD 	r6, Z+8 	;R020008
LDI 	r30, 1 		; 
LDD 	r6, Z+2 	;R190003



; LDI (has been tested throughout code)



; LDS
LDS		r7, $0015 	;R010015
LDS 	r7, $0009	;R140009



; MOV (has been tested throughout code)



; ST X
LDI 	r27, 0 		; 
LDI 	r26, $38 	; 
LDI  	r16, $AA 	; 
ST 		X, r16 		;WAA0038
INC 	r26 		; 
LDI 	r17, $BB 	; 
LDI 	r18, $CC 	; 
LDI 	r19, $DD 	; 
LDI 	r20, $EE 	; 
LDI 	r21, $FF 	; 
ST 		X+, r17 	;WBB0039
ST 		X+, r18 	;WCC003A
LDI 	r26, $3E 	; 
ST 		-X, r19		;WDD003D
ST 		-X, r20 	;WEE003C
ST 		-X, r21 	;WFF003B



; ST Y
LDI 	r29, 0 		; 
LDI 	r28, $3E 	; 
ST 		Y+, r16 	;WAA003E
ST 		Y+, r17 	;WBB003F
ST 		Y+, r18 	;WCC0040
LDI 	r28, $43 	; 
ST 		-Y, r19 	;WDD0042
ST 		-Y, r20 	;WEE0041



; ST Z
LDI 	r31, 0 		; 
LDI 	r30, $43 	; 
ST 		Z+, r16 	;WAA0043
ST 		Z+, r17 	;WBB0044
LDI 	r30, $48 	; 
ST 		-Z, r18 	;WCC0047
ST 		-Z, r19 	;WDD0046
ST 		-Z, r20 	;WEE0045



; STD Y
LDI 	r29, 0 		; 
LDI 	r28, $44 	; 
STD 	Y+4, r16	;WAA0048
STD 	Y+5, r17 	;WBB0049



; STD Z
LDI 	r31, 0 		; 
LDI 	r30, $43 	; 
STD 	Z+7, r16 	;WAA004A
STD 	Z+8, r17 	;WBB004B
STD 	Z+9, r18 	;WCC004C



; STS
STS $004D, r16 		;WAA004D
STS $004E, r17 		;WBB004E



; PUSH   *note, need to make sure stack pointer has been reset*
PUSH 	r16 		;WAAFFFF
PUSH 	r17 		;WBBFFFE
PUSH 	r18 		;WCCFFFD
PUSH 	r19 		;WDDFFFC
PUSH 	r20 		;WEEFFFB



; POP
POP 	r1 			;REEFFFB
POP 	r2 			;RDDFFFC
POP 	r3 			;RCCFFFD
POP 	r4 			;RBBFFFE
POP 	r5 			;RAAFFFF



; JMP 
JMP 	label1 		; 
NOP 				; should be skipped
label1: 			; 



; RJMP
RJMP 	label2 		; 
NOP 				; should be skipped
label2:				; 



; IJMP (tested in external vhdl TB file PC_TEST.vhd)



; CALL (tested in external vhdl TB file PC_TEST.vhd)



; RCALL (tested in external vhdl TB file PC_TEST.vhd)



; ICALL (tested in external vhdl TB file PC_TEST.vhd)



; RET (tested in external vhdl TB file PC_TEST.vhd)



; RETI (tested in external vhdl TB file PC_TEST.vhd)



; BRBC
BSET 	0 			; 
BRBC 	0, label3 	; 
NOP					; should NOT be skipped
label3: 			; 
BCLR 	0 			; 
BRBC 	0, label4 	; 
NOP					; should be skipped
label4:  			; 



; BRBS
BCLR 	0 			; 
BRBS 	0, label5 	; 
NOP					; should NOT be skipped
label5:  			; 
BSET 	0 			; 
BRBS 	0, label6 	; 
NOP					; should be skipped
label6: 			; 



; CPSE 
LDI 	r16, $AA 	; 
LDI 	r17, $AA 	; 
LDI 	r18, $BB 	; 
CPSE 	r16, r17 	; 
NOP 				; should be skipped
CPSE 	r16, r18 	; 
NOP 				; should NOT be skipped



; SBRC 
SBRC 	r16, 0 		; 
NOP 				; should be skipped
SBRC 	r16, 1 		; 
NOP 				; should NOT be skipped



; SBRS
SBRS 	r16, 0 		; 
NOP 				; should NOT be skipped
SBRS 	r16, 1 		; 
NOP 				; should be skipped






NOP
NOP
NOP
NOP
NOP







