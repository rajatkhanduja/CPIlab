;;; QUEUE ;;;;
;
; Memory location 8200 holds the starting position of the queue (16 bit-address)
; Memory location 8202 holds the size of the queue  (16-bits)
;     Note that the size refers to the number of elements that can be stored, not 
;     the size in the memory.
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

; Check if queue is not full ( (tail + 1) % size != head)
; First increment tail and find its modulo w.r.t. size
; If the value obtained by the above step is equal to head, queue is full
; else queue has space.
;LHLD 8206H  ; Get tail index
;INX H       ; Increment tail
;MVI 8202H
;LDAX D      ; Get size of queue
;INX D       ; increment the size because size of the queue in memory is 1 more than
;            ; the number of elements that can be stored.
;PUSH H      ; Push the tail-index (dividend)
;PUSH D      ; Push the size (divisor)
;CALL REMAINDER
;POP D       ; Value of remainder
;
;MVI 
;LDAX B      ; Get head index 
; TODO : Compare Head and Modded-incremented tail. (B & D)


; Get starting address
MVI A,8200
LDAX D

; Get tail address

; Compute tail address
DAD D     ; Add starting position of queue to index position of tail




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
