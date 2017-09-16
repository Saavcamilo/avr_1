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


; BLD

; BSET

; BST













