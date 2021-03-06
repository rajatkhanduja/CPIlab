;;; QUEUE ;;;;
;
; Memory location 8200 holds the starting position of the queue (16 bit-address)
; Memory location 8202 holds the size of the queue  (16-bits)
;     Note that the size refers to the number of 16-bit elements that can be stored
;     not the size in the memory.
; Memory location 8204 holds the head pointer index (16-bits)
; Memory location 8206 holds the tail pointer index (16-bits)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QUEUESTART: EQU 8200H
QUEUESIZE: EQU 8202H
QUEUEHEAD: EQU 8204H
QUEUETAIL: EQU 8206H


MAINPROG: nop
; Store 
PUSH H
PUSH D
PUSH B
PUSH PSW

MVI H,80H
MVI L,00
PUSH H
MVI H,00H
MVI L,02H
PUSH H
CALL QUEUEINIT 

; Call Enqueue
MVI H,00H
MVI L,05H
PUSH H
CALL ENQUEUE
POP H

; Call Enqueue
MVI H,00H
MVI L,03H
PUSH H
CALL ENQUEUE
POP H

CALL DEQUEUE
POP H

CALL DEQUEUE
POP H

CALL QUEUEISEMPTY
POP H
; Restore variables
POP PSW
POP B
POP D

RST 05

;;;;;;; QUEUEINIT ;;;;;;
QUEUEINIT: nop
POP H
XCHG

; Store size of queue (number of elements)
POP H	   ; Size
SHLD QUEUESIZE ; Store size at QUEUESIZE

; Store starting position
POP H	; Starting position
SHLD QUEUESTART ; Store starting position at 8200H

MVI H,00H
MVI L,00H
SHLD QUEUEHEAD ; Set head index = 0	
SHLD QUEUETAIL ; Set tail index = 0

PUSH D
RET
;;;;;;;;;;;;;; end of QUEUEINIT ;;;;;;;;;;;;;;;;;

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
POP H           ; Get output in HL pair
MOV A,L         ; A <- L
CPI 00H         ; if HL = 0000H
JZ NOTFULLLABEL
; Failure to insert
MVI H,00H
MVI L,01H
PUSH H
JMP ENQUEUERETLABEL

NOTFULLLABEL: nop
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
;Store result
POP H       ; Product
; Restore variables
POP B       ; Stores the ealier value of Tail in BC
POP D 
POP PSW

; Compute tail address
DAD D     ; Add starting position of queue to index position of tail
PUSH H
;SHLD 8500H	; DEBUG : Store computed value of HL (address)

; Store new index of tail. ;; 
INX B
LHLD QUEUESIZE  ; Get size of queue
INX H       ; Increment HL (size)
; Find modulo w.r.t. size
PUSH PSW    ; Store registers
PUSH D
PUSH H
; Call modulo
PUSH B
PUSH H
CALL REMAINDER
; Get result

POP B       ; B now stores the final value of tail-index
; Restore registers
POP H
POP D
POP PSW
; Store result (tail index) back in memory
MOV H,B     ; H <- B
MOV L,C     ; L <- C
SHLD QUEUETAIL

POP B	; Get address to be stored at.

;; DEBUG : Store Address at BC at 8502
;MOV H,B
;MOV L,C
;SHLD 8502H
; Store value at tail location
POP D       ; Value to be enqued
;; DEBUG : Store value in DE at 8504
;MOV H,D
;MOV L,E
;SHLD 8504H
;;
MOV A,E     ; A <- E
;; DEBUG
;STA 8506H
;;
STAX B      ; Store value in A at address located by BC
INX B       ; increment BC for the higher 8 bits' address
MOV A,D     ; A <- D
;; DEBUG
;STA 8507H
;;
STAX B     

;; DEBUG
;DCX B
;LDAX B
;; DEBUG
;STA 8508H
;INX B
;LDAX B
;STA 8509H
;;
;;

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
POP H       ; Store result in H
MOV A,L     ; A <- L
CPI 00H   ; Compare A with 0
JZ QUEUENOTEMPTYLABEL ; If not empty, continue
MVI H,00H   ; Set HL <- 00H
MVI L,00H   
PUSH H      ; Put HL (0000H) on stack        
JMP DEQUEUERETLABEL ; Jump to return statement

QUEUENOTEMPTYLABEL: nop
; Get the head index
LHLD QUEUEHEAD    ; Load the head index in HL
XCHG          ; DE <- HL

; Get the base address
LHLD QUEUESTART    ; The base address in HL

; Compute the head address
PUSH H        ; Storing registers
PUSH D        
PUSH PSW
; Call multiplication
MVI H,00
MVI L,02H
PUSH H
PUSH D
CALL MULTIPLICATION
POP B       ; Stores result in BC pair
; Restore registers
POP PSW     
POP D
POP H
; Add 2*head_index to Base address
DAD B

; Get the value at the address
; BC <- HL
MOV B,H   
MOV C,L
LDAX B      ; Read into A from address location in B
MOV L,A     ; L <- A
INX B       ; B = B + 1
LDAX B      ; Read into A from address location in B
MOV H,A     ; H <- A
PUSH H      ; This is the return value

; Compute new head index
INX D       ; Increment the head pointer
LHLD QUEUESIZE  ; Loads size into HL pair
INX H       ; increment size (HL)
; Find modulo with respect to size
; Save registers
PUSH PSW
PUSH H
PUSH B
; Call Modulo
PUSH D
PUSH H
CALL REMAINDER
; Get result
POP D
; Restore registers
POP B
POP H
POP PSW

XCHG         ; HL <-> DE
SHLD QUEUEHEAD   ; Copy the value in HL pair to QUEUEHEAD

DEQUEUERETLABEL: nop
; Return the value at the address
LHLD 8300H   ; Read return address
PUSH H      ; Place address on stack
RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end of DEQUEUE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;; QUEUEISEMPTY ;;;;;;;;
; Check if queue is empty (head == tail)
QUEUEISEMPTY: nop
POP H
SHLD 8302H

LHLD QUEUEHEAD  ; Get head index in HL
XCHG        ; DE <- HL
LHLD QUEUETAIL  ; Get tail index in HL
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
; Get the return address
POP H
SHLD 8304H  

LHLD QUEUETAIL  ; Get tail index
INX H       ; Increment tail
XCHG        ; DE <- HL
LHLD QUEUESIZE  ; Get size of the queue in HL
INX H       ; increment the size because size of the queue in memory is 1 more than
            ; the number of elements that can be stored.
; Save registers before calling REMAINDER
PUSH PSW
PUSH B
PUSH H
; Push arguments
PUSH D      ; Push the tail-index (dividend)
PUSH H      ; Push the size (divisor)
CALL REMAINDER
; Get result
POP D       ; Value of remainder
; Restore registers as before
POP H
POP B
POP PSW

LHLD QUEUEHEAD  ; Get head-index in HL
; Compare Head and Modded-incremented tail. (B & D)
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
; Get the return address and store in memory
POP H
SHLD 8302H
POP D       ; Pop divisor from stack to DE
POP H       ; Pop dividend from stack to HL
LXI B,0000H ; Set BC to 0
REMAINDERLOOP: MVI A,00H
MOV A,L     ; A <- L [copy the lower 8 bits ]
SUB E       ; A = A - E [subtract the lower 8 bits ]
MOV L,A     ; L <- A
MOV A,H     ; A <- H [copy the higher 8 bits]
SBB D       ; Subtract the higher 8 bits with borrow.
MOV H,A     ; H <- A
INX B       ; Increment B 
JNC REMAINDERLOOP    ; If not carry (which occurs if the subtraction yielded a negative number) Jump to loop
DCX B       ; Since we over-counted B, decrement B
DAD D       ; Add DE to HL (makes it positive)
PUSH H		; Push remainder on stack
LHLD 8302H  ; Read return address from memory
PUSH H      ; Push return address on memory
RET         ; Return

;;; Multiplication ;;;;
;;;;;;;;;;;;;;;;;;;;;;;


MULTIPLICATION: nop

;pop the return address
POP H
SHLD 8304H

;get arguments (numbers)
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
