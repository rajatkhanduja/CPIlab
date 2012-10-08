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


;;; QUEUE ;;;;
;
; Memory location 8200 holds the starting position of the queue (16 bit-address)
; Memory location 8202 holds the size of the queue  (16-bits)
;     Note that the size refers to the number of 16-bit elements that can be stored
;     not the size in the memory.
; Memory location 8204 holds the head pointer index (16-bits)
; Memory location 8206 holds the tail pointer index (16-bits)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;QUEUEINIT;;;;;;;;;;;;
QUEUEINIT: nop
POP H
XCHG

; Store size of queue (number of elements)
POP H	   ; Size
SHLD QUEUESIZE  ; Store size at QUEUESIZE

; Store starting position
POP H	    ; Starting position
SHLD QUEUESTART ; Store starting position at QUEUESTART

MVI H,00H
MVI L,00H
SHLD QUEUEHEAD  ; Set head index = 0
SHLD QUEUETAIL  ; Set tail index = 0

PUSH D
RET
;;;;;;;;;;;;;;;;;;;;;; end of QUEUEINIT ;;;;;;;;;;;;;;;;;;;;

;;;; ENQUEUE ;;;;;
; Pushes the first argument into the queue.
; Stores the return address at 8304
; If the queue is full, i.e. (tail + 1) % size = head, return 1 else return 0 ( for success)

ENQUEUE: nop
; Pop the return address
POP H 
SHLD 8300H

; Check if the queue is full or not
CALL QUEUEISFULL
POP H             ; Get output in HL pair
MOV A,L           ; A <- L
CPI 00H           ; if HL = 0000H
JZ NOTFULLLABEL   ; Jump to NOTFULLLABEL
; Failure to insert
MVI H,00H         ; else set HL to 01
MVI L,01H
PUSH H            ; and return HL.
JMP ENQUEUERETLABEL

NOTFULLLABEL: nop
;DBG : Times enqueue has been called when it is not full
LHLD 8208H
INX H
SHLD 8208H
;;
; Get starting address
LHLD QUEUESTART
XCHG

; Get tail index
LHLD QUEUETAIL

; Multiply tail by 2 for 16-bit elements
MVI B,00H
MVI C,02H
; Storing variables
PUSH PSW
PUSH D
PUSH H
; Calling multiplication
PUSH B
PUSH H
CALL MULTIPLICATION   ; Multiply by 2
; Store result
POP H         ; Product
; Restore variables
POP B         ; Stores the earlier value of Tail in BC                      
POP D   
POP PSW

; Compute tail address
DAD D         ; Add starting position of queue to index position of tail * 2
PUSH H


; Store new index of tail
INX B
LHLD QUEUESIZE  
;INX H       
; Find module w.r.t size
PUSH PSW       ; store registers
PUSH D
PUSH H
; Call modulo
PUSH B
PUSH H
CALL REMAINDER
; Get result

POP B           ; B now stores the final value of tail-index
; Restore registers
POP H
POP D
POP PSW
; Store result (tail index) back in memory
MOV H,B         ; H <- B
MOV L,C         ; L <- C
SHLD QUEUETAIL

POP B	          ; Get address to be stored at

; Store value at tail location
POP D           ; Value to be enqueued
MOV A,E         ; A <- E
STAX B          ; Store value in A at address located by BC
INX B           ; incrememnt BC for the higher bits' address
MOV A,D         ; A <- D
STAX B     

; Report success (return value 0)
MVI H,00H
MVI L,00H
PUSH H
ENQUEUERETLABEL: nop
LHLD 8300H
PUSH H
RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of ENQUEUE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; DEQUEUE ;;;;
; Get value of head index
; If the queue is empty, returns 0

DEQUEUE: nop
POP H
SHLD 8300H

; Check if the queue is empty or not.
CALL QUEUEISEMPTY
POP H           ; Store result in H
MOV A,L         ; A <- L  
CPI 00H         ; Compare A with 0
JZ QUEUENOTEMPTYLABEL ; if not empty, continue
MVI H,00H       ; Set HL <- 00H
MVI L,00H       
PUSH H          ; Put HL (0000H) on stack
JMP DEQUEUERETLABEL ; Jump on return statement

QUEUENOTEMPTYLABEL: nop
; DBG : Times dequeue has been called when it is not empty
LHLD 820AH
INX H
SHLD 820AH

; Get the head index
LHLD QUEUEHEAD    
XCHG            ; DE <- HL

; Get the base address
LHLD QUEUESTART ; The base address in HL   

; Compute the head address
PUSH H          ; Storing registers
PUSH D        
PUSH PSW
; Call multiplication
MVI H,00
MVI L,02H
PUSH H
PUSH D
CALL MULTIPLICATION   ; Multiply by 2
POP B       
; Store registers
POP PSW     
POP D
POP H
; Add 2 * head_index to base address
DAD B

; Get the value at the address
; BC <- HL
MOV B,H   
MOV C,L
LDAX B          ; Read into A from address location in B  
MOV L,A         ; L <- A
INX B           ; B = B + 1
LDAX B          ; Read into A from address location in B
MOV H,A         ; H <- A 
PUSH H          ; This is the return value

; Compute new head index
INX D           ; Increment the head pointer
LHLD QUEUESIZE  ; Loads size into HL pair
;INX H        
; Find modulo with respect to size
; Save registers
PUSH PSW
PUSH H
PUSH B
; Call modulo
PUSH D
PUSH H
CALL REMAINDER
; Get result
POP D
; Restore registers
POP B
POP H
POP PSW

XCHG             ; HL <-> DE
SHLD QUEUEHEAD   ; Copy the value in HL pair to QUEUEHEAD

DEQUEUERETLABEL: nop
; Return the value at the address
LHLD 8300H        ; Read return address
PUSH H            ; Place address on stack
RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of DEQUEUE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;; QUEUEISEMPTY ;;;;;;;;
; Check if queue is empty (head == tail)
QUEUEISEMPTY: nop
POP H
SHLD 8302H

LHLD QUEUEHEAD    ; Get head index in HL
XCHG              ; DE <- HL
LHLD QUEUETAIL    ; Get tail index in HL
; Compare HL and DE
MOV A,H
CMP D
JNZ QUEUENOTEMPTY
MOV A,L
CMP E
JNZ QUEUENOTEMPTY

; Empty
MVI H, 00H
MVI L, 01H
PUSH H
JMP QUEUEISEMPTYRETURNLABEL

; Not empty
QUEUENOTEMPTY: nop
MVI H,00H
MVI L,00H
PUSH H

QUEUEISEMPTYRETURNLABEL: nop
LHLD 8302H
PUSH H
RET
;;;;;;;;;;;;;;;;;;;;;;;;; end of QUEUEISEMPTY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; QUEUEISFULL ;;;
; Check if queue is not full ( (tail + 1) % size != head)
; First increment tail and find its modulo w.r.t. size
; If the value obtained by the above step is equal to head, queue is full (ret 1)
; else queue has space (ret 0)
QUEUEISFULL: nop

POP H
SHLD 8304H  

LHLD QUEUETAIL      ; Get tail index
INX H               ; Increment tail
XCHG                ; DE <-> HL
LHLD QUEUESIZE      ; Get sizeo of the queue in HL
;INX H          
            
; Save registers before calling REMAINDER
PUSH PSW
PUSH B
PUSH H
; Push arguments
PUSH D      
PUSH H      
CALL REMAINDER
; Get result
POP D       
; Restore registers as before
POP H
POP B
POP PSW

LHLD QUEUEHEAD        ; Get head-index in HL
;  Compare head and modded incremented tail (B & D)
MOV A,H
CMP D
JNZ NOTSAMELABEL
MOV A,L
CMP E
JNZ NOTSAMELABEL

; head = tail case
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
;;;;;;;;;;;;;;;;;;;;;;;;;;; end of QUEUEISFULL ;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;MOD;;;;;
;;;;;;;;;;;

; 16-bit modulo
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


;;; Multiplication ;;;;
;;;;;;;;;;;;;;;;;;;;;;;
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
