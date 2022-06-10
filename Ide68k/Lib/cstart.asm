; CSTART.ASM  -  C startup-code for SIM68K

; Section definitions and memory layout

lomem      equ         $400            ; Lowest usable address
himem      equ         $10000          ; Highest memory addres + 1
stklen     equ         $1000           ; Default stacksize

           option      S0              ; write program ID to S0 record

           section     code
           org         lomem
code       equ         *               ; start address of code section (instructions in ROM)

           section     const
const      equ         *               ; start address of const section (initialized data in ROM)

           section     data
data       equ         *               ; start address of data section (initialized global data ROM/RAM))

           section     bss
bss        equ         *               ; start address of bss section (uninitialized global data in RAM)

           section     heap
heap       equ         *               ; start address of heap section (start of free memory, RAM)

           section     code
start:
           lea         bss,A0
           clr.b       (A0)+           ; set bss section to zero
           cmp.l       #heap,A0
           bcs.s       *-8
           move.l      #-1,__ungetbuf  ; unget-buffer for keyboard input
           move.l      #0,__allocp     ; pointer to allocated memory for malloc-function
           move.l      #heap,__heap    ; pointer to free memory
           move.l      #(himem-stklen),__stack ; top of stack (for stack overflow detection)
           move.l      #himem,A7       ; initial stack pointer
           jsr         _main

           xdef        __exit
__exit:                                ; exit program
           trap        #15
           dc.w        0
           bra         start           ; restart

           xdef        __putch
__putch:                               ; Basic character output routine
           move.l      4(A7),D0
           trap        #15
           dc.w        1               ; IDE68K system call 1 -> PUTCH
           rts

           xdef        __getch
__getch:                               ; Basic character input routine
           trap        #15
           dc.w        3               ; IDE68K system call 3 -> GETCH
           ext.w       D0
           ext.l       D0              ; D0.L is char, sign extended to 32 bits
           rts

           xdef        __kbhit
__kbhit:
           trap        #15
           dc.w        4               ; IDE68K system call 4 -> KBHIT
           sne         D0              ; D0.B = $FF if char in buffer, $00 if not
           rts

           xdef        __time
__time:
           trap        #15             ; IDE68K system call 40 -> GETTIME
           dc.w        40              ; D0 = seconds since Jan 1, 1970, 00:00:00 hr UTC
           rts

           xdef        __localoffset
__localoffset:
           trap        #15             ; IDE68K system call 41 -> LOCALOFFSET
           dc.w        41              ; D0 = offset in seconds between UTC and local time
           rts

           xdef        stackoverflow
stackoverflow:
           lea         himem,A7        ; reset stackpointer
           lea         stackmsg,A0
           trap        #15             ; print message
           dc.w        7
           bra         __exit          ; abort program

           section     const
stackmsg:
           dc.b        'Stack overflow!',$0A,$0D
           dc.b        'Program aborted',$0A,$0D,0

           section     bss
           xdef        __ungetbuf
__ungetbuf:
           ds.l        1               ; ungetbuffer for stdio functions
           xdef        __allocp
__allocp:
           ds.l        1               ; start of free memory block list
           xdef        __heap
__heap:
           ds.l        1               ; begin of free memory
           xdef        __stack
__stack:
           ds.l        1               ; bottom of stack