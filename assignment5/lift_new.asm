cpu "8085.tbl"
hof "int8"

org 9000h




QUEUESTART: EQU 8200H
QUEUESIZE: EQU 8202H
QUEUEHEAD: EQU 8204H
QUEUETAIL: EQU 8206H


;LXI SP,7FFFH

MVI A, 8BH
OUT 43H

; initial position of the lift
MVI H, 00H
MVI L, 01H
SHLD 8500H

; initial configuration of the floor bit vector
MVI A, 00H
STA 8600H
MVI A, 01H
OUT 40H


MVI H,80H
MVI L,00H

PUSH H
MVI H,00H
MVI L,08H
PUSH H
CALL QUEUEINIT 

;RST 05H ;dbg

WAITINPUT: NOP ;while there is no input, keep calling POLLING (inside DELAY).
CALL POLLING
CALL DEQUEUE ;returns the floor to move to by setting a bit in a byte.
POP H

SHLD 8800H ;dbg

MOV A, L
CPI 00H
JZ WAITINPUT

;;dbg;;
SHLD 8802H ; polled input
;;

;; enqueue received input ;;
PUSH H
CALL ENQUEUE
POP H
;;


RDQUE: NOP
CALL DEQUEUE
POP H

SHLD 8804H ; polled input

;RST 05H; ;dbg ;outputs are as expected. WORKING TILL HERE!

MOV A, L
CPI 00H
JZ WAITINPUT

SHLD 8900H


MVI B, 00H
MOV C, L
; so BC is the destination floor


LHLD 8500H
; so HL is the source floor

;; debug
SHLD 8902H

; move current destination floor to next source floor
MOV A, C
STA 8500H
MOV A, B
STA 8501H



; store the sign of destination floor - source floor
MVI A, 01H
STA 8502H

MOV A, C
CMP L
JC HIGHTOLOW
JMP LOWTOHIGH
;;;;;;;;;;;;;;;;;;;;;;;;;;;


HIGHTOLOW: NOP
SUI 01H
STA 8502H



LOWTOHIGH: NOP

;RST 05H ; WORKING TILL HERE!

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

MOV A, L
CMP C
JZ RDLIFTBUTTON


LDA 8502H
CPI 00H
MOV A, L
JZ ROTATERIGHT

ROTATELEFT:
RLC
JMP AFTERROTATION

ROTATERIGHT:
RRC


AFTERROTATION: NOP

MOV L, A
OUT 40H

;RST 05H

;;check if this floor is set and stop if it is
; save register values
PUSH H
PUSH B

; argument; floor to be checked
PUSH H
CALL ISFLOORSET
; pop the result
POP H
;;;;;;;;;;;;;;

MOV A, L
CPI 01H

; retrieve saved reg values
POP B
POP H

;RST 05H ; WORKING TILL HERE !!

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

; don't stop and make some delay if the floor bit is not set
JNZ MAKEDELAY

PUSH H
CALL RESETFLOORBIT
;RST 05H
JMP RDLIFTBUTTON

MAKEDELAY: NOP

;RST 05H

; introduce some delay
; save reg values
PUSH B 
PUSH H

CALL DELAY

; retrieve saved reg values
POP H
POP B
;;;;;;;;;;;;;;;;;

;RST 05H

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

;RST 05H

JMP LOWTOHIGH

RDLIFTBUTTON: NOP

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

RST 05H

;; DEBUG
;; INDICATE THAT RDLIFTBUTTON HAS BEEN REACHED
MVI A, 01H
STA 8908H
;;;;;;;;;;

;; READ THE BUTTON INSIDE THE LIFT
CALL 03BAH ; RDKBD

;; CONVERT THE KEYBOARD INPUT TO BIT CONFIGURATION
MOV E, A
DCR E
MVI A, 01H
CONVERTLOOP: NOP
MOV D, A
MOV A, E
CPI 00H
MOV A, D
JZ AFTERCONVERTLOOP
DCR E
RLC
JMP CONVERTLOOP
;;;;;;;;;;;;;;;;;;;;;;;;;;

AFTERCONVERTLOOP: NOP
STA 8909H ; BUTTON PRESSED INSIDE THE LIFT
MVI D, 00H
MOV E, A

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

PUSH H
PUSH B
PUSH D

; check if the floor corresponding to pressed button is already set
PUSH D
CALL ISFLOORSET
POP H
;;;;;;;
MOV A, L
CPI 01H

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

POP D
POP B
POP H

;; don't enqueue if the floor bit is already set
JZ NEXTACTION

PUSH H
PUSH B
PUSH D
PUSH D

;; ENQUEUE THE FLOOR NUMBER if its bit was not set
PUSH D
CALL ENQUEUE
POP H
;;;;;;;;;;;;;

;; SET THE FLOOR BIT AS IT HAS BEEN ENQUEUED
CALL SETFLOORBIT
;RST 05H
;POP H

POP D
POP B
POP H

;; DEBUG
SHLD 8904H
MOV A, C
STA 8906H
MOV A, B
STA 8907H
;;;;;;;;;;

RST 05H

NEXTACTION: NOP

MOV A, C
CMP L
MVI A, 01H
STA 890DH
JZ RDQUE
MVI A, 02H
STA 890DH
JMP LOWTOHIGH

RST 05H 





ISFLOORSET: NOP

POP H
SHLD 8700H

POP H
LDA 8600H
ANA L
JZ RETZERO

RETONE: NOP
MVI L, 01H
MVI	H, 00H
PUSH H
JMP RETISFLOORSET

RETZERO: NOP
MVI L, 00H
MVI	H, 00H
PUSH H

RETISFLOORSET: NOP
LHLD 8700H
PUSH H
RET




SETFLOORBIT: NOP
; save return address
POP H
SHLD 8700H

POP H ;SFB's input
LDA 8600H
ORA L
STA 8600H

; retrieve return address
LHLD 8700H
PUSH H
RET





RESETFLOORBIT: NOP

POP H
SHLD 8700H


POP H

LDA 8600H
XRA L
STA 8600H


LHLD 8700H
PUSH H
RET





DELAY: NOP
LXI D, 01FFFH
DLOOP: NOP
PUSH D
;; TO INDICATE POLLING HAS STARTED
MVI A, 00H
STA 890AH
CALL POLLING
;; TO INDICATE POLLING HAS ENDED
MVI A, 01H
STA 890AH
POP D
DCX D
MOV A,D
ORA E
JNZ DLOOP
RET




POLLING: NOP
IN 41H 
CMA
;;dbg;;
MVI H, 00H
MOV L, A
SHLD 8806H
;;
CPI 00H
RZ
;MVI H, 00H
;MOV L, A
SHLD 8808H ;dbg
PUSH H ;has input

;PUSH B
;PUSH PSW

;; Call ISFLOORSET
PUSH H
;; TO INDICATE isfloorset HAS STARTED
MVI A, 00H
STA 890BH
CALL ISFLOORSET
;; TO INDICATE isfloorset HAS ENDED
MVI A, 01H
STA 890BH
POP D
;;  
;POP PSW
;POP B
POP H ;has input

SHLD 880AH ;dbg

MOV A, E
CPI 01H
RZ
PUSH H

; Call enqueue
PUSH H
CALL ENQUEUE
POP H ;queue's exit flag ignored
;;
;POP H
;PUSH H
;; TO INDICATE setfloorbit HAS STARTED
MVI A, 00H
STA 890CH
CALL SETFLOORBIT
;; TO INDICATE setfloorbit HAS ENDED
MVI A, 01H
STA 890CH
RET





QUEUEINIT: nop
POP H
XCHG


POP H	   
SHLD QUEUESIZE 


POP H	
SHLD QUEUESTART 

MVI H,00H
MVI L,00H
SHLD QUEUEHEAD 
SHLD QUEUETAIL 

PUSH D
RET







ENQUEUE: nop

POP H 
SHLD 8300H

CALL QUEUEISFULL
POP H           
MOV A,L         
CPI 00H         
JZ NOTFULLLABEL

MVI H,00H
MVI L,01H
PUSH H
JMP ENQUEUERETLABEL

NOTFULLLABEL: nop

; Times enqueue has been called when it is not full
LHLD 8208H
INX H
SHLD 8208H

LHLD QUEUESTART
XCHG


LHLD QUEUETAIL


MVI B,00H
MVI C,02H

PUSH PSW
PUSH D
PUSH H

PUSH B
PUSH H
CALL MULTIPLICATION   

POP H       

POP B       
POP D 
POP PSW


DAD D     
PUSH H



INX B
LHLD QUEUESIZE  
;INX H       

PUSH PSW    
PUSH D
PUSH H

PUSH B
PUSH H
CALL REMAINDER


POP B       

POP H
POP D
POP PSW

MOV H,B     
MOV L,C     
SHLD QUEUETAIL

POP B	






POP D       





MOV A,E     



STAX B      
INX B       
MOV A,D     



STAX B     













MVI H,00H
MVI L,00H
PUSH H
ENQUEUERETLABEL: nop
LHLD 8300H
PUSH H
RET





DEQUEUE: nop
POP H
SHLD 8300H


CALL QUEUEISEMPTY
POP H       
MOV A,L     
CPI 00H   
JZ QUEUENOTEMPTYLABEL 
MVI H,00H   
MVI L,00H   
PUSH H      
JMP DEQUEUERETLABEL 

QUEUENOTEMPTYLABEL: nop

; Times dequeue has been called when it is not empty
LHLD 820AH
INX H
SHLD 820AH

LHLD QUEUEHEAD    
XCHG          


LHLD QUEUESTART    


PUSH H        
PUSH D        
PUSH PSW

MVI H,00
MVI L,02H
PUSH H
PUSH D
CALL MULTIPLICATION
POP B       

POP PSW     
POP D
POP H

DAD B



MOV B,H   
MOV C,L
LDAX B      
MOV L,A     
INX B       
LDAX B      
MOV H,A     
PUSH H      


INX D       
LHLD QUEUESIZE  
;INX H       


PUSH PSW
PUSH H
PUSH B

PUSH D
PUSH H
CALL REMAINDER

POP D

POP B
POP H
POP PSW

XCHG         
SHLD QUEUEHEAD   

DEQUEUERETLABEL: nop

LHLD 8300H   
PUSH H      
RET





QUEUEISEMPTY: nop
POP H
SHLD 8302H

LHLD QUEUEHEAD  
XCHG        
LHLD QUEUETAIL  

MOV A,H
CMP D
JNZ QUEUENOTEMPTY
MOV A,L
CMP E
JNZ QUEUENOTEMPTY


MVI H, 00H
MVI L, 01H
PUSH H
JMP QUEUEISEMPTYRETURNLABEL


QUEUENOTEMPTY: nop
MVI H,00H
MVI L,00H
PUSH H

QUEUEISEMPTYRETURNLABEL: nop
LHLD 8302H
PUSH H
RET








QUEUEISFULL: nop

POP H
SHLD 8304H  

LHLD QUEUETAIL  
INX H       
XCHG        
LHLD QUEUESIZE  
;INX H       
            

PUSH PSW
PUSH B
PUSH H

PUSH D      
PUSH H      
CALL REMAINDER

POP D       

POP H
POP B
POP PSW

LHLD QUEUEHEAD  

MOV A,H
CMP D
JNZ NOTSAMELABEL
MOV A,L
CMP E
JNZ NOTSAMELABEL


MVI H,00H
MVI L,01H
PUSH H
JMP QUEUEISFULLRETURNLABEL

NOTSAMELABEL: nop
MVI H,00H
MVI L,00H
PUSH H

QUEUEISFULLRETURNLABEL: nop
LHLD 8304H
PUSH H
RET






REMAINDER: MVI H,00H

POP H
SHLD 8302H
POP D       
POP H       
LXI B,0000H 
REMAINDERLOOP: MVI A,00H
MOV A,L     
SUB E       
MOV L,A     
MOV A,H     
SBB D       
MOV H,A     
INX B       
JNC REMAINDERLOOP    
DCX B       
DAD D       
PUSH H		
LHLD 8302H  
PUSH H      
RET         





MULTIPLICATION: nop


POP H
SHLD 8304H


POP B
POP D

MVI L,00H
MVI H,00H
loop: MVI A,00H
ORA B 
JNZ decr
ORA C
JZ exit
decr: DAD D
DCX B
JMP loop
exit: PUSH H
LHLD 8304H
PUSH H
RET
