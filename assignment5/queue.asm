;;; QUEUE ;;;;
;
; Memory location 8200 holds the starting position of the queue (16 bit-address)
; Memory location 8202 holds the size of the queue  (16-bits)
;     Note that the size refers to the number of 16-bit elements that can be stored
;     not the size in the memory.
; Memory location 8204 holds the head pointer index (16-bits)
; Memory location 8206 holds the tail pointer index (16-bits)

;;;; PUSHINQUEUE ;;;;;
; Pushes the first argument into the queue.
; Stores the return address at 8304
; If the queue is full, i.e. (tail + 1) % size = head, return 1 else return 0 ( for success)

PUSHINQUEUE: nop
; Pop the return address
POP H 
SHLD 8304H
POP H
MV

; Check if the queue is full or not
CALL QUEUEISFULL
POP H           ; Get output in HL pair
CPI L,00H       ; if HL = 0000H
JZ NOTFULLLABEL
; Failure to insert
MVI H,00H
MVI L,00H
PUSH H
JMP PUSHINDEXRETLABEL

; Get starting address
MVI A,8200
LDAX D

; Get tail index
MVI A,8206H
LHLD H

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

; Store new index of tail.
INX B
MVI A,8206H
STAX B      ; Stores the new tail index

PUSHINDEXRETLABEL: nop
LHLD 8304H
PUSH H
RET


;;; QUEUEISFULL ;;;
; Check if queue is not full ( (tail + 1) % size != head)
; First increment tail and find its modulo w.r.t. size
; If the value obtained by the above step is equal to head, queue is full (ret 1)
; else queue has space (ret 0)
QUEUEISFULL: nop
; Get the return address
POP H
SHLD 8302H  

LHLD 8206H   ; Get tail index
INX H       ; Increment tail
MVI A,8202H
LDAX D      ; Get size of queue
INX D       ; increment the size because size of the queue in memory is 1 more than
            ; the number of elements that can be stored.
; Save registers before calling REMAINDER
PUSH PSW
PUSH B
PUSH H
; Push arguments
PUSH H      ; Push the tail-index (dividend)
PUSH D      ; Push the size (divisor)
CALL REMAINDER
; Get result
POP D       ; Value of remainder
; Restore registers as before
POP H
POP B
POP PSW

MVI A,8204
LDAX B      ; Get head index 
; Compare Head and Modded-incremented tail. (B & D)
MOV A,B
CMP D
JNZ NOTSAMELABEL
MOV A,C
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
LHLD 8302H
PUSH H
RET


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
SHLD 8300H

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
LHLD 8300H
PUSH H
RET
