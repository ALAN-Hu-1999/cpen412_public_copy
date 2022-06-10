; STRANGE.ASM - A strange addressing mode
;
; This small program illustrates an extreme example of the extra 68020 addressing-modes.
; It comes from the (bd,An,Xn.SIZE*SCALE) operand format with base displacement, address
; register and size suppressed. This is a valid 68020 addressing mode.
;
; Select 68020 or CPU32 processor to run (single step mode preferred).

           org         $400

           move.l      #$100,D0
           jmp         (D0*4)         ; jump to $400 (= infinite loop)

