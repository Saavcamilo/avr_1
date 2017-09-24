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
















