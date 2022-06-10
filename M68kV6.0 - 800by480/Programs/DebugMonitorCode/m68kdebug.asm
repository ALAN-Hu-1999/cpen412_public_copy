; G:\COURSES\ELEC 465\M68K SYSTEMS\DE1\VERILOG\M68KV6.0 - 800BY480 - (VERILOG) FOR STUDENTS\PROGRAMS\DEBUGMONITORCODE\M68KDEBUG.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include "DebugMonitor.h"
; // use 08030000 for a system running from sram or 0B000000 for system running from dram
; #define StartOfExceptionVectorTable 0x08030000
; //#define StartOfExceptionVectorTable 0x0B000000
; // use 0C000000 for dram or hex 08040000 for sram
; #define TopOfStack 0x08040000
; //#define TopOfStack 0x0C000000
; /* DO NOT INITIALISE GLOBAL VARIABLES - DO IT in MAIN() */
; unsigned int i, x, y, z, PortA_Count;
; int     Trace, GoFlag, Echo;                       // used in tracing/single stepping
; // 68000 register dump and preintialise value (these can be changed by the user program when it is running, e.g. stack pointer, registers etc
; unsigned int d0,d1,d2,d3,d4,d5,d6,d7 ;
; unsigned int a0,a1,a2,a3,a4,a5,a6 ;
; unsigned int PC, SSP, USP ;
; unsigned short int SR;
; // Breakpoint variables
; unsigned int BreakPointAddress[8];                      //array of 8 breakpoint addresses
; unsigned short int BreakPointInstruction[8] ;           // to hold the instruction opcode at the breakpoint
; unsigned int BreakPointSetOrCleared[8] ;
; unsigned int InstructionSize ;
; // watchpoint variables
; unsigned int WatchPointAddress[8];                      //array of 8 breakpoint addresses
; unsigned int WatchPointSetOrCleared[8] ;
; char WatchPointString[8][100] ;
; // for disassembly of program
; char    Instruction[100] ;
; char    TempString[100] ;
; /************************************************************************************
; *Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       section   code
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; long int  i ;
; for(i = 0; i < 1000; i ++)
       clr.l     D2
Wait1ms_1:
       cmp.l     #1000,D2
       bge.s     Wait1ms_3
       addq.l    #1,D2
       bra       Wait1ms_1
Wait1ms_3:
       move.l    (A7)+,D2
       rts
; ;
; }
; /************************************************************************************
; *Subroutine to give the 68000 something useless to do to waste 3 mSec
; **************************************************************************************/
; void Wait3ms(void)
; {
       xdef      _Wait3ms
_Wait3ms:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 3; i++)
       clr.l     D2
Wait3ms_1:
       cmp.l     #3,D2
       bge.s     Wait3ms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait3ms_1
Wait3ms_3:
       move.l    (A7)+,D2
       rts
; }
; /*********************************************************************************************
; *Subroutine to initialise the display by writing some commands to the LCD internal registers
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = (char)(0x0c) ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = (char)(0x38) ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /******************************************************************************
; *subroutine to output a single character held in d1 to the LCD display
; *it is assumed the character is an ASCII code and it will be displayed at the
; *current cursor position
; *******************************************************************************/
; void Outchar(int c)
; {
       xdef      _Outchar
_Outchar:
       link      A6,#0
; LCDdata = (char)(c);
       move.l    8(A6),D0
       move.b    D0,4194338
; Wait1ms() ;
       jsr       _Wait1ms
       unlk      A6
       rts
; }
; /**********************************************************************************
; *subroutine to output a message at the current cursor position of the LCD display
; ************************************************************************************/
; void OutMess(char *theMessage)
; {
       xdef      _OutMess
_OutMess:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != (char)(0))
OutMess_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     OutMess_3
; Outchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _Outchar
       addq.w    #4,A7
       bra       OutMess_1
OutMess_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void Clearln(void)
; {
       xdef      _Clearln
_Clearln:
       move.l    D2,-(A7)
; unsigned char i ;
; for(i = 0; i < 24; i ++)
       clr.b     D2
Clearln_1:
       cmp.b     #24,D2
       bhs.s     Clearln_3
; Outchar(' ') ;  /* write a space char to the LCD display */
       pea       32
       jsr       _Outchar
       addq.w    #4,A7
       addq.b    #1,D2
       bra       Clearln_1
Clearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; *subroutine to move the cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void Oline0(char *theMessage)
; {
       xdef      _Oline0
_Oline0:
       link      A6,#0
; LCDcommand = (char)(0x80) ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; Clearln() ;
       jsr       _Clearln
; LCDcommand = (char)(0x80) ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; OutMess(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _OutMess
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to move the cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void Oline1(char *theMessage)
; {
       xdef      _Oline1
_Oline1:
       link      A6,#0
; LCDcommand = (char)(0xC0) ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; Clearln() ;
       jsr       _Clearln
; LCDcommand = (char)(0xC0) ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; OutMess(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _OutMess
       addq.w    #4,A7
       unlk      A6
       rts
; }
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #134414336,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; void TestLEDS(void)
; {
       xdef      _TestLEDS
_TestLEDS:
       movem.l   D2/D3,-(A7)
; int delay ;
; unsigned char count = 0 ;
       clr.b     D2
; while(1)    {
TestLEDS_1:
; PortA = PortB = PortC = PortD = HEX_A = HEX_B = HEX_C = HEX_D = ((count << 4) + (count & 0x0f)) ;
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194326
       move.b    D0,4194324
       move.b    D0,4194322
       move.b    D0,4194320
       move.b    D0,4194310
       move.b    D0,4194308
       move.b    D0,4194306
       move.b    D0,4194304
; for(delay = 0; delay < 200000; delay ++)
       clr.l     D3
TestLEDS_4:
       cmp.l     #200000,D3
       bge.s     TestLEDS_6
       addq.l    #1,D3
       bra       TestLEDS_4
TestLEDS_6:
; ;
; count ++;
       addq.b    #1,D2
       bra       TestLEDS_1
; }
; }
; void SwitchTest(void)
; {
       xdef      _SwitchTest
_SwitchTest:
       movem.l   D2/D3/A2,-(A7)
       lea       _printf.L,A2
; int i, switches = 0 ;
       clr.l     D3
; printf("\r\n") ;
       pea       @m68kde~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; while(1)    {
SwitchTest_1:
; switches = (PortB << 8) | (PortA) ;
       move.b    4194306,D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.b    4194304,D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D3
; printf("\rSwitches SW[7-0] = ") ;
       pea       @m68kde~1_2.L
       jsr       (A2)
       addq.w    #4,A7
; for( i = (int)(0x00000080); i > 0; i = i >> 1)  {
       move.l    #128,D2
SwitchTest_4:
       cmp.l     #0,D2
       ble.s     SwitchTest_6
; if((switches & i) == 0)
       move.l    D3,D0
       and.l     D2,D0
       bne.s     SwitchTest_7
; printf("0") ;
       pea       @m68kde~1_3.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     SwitchTest_8
SwitchTest_7:
; else
; printf("1") ;
       pea       @m68kde~1_4.L
       jsr       (A2)
       addq.w    #4,A7
SwitchTest_8:
       asr.l     #1,D2
       bra       SwitchTest_4
SwitchTest_6:
       bra       SwitchTest_1
; }
; }
; }
; /*********************************************************************************************
; *Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; int kbhit(void)
; {
       xdef      _kbhit
_kbhit:
; if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // wait for Rx bit in status register to be '1'
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne.s     kbhit_1
; return 1 ;
       moveq     #1,D0
       bra.s     kbhit_3
kbhit_1:
; else
; return 0 ;
       clr.l     D0
kbhit_3:
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level output function to 6850 ACIA
; **  This routine provides the basic functionality to output a single character to the serial Port
; **  to allow the board to communicate with HyperTerminal Program
; **
; **  NOTE you do not call this function directly, instead you call the normal putchar() function
; **  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
; **  call _putch() also
; *********************************************************************************************************/
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.b     #127,D0
       move.b    D0,4194370
; return c ;                                              // putchar() expects the character to be returned
       move.l    8(A6),D0
       unlk      A6
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level input function to 6850 ACIA
; **  This routine provides the basic functionality to input a single character from the serial Port
; **  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
; **
; **  NOTE you do not call this function directly, instead you call the normal _getch() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       move.l    D2,-(A7)
; int c ;
; while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       move.l    D0,D2
; // shall we echo the character? Echo is set to TRUE at reset, but for speed we don't want to echo when downloading code with the 'L' debugger command
; if(Echo)
       tst.l     _Echo.L
       beq.s     _getch_4
; _putch(c);
       move.l    D2,-(A7)
       jsr       __putch
       addq.w    #4,A7
_getch_4:
; return c ;
       move.l    D2,D0
       move.l    (A7)+,D2
       rts
; }
; // flush the input stream for any unread characters
; void FlushKeyboard(void)
; {
       xdef      _FlushKeyboard
_FlushKeyboard:
       link      A6,#-4
; char c ;
; while(1)    {
FlushKeyboard_1:
; if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // if Rx bit in status register is '1'
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne.s     FlushKeyboard_4
; c = ((char)(RS232_RxData) & (char)(0x7f)) ;
       move.b    4194370,D0
       and.b     #127,D0
       move.b    D0,-1(A6)
       bra.s     FlushKeyboard_5
FlushKeyboard_4:
; else
; return ;
       bra.s     FlushKeyboard_6
FlushKeyboard_5:
       bra       FlushKeyboard_1
FlushKeyboard_6:
       unlk      A6
       rts
; }
; }
; // converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
; // char assumed to be a valid hex char 0-9, a-f, A-F
; char xtod(int c)
; {
       xdef      _xtod
_xtod:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if ((char)(c) <= (char)('9'))
       cmp.b     #57,D2
       bgt.s     xtod_1
; return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
       move.b    D2,D0
       sub.b     #48,D0
       bra.s     xtod_3
xtod_1:
; else if((char)(c) > (char)('F'))    // assume lower case
       cmp.b     #70,D2
       ble.s     xtod_4
; return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
       move.b    D2,D0
       sub.b     #87,D0
       bra.s     xtod_3
xtod_4:
; else
; return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
       move.b    D2,D0
       sub.b     #55,D0
xtod_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get2HexDigits(char *CheckSumPtr)
; {
       xdef      _Get2HexDigits
_Get2HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = (xtod(_getch()) << 4) | (xtod(_getch()));
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; if(CheckSumPtr)
       tst.l     8(A6)
       beq.s     Get2HexDigits_1
; *CheckSumPtr += i ;
       move.l    8(A6),A0
       add.b     D2,(A0)
Get2HexDigits_1:
; return i ;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get4HexDigits(char *CheckSumPtr)
; {
       xdef      _Get4HexDigits
_Get4HexDigits:
       link      A6,#0
; return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get6HexDigits(char *CheckSumPtr)
; {
       xdef      _Get6HexDigits
_Get6HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get8HexDigits(char *CheckSumPtr)
; {
       xdef      _Get8HexDigits
_Get8HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; char *strcatInstruction(char *s) {    return strcat(Instruction,s) ; }
       xdef      _strcatInstruction
_strcatInstruction:
       link      A6,#0
       move.l    8(A6),-(A7)
       pea       _Instruction.L
       jsr       _strcat
       addq.w    #8,A7
       unlk      A6
       rts
; char *strcpyInstruction(char *s) {    return strcpy(Instruction,s) ; }
       xdef      _strcpyInstruction
_strcpyInstruction:
       link      A6,#0
       move.l    8(A6),-(A7)
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
       unlk      A6
       rts
; void DisassembleProgram(void )
; {
       xdef      _DisassembleProgram
_DisassembleProgram:
       link      A6,#-8
       movem.l   D2/D3/A2/A3/A4,-(A7)
       lea       _InstructionSize.L,A2
       lea       _printf.L,A3
       lea       _Instruction.L,A4
; char c ;
; int i, j ;
; unsigned short int *ProgramPtr ; // pointer to where the program is stored
; printf("\r\nEnter Start Address: ") ;
       pea       @m68kde~1_5.L
       jsr       (A3)
       addq.w    #4,A7
; ProgramPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\n<ESC> = Abort, SPACE to Continue") ;
       pea       @m68kde~1_6.L
       jsr       (A3)
       addq.w    #4,A7
; while(1)    {
DisassembleProgram_1:
; for(i = 0; i < 20; i ++)
       clr.l     D3
DisassembleProgram_4:
       cmp.l     #20,D3
       bge       DisassembleProgram_6
; {
; InstructionSize = 1 ;                   // assume all instruction are at least 1 word
       move.l    #1,(A2)
; DisassembleInstruction(ProgramPtr) ;    // build up string for disassembled instruction at address in programptr
       move.l    D2,-(A7)
       jsr       _DisassembleInstruction
       addq.w    #4,A7
; if(InstructionSize == 1)
       move.l    (A2),D0
       cmp.l     #1,D0
       bne.s     DisassembleProgram_7
; printf("\r\n%08X  %04X                        %s", ProgramPtr, ProgramPtr[0], Instruction) ;
       move.l    A4,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_7.L
       jsr       (A3)
       add.w     #16,A7
       bra       DisassembleProgram_15
DisassembleProgram_7:
; else if(InstructionSize == 2)
       move.l    (A2),D0
       cmp.l     #2,D0
       bne.s     DisassembleProgram_9
; printf("\r\n%08X  %04X %04X                   %s", ProgramPtr, ProgramPtr[0], ProgramPtr[1], Instruction) ;
       move.l    A4,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_8.L
       jsr       (A3)
       add.w     #20,A7
       bra       DisassembleProgram_15
DisassembleProgram_9:
; else if(InstructionSize == 3)
       move.l    (A2),D0
       cmp.l     #3,D0
       bne       DisassembleProgram_11
; printf("\r\n%08X  %04X %04X %04X              %s", ProgramPtr, ProgramPtr[0], ProgramPtr[1], ProgramPtr[2], Instruction) ;
       move.l    A4,-(A7)
       move.l    D2,A0
       move.w    4(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_9.L
       jsr       (A3)
       add.w     #24,A7
       bra       DisassembleProgram_15
DisassembleProgram_11:
; else if(InstructionSize == 4)
       move.l    (A2),D0
       cmp.l     #4,D0
       bne       DisassembleProgram_13
; printf("\r\n%08X  %04X %04X %04X %04X         %s", ProgramPtr, ProgramPtr[0], ProgramPtr[1], ProgramPtr[2], ProgramPtr[3], Instruction) ;
       move.l    A4,-(A7)
       move.l    D2,A0
       move.w    6(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    4(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_10.L
       jsr       (A3)
       add.w     #28,A7
       bra       DisassembleProgram_15
DisassembleProgram_13:
; else if(InstructionSize == 5)
       move.l    (A2),D0
       cmp.l     #5,D0
       bne       DisassembleProgram_15
; printf("\r\n%08X  %04X %04X %04X %04X %04X    %s", ProgramPtr, ProgramPtr[0], ProgramPtr[1], ProgramPtr[2], ProgramPtr[3], ProgramPtr[4], Instruction) ;
       move.l    A4,-(A7)
       move.l    D2,A0
       move.w    8(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    6(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    4(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_11.L
       jsr       (A3)
       add.w     #32,A7
DisassembleProgram_15:
; ProgramPtr += InstructionSize ;
       move.l    (A2),D0
       lsl.l     #1,D0
       add.l     D0,D2
       addq.l    #1,D3
       bra       DisassembleProgram_4
DisassembleProgram_6:
; }
; c = _getch() ;
       jsr       __getch
       move.b    D0,-5(A6)
; if(c == 0x1b)          // break on ESC
       move.b    -5(A6),D0
       cmp.b     #27,D0
       bne.s     DisassembleProgram_17
; return ;
       bra.s     DisassembleProgram_19
DisassembleProgram_17:
       bra       DisassembleProgram_1
DisassembleProgram_19:
       movem.l   (A7)+,D2/D3/A2/A3/A4
       unlk      A6
       rts
; }
; }
; void DumpMemory(void)   // simple dump memory fn
; {
       xdef      _DumpMemory
_DumpMemory:
       movem.l   D2/D3/D4/D5/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _putch.L,A3
; int i, j ;
; unsigned char *RamPtr,c ; // pointer to where the program is download (assumed)
; printf("\r\nDump Memory Block: <ESC> to Abort, <SPACE> to Continue") ;
       pea       @m68kde~1_12.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter Start Address: ") ;
       pea       @m68kde~1_13.L
       jsr       (A2)
       addq.w    #4,A7
; RamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; while(1)    {
DumpMemory_1:
; for(i = 0; i < 16; i ++)    {
       clr.l     D5
DumpMemory_4:
       cmp.l     #16,D5
       bge       DumpMemory_6
; printf("\r\n%08x ", RamPtr) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_14.L
       jsr       (A2)
       addq.w    #8,A7
; for(j=0; j < 16; j ++)  {
       clr.l     D2
DumpMemory_7:
       cmp.l     #16,D2
       bge.s     DumpMemory_9
; printf("%02X",RamPtr[j]) ;
       move.l    D3,A0
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_15.L
       jsr       (A2)
       addq.w    #8,A7
; putchar(' ') ;
       pea       32
       jsr       (A3)
       addq.w    #4,A7
       addq.l    #1,D2
       bra       DumpMemory_7
DumpMemory_9:
; }
; // now display the data as ASCII at the end
; printf("  ") ;
       pea       @m68kde~1_16.L
       jsr       (A2)
       addq.w    #4,A7
; for(j = 0; j < 16; j++) {
       clr.l     D2
DumpMemory_10:
       cmp.l     #16,D2
       bge       DumpMemory_12
; c = ((char)(RamPtr[j]) & 0x7f) ;
       move.l    D3,A0
       move.b    0(A0,D2.L),D0
       and.b     #127,D0
       move.b    D0,D4
; if((c > (char)(0x7f)) || (c < ' '))
       cmp.b     #127,D4
       bhi.s     DumpMemory_15
       cmp.b     #32,D4
       bhs.s     DumpMemory_13
DumpMemory_15:
; putchar('.') ;
       pea       46
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DumpMemory_14
DumpMemory_13:
; else
; putchar(RamPtr[j]) ;
       move.l    D3,A0
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
DumpMemory_14:
       addq.l    #1,D2
       bra       DumpMemory_10
DumpMemory_12:
; }
; RamPtr = RamPtr + 16 ;
       add.l     #16,D3
       addq.l    #1,D5
       bra       DumpMemory_4
DumpMemory_6:
; }
; printf("\r\n") ;
       pea       @m68kde~1_17.L
       jsr       (A2)
       addq.w    #4,A7
; c = _getch() ;
       jsr       __getch
       move.b    D0,D4
; if(c == 0x1b)          // break on ESC
       cmp.b     #27,D4
       bne.s     DumpMemory_16
; break ;
       bra.s     DumpMemory_3
DumpMemory_16:
       bra       DumpMemory_1
DumpMemory_3:
       movem.l   (A7)+,D2/D3/D4/D5/A2/A3
       rts
; }
; }
; void FillMemory()
; {
       xdef      _FillMemory
_FillMemory:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
; char *StartRamPtr, *EndRamPtr ;
; unsigned char FillData ;
; printf("\r\nFill Memory Block") ;
       pea       @m68kde~1_18.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter Start Address: ") ;
       pea       @m68kde~1_19.L
       jsr       (A2)
       addq.w    #4,A7
; StartRamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\nEnter End Address: ") ;
       pea       @m68kde~1_20.L
       jsr       (A2)
       addq.w    #4,A7
; EndRamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D4
; printf("\r\nEnter Fill Data: ") ;
       pea       @m68kde~1_21.L
       jsr       (A2)
       addq.w    #4,A7
; FillData = Get2HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.b    D0,D3
; printf("\r\nFilling Addresses [$%08X - $%08X] with $%02X", StartRamPtr, EndRamPtr, FillData) ;
       and.l     #255,D3
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_22.L
       jsr       (A2)
       add.w     #16,A7
; while(StartRamPtr < EndRamPtr)
FillMemory_1:
       cmp.l     D4,D2
       bhs.s     FillMemory_3
; *StartRamPtr++ = FillData ;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    D3,(A0)
       bra       FillMemory_1
FillMemory_3:
       movem.l   (A7)+,D2/D3/D4/A2
       rts
; }
; void Load_SRecordFile()
; {
       xdef      _Load_SRecordFile
_Load_SRecordFile:
       link      A6,#-36
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       -6(A6),A2
       lea       _Get2HexDigits.L,A3
       lea       _printf.L,A4
; int i, Address, AddressSize, DataByte, NumDataBytesToRead, LoadFailed, FailedAddress, AddressFail, SRecordCount = 0, ByteTotal = 0 ;
       clr.l     -18(A6)
       move.w    #0,A5
; int result, ByteCount ;
; char c, CheckSum, ReadCheckSum, HeaderType ;
; char *RamPtr ;                          // pointer to Memory where downloaded program will be stored
; LoadFailed = 0 ;                        //assume LOAD operation will pass
       moveq     #0,D7
; AddressFail = 0 ;
       clr.l     -22(A6)
; Echo = 0 ;                              // don't echo S records during download
       clr.l     _Echo.L
; printf("\r\nUse HyperTerminal to Send Text File (.hex)\r\n") ;
       pea       @m68kde~1_23.L
       jsr       (A4)
       addq.w    #4,A7
; while(1)    {
Load_SRecordFile_1:
; CheckSum = 0 ;
       clr.b     (A2)
; do {
Load_SRecordFile_4:
; c = toupper(_getch()) ;
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D6
; if(c == 0x1b )      // if break
       cmp.b     #27,D6
       bne.s     Load_SRecordFile_6
; return;
       bra       Load_SRecordFile_8
Load_SRecordFile_6:
       cmp.b     #83,D6
       bne       Load_SRecordFile_4
; }while(c != (char)('S'));   // wait for S start of header
; HeaderType = _getch() ;
       jsr       __getch
       move.b    D0,D3
; if(HeaderType == (char)('0') || HeaderType == (char)('5'))       // ignore s0, s5 records
       cmp.b     #48,D3
       beq.s     Load_SRecordFile_11
       cmp.b     #53,D3
       bne.s     Load_SRecordFile_9
Load_SRecordFile_11:
; continue ;
       bra       Load_SRecordFile_23
Load_SRecordFile_9:
; if(HeaderType >= (char)('7'))
       cmp.b     #55,D3
       blt.s     Load_SRecordFile_12
; break ;                 // end load on s7,s8,s9 records
       bra       Load_SRecordFile_3
Load_SRecordFile_12:
; // get the bytecount
; ByteCount = Get2HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,-10(A6)
; // get the address, 4 digits for s1, 6 digits for s2, and 8 digits for s3 record
; if(HeaderType == (char)('1')) {
       cmp.b     #49,D3
       bne.s     Load_SRecordFile_14
; AddressSize = 2 ;       // 2 byte address
       moveq     #2,D5
; Address = Get4HexDigits(&CheckSum);
       move.l    A2,-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D4
       bra.s     Load_SRecordFile_17
Load_SRecordFile_14:
; }
; else if (HeaderType == (char)('2')) {
       cmp.b     #50,D3
       bne.s     Load_SRecordFile_16
; AddressSize = 3 ;       // 3 byte address
       moveq     #3,D5
; Address = Get6HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       _Get6HexDigits
       addq.w    #4,A7
       move.l    D0,D4
       bra.s     Load_SRecordFile_17
Load_SRecordFile_16:
; }
; else    {
; AddressSize = 4 ;       // 4 byte address
       moveq     #4,D5
; Address = Get8HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D4
Load_SRecordFile_17:
; }
; RamPtr = (char *)(Address) ;                            // point to download area
       move.l    D4,-4(A6)
; NumDataBytesToRead = ByteCount - AddressSize - 1 ;
       move.l    -10(A6),D0
       sub.l     D5,D0
       subq.l    #1,D0
       move.l    D0,-30(A6)
; for(i = 0; i < NumDataBytesToRead; i ++) {     // read in remaining data bytes (ignore address and checksum at the end
       clr.l     D2
Load_SRecordFile_18:
       cmp.l     -30(A6),D2
       bge.s     Load_SRecordFile_20
; DataByte = Get2HexDigits(&CheckSum) ;
       move.l    A2,-(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,-34(A6)
; *RamPtr++ = DataByte ;                      // store downloaded byte in Ram at specified address
       move.l    -34(A6),D0
       move.l    -4(A6),A0
       addq.l    #1,-4(A6)
       move.b    D0,(A0)
; ByteTotal++;
       addq.w    #1,A5
       addq.l    #1,D2
       bra       Load_SRecordFile_18
Load_SRecordFile_20:
; }
; // checksum is the 1's complement of the sum of all data pairs following the bytecount, i.e. it includes the address and the data itself
; ReadCheckSum = Get2HexDigits(0) ;
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.b    D0,-5(A6)
; if((~CheckSum&0Xff) != (ReadCheckSum&0Xff))   {
       move.b    (A2),D0
       not.b     D0
       ext.w     D0
       and.w     #255,D0
       move.b    -5(A6),D1
       ext.w     D1
       and.w     #255,D1
       cmp.w     D1,D0
       beq.s     Load_SRecordFile_21
; LoadFailed = 1 ;
       moveq     #1,D7
; FailedAddress = Address ;
       move.l    D4,-26(A6)
; break;
       bra.s     Load_SRecordFile_3
Load_SRecordFile_21:
; }
; SRecordCount++ ;
       addq.l    #1,-18(A6)
; // display feedback on progress
; if(SRecordCount % 25 == 0)
       move.l    -18(A6),-(A7)
       pea       25
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     Load_SRecordFile_23
; putchar('.') ;
       pea       46
       jsr       _putch
       addq.w    #4,A7
Load_SRecordFile_23:
       bra       Load_SRecordFile_1
Load_SRecordFile_3:
; }
; if(LoadFailed == 1) {
       cmp.l     #1,D7
       bne.s     Load_SRecordFile_25
; printf("\r\nLoad Failed at Address = [$%08X]\r\n", FailedAddress) ;
       move.l    -26(A6),-(A7)
       pea       @m68kde~1_24.L
       jsr       (A4)
       addq.w    #8,A7
       bra.s     Load_SRecordFile_26
Load_SRecordFile_25:
; }
; else
; printf("\r\nSuccess: Downloaded %d bytes\r\n", ByteTotal) ;
       move.l    A5,-(A7)
       pea       @m68kde~1_25.L
       jsr       (A4)
       addq.w    #8,A7
Load_SRecordFile_26:
; // pause at the end to wait for download to finish transmitting at the end of S8 etc
; for(i = 0; i < 400000; i ++)
       clr.l     D2
Load_SRecordFile_27:
       cmp.l     #400000,D2
       bge.s     Load_SRecordFile_29
       addq.l    #1,D2
       bra       Load_SRecordFile_27
Load_SRecordFile_29:
; ;
; FlushKeyboard() ;
       jsr       _FlushKeyboard
; Echo = 1;
       move.l    #1,_Echo.L
Load_SRecordFile_8:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void MemoryChange(void)
; {
       xdef      _MemoryChange
_MemoryChange:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
; unsigned char *RamPtr,c ; // pointer to memory
; int Data ;
; printf("\r\nExamine and Change Memory") ;
       pea       @m68kde~1_26.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n<ESC> to Stop, <SPACE> to Advance, '-' to Go Back, <DATA> to change") ;
       pea       @m68kde~1_27.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter Address: ") ;
       pea       @m68kde~1_28.L
       jsr       (A2)
       addq.w    #4,A7
; RamPtr = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; while(1)    {
MemoryChange_1:
; printf("\r\n[%08x] : %02x  ", RamPtr, *RamPtr) ;
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       pea       @m68kde~1_29.L
       jsr       (A2)
       add.w     #12,A7
; c = tolower(_getch()) ;
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.b    D0,D2
; if(c == (char)(0x1b))
       cmp.b     #27,D2
       bne.s     MemoryChange_4
; return ;                                // abort on escape
       bra       MemoryChange_6
MemoryChange_4:
; else if((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {  // are we trying to change data at this location by entering a hex char
       cmp.b     #48,D2
       blo.s     MemoryChange_10
       cmp.b     #57,D2
       bls.s     MemoryChange_9
MemoryChange_10:
       cmp.b     #97,D2
       blo       MemoryChange_7
       cmp.b     #102,D2
       bhi       MemoryChange_7
MemoryChange_9:
; Data = (xtod(c) << 4) | (xtod(_getch()));
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D4
; *RamPtr = (char)(Data) ;
       move.l    D3,A0
       move.b    D4,(A0)
; if(*RamPtr != Data) {
       move.l    D3,A0
       move.b    (A0),D0
       and.l     #255,D0
       cmp.l     D4,D0
       beq.s     MemoryChange_11
; printf("\r\nWarning Change Failed: Wrote [%02x], Read [%02x]", Data, *RamPtr) ;
       move.l    D3,A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D4,-(A7)
       pea       @m68kde~1_30.L
       jsr       (A2)
       add.w     #12,A7
MemoryChange_11:
       bra.s     MemoryChange_13
MemoryChange_7:
; }
; }
; else if(c == (char)('-'))
       cmp.b     #45,D2
       bne.s     MemoryChange_13
; RamPtr -= 2 ; ;
       subq.l    #2,D3
MemoryChange_13:
; RamPtr ++ ;
       addq.l    #1,D3
       bra       MemoryChange_1
MemoryChange_6:
       movem.l   (A7)+,D2/D3/D4/A2
       rts
; }
; }
; /*******************************************************************
; ** Write a program to SPI Flash Chip from memory and verify by reading back
; ********************************************************************/
; void ProgramFlashChip(void)
; {
       xdef      _ProgramFlashChip
_ProgramFlashChip:
       rts
; //
; // TODO : put your code here to program the 1st 256k of ram (where user program is held at hex 08000000) to SPI flash chip
; // TODO : then verify by reading it back and comparing to memory
; //
; }
; /*************************************************************************
; ** Load a program from SPI Flash Chip and copy to Dram
; **************************************************************************/
; void LoadFromFlashChip(void)
; {
       xdef      _LoadFromFlashChip
_LoadFromFlashChip:
; printf("\r\nLoading Program From SPI Flash....") ;
       pea       @m68kde~1_31.L
       jsr       _printf
       addq.w    #4,A7
       rts
; //
; // TODO : put your code here to read 256k of data from SPI flash chip and store in user ram starting at hex 08000000
; //
; }
; // get rid of excess spaces
; void FormatInstructionForTrace(void)
; {
       xdef      _FormatInstructionForTrace
_FormatInstructionForTrace:
       link      A6,#-100
       movem.l   D2/D3/D4/D5/A2,-(A7)
       lea       -100(A6),A2
; unsigned short int i ;
; char c, temp[100], *iptr, *tempptr ;
; for(i=0; i < 100; i++)
       clr.w     D4
FormatInstructionForTrace_1:
       cmp.w     #100,D4
       bhs.s     FormatInstructionForTrace_3
; temp[i] = 0 ;
       and.l     #65535,D4
       clr.b     0(A2,D4.L)
       addq.w    #1,D4
       bra       FormatInstructionForTrace_1
FormatInstructionForTrace_3:
; iptr = Instruction ;
       lea       _Instruction.L,A0
       move.l    A0,D2
; tempptr = temp ;
       move.l    A2,D5
; do{
FormatInstructionForTrace_4:
; c = *iptr++ ;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    (A0),D3
; *tempptr++ = c ;  // copy chars over
       move.l    D5,A0
       addq.l    #1,D5
       move.b    D3,(A0)
; if(c == ' ')  {   // if copied space
       cmp.b     #32,D3
       bne.s     FormatInstructionForTrace_6
; while(*iptr == ' ') {
FormatInstructionForTrace_8:
       move.l    D2,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       bne.s     FormatInstructionForTrace_10
; if(*iptr == 0)  // if end of string then done
       move.l    D2,A0
       move.b    (A0),D0
       bne.s     FormatInstructionForTrace_11
; break ;
       bra.s     FormatInstructionForTrace_10
FormatInstructionForTrace_11:
; iptr++ ; // skip over remaining spaces
       addq.l    #1,D2
       bra       FormatInstructionForTrace_8
FormatInstructionForTrace_10:
; }
; strcat(tempptr,iptr) ;
       move.l    D2,-(A7)
       move.l    D5,-(A7)
       jsr       _strcat
       addq.w    #8,A7
FormatInstructionForTrace_6:
       tst.b     D3
       bne       FormatInstructionForTrace_4
; }
; }while(c != 0) ;
; strcpyInstruction(temp) ;
       move.l    A2,-(A7)
       jsr       _strcpyInstruction
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; //////////////////////////////////////////////////////////////////////////////////////////////////
; // IMPORTANT
; // TG68 does not support the Native Trace mode of the original 68000 so tracing
; // has to be done with an interrupt (IRQ Level 6)
; //
; // To allow the 68000 to execute one more instruction after each pseudo trace (IRQ6)
; // the IRQ is removed in hardware once the TG68 reads the IRQ autovector (i.e. acknowledges the IRQ)
; //
; // on return from the IRQ service handler, the first access to the user memory program space
; // generates a fresh IRQ (in hardware) to generate a new trace, this allows the tg68 to
; // execute one more new instruction (without it the TG68 would trace on the same instruction
; // each time and not after the next one). It also means it doesn't simgle step outside the user
; // program area
; //
; // The bottom line is the Trace handler, which includes the Dump registers below
; // cannot access the user memory to display for example the Instruction Opcode or to disassemble etc
; // as this would lead to a new IRQ being reset and the TG68 would trace on same instruction
; // NOT SURE THIS IS TRUE NOW THAT TRACE HANDLER HAS BEEN MODIVIED TO NOT AUTOMATICALLY GENERATE A TRACE EXCEPTION
; // INSTEAD IT IS DONE IN THE 'N' COMMAND FOR NEXT
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; void DumpRegisters()
; {
       xdef      _DumpRegisters
_DumpRegisters:
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _putch.L,A2
       lea       _printf.L,A3
       lea       _SR.L,A4
       lea       _WatchPointString.L,A5
; short i, x, j, k ;
; unsigned char c, *BytePointer;
; // buld up strings for displaying watchpoints
; for(x = 0; x < (short)(8); x++)
       clr.w     D2
DumpRegisters_1:
       cmp.w     #8,D2
       bge       DumpRegisters_3
; {
; if(WatchPointSetOrCleared[x] == 1)
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne       DumpRegisters_4
; {
; sprintf(WatchPointString[x], "$%08X  ", WatchPointAddress[x]) ;
       ext.l     D2
       move.l    D2,D1
       lsl.l     #2,D1
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D1.L),-(A7)
       pea       @m68kde~1_32.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _sprintf
       add.w     #12,A7
; BytePointer = (char *)(WatchPointAddress[x]) ;
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D0.L),D5
; for(j = 0; j < (short)(16); j+=2)
       clr.w     D3
DumpRegisters_6:
       cmp.w     #16,D3
       bge       DumpRegisters_8
; {
; for(k = 0; k < (short)(2); k++)
       clr.w     D6
DumpRegisters_9:
       cmp.w     #2,D6
       bge       DumpRegisters_11
; {
; sprintf(TempString, "%02X", BytePointer[j+k]) ;
       move.l    D5,A0
       ext.l     D3
       move.l    D3,D1
       ext.l     D6
       add.l     D6,D1
       move.b    0(A0,D1.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_33.L
       pea       _TempString.L
       jsr       _sprintf
       add.w     #12,A7
; strcat(WatchPointString[x], TempString) ;
       pea       _TempString.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       addq.w    #1,D6
       bra       DumpRegisters_9
DumpRegisters_11:
; }
; strcat(WatchPointString[x]," ") ;
       pea       @m68kde~1_34.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       addq.w    #2,D3
       bra       DumpRegisters_6
DumpRegisters_8:
; }
; strcat(WatchPointString[x], "  ") ;
       pea       @m68kde~1_35.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
; BytePointer = (char *)(WatchPointAddress[x]) ;
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D0.L),D5
; for(j = 0; j < (short)(16); j++)
       clr.w     D3
DumpRegisters_12:
       cmp.w     #16,D3
       bge       DumpRegisters_14
; {
; c = ((char)(BytePointer[j]) & 0x7f) ;
       move.l    D5,A0
       ext.l     D3
       move.b    0(A0,D3.L),D0
       and.b     #127,D0
       move.b    D0,D7
; if((c > (char)(0x7f)) || (c < (char)(' ')))
       cmp.b     #127,D7
       bhi.s     DumpRegisters_17
       cmp.b     #32,D7
       bhs.s     DumpRegisters_15
DumpRegisters_17:
; sprintf(TempString, ".") ;
       pea       @m68kde~1_36.L
       pea       _TempString.L
       jsr       _sprintf
       addq.w    #8,A7
       bra.s     DumpRegisters_16
DumpRegisters_15:
; else
; sprintf(TempString, "%c", BytePointer[j]) ;
       move.l    D5,A0
       ext.l     D3
       move.b    0(A0,D3.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_37.L
       pea       _TempString.L
       jsr       _sprintf
       add.w     #12,A7
DumpRegisters_16:
; strcat(WatchPointString[x], TempString) ;
       pea       _TempString.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcat
       addq.w    #8,A7
       addq.w    #1,D3
       bra       DumpRegisters_12
DumpRegisters_14:
       bra.s     DumpRegisters_5
DumpRegisters_4:
; }
; }
; else
; strcpy(WatchPointString[x], "") ;
       pea       @m68kde~1_38.L
       move.l    A5,D1
       ext.l     D2
       move.l    D0,-(A7)
       move.l    D2,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _strcpy
       addq.w    #8,A7
DumpRegisters_5:
       addq.w    #1,D2
       bra       DumpRegisters_1
DumpRegisters_3:
; }
; printf("\r\n\r\n D0 = $%08X  A0 = $%08X",d0,a0) ;
       move.l    _a0.L,-(A7)
       move.l    _d0.L,-(A7)
       pea       @m68kde~1_39.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D1 = $%08X  A1 = $%08X",d1,a1) ;
       move.l    _a1.L,-(A7)
       move.l    _d1.L,-(A7)
       pea       @m68kde~1_40.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D2 = $%08X  A2 = $%08X",d2,a2) ;
       move.l    _a2.L,-(A7)
       move.l    _d2.L,-(A7)
       pea       @m68kde~1_41.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D3 = $%08X  A3 = $%08X",d3,a3) ;
       move.l    _a3.L,-(A7)
       move.l    _d3.L,-(A7)
       pea       @m68kde~1_42.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D4 = $%08X  A4 = $%08X",d4,a4) ;
       move.l    _a4.L,-(A7)
       move.l    _d4.L,-(A7)
       pea       @m68kde~1_43.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D5 = $%08X  A5 = $%08X",d5,a5) ;
       move.l    _a5.L,-(A7)
       move.l    _d5.L,-(A7)
       pea       @m68kde~1_44.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D6 = $%08X  A6 = $%08X",d6,a6) ;
       move.l    _a6.L,-(A7)
       move.l    _d6.L,-(A7)
       pea       @m68kde~1_45.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n D7 = $%08X  A7 = $%08X",d7,((SR & (unsigned short int)(0x2000)) == ((unsigned short int)(0x2000))) ? SSP : USP) ;
       move.w    (A4),D1
       and.w     #8192,D1
       cmp.w     #8192,D1
       bne.s     DumpRegisters_18
       move.l    _SSP.L,D1
       bra.s     DumpRegisters_19
DumpRegisters_18:
       move.l    _USP.L,D1
DumpRegisters_19:
       move.l    D1,-(A7)
       move.l    _d7.L,-(A7)
       pea       @m68kde~1_46.L
       jsr       (A3)
       add.w     #12,A7
; printf("\r\n\r\nUSP = $%08X  (A7) User SP", USP ) ;
       move.l    _USP.L,-(A7)
       pea       @m68kde~1_47.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\nSSP = $%08X  (A7) Supervisor SP", SSP) ;
       move.l    _SSP.L,-(A7)
       pea       @m68kde~1_48.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n SR = $%04X   ",SR) ;
       move.w    (A4),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_49.L
       jsr       (A3)
       addq.w    #8,A7
; // display the status word in characters etc.
; printf("   [") ;
       pea       @m68kde~1_50.L
       jsr       (A3)
       addq.w    #4,A7
; if((SR & (unsigned short int)(0x8000)) == (unsigned short int)(0x8000)) putchar('T') ; else putchar('-') ;      // Trace bit(bit 15)
       move.w    (A4),D0
       and.w     #32768,D0
       cmp.w     #32768,D0
       bne.s     DumpRegisters_20
       pea       84
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_21
DumpRegisters_20:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_21:
; if((SR & (unsigned short int)(0x2000)) == (unsigned short int)(0x2000)) putchar('S') ; else putchar('U') ;      // supervisor bit  (bit 13)
       move.w    (A4),D0
       and.w     #8192,D0
       cmp.w     #8192,D0
       bne.s     DumpRegisters_22
       pea       83
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_23
DumpRegisters_22:
       pea       85
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_23:
; if((SR & (unsigned short int)(0x0400)) == (unsigned short int)(0x0400)) putchar('1') ; else putchar('0') ;      // IRQ2 Bit (bit 10)
       move.w    (A4),D0
       and.w     #1024,D0
       cmp.w     #1024,D0
       bne.s     DumpRegisters_24
       pea       49
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_25
DumpRegisters_24:
       pea       48
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_25:
; if((SR & (unsigned short int)(0x0200)) == (unsigned short int)(0x0200)) putchar('1') ; else putchar('0') ;      // IRQ1 Bit (bit 9)
       move.w    (A4),D0
       and.w     #512,D0
       cmp.w     #512,D0
       bne.s     DumpRegisters_26
       pea       49
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_27
DumpRegisters_26:
       pea       48
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_27:
; if((SR & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100)) putchar('1') ; else putchar('0') ;      // IRQ0 Bit (bit 8)
       move.w    (A4),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DumpRegisters_28
       pea       49
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_29
DumpRegisters_28:
       pea       48
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_29:
; if((SR & (unsigned short int)(0x0010)) == (unsigned short int)(0x0010)) putchar('X') ; else putchar('-') ;      // X Bit (bit 4)
       move.w    (A4),D0
       and.w     #16,D0
       cmp.w     #16,D0
       bne.s     DumpRegisters_30
       pea       88
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_31
DumpRegisters_30:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_31:
; if((SR & (unsigned short int)(0x0008)) == (unsigned short int)(0x0008)) putchar('N') ; else putchar('-') ;      // N Bit (bit 3)
       move.w    (A4),D0
       and.w     #8,D0
       cmp.w     #8,D0
       bne.s     DumpRegisters_32
       pea       78
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_33
DumpRegisters_32:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_33:
; if((SR & (unsigned short int)(0x0004)) == (unsigned short int)(0x0004)) putchar('Z') ; else putchar('-') ;      // Z Bit (bit 2)
       move.w    (A4),D0
       and.w     #4,D0
       cmp.w     #4,D0
       bne.s     DumpRegisters_34
       pea       90
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_35
DumpRegisters_34:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_35:
; if((SR & (unsigned short int)(0x0002)) == (unsigned short int)(0x0002)) putchar('V') ; else putchar('-') ;      // V Bit (bit 1)
       move.w    (A4),D0
       and.w     #2,D0
       cmp.w     #2,D0
       bne.s     DumpRegisters_36
       pea       86
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_37
DumpRegisters_36:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_37:
; if((SR & (unsigned short int)(0x0001)) == (unsigned short int)(0x0001)) putchar('C') ; else putchar('-') ;      // C Bit (bit 0)
       move.w    (A4),D0
       and.w     #1,D0
       cmp.w     #1,D0
       bne.s     DumpRegisters_38
       pea       67
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DumpRegisters_39
DumpRegisters_38:
       pea       45
       jsr       (A2)
       addq.w    #4,A7
DumpRegisters_39:
; putchar(']') ;
       pea       93
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n PC = $%08X  ", PC) ;
       move.l    _PC.L,-(A7)
       pea       @m68kde~1_51.L
       jsr       (A3)
       addq.w    #8,A7
; if(*(unsigned short int *)(PC) != 0x4e4e)   {
       move.l    _PC.L,D0
       move.l    D0,A0
       move.w    (A0),D0
       cmp.w     #20046,D0
       beq.s     DumpRegisters_40
; DisassembleInstruction(PC) ;
       move.l    _PC.L,-(A7)
       jsr       _DisassembleInstruction
       addq.w    #4,A7
; FormatInstructionForTrace() ;
       jsr       _FormatInstructionForTrace
; printf("%s", Instruction) ;
       pea       _Instruction.L
       pea       @m68kde~1_52.L
       jsr       (A3)
       addq.w    #8,A7
       bra.s     DumpRegisters_41
DumpRegisters_40:
; }
; else
; printf("[BREAKPOINT]") ;
       pea       @m68kde~1_53.L
       jsr       (A3)
       addq.w    #4,A7
DumpRegisters_41:
; printf("\r\n") ;
       pea       @m68kde~1_54.L
       jsr       (A3)
       addq.w    #4,A7
; for(i=0; i < 8; i++)    {
       clr.w     D4
DumpRegisters_42:
       cmp.w     #8,D4
       bge       DumpRegisters_44
; if(WatchPointSetOrCleared[i] == 1)
       ext.l     D4
       move.l    D4,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     DumpRegisters_45
; printf("\r\nWP%d = %s", i, WatchPointString[i]) ;
       move.l    A5,D1
       ext.l     D4
       move.l    D0,-(A7)
       move.l    D4,D0
       muls      #100,D0
       add.l     D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       ext.l     D4
       move.l    D4,-(A7)
       pea       @m68kde~1_55.L
       jsr       (A3)
       add.w     #12,A7
DumpRegisters_45:
       addq.w    #1,D4
       bra       DumpRegisters_42
DumpRegisters_44:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       rts
; }
; }
; // Trace Exception Handler
; void DumpRegistersandPause(void)
; {
       xdef      _DumpRegistersandPause
_DumpRegistersandPause:
       move.l    A2,-(A7)
       lea       _printf.L,A2
; printf("\r\n\r\n\r\n\r\n\r\n\r\nSingle Step  :[ON]") ;
       pea       @m68kde~1_56.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nBreak Points :[Disabled]") ;
       pea       @m68kde~1_57.L
       jsr       (A2)
       addq.w    #4,A7
; DumpRegisters() ;
       jsr       _DumpRegisters
; printf("\r\nPress <SPACE> to Execute Next Instruction");
       pea       @m68kde~1_58.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nPress <ESC> to Resume Program") ;
       pea       @m68kde~1_59.L
       jsr       (A2)
       addq.w    #4,A7
; menu() ;
       jsr       _menu
       move.l    (A7)+,A2
       rts
; }
; void ChangeRegisters(void)
; {
       xdef      _ChangeRegisters
_ChangeRegisters:
       link      A6,#-4
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _printf.L,A2
       lea       -4(A6),A3
       lea       _Get8HexDigits.L,A4
       lea       __getch.L,A5
; // get register name d0-d7, a0-a7, up, sp, sr, pc
; int reg_val ;
; char c, reg[3] ;
; reg[0] = tolower(_getch()) ;
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.b    D0,(A3)
; reg[1] = c = tolower(_getch()) ;
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       move.b    D0,D2
       move.b    D0,1(A3)
; if(reg[0] == (char)('d'))  {    // change data register
       move.b    (A3),D0
       cmp.b     #100,D0
       bne       ChangeRegisters_1
; if((reg[1] > (char)('7')) || (reg[1] < (char)('0'))) {
       move.b    1(A3),D0
       cmp.b     #55,D0
       bgt.s     ChangeRegisters_5
       move.b    1(A3),D0
       cmp.b     #48,D0
       bge.s     ChangeRegisters_3
ChangeRegisters_5:
; printf("\r\nIllegal Data Register : Use D0-D7.....\r\n") ;
       pea       @m68kde~1_60.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_3:
; }
; else {
; printf("\r\nD%c = ", c) ;
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_61.L
       jsr       (A2)
       addq.w    #8,A7
; reg_val = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,D3
; }
; // bit cludgy but d0-d7 not stored as an array for good reason
; if(c == (char)('0'))
       cmp.b     #48,D2
       bne.s     ChangeRegisters_7
; d0 = reg_val ;
       move.l    D3,_d0.L
       bra       ChangeRegisters_20
ChangeRegisters_7:
; else if(c == (char)('1'))
       cmp.b     #49,D2
       bne.s     ChangeRegisters_9
; d1 = reg_val ;
       move.l    D3,_d1.L
       bra       ChangeRegisters_20
ChangeRegisters_9:
; else if(c == (char)('2'))
       cmp.b     #50,D2
       bne.s     ChangeRegisters_11
; d2 = reg_val ;
       move.l    D3,_d2.L
       bra       ChangeRegisters_20
ChangeRegisters_11:
; else if(c == (char)('3'))
       cmp.b     #51,D2
       bne.s     ChangeRegisters_13
; d3 = reg_val ;
       move.l    D3,_d3.L
       bra.s     ChangeRegisters_20
ChangeRegisters_13:
; else if(c == (char)('4'))
       cmp.b     #52,D2
       bne.s     ChangeRegisters_15
; d4 = reg_val ;
       move.l    D3,_d4.L
       bra.s     ChangeRegisters_20
ChangeRegisters_15:
; else if(c == (char)('5'))
       cmp.b     #53,D2
       bne.s     ChangeRegisters_17
; d5 = reg_val ;
       move.l    D3,_d5.L
       bra.s     ChangeRegisters_20
ChangeRegisters_17:
; else if(c == (char)('6'))
       cmp.b     #54,D2
       bne.s     ChangeRegisters_19
; d6 = reg_val ;
       move.l    D3,_d6.L
       bra.s     ChangeRegisters_20
ChangeRegisters_19:
; else
; d7 = reg_val ;
       move.l    D3,_d7.L
ChangeRegisters_20:
       bra       ChangeRegisters_51
ChangeRegisters_1:
; }
; else if(reg[0] == (char)('a'))  {    // change address register, a7 is the user stack pointer, sp is the system stack pointer
       move.b    (A3),D0
       cmp.b     #97,D0
       bne       ChangeRegisters_21
; if((c > (char)('7')) || (c < (char)('0'))) {
       cmp.b     #55,D2
       bgt.s     ChangeRegisters_25
       cmp.b     #48,D2
       bge.s     ChangeRegisters_23
ChangeRegisters_25:
; printf("\r\nIllegal Address Register : Use A0-A7.....\r\n") ;
       pea       @m68kde~1_62.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_23:
; }
; else {
; printf("\r\nA%c = ", c) ;
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_63.L
       jsr       (A2)
       addq.w    #8,A7
; reg_val = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,D3
; }
; // bit cludgy but a0-a7 not stored as an array for good reason
; if(c == (char)('0'))
       cmp.b     #48,D2
       bne.s     ChangeRegisters_26
; a0 = reg_val ;
       move.l    D3,_a0.L
       bra       ChangeRegisters_39
ChangeRegisters_26:
; else if(c == (char)('1'))
       cmp.b     #49,D2
       bne.s     ChangeRegisters_28
; a1 = reg_val ;
       move.l    D3,_a1.L
       bra       ChangeRegisters_39
ChangeRegisters_28:
; else if(c == (char)('2'))
       cmp.b     #50,D2
       bne.s     ChangeRegisters_30
; a2 = reg_val ;
       move.l    D3,_a2.L
       bra       ChangeRegisters_39
ChangeRegisters_30:
; else if(c == (char)('3'))
       cmp.b     #51,D2
       bne.s     ChangeRegisters_32
; a3 = reg_val ;
       move.l    D3,_a3.L
       bra.s     ChangeRegisters_39
ChangeRegisters_32:
; else if(c == (char)('4'))
       cmp.b     #52,D2
       bne.s     ChangeRegisters_34
; a4 = reg_val ;
       move.l    D3,_a4.L
       bra.s     ChangeRegisters_39
ChangeRegisters_34:
; else if(c == (char)('5'))
       cmp.b     #53,D2
       bne.s     ChangeRegisters_36
; a5 = reg_val ;
       move.l    D3,_a5.L
       bra.s     ChangeRegisters_39
ChangeRegisters_36:
; else if(c == (char)('6'))
       cmp.b     #54,D2
       bne.s     ChangeRegisters_38
; a6 = reg_val ;
       move.l    D3,_a6.L
       bra.s     ChangeRegisters_39
ChangeRegisters_38:
; else
; USP = reg_val ;
       move.l    D3,_USP.L
ChangeRegisters_39:
       bra       ChangeRegisters_51
ChangeRegisters_21:
; }
; else if((reg[0] == (char)('u')) && (c == (char)('s')))  {
       move.b    (A3),D0
       cmp.b     #117,D0
       bne       ChangeRegisters_40
       cmp.b     #115,D2
       bne       ChangeRegisters_40
; if(tolower(_getch()) == 'p')  {    // change user stack pointer
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       cmp.l     #112,D0
       bne.s     ChangeRegisters_42
; printf("\r\nUser SP = ") ;
       pea       @m68kde~1_64.L
       jsr       (A2)
       addq.w    #4,A7
; USP = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,_USP.L
       bra.s     ChangeRegisters_43
ChangeRegisters_42:
; }
; else {
; printf("\r\nIllegal Register....") ;
       pea       @m68kde~1_65.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_43:
       bra       ChangeRegisters_51
ChangeRegisters_40:
; }
; }
; else if((reg[0] == (char)('s')) && (c == (char)('s')))  {
       move.b    (A3),D0
       cmp.b     #115,D0
       bne       ChangeRegisters_44
       cmp.b     #115,D2
       bne       ChangeRegisters_44
; if(tolower(_getch()) == 'p')  {    // change system stack pointer
       move.l    D0,-(A7)
       jsr       (A5)
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _tolower
       addq.w    #4,A7
       cmp.l     #112,D0
       bne.s     ChangeRegisters_46
; printf("\r\nSystem SP = ") ;
       pea       @m68kde~1_66.L
       jsr       (A2)
       addq.w    #4,A7
; SSP = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,_SSP.L
       bra.s     ChangeRegisters_47
ChangeRegisters_46:
; }
; else {
; printf("\r\nIllegal Register....") ;
       pea       @m68kde~1_67.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       ChangeRegisters_6
ChangeRegisters_47:
       bra       ChangeRegisters_51
ChangeRegisters_44:
; }
; }
; else if((reg[0] == (char)('p')) && (c == (char)('c')))  {    // change program counter
       move.b    (A3),D0
       cmp.b     #112,D0
       bne.s     ChangeRegisters_48
       cmp.b     #99,D2
       bne.s     ChangeRegisters_48
; printf("\r\nPC = ") ;
       pea       @m68kde~1_68.L
       jsr       (A2)
       addq.w    #4,A7
; PC = Get8HexDigits(0) ;    // read 32 bit value from user keyboard
       clr.l     -(A7)
       jsr       (A4)
       addq.w    #4,A7
       move.l    D0,_PC.L
       bra       ChangeRegisters_51
ChangeRegisters_48:
; }
; else if((reg[0] == (char)('s')) && (c == (char)('r')))  {    // change status register
       move.b    (A3),D0
       cmp.b     #115,D0
       bne.s     ChangeRegisters_50
       cmp.b     #114,D2
       bne.s     ChangeRegisters_50
; printf("\r\nSR = ") ;
       pea       @m68kde~1_69.L
       jsr       (A2)
       addq.w    #4,A7
; SR = Get4HexDigits(0) ;    // read 16 bit value from user keyboard
       clr.l     -(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.w    D0,_SR.L
       bra.s     ChangeRegisters_51
ChangeRegisters_50:
; }
; else
; printf("\r\nIllegal Register: Use A0-A7, D0-D7, SSP, USP, PC or SR\r\n") ;
       pea       @m68kde~1_70.L
       jsr       (A2)
       addq.w    #4,A7
ChangeRegisters_51:
; DumpRegisters() ;
       jsr       _DumpRegisters
ChangeRegisters_6:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void BreakPointDisplay(void)
; {
       xdef      _BreakPointDisplay
_BreakPointDisplay:
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _BreakPointAddress.L,A3
; int i, BreakPointsSet = 0 ;
       clr.l     D3
; // any break points  set
; for(i = 0; i < 8; i++)  {
       clr.l     D2
BreakPointDisplay_1:
       cmp.l     #8,D2
       bge.s     BreakPointDisplay_3
; if(BreakPointSetOrCleared[i] == 1)
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     BreakPointDisplay_4
; BreakPointsSet = 1;
       moveq     #1,D3
BreakPointDisplay_4:
       addq.l    #1,D2
       bra       BreakPointDisplay_1
BreakPointDisplay_3:
; }
; if(BreakPointsSet == 1) {
       cmp.l     #1,D3
       bne.s     BreakPointDisplay_6
; printf("\r\n\r\nNum     Address      Instruction") ;
       pea       @m68kde~1_71.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n---     ---------    -----------") ;
       pea       @m68kde~1_72.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     BreakPointDisplay_7
BreakPointDisplay_6:
; }
; else
; printf("\r\nNo BreakPoints Set") ;
       pea       @m68kde~1_73.L
       jsr       (A2)
       addq.w    #4,A7
BreakPointDisplay_7:
; for(i = 0; i < 8; i++)  {
       clr.l     D2
BreakPointDisplay_8:
       cmp.l     #8,D2
       bge       BreakPointDisplay_10
; // put opcode back to disassemble it, then put break point back
; if(BreakPointSetOrCleared[i] == 1)  {
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne       BreakPointDisplay_11
; *(unsigned short int *)(BreakPointAddress[i]) = BreakPointInstruction[i];
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    0(A3,D1.L),D1
       move.l    D1,A1
       move.w    0(A0,D0.L),(A1)
; DisassembleInstruction(BreakPointAddress[i]) ;
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    0(A3,D1.L),-(A7)
       jsr       _DisassembleInstruction
       addq.w    #4,A7
; FormatInstructionForTrace() ;
       jsr       _FormatInstructionForTrace
; *(unsigned short int *)(BreakPointAddress[i]) = (unsigned short int)(0x4e4e) ;
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       move.l    D0,A0
       move.w    #20046,(A0)
; printf("\r\n%3d     $%08x",i, BreakPointAddress[i]) ;
       move.l    D2,D1
       lsl.l     #2,D1
       move.l    0(A3,D1.L),-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_74.L
       jsr       (A2)
       add.w     #12,A7
; printf("    %s", Instruction);
       pea       _Instruction.L
       pea       @m68kde~1_75.L
       jsr       (A2)
       addq.w    #8,A7
BreakPointDisplay_11:
       addq.l    #1,D2
       bra       BreakPointDisplay_8
BreakPointDisplay_10:
; }
; }
; printf("\r\n") ;
       pea       @m68kde~1_76.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2/A3
       rts
; }
; void WatchPointDisplay(void)
; {
       xdef      _WatchPointDisplay
_WatchPointDisplay:
       movem.l   D2/D3/A2,-(A7)
       lea       _printf.L,A2
; int i ;
; int WatchPointsSet = 0 ;
       clr.l     D3
; // any watchpoints set
; for(i = 0; i < 8; i++)  {
       clr.l     D2
WatchPointDisplay_1:
       cmp.l     #8,D2
       bge.s     WatchPointDisplay_3
; if(WatchPointSetOrCleared[i] == 1)
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     WatchPointDisplay_4
; WatchPointsSet = 1;
       moveq     #1,D3
WatchPointDisplay_4:
       addq.l    #1,D2
       bra       WatchPointDisplay_1
WatchPointDisplay_3:
; }
; if(WatchPointsSet == 1) {
       cmp.l     #1,D3
       bne.s     WatchPointDisplay_6
; printf("\r\nNum     Address") ;
       pea       @m68kde~1_77.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n---     ---------") ;
       pea       @m68kde~1_78.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     WatchPointDisplay_7
WatchPointDisplay_6:
; }
; else
; printf("\r\nNo WatchPoints Set") ;
       pea       @m68kde~1_79.L
       jsr       (A2)
       addq.w    #4,A7
WatchPointDisplay_7:
; for(i = 0; i < 8; i++)  {
       clr.l     D2
WatchPointDisplay_8:
       cmp.l     #8,D2
       bge       WatchPointDisplay_10
; if(WatchPointSetOrCleared[i] == 1)
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     WatchPointDisplay_11
; printf("\r\n%3d     $%08x",i, WatchPointAddress[i]) ;
       move.l    D2,D1
       lsl.l     #2,D1
       lea       _WatchPointAddress.L,A0
       move.l    0(A0,D1.L),-(A7)
       move.l    D2,-(A7)
       pea       @m68kde~1_80.L
       jsr       (A2)
       add.w     #12,A7
WatchPointDisplay_11:
       addq.l    #1,D2
       bra       WatchPointDisplay_8
WatchPointDisplay_10:
; }
; printf("\r\n") ;
       pea       @m68kde~1_81.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; void BreakPointClear(void)
; {
       xdef      _BreakPointClear
_BreakPointClear:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; unsigned int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; BreakPointDisplay() ;
       jsr       _BreakPointDisplay
; printf("\r\nEnter Break Point Number: ") ;
       pea       @m68kde~1_82.L
       jsr       (A2)
       addq.w    #4,A7
; i = xtod(_getch()) ;           // get break pointer number
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D2
; if((i < 0) || (i > 7))   {
       cmp.l     #0,D2
       blo.s     BreakPointClear_3
       cmp.l     #7,D2
       bls.s     BreakPointClear_1
BreakPointClear_3:
; printf("\r\nIllegal Range : Use 0 - 7") ;
       pea       @m68kde~1_83.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       BreakPointClear_4
BreakPointClear_1:
; }
; if(BreakPointSetOrCleared[i] == 1)  {       // if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne       BreakPointClear_5
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program we are about to change
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; BreakPointAddress[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; *ProgramBreakPointAddress = BreakPointInstruction[i] ;  // put original instruction back
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
; BreakPointInstruction[i] = 0 ;
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
; printf("\r\nBreak Point Cleared.....\r\n") ;
       pea       @m68kde~1_84.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     BreakPointClear_6
BreakPointClear_5:
; }
; else
; printf("\r\nBreak Point wasn't Set.....") ;
       pea       @m68kde~1_85.L
       jsr       (A2)
       addq.w    #4,A7
BreakPointClear_6:
; BreakPointDisplay() ;
       jsr       _BreakPointDisplay
; return ;
BreakPointClear_4:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; void WatchPointClear(void)
; {
       xdef      _WatchPointClear
_WatchPointClear:
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; unsigned int i ;
; WatchPointDisplay() ;
       jsr       _WatchPointDisplay
; printf("\r\nEnter Watch Point Number: ") ;
       pea       @m68kde~1_86.L
       jsr       (A2)
       addq.w    #4,A7
; i = xtod(_getch()) ;           // get watch pointer number
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D2
; if((i < 0) || (i > 7))   {
       cmp.l     #0,D2
       blo.s     WatchPointClear_3
       cmp.l     #7,D2
       bls.s     WatchPointClear_1
WatchPointClear_3:
; printf("\r\nIllegal Range : Use 0 - 7") ;
       pea       @m68kde~1_87.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       WatchPointClear_4
WatchPointClear_1:
; }
; if(WatchPointSetOrCleared[i] == 1)  {       // if watch point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     WatchPointClear_5
; WatchPointAddress[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       clr.l     0(A0,D0.L)
; WatchPointSetOrCleared[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; printf("\r\nWatch Point Cleared.....\r\n") ;
       pea       @m68kde~1_88.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     WatchPointClear_6
WatchPointClear_5:
; }
; else
; printf("\r\nWatch Point Was not Set.....") ;
       pea       @m68kde~1_89.L
       jsr       (A2)
       addq.w    #4,A7
WatchPointClear_6:
; WatchPointDisplay() ;
       jsr       _WatchPointDisplay
; return ;
WatchPointClear_4:
       movem.l   (A7)+,D2/A2
       rts
; }
; void DisableBreakPoints(void)
; {
       xdef      _DisableBreakPoints
_DisableBreakPoints:
       link      A6,#-4
       move.l    D2,-(A7)
; int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
DisableBreakPoints_1:
       cmp.l     #8,D2
       bge       DisableBreakPoints_3
; if(BreakPointSetOrCleared[i] == 1)    {                                                    // if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     DisableBreakPoints_4
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; *ProgramBreakPointAddress = BreakPointInstruction[i];                                  // copy the instruction back to the user program overwritting the $4e4e
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
DisableBreakPoints_4:
       addq.l    #1,D2
       bra       DisableBreakPoints_1
DisableBreakPoints_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void EnableBreakPoints(void)
; {
       xdef      _EnableBreakPoints
_EnableBreakPoints:
       link      A6,#-4
       move.l    D2,-(A7)
; int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
EnableBreakPoints_1:
       cmp.l     #8,D2
       bge.s     EnableBreakPoints_3
; if(BreakPointSetOrCleared[i] == 1)    {                                                     // if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       move.l    0(A0,D0.L),D0
       cmp.l     #1,D0
       bne.s     EnableBreakPoints_4
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; *ProgramBreakPointAddress = (unsigned short int)(0x4e4e);                              // put the breakpoint back in user program
       move.l    -4(A6),A0
       move.w    #20046,(A0)
EnableBreakPoints_4:
       addq.l    #1,D2
       bra       EnableBreakPoints_1
EnableBreakPoints_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void KillAllBreakPoints(void)
; {
       xdef      _KillAllBreakPoints
_KillAllBreakPoints:
       link      A6,#-4
       move.l    D2,-(A7)
; int i ;
; volatile unsigned short int *ProgramBreakPointAddress ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
KillAllBreakPoints_1:
       cmp.l     #8,D2
       bge       KillAllBreakPoints_3
; // clear BP
; ProgramBreakPointAddress = (volatile unsigned short int *)(BreakPointAddress[i]) ;     // point to the instruction in the user program where the break point has been set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),-4(A6)
; *ProgramBreakPointAddress = BreakPointInstruction[i];                                  // copy the instruction back to the user program
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
; BreakPointAddress[i] = 0 ;                                                             // set BP address to NULL
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointInstruction[i] = 0 ;
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0 ;                                                        // mark break point as cleared for future setting
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
       addq.l    #1,D2
       bra       KillAllBreakPoints_1
KillAllBreakPoints_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; //BreakPointDisplay() ;       // display the break points
; }
; void KillAllWatchPoints(void)
; {
       xdef      _KillAllWatchPoints
_KillAllWatchPoints:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 8; i++)  {
       clr.l     D2
KillAllWatchPoints_1:
       cmp.l     #8,D2
       bge.s     KillAllWatchPoints_3
; WatchPointAddress[i] = 0 ;                                                             // set BP address to NULL
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       clr.l     0(A0,D0.L)
; WatchPointSetOrCleared[i] = 0 ;                                                        // mark break point as cleared for future setting
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
       addq.l    #1,D2
       bra       KillAllWatchPoints_1
KillAllWatchPoints_3:
       move.l    (A7)+,D2
       rts
; }
; //WatchPointDisplay() ;       // display the break points
; }
; void SetBreakPoint(void)
; {
       xdef      _SetBreakPoint
_SetBreakPoint:
       link      A6,#-4
       movem.l   D2/D3/D4/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _BreakPointSetOrCleared.L,A3
; int i ;
; int BPNumber;
; int BPAddress;
; volatile unsigned short int *ProgramBreakPointAddress ;
; // see if any free break points
; for(i = 0; i < 8; i ++) {
       clr.l     D2
SetBreakPoint_1:
       cmp.l     #8,D2
       bge.s     SetBreakPoint_3
; if( BreakPointSetOrCleared[i] == 0)
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne.s     SetBreakPoint_4
; break ;         // if spare BP found allow user to set it
       bra.s     SetBreakPoint_3
SetBreakPoint_4:
       addq.l    #1,D2
       bra       SetBreakPoint_1
SetBreakPoint_3:
; }
; if(i == 8) {
       cmp.l     #8,D2
       bne.s     SetBreakPoint_6
; printf("\r\nNo FREE Break Points.....") ;
       pea       @m68kde~1_90.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_6:
; }
; printf("\r\nBreak Point Address: ") ;
       pea       @m68kde~1_91.L
       jsr       (A2)
       addq.w    #4,A7
; BPAddress = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; ProgramBreakPointAddress = (volatile unsigned short int *)(BPAddress) ;     // point to the instruction in the user program we are about to change
       move.l    D3,D4
; if((BPAddress & 0x00000001) == 0x00000001)  {   // cannot set BP at an odd address
       move.l    D3,D0
       and.l     #1,D0
       cmp.l     #1,D0
       bne.s     SetBreakPoint_9
; printf("\r\nError : Break Points CANNOT be set at ODD addresses") ;
       pea       @m68kde~1_92.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_9:
; }
; if(BPAddress < 0x00008000)  {   // cannot set BP in ROM
       cmp.l     #32768,D3
       bhs.s     SetBreakPoint_11
; printf("\r\nError : Break Points CANNOT be set for ROM in Range : [$0-$00007FFF]") ;
       pea       @m68kde~1_93.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_11:
; }
; // search for first free bp or existing same BP
; for(i = 0; i < 8; i++)  {
       clr.l     D2
SetBreakPoint_13:
       cmp.l     #8,D2
       bge       SetBreakPoint_15
; if(BreakPointAddress[i] == BPAddress)   {
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       cmp.l     0(A0,D0.L),D3
       bne.s     SetBreakPoint_16
; printf("\r\nError: Break Point Already Exists at Address : %08x\r\n", BPAddress) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_94.L
       jsr       (A2)
       addq.w    #8,A7
; return ;
       bra       SetBreakPoint_15
SetBreakPoint_16:
; }
; if(BreakPointSetOrCleared[i] == 0) {
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne       SetBreakPoint_18
; // set BP here
; BreakPointSetOrCleared[i] = 1 ;                                 // mark this breakpoint as set
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    #1,0(A3,D0.L)
; BreakPointInstruction[i] = *ProgramBreakPointAddress ;          // copy the user program instruction here so we can put it back afterwards
       move.l    D4,A0
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A1
       move.w    (A0),0(A1,D0.L)
; DisassembleInstruction(ProgramBreakPointAddress) ;
       move.l    D4,-(A7)
       jsr       _DisassembleInstruction
       addq.w    #4,A7
; FormatInstructionForTrace() ;
       jsr       _FormatInstructionForTrace
; printf("\r\nBreak Point Set at Address: [$%08x], Instruction = %s", ProgramBreakPointAddress, Instruction) ;
       pea       _Instruction.L
       move.l    D4,-(A7)
       pea       @m68kde~1_95.L
       jsr       (A2)
       add.w     #12,A7
; *ProgramBreakPointAddress = (unsigned short int)(0x4e4e)    ;   // put a Trap14 instruction at the user specified address
       move.l    D4,A0
       move.w    #20046,(A0)
; BreakPointAddress[i] = BPAddress ;                              // record the address of this break point in the debugger
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    D3,0(A0,D0.L)
; printf("\r\n") ;
       pea       @m68kde~1_96.L
       jsr       (A2)
       addq.w    #4,A7
; BreakPointDisplay() ;       // display the break points
       jsr       _BreakPointDisplay
; return ;
       bra.s     SetBreakPoint_15
SetBreakPoint_18:
       addq.l    #1,D2
       bra       SetBreakPoint_13
SetBreakPoint_15:
       movem.l   (A7)+,D2/D3/D4/A2/A3
       unlk      A6
       rts
; }
; }
; }
; void SetWatchPoint(void)
; {
       xdef      _SetWatchPoint
_SetWatchPoint:
       link      A6,#-8
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _WatchPointSetOrCleared.L,A3
; int i ;
; int WPNumber;
; int WPAddress;
; volatile unsigned short int *ProgramWatchPointAddress ;
; // see if any free break points
; for(i = 0; i < 8; i ++) {
       clr.l     D2
SetWatchPoint_1:
       cmp.l     #8,D2
       bge.s     SetWatchPoint_3
; if( WatchPointSetOrCleared[i] == 0)
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne.s     SetWatchPoint_4
; break ;         // if spare WP found allow user to set it
       bra.s     SetWatchPoint_3
SetWatchPoint_4:
       addq.l    #1,D2
       bra       SetWatchPoint_1
SetWatchPoint_3:
; }
; if(i == 8) {
       cmp.l     #8,D2
       bne.s     SetWatchPoint_6
; printf("\r\nNo FREE Watch Points.....") ;
       pea       @m68kde~1_97.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra       SetWatchPoint_11
SetWatchPoint_6:
; }
; printf("\r\nWatch Point Address: ") ;
       pea       @m68kde~1_98.L
       jsr       (A2)
       addq.w    #4,A7
; WPAddress = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D3
; // search for first free wp or existing same wp
; for(i = 0; i < 8; i++)  {
       clr.l     D2
SetWatchPoint_9:
       cmp.l     #8,D2
       bge       SetWatchPoint_11
; if(WatchPointAddress[i] == WPAddress && WPAddress != 0)   {     //so we can set a wp at 0
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       cmp.l     0(A0,D0.L),D3
       bne.s     SetWatchPoint_12
       tst.l     D3
       beq.s     SetWatchPoint_12
; printf("\r\nError: Watch Point Already Set at Address : %08x\r\n", WPAddress) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_99.L
       jsr       (A2)
       addq.w    #8,A7
; return ;
       bra       SetWatchPoint_11
SetWatchPoint_12:
; }
; if(WatchPointSetOrCleared[i] == 0) {
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    0(A3,D0.L),D0
       bne       SetWatchPoint_14
; WatchPointSetOrCleared[i] = 1 ;                                 // mark this watchpoint as set
       move.l    D2,D0
       lsl.l     #2,D0
       move.l    #1,0(A3,D0.L)
; printf("\r\nWatch Point Set at Address: [$%08x]", WPAddress) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_100.L
       jsr       (A2)
       addq.w    #8,A7
; WatchPointAddress[i] = WPAddress ;                              // record the address of this watch point in the debugger
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       move.l    D3,0(A0,D0.L)
; printf("\r\n") ;
       pea       @m68kde~1_101.L
       jsr       (A2)
       addq.w    #4,A7
; WatchPointDisplay() ;       // display the break points
       jsr       _WatchPointDisplay
; return ;
       bra.s     SetWatchPoint_11
SetWatchPoint_14:
       addq.l    #1,D2
       bra       SetWatchPoint_9
SetWatchPoint_11:
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; }
; }
; void HandleBreakPoint(void)
; {
       xdef      _HandleBreakPoint
_HandleBreakPoint:
       link      A6,#-4
       movem.l   A2/A3/A4,-(A7)
       lea       _i.L,A2
       lea       _printf.L,A3
       lea       _PC.L,A4
; volatile unsigned short int *ProgramBreakPointAddress ;
; // now we have to put the break point back to run the instruction
; // PC will contain the address of the TRAP instruction but advanced by two bytes so lets play with that
; PC = PC - 2 ;  // ready for user to resume after reaching breakpoint
       subq.l    #2,(A4)
; printf("\r\n\r\n\r\n\r\n@BREAKPOINT") ;
       pea       @m68kde~1_102.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nSingle Step : [ON]") ;
       pea       @m68kde~1_103.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nBreakPoints : [Enabled]") ;
       pea       @m68kde~1_104.L
       jsr       (A3)
       addq.w    #4,A7
; // now clear the break point (put original instruction back)
; ProgramBreakPointAddress = PC ;
       move.l    (A4),-4(A6)
; for(i = 0; i < 8; i ++) {
       clr.l     (A2)
HandleBreakPoint_1:
       move.l    (A2),D0
       cmp.l     #8,D0
       bhs       HandleBreakPoint_3
; if(BreakPointAddress[i] == PC) {        // if we have found the breakpoint
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       move.l    0(A0,D0.L),D1
       cmp.l     (A4),D1
       bne       HandleBreakPoint_4
; BreakPointAddress[i] = 0 ;
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0 ;
       move.l    (A2),D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; *ProgramBreakPointAddress = BreakPointInstruction[i] ;  // put original instruction back
       move.l    (A2),D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       move.l    -4(A6),A1
       move.w    0(A0,D0.L),(A1)
; BreakPointInstruction[i] = 0 ;
       move.l    (A2),D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
HandleBreakPoint_4:
       addq.l    #1,(A2)
       bra       HandleBreakPoint_1
HandleBreakPoint_3:
; }
; }
; DumpRegisters() ;
       jsr       _DumpRegisters
; printf("\r\nPress <SPACE> to Execute Next Instruction");
       pea       @m68kde~1_105.L
       jsr       (A3)
       addq.w    #4,A7
; printf("\r\nPress <ESC> to Resume User Program\r\n") ;
       pea       @m68kde~1_106.L
       jsr       (A3)
       addq.w    #4,A7
; menu() ;
       jsr       _menu
       movem.l   (A7)+,A2/A3/A4
       unlk      A6
       rts
; }
; void UnknownCommand()
; {
       xdef      _UnknownCommand
_UnknownCommand:
; printf("\r\nUnknown Command.....\r\n") ;
       pea       @m68kde~1_107.L
       jsr       _printf
       addq.w    #4,A7
; Help() ;
       jsr       _Help
       rts
; }
; // system when the users program executes a TRAP #15 instruction to halt program and return to debug monitor
; void CallDebugMonitor(void)
; {
       xdef      _CallDebugMonitor
_CallDebugMonitor:
; printf("\r\nProgram Ended (TRAP #15)....") ;
       pea       @m68kde~1_108.L
       jsr       _printf
       addq.w    #4,A7
; menu();
       jsr       _menu
       rts
; }
; void Breakpoint(void)
; {
       xdef      _Breakpoint
_Breakpoint:
       move.l    D2,-(A7)
; char c;
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if( c == (char)('D'))                                      // BreakPoint Display
       cmp.b     #68,D2
       bne.s     Breakpoint_1
; BreakPointDisplay() ;
       jsr       _BreakPointDisplay
       bra       Breakpoint_10
Breakpoint_1:
; else if(c == (char)('K')) {                                 // breakpoint Kill
       cmp.b     #75,D2
       bne.s     Breakpoint_3
; printf("\r\nKill All Break Points...(y/n)?") ;
       pea       @m68kde~1_109.L
       jsr       _printf
       addq.w    #4,A7
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if(c == (char)('Y'))
       cmp.b     #89,D2
       bne.s     Breakpoint_5
; KillAllBreakPoints() ;
       jsr       _KillAllBreakPoints
Breakpoint_5:
       bra.s     Breakpoint_10
Breakpoint_3:
; }
; else if(c == (char)('S')) {
       cmp.b     #83,D2
       bne.s     Breakpoint_7
; SetBreakPoint() ;
       jsr       _SetBreakPoint
       bra.s     Breakpoint_10
Breakpoint_7:
; }
; else if(c == (char)('C')) {
       cmp.b     #67,D2
       bne.s     Breakpoint_9
; BreakPointClear() ;
       jsr       _BreakPointClear
       bra.s     Breakpoint_10
Breakpoint_9:
; }
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
Breakpoint_10:
       move.l    (A7)+,D2
       rts
; }
; void Watchpoint(void)
; {
       xdef      _Watchpoint
_Watchpoint:
       move.l    D2,-(A7)
; char c;
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if( c == (char)('D'))                                      // WatchPoint Display
       cmp.b     #68,D2
       bne.s     Watchpoint_1
; WatchPointDisplay() ;
       jsr       _WatchPointDisplay
       bra       Watchpoint_10
Watchpoint_1:
; else if(c == (char)('K')) {                                 // wtahcpoint Kill
       cmp.b     #75,D2
       bne.s     Watchpoint_3
; printf("\r\nKill All Watch Points...(y/n)?") ;
       pea       @m68kde~1_110.L
       jsr       _printf
       addq.w    #4,A7
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if(c == (char)('Y'))
       cmp.b     #89,D2
       bne.s     Watchpoint_5
; KillAllWatchPoints() ;
       jsr       _KillAllWatchPoints
Watchpoint_5:
       bra.s     Watchpoint_10
Watchpoint_3:
; }
; else if(c == (char)('S')) {
       cmp.b     #83,D2
       bne.s     Watchpoint_7
; SetWatchPoint() ;
       jsr       _SetWatchPoint
       bra.s     Watchpoint_10
Watchpoint_7:
; }
; else if(c == (char)('C')) {
       cmp.b     #67,D2
       bne.s     Watchpoint_9
; WatchPointClear() ;
       jsr       _WatchPointClear
       bra.s     Watchpoint_10
Watchpoint_9:
; }
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
Watchpoint_10:
       move.l    (A7)+,D2
       rts
; }
; void DMenu(void)
; {
       xdef      _DMenu
_DMenu:
       move.l    D2,-(A7)
; char c;
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if( c == (char)('U'))                                     // Dump Memory
       cmp.b     #85,D2
       bne.s     DMenu_1
; DumpMemory() ;
       jsr       _DumpMemory
       bra.s     DMenu_4
DMenu_1:
; else if(c == (char)('I'))   {
       cmp.b     #73,D2
       bne.s     DMenu_3
; DisableBreakPoints() ;
       jsr       _DisableBreakPoints
; DisassembleProgram() ;
       jsr       _DisassembleProgram
; EnableBreakPoints() ;
       jsr       _EnableBreakPoints
       bra.s     DMenu_4
DMenu_3:
; }
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
DMenu_4:
       move.l    (A7)+,D2
       rts
; }
; void Help(void)
; {
       xdef      _Help
_Help:
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; char *banner = "\r\n----------------------------------------------------------------" ;
       lea       @m68kde~1_111.L,A0
       move.l    A0,D2
; printf(banner) ;
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  Debugger Command Summary") ;
       pea       @m68kde~1_112.L
       jsr       (A2)
       addq.w    #4,A7
; printf(banner) ;
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  .(reg)       - Change Registers: e.g A0-A7,D0-D7,PC,SSP,USP,SR");
       pea       @m68kde~1_113.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  BD/BS/BC/BK  - Break Point: Display/Set/Clear/Kill") ;
       pea       @m68kde~1_114.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  C            - Copy Program from Flash to Main Memory") ;
       pea       @m68kde~1_115.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  DI           - Disassemble Program");
       pea       @m68kde~1_116.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  DU           - Dump Memory Contents to Screen") ;
       pea       @m68kde~1_117.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  E            - Enter String into Memory") ;
       pea       @m68kde~1_118.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  F            - Fill Memory with Data") ;
       pea       @m68kde~1_119.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  G            - Go Program Starting at Address: $%08X", PC) ;
       move.l    _PC.L,-(A7)
       pea       @m68kde~1_120.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n  L            - Load Program (.HEX file) from Laptop") ;
       pea       @m68kde~1_121.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  M            - Memory Examine and Change");
       pea       @m68kde~1_122.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  P            - Program Flash Memory with User Program") ;
       pea       @m68kde~1_123.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  R            - Display 68000 Registers") ;
       pea       @m68kde~1_124.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  S            - Toggle ON/OFF Single Step Mode") ;
       pea       @m68kde~1_125.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  TM           - Test Memory") ;
       pea       @m68kde~1_126.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  TS           - Test Switches: SW7-0") ;
       pea       @m68kde~1_127.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  TD           - Test Displays: LEDs and 7-Segment") ;
       pea       @m68kde~1_128.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n  WD/WS/WC/WK  - Watch Point: Display/Set/Clear/Kill") ;
       pea       @m68kde~1_129.L
       jsr       (A2)
       addq.w    #4,A7
; printf(banner) ;
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/A2
       rts
; }
; void menu(void)
; {
       xdef      _menu
_menu:
       movem.l   D2/D3/A2/A3/A4/A5,-(A7)
       lea       _printf.L,A2
       lea       _Trace.L,A3
       lea       _x.L,A4
       lea       _SR.L,A5
; char c,c1 ;
; while(1)    {
menu_1:
; FlushKeyboard() ;               // dump unread characters from keyboard
       jsr       _FlushKeyboard
; printf("\r\n#") ;
       pea       @m68kde~1_130.L
       jsr       (A2)
       addq.w    #4,A7
; c = toupper(_getch());
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D2
; if( c == (char)('L'))                  // load s record file
       cmp.b     #76,D2
       bne.s     menu_4
; Load_SRecordFile() ;
       jsr       _Load_SRecordFile
       bra       menu_46
menu_4:
; else if( c == (char)('D'))             // dump memory
       cmp.b     #68,D2
       bne.s     menu_6
; DMenu() ;
       jsr       _DMenu
       bra       menu_46
menu_6:
; else if( c == (char)('E'))             // Enter String into memory
       cmp.b     #69,D2
       bne.s     menu_8
; EnterString() ;
       jsr       _EnterString
       bra       menu_46
menu_8:
; else if( c == (char)('F'))             // fill memory
       cmp.b     #70,D2
       bne.s     menu_10
; FillMemory() ;
       jsr       _FillMemory
       bra       menu_46
menu_10:
; else if( c == (char)('G'))  {           // go user program
       cmp.b     #71,D2
       bne.s     menu_12
; printf("\r\nProgram Running.....") ;
       pea       @m68kde~1_131.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nPress <RESET> button <Key0> on DE1 to stop") ;
       pea       @m68kde~1_132.L
       jsr       (A2)
       addq.w    #4,A7
; GoFlag = 1 ;
       move.l    #1,_GoFlag.L
; go() ;
       jsr       _go
       bra       menu_46
menu_12:
; }
; else if( c == (char)('M'))           // memory examine and modify
       cmp.b     #77,D2
       bne.s     menu_14
; MemoryChange() ;
       jsr       _MemoryChange
       bra       menu_46
menu_14:
; else if( c == (char)('P'))            // Program Flash Chip
       cmp.b     #80,D2
       bne.s     menu_16
; ProgramFlashChip() ;
       jsr       _ProgramFlashChip
       bra       menu_46
menu_16:
; else if( c == (char)('C'))             // copy flash chip to ram and go
       cmp.b     #67,D2
       bne.s     menu_18
; LoadFromFlashChip();
       jsr       _LoadFromFlashChip
       bra       menu_46
menu_18:
; else if( c == (char)('R'))             // dump registers
       cmp.b     #82,D2
       bne.s     menu_20
; DumpRegisters() ;
       jsr       _DumpRegisters
       bra       menu_46
menu_20:
; else if( c == (char)('.'))           // change registers
       cmp.b     #46,D2
       bne.s     menu_22
; ChangeRegisters() ;
       jsr       _ChangeRegisters
       bra       menu_46
menu_22:
; else if( c == (char)('B'))              // breakpoint command
       cmp.b     #66,D2
       bne.s     menu_24
; Breakpoint() ;
       jsr       _Breakpoint
       bra       menu_46
menu_24:
; else if( c == (char)('T'))  {          // Test command
       cmp.b     #84,D2
       bne       menu_26
; c1 = toupper(_getch()) ;
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _toupper
       addq.w    #4,A7
       move.b    D0,D3
; if(c1 == (char)('M'))                    // memory test
       cmp.b     #77,D3
       bne.s     menu_28
; MemoryTest() ;
       jsr       _MemoryTest
       bra.s     menu_33
menu_28:
; else if( c1 == (char)('S'))              // Switch Test command
       cmp.b     #83,D3
       bne.s     menu_30
; SwitchTest() ;
       jsr       _SwitchTest
       bra.s     menu_33
menu_30:
; else if( c1 == (char)('D'))              // display Test command
       cmp.b     #68,D3
       bne.s     menu_32
; TestLEDS() ;
       jsr       _TestLEDS
       bra.s     menu_33
menu_32:
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
menu_33:
       bra       menu_46
menu_26:
; }
; else if( c == (char)(' ')) {             // Next instruction command
       cmp.b     #32,D2
       bne.s     menu_34
; DisableBreakPoints() ;
       jsr       _DisableBreakPoints
; if(Trace == 1 && GoFlag == 1)   {    // if the program is running and trace mode on then 'N' is valid
       move.l    (A3),D0
       cmp.l     #1,D0
       bne.s     menu_36
       move.l    _GoFlag.L,D0
       cmp.l     #1,D0
       bne.s     menu_36
; TraceException = 1 ;             // generate a trace exception for the next instruction if user wants to single step though next instruction
       move.b    #1,4194314
; return ;
       bra       menu_38
menu_36:
; }
; else
; printf("\r\nError: Press 'G' first to start program") ;
       pea       @m68kde~1_133.L
       jsr       (A2)
       addq.w    #4,A7
       bra       menu_46
menu_34:
; }
; else if( c == (char)('S')) {             // single step
       cmp.b     #83,D2
       bne       menu_39
; if(Trace == 0) {
       move.l    (A3),D0
       bne       menu_41
; DisableBreakPoints() ;
       jsr       _DisableBreakPoints
; printf("\r\nSingle Step  :[ON]") ;
       pea       @m68kde~1_134.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nBreak Points :[Disabled]") ;
       pea       @m68kde~1_135.L
       jsr       (A2)
       addq.w    #4,A7
; SR = SR | (unsigned short int)(0x8000) ;    // set T bit in status register
       or.w      #32768,(A5)
; printf("\r\nPress 'G' to Trace Program from address $%X.....",PC) ;
       move.l    _PC.L,-(A7)
       pea       @m68kde~1_136.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nPush <RESET Button> to Stop.....") ;
       pea       @m68kde~1_137.L
       jsr       (A2)
       addq.w    #4,A7
; DumpRegisters() ;
       jsr       _DumpRegisters
; Trace = 1;
       move.l    #1,(A3)
; TraceException = 1;
       move.b    #1,4194314
; x = *(unsigned int *)(0x00000074) ;       // simulate responding to a Level 5 IRQ by reading vector to reset Trace exception generator
       move.l    116,(A4)
       bra.s     menu_42
menu_41:
; }
; else {
; Trace = 0 ;
       clr.l     (A3)
; TraceException = 0 ;
       clr.b     4194314
; x = *(unsigned int *)(0x00000074) ;       // simulate responding to a Level 5 IRQ by reading vector to reset Trace exception generator
       move.l    116,(A4)
; EnableBreakPoints() ;
       jsr       _EnableBreakPoints
; SR = SR & (unsigned short int)(0x7FFF) ;    // clear T bit in status register
       and.w     #32767,(A5)
; printf("\r\nSingle Step : [OFF]") ;
       pea       @m68kde~1_138.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nBreak Points :[Enabled]") ;
       pea       @m68kde~1_139.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nPress <ESC> to Resume User Program.....") ;
       pea       @m68kde~1_140.L
       jsr       (A2)
       addq.w    #4,A7
menu_42:
       bra       menu_46
menu_39:
; }
; }
; else if(c == (char)(0x1b))  {   // if user choses to end trace and run program
       cmp.b     #27,D2
       bne       menu_43
; Trace = 0;
       clr.l     (A3)
; TraceException = 0;
       clr.b     4194314
; x = *(unsigned int *)(0x00000074) ;   // read IRQ 5 vector to reset trace vector generator
       move.l    116,(A4)
; EnableBreakPoints() ;
       jsr       _EnableBreakPoints
; SR = SR & (unsigned short int)(0x7FFF) ;    // clear T bit in status register
       and.w     #32767,(A5)
; printf("\r\nSingle Step  :[OFF]") ;
       pea       @m68kde~1_141.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nBreak Points :[Enabled]");
       pea       @m68kde~1_142.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nProgram Running.....") ;
       pea       @m68kde~1_143.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nPress <RESET> button <Key0> on DE1 to stop") ;
       pea       @m68kde~1_144.L
       jsr       (A2)
       addq.w    #4,A7
; return ;
       bra.s     menu_38
menu_43:
; }
; else if( c == (char)('W'))              // Watchpoint command
       cmp.b     #87,D2
       bne.s     menu_45
; Watchpoint() ;
       jsr       _Watchpoint
       bra.s     menu_46
menu_45:
; else
; UnknownCommand() ;
       jsr       _UnknownCommand
menu_46:
       bra       menu_1
menu_38:
       movem.l   (A7)+,D2/D3/A2/A3/A4/A5
       rts
; }
; }
; void PrintErrorMessageandAbort(char *string) {
       xdef      _PrintErrorMessageandAbort
_PrintErrorMessageandAbort:
       link      A6,#0
; printf("\r\n\r\nProgram ABORT !!!!!!\r\n") ;
       pea       @m68kde~1_145.L
       jsr       _printf
       addq.w    #4,A7
; printf("%s\r\n", string) ;
       move.l    8(A6),-(A7)
       pea       @m68kde~1_146.L
       jsr       _printf
       addq.w    #8,A7
; menu() ;
       jsr       _menu
       unlk      A6
       rts
; }
; void IRQMessage(int level) {
       xdef      _IRQMessage
_IRQMessage:
       link      A6,#0
; printf("\r\n\r\nProgram ABORT !!!!!");
       pea       @m68kde~1_147.L
       jsr       _printf
       addq.w    #4,A7
; printf("\r\nUnhandled Interrupt: IRQ%d !!!!!", level) ;
       move.l    8(A6),-(A7)
       pea       @m68kde~1_148.L
       jsr       _printf
       addq.w    #8,A7
; menu() ;
       jsr       _menu
       unlk      A6
       rts
; }
; void UnhandledIRQ1(void) {
       xdef      _UnhandledIRQ1
_UnhandledIRQ1:
; IRQMessage(1);
       pea       1
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ2(void) {
       xdef      _UnhandledIRQ2
_UnhandledIRQ2:
; IRQMessage(2);
       pea       2
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ3(void){
       xdef      _UnhandledIRQ3
_UnhandledIRQ3:
; IRQMessage(3);
       pea       3
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ4(void) {
       xdef      _UnhandledIRQ4
_UnhandledIRQ4:
; IRQMessage(4);
       pea       4
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ5(void) {
       xdef      _UnhandledIRQ5
_UnhandledIRQ5:
; IRQMessage(5);
       pea       5
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledIRQ6(void) {
       xdef      _UnhandledIRQ6
_UnhandledIRQ6:
; PrintErrorMessageandAbort("ADDRESS ERROR: 16 or 32 Bit Transfer to/from an ODD Address....") ;
       pea       @m68kde~1_149.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
; menu() ;
       jsr       _menu
       rts
; }
; void UnhandledIRQ7(void) {
       xdef      _UnhandledIRQ7
_UnhandledIRQ7:
; IRQMessage(7);
       pea       7
       jsr       _IRQMessage
       addq.w    #4,A7
       rts
; }
; void UnhandledTrap(void) {
       xdef      _UnhandledTrap
_UnhandledTrap:
; PrintErrorMessageandAbort("Unhandled Trap !!!!!") ;
       pea       @m68kde~1_150.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void BusError() {
       xdef      _BusError
_BusError:
; PrintErrorMessageandAbort("BUS Error!") ;
       pea       @m68kde~1_151.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void AddressError() {
       xdef      _AddressError
_AddressError:
; PrintErrorMessageandAbort("ADDRESS Error!") ;
       pea       @m68kde~1_152.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void IllegalInstruction() {
       xdef      _IllegalInstruction
_IllegalInstruction:
; PrintErrorMessageandAbort("ILLEGAL INSTRUCTION") ;
       pea       @m68kde~1_153.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Dividebyzero() {
       xdef      _Dividebyzero
_Dividebyzero:
; PrintErrorMessageandAbort("DIVIDE BY ZERO") ;
       pea       @m68kde~1_154.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Check() {
       xdef      _Check
_Check:
; PrintErrorMessageandAbort("'CHK' INSTRUCTION") ;
       pea       @m68kde~1_155.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Trapv() {
       xdef      _Trapv
_Trapv:
; PrintErrorMessageandAbort("TRAPV INSTRUCTION") ;
       pea       @m68kde~1_156.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void PrivError() {
       xdef      _PrivError
_PrivError:
; PrintErrorMessageandAbort("PRIVILEGE VIOLATION") ;
       pea       @m68kde~1_157.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void UnitIRQ() {
       xdef      _UnitIRQ
_UnitIRQ:
; PrintErrorMessageandAbort("UNINITIALISED IRQ") ;
       pea       @m68kde~1_158.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void Spurious() {
       xdef      _Spurious
_Spurious:
; PrintErrorMessageandAbort("SPURIOUS IRQ") ;
       pea       @m68kde~1_159.L
       jsr       _PrintErrorMessageandAbort
       addq.w    #4,A7
       rts
; }
; void EnterString(void)
; {
       xdef      _EnterString
_EnterString:
       link      A6,#-4
       move.l    D2,-(A7)
; unsigned char *Start;
; unsigned char c;
; printf("\r\nStart Address in Memory: ") ;
       pea       @m68kde~1_160.L
       jsr       _printf
       addq.w    #4,A7
; Start = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,D2
; printf("\r\nEnter String (ESC to end) :") ;
       pea       @m68kde~1_161.L
       jsr       _printf
       addq.w    #4,A7
; while((c = getchar()) != 0x1b)
EnterString_1:
       jsr       _getch
       move.b    D0,-1(A6)
       cmp.b     #27,D0
       beq.s     EnterString_3
; *Start++ = c ;
       move.l    D2,A0
       addq.l    #1,D2
       move.b    -1(A6),(A0)
       bra       EnterString_1
EnterString_3:
; *Start = 0x00;  // terminate with a null
       move.l    D2,A0
       clr.b     (A0)
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; void MemoryTest(void)
; {
       xdef      _MemoryTest
_MemoryTest:
       link      A6,#-24
; unsigned int *RamPtr, counter1=1 ;
       move.l    #1,-18(A6)
; register unsigned int i ;
; unsigned int Start, End ;
; char c ;
; printf("\r\nStart Address: ") ;
       pea       @m68kde~1_162.L
       jsr       _printf
       addq.w    #4,A7
; Start = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,-10(A6)
; printf("\r\nEnd Address: ") ;
       pea       @m68kde~1_163.L
       jsr       _printf
       addq.w    #4,A7
; End = Get8HexDigits(0) ;
       clr.l     -(A7)
       jsr       _Get8HexDigits
       addq.w    #4,A7
       move.l    D0,-6(A6)
       unlk      A6
       rts
; // TODO
; // add your code to test memory here using 32 bit reads and writes of data between the start and end of memory
; }
; void main(void)
; {
       xdef      _main
_main:
       link      A6,#-12
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _InstallExceptionHandler.L,A2
       lea       _printf.L,A3
; char c ;
; int i, j ;
; char *BugMessage = "DE1-68k Bug V1.77";
       lea       @m68kde~1_164.L,A0
       move.l    A0,D3
; char *CopyrightMessage = "Copyright (C) PJ Davies 2016";
       lea       @m68kde~1_165.L,A0
       move.l    A0,-4(A6)
; KillAllBreakPoints() ;
       jsr       _KillAllBreakPoints
; i = x = y = z = PortA_Count = 0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     D2
; Trace = GoFlag = 0;                       // used in tracing/single stepping
       clr.l     _GoFlag.L
       clr.l     _Trace.L
; Echo = 1 ;
       move.l    #1,_Echo.L
; d0=d1=d2=d3=d4=d5=d6=d7=0 ;
       clr.l     _d7.L
       clr.l     _d6.L
       clr.l     _d5.L
       clr.l     _d4.L
       clr.l     _d3.L
       clr.l     _d2.L
       clr.l     _d1.L
       clr.l     _d0.L
; a0=a1=a2=a3=a4=a5=a6=0 ;
       clr.l     _a6.L
       clr.l     _a5.L
       clr.l     _a4.L
       clr.l     _a3.L
       clr.l     _a2.L
       clr.l     _a1.L
       clr.l     _a0.L
; PC = ProgramStart, SSP=TopOfStack, USP = TopOfStack;
       move.l    #134217728,_PC.L
       move.l    #134479872,_SSP.L
       move.l    #134479872,_USP.L
; SR = 0x2000;                            // clear interrupts enable tracing  uses IRQ6
       move.w    #8192,_SR.L
; // Initialise Breakpoint variables
; for(i = 0; i < 8; i++)  {
       clr.l     D2
main_1:
       cmp.l     #8,D2
       bge       main_3
; BreakPointAddress[i] = 0;               //array of 8 breakpoint addresses
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointAddress.L,A0
       clr.l     0(A0,D0.L)
; WatchPointAddress[i] = 0 ;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointAddress.L,A0
       clr.l     0(A0,D0.L)
; BreakPointInstruction[i] = 0;           // to hold the instruction at the break point
       move.l    D2,D0
       lsl.l     #1,D0
       lea       _BreakPointInstruction.L,A0
       clr.w     0(A0,D0.L)
; BreakPointSetOrCleared[i] = 0;          // indicates if break point set
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _BreakPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
; WatchPointSetOrCleared[i] = 0;
       move.l    D2,D0
       lsl.l     #2,D0
       lea       _WatchPointSetOrCleared.L,A0
       clr.l     0(A0,D0.L)
       addq.l    #1,D2
       bra       main_1
main_3:
; }
; Init_RS232() ;     // initialise the RS232 port
       jsr       _Init_RS232
; Init_LCD() ;
       jsr       _Init_LCD
; for( i = 32; i < 48; i++)
       moveq     #32,D2
main_4:
       cmp.l     #48,D2
       bge.s     main_6
; InstallExceptionHandler(UnhandledTrap, i) ;		        // install Trap exception handler on vector 32-47
       move.l    D2,-(A7)
       pea       _UnhandledTrap.L
       jsr       (A2)
       addq.w    #8,A7
       addq.l    #1,D2
       bra       main_4
main_6:
; InstallExceptionHandler(menu, 47) ;		                   // TRAP #15 call debug and end program
       pea       47
       pea       _menu.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ1, 25) ;		      // install handler for interrupts
       pea       25
       pea       _UnhandledIRQ1.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ2, 26) ;		      // install handler for interrupts
       pea       26
       pea       _UnhandledIRQ2.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ3, 27) ;		      // install handler for interrupts
       pea       27
       pea       _UnhandledIRQ3.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ4, 28) ;		      // install handler for interrupts
       pea       28
       pea       _UnhandledIRQ4.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ5, 29) ;		      // install handler for interrupts
       pea       29
       pea       _UnhandledIRQ5.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ6, 30) ;		      // install handler for interrupts
       pea       30
       pea       _UnhandledIRQ6.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnhandledIRQ7, 31) ;		      // install handler for interrupts
       pea       31
       pea       _UnhandledIRQ7.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(HandleBreakPoint, 46) ;		           // install Trap 14 Break Point exception handler on vector 46
       pea       46
       pea       _HandleBreakPoint.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(DumpRegistersandPause, 29) ;		   // install TRACE handler for IRQ5 on vector 29
       pea       29
       pea       _DumpRegistersandPause.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(BusError,2) ;                          // install Bus error handler
       pea       2
       pea       _BusError.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(AddressError,3) ;                      // install address error handler (doesn't work on soft core 68k implementation)
       pea       3
       pea       _AddressError.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(IllegalInstruction,4) ;                // install illegal instruction exception handler
       pea       4
       pea       _IllegalInstruction.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Dividebyzero,5) ;                      // install /0 exception handler
       pea       5
       pea       _Dividebyzero.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Check,6) ;                             // install check instruction exception handler
       pea       6
       pea       _Check.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Trapv,7) ;                             // install trapv instruction exception handler
       pea       7
       pea       _Trapv.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(PrivError,8) ;                         // install Priv Violation exception handler
       pea       8
       pea       _PrivError.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(UnitIRQ,15) ;                          // install uninitialised IRQ exception handler
       pea       15
       pea       _UnitIRQ.L
       jsr       (A2)
       addq.w    #8,A7
; InstallExceptionHandler(Check,24) ;                            // install spurious IRQ exception handler
       pea       24
       pea       _Check.L
       jsr       (A2)
       addq.w    #8,A7
; FlushKeyboard() ;                        // dump unread characters from keyboard
       jsr       _FlushKeyboard
; TraceException = 0 ;                     // clear trace exception port to remove any software generated single step/trace
       clr.b     4194314
; // test for auto flash boot and run from Flash by reading switch 9 on DE1-soc board. If set, copy program from flash into Dram and run
; while(((char)(PortB & 0x02)) == (char)(0x02))    {
main_7:
       move.b    4194306,D0
       and.b     #2,D0
       cmp.b     #2,D0
       bne.s     main_9
; LoadFromFlashChip();
       jsr       _LoadFromFlashChip
; printf("\r\nRunning.....") ;
       pea       @m68kde~1_166.L
       jsr       (A3)
       addq.w    #4,A7
; Oline1("Running.....") ;
       pea       @m68kde~1_167.L
       jsr       _Oline1
       addq.w    #4,A7
; GoFlag = 1;
       move.l    #1,_GoFlag.L
; go() ;
       jsr       _go
       bra       main_7
main_9:
; }
; // otherwise start the debug monitor
; Oline0(BugMessage) ;
       move.l    D3,-(A7)
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("By: PJ Davies") ;
       pea       @m68kde~1_168.L
       jsr       _Oline1
       addq.w    #4,A7
; printf("\r\n%s", BugMessage) ;
       move.l    D3,-(A7)
       pea       @m68kde~1_169.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\n%s", CopyrightMessage) ;
       move.l    -4(A6),-(A7)
       pea       @m68kde~1_170.L
       jsr       (A3)
       addq.w    #8,A7
; menu();
       jsr       _menu
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; void FormatInstruction(void)    // for disassembly
; {
       xdef      _FormatInstruction
_FormatInstruction:
       link      A6,#-320
       movem.l   D2/D3/D4/D5/A2,-(A7)
       lea       -320(A6),A2
; short i, ilen = 0 ;
       clr.w     D5
; char *iptr = Instruction ;
       lea       _Instruction.L,A0
       move.l    A0,D3
; char *Formatted[80], *fptr ;
; fptr = Formatted ;
       move.l    A2,D4
; for(i = 0; i < (short)(80); i ++)
       clr.w     D2
FormatInstruction_1:
       cmp.w     #80,D2
       bge.s     FormatInstruction_3
; Formatted[i] = (char)(0);          // set formatted string to null
       ext.l     D2
       move.l    D2,D0
       lsl.l     #2,D0
       clr.l     0(A2,D0.L)
       addq.w    #1,D2
       bra       FormatInstruction_1
FormatInstruction_3:
; while((*iptr != ' '))   {   // while ot a space char
FormatInstruction_4:
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       beq.s     FormatInstruction_6
; *fptr++ = *iptr++ ;     // copy string until space or end encountered
       move.l    D3,A0
       addq.l    #1,D3
       move.l    D4,A1
       addq.l    #1,D4
       move.b    (A0),(A1)
; ilen ++ ;               // count length of string as we go
       addq.w    #1,D5
; if(*iptr == 0)          // if we got the end and copied the NUL then return
       move.l    D3,A0
       move.b    (A0),D0
       bne.s     FormatInstruction_7
; return ;
       bra       FormatInstruction_9
FormatInstruction_7:
       bra       FormatInstruction_4
FormatInstruction_6:
; }
; // must still be more text to process otherwise we would have returned above if got to the end
; for(i = 0; i < ((short)(8) - ilen); i++)
       clr.w     D2
FormatInstruction_10:
       moveq     #8,D0
       ext.w     D0
       sub.w     D5,D0
       cmp.w     D0,D2
       bge.s     FormatInstruction_12
; *fptr++ = ' ' ;        // make sure first operand appears in field 8 of formatted string
       move.l    D4,A0
       addq.l    #1,D4
       move.b    #32,(A0)
       addq.w    #1,D2
       bra       FormatInstruction_10
FormatInstruction_12:
; // now skip over any spaces in original unformatted string before copying the rest
; while((*iptr == ' '))
FormatInstruction_13:
       move.l    D3,A0
       move.b    (A0),D0
       cmp.b     #32,D0
       bne.s     FormatInstruction_15
; iptr++ ;
       addq.l    #1,D3
       bra       FormatInstruction_13
FormatInstruction_15:
; strcat(fptr,iptr) ;
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       jsr       _strcat
       addq.w    #8,A7
; strcpyInstruction(Formatted) ;
       move.l    A2,-(A7)
       jsr       _strcpyInstruction
       addq.w    #4,A7
FormatInstruction_9:
       movem.l   (A7)+,D2/D3/D4/D5/A2
       unlk      A6
       rts
; }
; unsigned short int Decode2BitOperandSize(unsigned short int OpCode)
; {
       xdef      _Decode2BitOperandSize
_Decode2BitOperandSize:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       move.w    10(A6),D3
       and.l     #65535,D3
       lea       _strcatInstruction.L,A2
; unsigned short int DataSize ;       // used to determine the size of data following say an immediate instruction such as addi etc
; OpCode = (OpCode & (unsigned short int)(0x00C0)) >> 6 ;             // get bits 7 and 6 into positions 1,0
       move.w    D3,D0
       and.w     #192,D0
       lsr.w     #6,D0
       move.w    D0,D3
; if(OpCode == (unsigned short int)(0))   {
       tst.w     D3
       bne.s     Decode2BitOperandSize_1
; strcatInstruction(".B ") ;
       pea       @m68kde~1_171.L
       jsr       (A2)
       addq.w    #4,A7
; DataSize = 1 ;
       moveq     #1,D2
       bra.s     Decode2BitOperandSize_4
Decode2BitOperandSize_1:
; }
; else if(OpCode == (unsigned short int)(1)) {
       cmp.w     #1,D3
       bne.s     Decode2BitOperandSize_3
; strcatInstruction(".W ") ;
       pea       @m68kde~1_172.L
       jsr       (A2)
       addq.w    #4,A7
; DataSize = 1 ;
       moveq     #1,D2
       bra.s     Decode2BitOperandSize_4
Decode2BitOperandSize_3:
; }
; else {
; strcatInstruction(".L ") ;
       pea       @m68kde~1_173.L
       jsr       (A2)
       addq.w    #4,A7
; DataSize = 2 ;
       moveq     #2,D2
Decode2BitOperandSize_4:
; }
; return DataSize;
       move.w    D2,D0
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; void Decode3BitDataRegister(unsigned short int OpCode)                // Data Register in Bits 11, 10 and 9
; {
       xdef      _Decode3BitDataRegister
_Decode3BitDataRegister:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       -4(A6),A2
; unsigned char RegNumber[3] ;
; RegNumber[0] = 'D' ;
       move.b    #68,(A2)
; RegNumber[1] = (unsigned char)(0x30) + (unsigned char)((OpCode & 0x0E00) >> 9) ;   // get data register number in bits 2,1,0 and convert to ASCII equiv
       moveq     #48,D0
       move.w    10(A6),D1
       and.w     #3584,D1
       lsr.w     #8,D1
       lsr.w     #1,D1
       add.b     D1,D0
       move.b    D0,1(A2)
; RegNumber[2] = 0 ;
       clr.b     2(A2)
; strcatInstruction(RegNumber) ;        // write register number to the disassembled instruction
       move.l    A2,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; void Decode3BitAddressRegister(unsigned short int Reg)                // Address Register in Bits 2,1,0
; {
       xdef      _Decode3BitAddressRegister
_Decode3BitAddressRegister:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       -4(A6),A2
; unsigned char RegNumber[3];
; RegNumber[0] = 'A' ;
       move.b    #65,(A2)
; RegNumber[1] = (unsigned char)(0x30) + (unsigned char)(Reg) ;   // get data register number in bits 2,1,0 and convert to ASCII equiv
       moveq     #48,D0
       move.w    10(A6),D1
       add.b     D1,D0
       move.b    D0,1(A2)
; RegNumber[2] = 0 ;
       clr.b     2(A2)
; strcatInstruction(RegNumber) ;        // write register number to the disassembled instruction
       move.l    A2,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; // Special function is used to print 8,16, 32 bit operands after move #
; //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; void DecodeBWLDataAfterOpCodeForMove(unsigned short int *OpCode )
; {
       xdef      _DecodeBWLDataAfterOpCodeForMove
_DecodeBWLDataAfterOpCodeForMove:
       link      A6,#0
       movem.l   D2/D3/A2/A3,-(A7)
       move.l    8(A6),D2
       lea       _TempString.L,A2
       lea       _sprintf.L,A3
; unsigned char OperandSize ;
; OperandSize = (*OpCode >> 12) & (unsigned short int)(0x0003) ;               // get bits 13,12 into 1,0 as these define size of #operand
       move.l    D2,A0
       move.w    (A0),D0
       lsr.w     #8,D0
       lsr.w     #4,D0
       and.w     #3,D0
       move.b    D0,D3
; InstructionSize += 1;
       addq.l    #1,_InstructionSize.L
; if(OperandSize == (char)(1))                // #byte value
       cmp.b     #1,D3
       bne.s     DecodeBWLDataAfterOpCodeForMove_1
; sprintf(TempString, "#$%X", (unsigned int)(OpCode[1]));
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_174.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
       bra       DecodeBWLDataAfterOpCodeForMove_5
DecodeBWLDataAfterOpCodeForMove_1:
; else if(OperandSize == (char)(3))          // #word value
       cmp.b     #3,D3
       bne.s     DecodeBWLDataAfterOpCodeForMove_3
; sprintf(TempString, "#$%X", (unsigned int)(OpCode[1]));
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_175.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
       bra       DecodeBWLDataAfterOpCodeForMove_5
DecodeBWLDataAfterOpCodeForMove_3:
; else if(OperandSize == (char)(2)) {                                       // long value
       cmp.b     #2,D3
       bne       DecodeBWLDataAfterOpCodeForMove_5
; sprintf(TempString, "#$%X", ((unsigned int)(OpCode[1]) << 16) | (unsigned int)(OpCode[2])); // create 3
       move.l    D2,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       lsl.l     #8,D1
       lsl.l     #8,D1
       move.l    D2,A0
       move.l    D0,-(A7)
       move.w    4(A0),D0
       and.l     #65535,D0
       or.l      D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       pea       @m68kde~1_176.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
; InstructionSize += 1;
       addq.l    #1,_InstructionSize.L
DecodeBWLDataAfterOpCodeForMove_5:
; }
; strcatInstruction(TempString) ;
       move.l    A2,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; // This function is used to print 8,16, 32 bit operands after the opcode, this is in instruction like ADD # where immediate addressing is used as source
; /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; void DecodeBWLDataAfterOpCode(unsigned short int *OpCode )
; {
       xdef      _DecodeBWLDataAfterOpCode
_DecodeBWLDataAfterOpCode:
       link      A6,#0
       movem.l   D2/D3/A2/A3/A4,-(A7)
       move.l    8(A6),D3
       lea       _TempString.L,A2
       lea       _sprintf.L,A3
       lea       _InstructionSize.L,A4
; unsigned char OperandSize ;
; OperandSize = (*OpCode & (unsigned short int)(0x01C0)) >> 6 ;               // get bits 8,7 and 6 into positions 1,0, these define size of operand
       move.l    D3,A0
       move.w    (A0),D0
       and.w     #448,D0
       lsr.w     #6,D0
       move.b    D0,D2
; InstructionSize += 1;
       addq.l    #1,(A4)
; if((OperandSize == (char)(0)) || (OperandSize == (char)(4)))                // #byte value
       tst.b     D2
       beq.s     DecodeBWLDataAfterOpCode_3
       cmp.b     #4,D2
       bne.s     DecodeBWLDataAfterOpCode_1
DecodeBWLDataAfterOpCode_3:
; sprintf(TempString, "#$%X", (unsigned int)(OpCode[1]));
       move.l    D3,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_177.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
       bra       DecodeBWLDataAfterOpCode_7
DecodeBWLDataAfterOpCode_1:
; // #word value 7 is used by divs.w instruction (not divu)
; // however used by instructions like adda, cmpa, suba # to mean long value -
; // bugger - have to build a special case and look at opcode to see what instruction is
; else if((OperandSize == (char)(1)) || (OperandSize == (char)(5)) || (OperandSize == (char)(3)))         //# byte or word value
       cmp.b     #1,D2
       beq.s     DecodeBWLDataAfterOpCode_6
       cmp.b     #5,D2
       beq.s     DecodeBWLDataAfterOpCode_6
       cmp.b     #3,D2
       bne.s     DecodeBWLDataAfterOpCode_4
DecodeBWLDataAfterOpCode_6:
; sprintf(TempString, "#$%X", (unsigned int)(OpCode[1]));
       move.l    D3,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_178.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
       bra       DecodeBWLDataAfterOpCode_7
DecodeBWLDataAfterOpCode_4:
; else if((OperandSize == (char)(2))  || (OperandSize == (char)(6)) || (OperandSize == (char)(7)))    {    //# long value
       cmp.b     #2,D2
       beq.s     DecodeBWLDataAfterOpCode_9
       cmp.b     #6,D2
       beq.s     DecodeBWLDataAfterOpCode_9
       cmp.b     #7,D2
       bne       DecodeBWLDataAfterOpCode_7
DecodeBWLDataAfterOpCode_9:
; sprintf(TempString, "#$%X", ((unsigned int)(OpCode[1]) << 16) | (unsigned int)(OpCode[2]) ); // create 3
       move.l    D3,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       lsl.l     #8,D1
       lsl.l     #8,D1
       move.l    D3,A0
       move.l    D0,-(A7)
       move.w    4(A0),D0
       and.l     #65535,D0
       or.l      D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       pea       @m68kde~1_179.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
; InstructionSize += 1;
       addq.l    #1,(A4)
DecodeBWLDataAfterOpCode_7:
; }
; // special case for divs - bugger!!!
; if((*OpCode & (unsigned short int)(0xF1C0)) == (unsigned short int)(0x81C0)) // it's the divs instruction
       move.l    D3,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #33216,D0
       bne.s     DecodeBWLDataAfterOpCode_10
; {
; InstructionSize = 2 ;
       move.l    #2,(A4)
; sprintf(TempString, "#$%X", (unsigned int)(OpCode[1]));
       move.l    D3,A0
       move.w    2(A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_180.L
       move.l    A2,-(A7)
       jsr       (A3)
       add.w     #12,A7
DecodeBWLDataAfterOpCode_10:
; }
; strcatInstruction(TempString) ;
       move.l    A2,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/A2/A3/A4
       unlk      A6
       rts
; }
; //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; // This function decodes the MODE|EA bits opcode in bits 5,4,3,2,1,0 or 11-6
; // DataSize is used to gain access to the operand used by EA, e.g. ADDI  #$2344422,$234234
; // since the data following the opcode is actually the immediate data which could be 1 or 2 words
; //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
; void Decode6BitEA(unsigned short int *OpCode, int EAChoice, unsigned short int DataSize, unsigned short int IsItMoveInstruction)     // decode Mode/Register
; {
       xdef      _Decode6BitEA
_Decode6BitEA:
       link      A6,#-12
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _strcatInstruction.L,A2
       lea       _TempString.L,A3
       move.l    8(A6),D4
       lea       _sprintf.L,A4
       lea       _InstructionSize.L,A5
       move.w    18(A6),D6
       and.l     #65535,D6
; unsigned char OperandMode, OperandRegister, OperandSize;
; short int ExWord1, ExWord2 ;                       // get any extra 16 bit word associated with EA
; unsigned char RegNumber[3];
; signed char offset ;
; unsigned short int Xn, XnSize ;
; if(EAChoice == 0)   {   // if EA in bits 5-0
       move.l    12(A6),D0
       bne.s     Decode6BitEA_1
; OperandMode = ((unsigned char)(*OpCode >> 3) & (unsigned short int)(0x7)) ;    // get bits 5,4,3 into position 2,1,0
       move.l    D4,A0
       move.w    (A0),D0
       lsr.w     #3,D0
       and.w     #255,D0
       and.w     #7,D0
       move.b    D0,D5
; OperandRegister = ((unsigned char)(*OpCode) & (unsigned short int)(0x7)) ;
       move.l    D4,A0
       move.w    (A0),D0
       and.w     #255,D0
       and.w     #7,D0
       move.b    D0,D3
       bra.s     Decode6BitEA_2
Decode6BitEA_1:
; }
; else    {               // else EA in bits 11-6
; OperandMode = ((unsigned char)(*OpCode >> 6) & (unsigned short int)(0x7)) ;
       move.l    D4,A0
       move.w    (A0),D0
       lsr.w     #6,D0
       and.w     #255,D0
       and.w     #7,D0
       move.b    D0,D5
; OperandRegister = ((unsigned char)(*OpCode >> 9) & (unsigned short int)(0x7)) ;
       move.l    D4,A0
       move.w    (A0),D0
       lsr.w     #8,D0
       lsr.w     #1,D0
       and.w     #255,D0
       and.w     #7,D0
       move.b    D0,D3
Decode6BitEA_2:
; }
; if(EAChoice == 0)    {
       move.l    12(A6),D0
       bne       Decode6BitEA_3
; ExWord1 = OpCode[1+DataSize] ;
       move.l    D4,A0
       moveq     #1,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D6
       add.l     D6,D0
       lsl.l     #1,D0
       move.w    0(A0,D0.L),D2
; ExWord2 = OpCode[2+DataSize] ;
       move.l    D4,A0
       moveq     #2,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D6
       add.l     D6,D0
       lsl.l     #1,D0
       move.w    0(A0,D0.L),-8(A6)
       bra       Decode6BitEA_7
Decode6BitEA_3:
; }
; else if(EAChoice == 1)   {
       move.l    12(A6),D0
       cmp.l     #1,D0
       bne       Decode6BitEA_5
; ExWord1 = OpCode[3+DataSize] ;
       move.l    D4,A0
       moveq     #3,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D6
       add.l     D6,D0
       lsl.l     #1,D0
       move.w    0(A0,D0.L),D2
; ExWord2 = OpCode[4+DataSize] ;
       move.l    D4,A0
       moveq     #4,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D6
       add.l     D6,D0
       lsl.l     #1,D0
       move.w    0(A0,D0.L),-8(A6)
       bra       Decode6BitEA_7
Decode6BitEA_5:
; }
; else if(EAChoice == 2)   {  // for move instruction
       move.l    12(A6),D0
       cmp.l     #2,D0
       bne       Decode6BitEA_7
; ExWord1 = OpCode[1+DataSize] ;
       move.l    D4,A0
       moveq     #1,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D6
       add.l     D6,D0
       lsl.l     #1,D0
       move.w    0(A0,D0.L),D2
; ExWord2 = OpCode[2+DataSize] ;
       move.l    D4,A0
       moveq     #2,D0
       ext.w     D0
       ext.l     D0
       and.l     #65535,D6
       add.l     D6,D0
       lsl.l     #1,D0
       move.w    0(A0,D0.L),-8(A6)
Decode6BitEA_7:
; }
; if(OperandMode == (unsigned char)(0)) {                    // Effective Address = Dn
       tst.b     D5
       bne.s     Decode6BitEA_9
; RegNumber[0] = 'D' ;
       move.b    #68,-6+0(A6)
; RegNumber[1] = (unsigned char)(0x30 + OperandRegister) ;
       moveq     #48,D0
       add.b     D3,D0
       move.b    D0,-6+1(A6)
; RegNumber[2] = 0 ;
       clr.b     -6+2(A6)
; strcatInstruction(RegNumber) ;
       pea       -6(A6)
       jsr       (A2)
       addq.w    #4,A7
       bra       Decode6BitEA_44
Decode6BitEA_9:
; }
; else if(OperandMode == (unsigned char)(1)) {                    // Effective Address = An
       cmp.b     #1,D5
       bne.s     Decode6BitEA_11
; Decode3BitAddressRegister(OperandRegister) ;
       and.w     #255,D3
       and.l     #65535,D3
       move.l    D3,-(A7)
       jsr       _Decode3BitAddressRegister
       addq.w    #4,A7
       bra       Decode6BitEA_44
Decode6BitEA_11:
; }
; else if(OperandMode == (unsigned char)(2)) {                    // Effective Address = (An)
       cmp.b     #2,D5
       bne.s     Decode6BitEA_13
; strcatInstruction("(") ;
       pea       @m68kde~1_181.L
       jsr       (A2)
       addq.w    #4,A7
; Decode3BitAddressRegister(OperandRegister) ;
       and.w     #255,D3
       and.l     #65535,D3
       move.l    D3,-(A7)
       jsr       _Decode3BitAddressRegister
       addq.w    #4,A7
; strcatInstruction(")") ;
       pea       @m68kde~1_182.L
       jsr       (A2)
       addq.w    #4,A7
       bra       Decode6BitEA_44
Decode6BitEA_13:
; }
; else if(OperandMode == (unsigned char)(3)) {                    // Effective Address = (An)+
       cmp.b     #3,D5
       bne.s     Decode6BitEA_15
; strcatInstruction("(") ;
       pea       @m68kde~1_183.L
       jsr       (A2)
       addq.w    #4,A7
; Decode3BitAddressRegister(OperandRegister) ;
       and.w     #255,D3
       and.l     #65535,D3
       move.l    D3,-(A7)
       jsr       _Decode3BitAddressRegister
       addq.w    #4,A7
; strcatInstruction(")+") ;
       pea       @m68kde~1_184.L
       jsr       (A2)
       addq.w    #4,A7
       bra       Decode6BitEA_44
Decode6BitEA_15:
; }
; else if(OperandMode == (unsigned char)(4)) {                    // Effective Address = -(An)
       cmp.b     #4,D5
       bne.s     Decode6BitEA_17
; strcatInstruction("-(") ;
       pea       @m68kde~1_185.L
       jsr       (A2)
       addq.w    #4,A7
; Decode3BitAddressRegister(OperandRegister) ;
       and.w     #255,D3
       and.l     #65535,D3
       move.l    D3,-(A7)
       jsr       _Decode3BitAddressRegister
       addq.w    #4,A7
; strcatInstruction(")") ;
       pea       @m68kde~1_186.L
       jsr       (A2)
       addq.w    #4,A7
       bra       Decode6BitEA_44
Decode6BitEA_17:
; }
; else if(OperandMode == (unsigned char)(5)) {                    // Effective Address = (d16, An)
       cmp.b     #5,D5
       bne.s     Decode6BitEA_19
; sprintf(TempString, "%d(A%d)", ExWord1, OperandRegister) ;
       and.l     #255,D3
       move.l    D3,-(A7)
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_187.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #16,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; InstructionSize += 1;
       addq.l    #1,(A5)
       bra       Decode6BitEA_44
Decode6BitEA_19:
; }
; else if(OperandMode == (unsigned char)(6)) {                    // Effective Address = (d8, An, Xn)
       cmp.b     #6,D5
       bne       Decode6BitEA_21
; offset = ExWord1 & (short int)(0x00FF);
       move.w    D2,D0
       and.w     #255,D0
       move.b    D0,-3(A6)
; sprintf(TempString, "%d(A%d,", offset, OperandRegister) ;
       and.l     #255,D3
       move.l    D3,-(A7)
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_188.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #16,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; InstructionSize += 1;
       addq.l    #1,(A5)
; // decode the Xn bit
; if((ExWord1 & (unsigned short int)(0x8000)) == (unsigned short int)(0x0000))
       move.w    D2,D0
       and.w     #32768,D0
       bne.s     Decode6BitEA_23
; strcatInstruction("D") ;
       pea       @m68kde~1_189.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     Decode6BitEA_24
Decode6BitEA_23:
; else
; strcatInstruction("A") ;
       pea       @m68kde~1_190.L
       jsr       (A2)
       addq.w    #4,A7
Decode6BitEA_24:
; Xn = (ExWord1 & (unsigned short int)(0x7000)) >> 12 ;        // get Xn register Number into bits 2,1,0
       move.w    D2,D0
       and.w     #28672,D0
       lsr.w     #8,D0
       lsr.w     #4,D0
       move.w    D0,-2(A6)
; sprintf(TempString, "%d",Xn) ;                               // generate string for reg number 0 -7
       move.w    -2(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_191.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; XnSize = (ExWord1 & (unsigned short int)(0x0800)) >> 11 ;    // get xn size into bit 0
       move.w    D2,D0
       and.w     #2048,D0
       lsr.w     #8,D0
       lsr.w     #3,D0
       move.w    D0,D7
; if(XnSize == 0)
       tst.w     D7
       bne.s     Decode6BitEA_25
; strcatInstruction(".W)") ;
       pea       @m68kde~1_192.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     Decode6BitEA_26
Decode6BitEA_25:
; else
; strcatInstruction(".L)") ;
       pea       @m68kde~1_193.L
       jsr       (A2)
       addq.w    #4,A7
Decode6BitEA_26:
       bra       Decode6BitEA_44
Decode6BitEA_21:
; }
; else if(OperandMode == (unsigned char)(7)) {
       cmp.b     #7,D5
       bne       Decode6BitEA_44
; if(OperandRegister == 0) {                               // EA = (xxx).W
       tst.b     D3
       bne.s     Decode6BitEA_29
; sprintf(TempString, "$%X", ExWord1) ;
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_194.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; InstructionSize += 1;
       addq.l    #1,(A5)
       bra       Decode6BitEA_44
Decode6BitEA_29:
; }
; else if(OperandRegister == 1)   {                         // EA = (xxx).L
       cmp.b     #1,D3
       bne       Decode6BitEA_31
; sprintf(TempString, "$%X", ((unsigned int)(ExWord1) << 16) | (unsigned int)(ExWord2)); // create 32 bit address
       move.w    D2,D1
       ext.l     D1
       lsl.l     #8,D1
       lsl.l     #8,D1
       move.l    D0,-(A7)
       move.w    -8(A6),D0
       ext.l     D0
       or.l      D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       pea       @m68kde~1_195.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; InstructionSize += 2;
       addq.l    #2,(A5)
       bra       Decode6BitEA_44
Decode6BitEA_31:
; }
; else if(OperandRegister == 4) {                                 // source EA = #Immediate addressing
       cmp.b     #4,D3
       bne.s     Decode6BitEA_33
; if(IsItMoveInstruction == 0)        //not move instruction
       move.w    22(A6),D0
       bne.s     Decode6BitEA_35
; DecodeBWLDataAfterOpCode(OpCode);
       move.l    D4,-(A7)
       jsr       _DecodeBWLDataAfterOpCode
       addq.w    #4,A7
       bra.s     Decode6BitEA_36
Decode6BitEA_35:
; else
; DecodeBWLDataAfterOpCodeForMove(OpCode);
       move.l    D4,-(A7)
       jsr       _DecodeBWLDataAfterOpCodeForMove
       addq.w    #4,A7
Decode6BitEA_36:
       bra       Decode6BitEA_44
Decode6BitEA_33:
; }
; else if(OperandRegister == 2) {                                 // source EA = (d16,PC)
       cmp.b     #2,D3
       bne.s     Decode6BitEA_37
; sprintf(TempString, "%d(PC)", ExWord1) ;
       ext.l     D2
       move.l    D2,-(A7)
       pea       @m68kde~1_196.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; InstructionSize += 1;
       addq.l    #1,(A5)
       bra       Decode6BitEA_44
Decode6BitEA_37:
; }
; else if(OperandRegister == 3) {                                 // source EA = (d8,PC, Xn)
       cmp.b     #3,D3
       bne       Decode6BitEA_44
; offset = ExWord1 & (short int)(0x00FF);
       move.w    D2,D0
       and.w     #255,D0
       move.b    D0,-3(A6)
; sprintf(TempString, "%d(PC,", offset ) ;
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_197.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; InstructionSize += 1;
       addq.l    #1,(A5)
; // decode the Xn bit
; if((ExWord1 & (unsigned short int)(0x8000)) == (unsigned short int)(0x0000))
       move.w    D2,D0
       and.w     #32768,D0
       bne.s     Decode6BitEA_41
; strcatInstruction("D") ;
       pea       @m68kde~1_198.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     Decode6BitEA_42
Decode6BitEA_41:
; else
; strcatInstruction("A") ;
       pea       @m68kde~1_199.L
       jsr       (A2)
       addq.w    #4,A7
Decode6BitEA_42:
; Xn = (ExWord1 & (unsigned short int)(0x7000)) >> 12 ;        // get Xn register Number into bits 2,1,0
       move.w    D2,D0
       and.w     #28672,D0
       lsr.w     #8,D0
       lsr.w     #4,D0
       move.w    D0,-2(A6)
; sprintf(TempString, "%d",Xn) ;                               // generate string for reg number 0 -7
       move.w    -2(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_200.L
       move.l    A3,-(A7)
       jsr       (A4)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; XnSize = (ExWord1 & (unsigned short int)(0x0800)) >> 11 ;    // get xn size into bit 0
       move.w    D2,D0
       and.w     #2048,D0
       lsr.w     #8,D0
       lsr.w     #3,D0
       move.w    D0,D7
; if(XnSize == 0)
       tst.w     D7
       bne.s     Decode6BitEA_43
; strcatInstruction(".W)") ;
       pea       @m68kde~1_201.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     Decode6BitEA_44
Decode6BitEA_43:
; else
; strcatInstruction(".L)") ;
       pea       @m68kde~1_202.L
       jsr       (A2)
       addq.w    #4,A7
Decode6BitEA_44:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; }
; void Decode3BitOperandMode(unsigned short int *OpCode)               // used with instructions like ADD determines source/destination
; {
       xdef      _Decode3BitOperandMode
_Decode3BitOperandMode:
       link      A6,#-4
       move.l    D2,-(A7)
       move.l    8(A6),D2
; unsigned short int OperandMode;
; OperandMode = (*OpCode & (unsigned short int)(0x0100)) >> 8 ;    // get bit 8 into position 0, defines source and destination
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       lsr.w     #8,D0
       move.w    D0,-2(A6)
; Decode2BitOperandSize(*OpCode);                                  // add .b, .w, .l size indicator to instruction string
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; if(OperandMode == 0)     {                                      // Destination is a Data Register
       move.w    -2(A6),D0
       bne       Decode3BitOperandMode_1
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_203.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode3BitDataRegister(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode3BitDataRegister
       addq.w    #4,A7
       bra.s     Decode3BitOperandMode_2
Decode3BitOperandMode_1:
; }
; else {                                                         // Destination is in EA
; Decode3BitDataRegister(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode3BitDataRegister
       addq.w    #4,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_204.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
Decode3BitOperandMode_2:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; void DecodeBranchCondition(unsigned short int Condition)
; {
       xdef      _DecodeBranchCondition
_DecodeBranchCondition:
       link      A6,#0
       movem.l   D2/A2,-(A7)
       lea       _strcatInstruction.L,A2
       move.w    10(A6),D2
       and.l     #65535,D2
; if(Condition == (unsigned short int)(0x04))
       cmp.w     #4,D2
       bne.s     DecodeBranchCondition_1
; strcatInstruction("CC") ;
       pea       @m68kde~1_205.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_1:
; else if(Condition == (unsigned short int)(0x05))
       cmp.w     #5,D2
       bne.s     DecodeBranchCondition_3
; strcatInstruction("CS") ;
       pea       @m68kde~1_206.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_3:
; else if(Condition == (unsigned short int)(0x07))
       cmp.w     #7,D2
       bne.s     DecodeBranchCondition_5
; strcatInstruction("EQ") ;
       pea       @m68kde~1_207.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_5:
; else if(Condition == (unsigned short int)(0x0C))
       cmp.w     #12,D2
       bne.s     DecodeBranchCondition_7
; strcatInstruction("GE") ;
       pea       @m68kde~1_208.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_7:
; else if(Condition == (unsigned short int)(0x0E))
       cmp.w     #14,D2
       bne.s     DecodeBranchCondition_9
; strcatInstruction("GT") ;
       pea       @m68kde~1_209.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_9:
; else if(Condition == (unsigned short int)(0x02))
       cmp.w     #2,D2
       bne.s     DecodeBranchCondition_11
; strcatInstruction("HI") ;
       pea       @m68kde~1_210.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_11:
; else if(Condition == (unsigned short int)(0x0F))
       cmp.w     #15,D2
       bne.s     DecodeBranchCondition_13
; strcatInstruction("LE") ;
       pea       @m68kde~1_211.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_13:
; else if(Condition == (unsigned short int)(0x03))
       cmp.w     #3,D2
       bne.s     DecodeBranchCondition_15
; strcatInstruction("LS") ;
       pea       @m68kde~1_212.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_15:
; else if(Condition == (unsigned short int)(0x0D))
       cmp.w     #13,D2
       bne.s     DecodeBranchCondition_17
; strcatInstruction("LT") ;
       pea       @m68kde~1_213.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_17:
; else if(Condition == (unsigned short int)(0x0B))
       cmp.w     #11,D2
       bne.s     DecodeBranchCondition_19
; strcatInstruction("MI") ;
       pea       @m68kde~1_214.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_19:
; else if(Condition == (unsigned short int)(0x06))
       cmp.w     #6,D2
       bne.s     DecodeBranchCondition_21
; strcatInstruction("NE") ;
       pea       @m68kde~1_215.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_21:
; else if(Condition == (unsigned short int)(0x0A))
       cmp.w     #10,D2
       bne.s     DecodeBranchCondition_23
; strcatInstruction("PL") ;
       pea       @m68kde~1_216.L
       jsr       (A2)
       addq.w    #4,A7
       bra       DecodeBranchCondition_30
DecodeBranchCondition_23:
; else if(Condition == (unsigned short int)(0x09))
       cmp.w     #9,D2
       bne.s     DecodeBranchCondition_25
; strcatInstruction("VS") ;
       pea       @m68kde~1_217.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DecodeBranchCondition_30
DecodeBranchCondition_25:
; else if(Condition == (unsigned short int)(0x08))
       cmp.w     #8,D2
       bne.s     DecodeBranchCondition_27
; strcatInstruction("VC") ;
       pea       @m68kde~1_218.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DecodeBranchCondition_30
DecodeBranchCondition_27:
; else if(Condition == (unsigned short int)(0))
       tst.w     D2
       bne.s     DecodeBranchCondition_29
; strcatInstruction("RA") ;
       pea       @m68kde~1_219.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     DecodeBranchCondition_30
DecodeBranchCondition_29:
; else
; strcatInstruction("SR");
       pea       @m68kde~1_220.L
       jsr       (A2)
       addq.w    #4,A7
DecodeBranchCondition_30:
; strcatInstruction(" ") ;
       pea       @m68kde~1_221.L
       jsr       (A2)
       addq.w    #4,A7
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; void DisassembleInstruction( short int *OpCode)         // pointer to Opcode
; {
       xdef      _DisassembleInstruction
_DisassembleInstruction:
       link      A6,#-40
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    8(A6),D2
       lea       _InstructionSize.L,A2
       lea       _strcpyInstruction.L,A3
       lea       _TempString.L,A4
       lea       _sprintf.L,A5
; unsigned short int MSBits = (*OpCode >> 12);    //mask off the lower 12 bits leaving top 4 bit to analyse
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #4,D0
       move.w    D0,-38(A6)
; unsigned short int LS12Bits = (*OpCode & (unsigned short int)(0x0FFF));
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #4095,D0
       move.w    D0,-36(A6)
; unsigned short int SourceBits, DestBits, Size ;
; unsigned char *Mode, Condition;
; unsigned short int Register, OpMode, EAMode, EARegister, Rx, Ry, EXGOpMode, DataSize, SourceReg;
; unsigned short int DataRegister, AddressRegister;
; signed char Displacement8Bit ;  // used for Bcc type instruction signed 8 bit displacement
; signed short int Displacement16Bit;
; short int Mask, DoneSlash;
; int i;
; strcpyInstruction("Unknown") ;
       pea       @m68kde~1_222.L
       jsr       (A3)
       addq.w    #4,A7
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ABCD
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1F0 )) == (unsigned short int)(0xC100))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61936,D0
       cmp.w     #49408,D0
       bne       DisassembleInstruction_4
; DestBits = (*OpCode >> 9) & (unsigned short int )(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,-32(A6)
; SourceBits = (*OpCode & (unsigned short int )(0x0007));
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,-34(A6)
; Mode = (*OpCode >> 3) & (unsigned short int )(0x0001) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       ext.l     D0
       and.l     #1,D0
       move.l    D0,-28(A6)
; if(Mode == 0)
       move.l    -28(A6),D0
       bne.s     DisassembleInstruction_3
; sprintf(Instruction, "ABCD D%d,D%d", SourceBits, DestBits) ;
       move.w    -32(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -34(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_223.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
       bra.s     DisassembleInstruction_4
DisassembleInstruction_3:
; else
; sprintf(Instruction, "ABCD -(A%d),-(A%d)", SourceBits, DestBits) ;
       move.w    -32(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -34(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_224.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_4:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ADD or ADDA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000 )) == (unsigned short int)(0xD000))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #53248,D0
       bne       DisassembleInstruction_8
; InstructionSize = 1;
       move.l    #1,(A2)
; OpMode = ((*OpCode >> 6) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #7,D0
       move.w    D0,D3
; if( (OpMode == (unsigned short int)(0x0003)) || (OpMode == (unsigned short int)(0x0007)))      // if destination is an address register then use ADDA otherwise use ADD
       cmp.w     #3,D3
       beq.s     DisassembleInstruction_9
       cmp.w     #7,D3
       bne       DisassembleInstruction_7
DisassembleInstruction_9:
; {
; if(OpMode == (unsigned short int)(0x0003))
       cmp.w     #3,D3
       bne.s     DisassembleInstruction_10
; strcpyInstruction("ADDA.W ") ;
       pea       @m68kde~1_225.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_11
DisassembleInstruction_10:
; else
; strcpyInstruction("ADDA.L ") ;
       pea       @m68kde~1_226.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_11:
; Decode6BitEA(OpCode,0,0,0)  ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",A%X", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_227.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       bra.s     DisassembleInstruction_8
DisassembleInstruction_7:
; }
; else {
; strcpyInstruction("ADD") ;
       pea       @m68kde~1_228.L
       jsr       (A3)
       addq.w    #4,A7
; Decode3BitOperandMode(OpCode) ;
       move.l    D2,-(A7)
       jsr       _Decode3BitOperandMode
       addq.w    #4,A7
DisassembleInstruction_8:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ADDI or ANDI or CMPI or EORI or ORI or SUBI
; /////////////////////////////////////////////////////////////////////////////////
; if( (*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0600) |
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #1536,D0
       bne.s     DisassembleInstruction_14
       moveq     #1,D0
       bra.s     DisassembleInstruction_15
DisassembleInstruction_14:
       clr.l     D0
DisassembleInstruction_15:
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65280,D1
       cmp.w     #512,D1
       bne.s     DisassembleInstruction_16
       moveq     #1,D1
       bra.s     DisassembleInstruction_17
DisassembleInstruction_16:
       clr.l     D1
DisassembleInstruction_17:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65280,D1
       cmp.w     #3072,D1
       bne.s     DisassembleInstruction_18
       moveq     #1,D1
       bra.s     DisassembleInstruction_19
DisassembleInstruction_18:
       clr.l     D1
DisassembleInstruction_19:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65280,D1
       cmp.w     #2560,D1
       bne.s     DisassembleInstruction_20
       moveq     #1,D1
       bra.s     DisassembleInstruction_21
DisassembleInstruction_20:
       clr.l     D1
DisassembleInstruction_21:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65280,D1
       bne.s     DisassembleInstruction_22
       moveq     #1,D1
       bra.s     DisassembleInstruction_23
DisassembleInstruction_22:
       clr.l     D1
DisassembleInstruction_23:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65280,D1
       cmp.w     #1024,D1
       bne.s     DisassembleInstruction_24
       moveq     #1,D1
       bra.s     DisassembleInstruction_25
DisassembleInstruction_24:
       clr.l     D1
DisassembleInstruction_25:
       or.w      D1,D0
       beq       DisassembleInstruction_12
; (*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0200) |
; (*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0C00) |
; (*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0A00) |
; (*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0000) |
; (*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0400))
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0600))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #1536,D0
       bne.s     DisassembleInstruction_26
; strcpyInstruction("ADDI") ;
       pea       @m68kde~1_229.L
       jsr       (A3)
       addq.w    #4,A7
       bra       DisassembleInstruction_36
DisassembleInstruction_26:
; else if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0200))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #512,D0
       bne.s     DisassembleInstruction_28
; strcpyInstruction("ANDI") ;
       pea       @m68kde~1_230.L
       jsr       (A3)
       addq.w    #4,A7
       bra       DisassembleInstruction_36
DisassembleInstruction_28:
; else if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0C00))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #3072,D0
       bne.s     DisassembleInstruction_30
; strcpyInstruction("CMPI") ;
       pea       @m68kde~1_231.L
       jsr       (A3)
       addq.w    #4,A7
       bra       DisassembleInstruction_36
DisassembleInstruction_30:
; else if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0A00))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #2560,D0
       bne.s     DisassembleInstruction_32
; strcpyInstruction("EORI") ;
       pea       @m68kde~1_232.L
       jsr       (A3)
       addq.w    #4,A7
       bra       DisassembleInstruction_36
DisassembleInstruction_32:
; else if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       bne.s     DisassembleInstruction_34
; strcpyInstruction("ORI") ;
       pea       @m68kde~1_233.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_36
DisassembleInstruction_34:
; else if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x0400))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #1024,D0
       bne.s     DisassembleInstruction_36
; strcpyInstruction("SUBI") ;
       pea       @m68kde~1_234.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_36:
; DataSize = Decode2BitOperandSize(*OpCode);                                  // add .b, .w, .l size indicator to instruction string
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
       move.w    D0,D7
; DecodeBWLDataAfterOpCode(OpCode);                                // go add the 8,16,32 bit data to instruction string
       move.l    D2,-(A7)
       jsr       _DecodeBWLDataAfterOpCode
       addq.w    #4,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_235.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,DataSize,0) ;                                         // decode EA
       clr.l     -(A7)
       and.l     #65535,D7
       move.l    D7,-(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_12:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ADDI #data,SR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode  == (unsigned short int)(0x027c))   {
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #636,D0
       bne.s     DisassembleInstruction_38
; InstructionSize = 2;
       move.l    #2,(A2)
; sprintf(Instruction, "ANDI #$%X,SR", OpCode[1]);
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_236.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_38:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ADDQ
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF100 )) == (unsigned short int)(0x5000))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61696,D0
       cmp.w     #20480,D0
       bne       DisassembleInstruction_40
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("ADDQ") ;
       pea       @m68kde~1_237.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode);                                  // add .b, .w, .l size indicator to instruction string
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; sprintf(TempString, "#%1X,", ((*OpCode >> 9) & (unsigned short int)(0x0007)));    // print 3 bit #data in positions 11,10,9 in opcode
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_238.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;                                           // decode EA
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_40:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ADDX
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF130 )) == (unsigned short int)(0xD100))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61744,D0
       cmp.w     #53504,D0
       bne       DisassembleInstruction_44
; InstructionSize = 1;
       move.l    #1,(A2)
; OpMode = ((*OpCode >> 6) & (unsigned short int)(0x0003)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       move.w    D0,D3
; if(OpMode != (unsigned short int)(0x0003)) // if size = 11 then it's ADDA not ADDX
       cmp.w     #3,D3
       beq       DisassembleInstruction_44
; {
; strcpyInstruction("ADDX") ;
       pea       @m68kde~1_239.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode);                                  // add .b, .w, .l size indicator to instruction string
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; if((*OpCode & (unsigned short int)(0x0008)) == (unsigned short int)(0))    // if bit 3 of opcode is 0 indicates data registers are used as source and destination
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #8,D0
       bne       DisassembleInstruction_46
; sprintf(TempString, "D%X,D%X", (*OpCode & 0x0007), ((*OpCode >> 9) & 0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_240.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
       bra       DisassembleInstruction_47
DisassembleInstruction_46:
; else        // -(ax),-(ay) mode used
; sprintf(TempString, "-(A%X),-(A%X)", (*OpCode & 0x0007), ((*OpCode >> 9) & 0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_241.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_47:
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_44:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is AND
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000 )) == (unsigned short int)(0xC000))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #49152,D0
       bne.s     DisassembleInstruction_50
; InstructionSize = 1;
       move.l    #1,(A2)
; // need to differentiate between AND and ABCD using Mode bits in 5,4,3
; OpMode = (*OpCode >> 4) & (unsigned short int)(0x001F);
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #4,D0
       and.w     #31,D0
       move.w    D0,D3
; if(OpMode != (unsigned short int)(0x0010))   {
       cmp.w     #16,D3
       beq.s     DisassembleInstruction_50
; strcpyInstruction("AND") ;
       pea       @m68kde~1_242.L
       jsr       (A3)
       addq.w    #4,A7
; Decode3BitOperandMode(OpCode) ;
       move.l    D2,-(A7)
       jsr       _Decode3BitOperandMode
       addq.w    #4,A7
DisassembleInstruction_50:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ANDI to CCR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x023C))   {
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #572,D0
       bne.s     DisassembleInstruction_52
; sprintf(Instruction, "ANDI #$%2X,CCR", OpCode[1] & (unsigned short int)(0x00FF)) ;
       move.l    D2,A0
       move.w    2(A0),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_243.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2;
       move.l    #2,(A2)
DisassembleInstruction_52:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ASL/ASR/LSL/LSR/ROL/ROR NOTE two versions of this with different OPCodes
; /////////////////////////////////////////////////////////////////////////////////
; if( ((*OpCode & (unsigned short int)(0xF018 )) == (unsigned short int)(0xE000)) |   // ASL/ASR
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61464,D0
       cmp.w     #57344,D0
       bne.s     DisassembleInstruction_56
       moveq     #1,D0
       bra.s     DisassembleInstruction_57
DisassembleInstruction_56:
       clr.l     D0
DisassembleInstruction_57:
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65216,D1
       cmp.w     #57536,D1
       bne.s     DisassembleInstruction_58
       moveq     #1,D1
       bra.s     DisassembleInstruction_59
DisassembleInstruction_58:
       clr.l     D1
DisassembleInstruction_59:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #61464,D1
       cmp.w     #57352,D1
       bne.s     DisassembleInstruction_60
       moveq     #1,D1
       bra.s     DisassembleInstruction_61
DisassembleInstruction_60:
       clr.l     D1
DisassembleInstruction_61:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65216,D1
       cmp.w     #58048,D1
       bne.s     DisassembleInstruction_62
       moveq     #1,D1
       bra.s     DisassembleInstruction_63
DisassembleInstruction_62:
       clr.l     D1
DisassembleInstruction_63:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #61464,D1
       cmp.w     #57368,D1
       bne.s     DisassembleInstruction_64
       moveq     #1,D1
       bra.s     DisassembleInstruction_65
DisassembleInstruction_64:
       clr.l     D1
DisassembleInstruction_65:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65216,D1
       cmp.w     #59072,D1
       bne.s     DisassembleInstruction_66
       moveq     #1,D1
       bra.s     DisassembleInstruction_67
DisassembleInstruction_66:
       clr.l     D1
DisassembleInstruction_67:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #61464,D1
       cmp.w     #57360,D1
       bne.s     DisassembleInstruction_68
       moveq     #1,D1
       bra.s     DisassembleInstruction_69
DisassembleInstruction_68:
       clr.l     D1
DisassembleInstruction_69:
       or.w      D1,D0
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #65216,D1
       cmp.w     #58560,D1
       bne.s     DisassembleInstruction_70
       moveq     #1,D1
       bra.s     DisassembleInstruction_71
DisassembleInstruction_70:
       clr.l     D1
DisassembleInstruction_71:
       or.w      D1,D0
       beq       DisassembleInstruction_73
; ((*OpCode & (unsigned short int)(0xFEC0 )) == (unsigned short int)(0xE0C0)) |
; ((*OpCode & (unsigned short int)(0xF018 )) == (unsigned short int)(0xE008)) |   // LSL/LSR
; ((*OpCode & (unsigned short int)(0xFEC0 )) == (unsigned short int)(0xE2C0)) |
; ((*OpCode & (unsigned short int)(0xF018 )) == (unsigned short int)(0xE018)) |   // ROR/ROL
; ((*OpCode & (unsigned short int)(0xFEC0 )) == (unsigned short int)(0xE6C0)) |
; ((*OpCode & (unsigned short int)(0xF018 )) == (unsigned short int)(0xE010)) |   // ROXR/ROXL
; ((*OpCode & (unsigned short int)(0xFEC0 )) == (unsigned short int)(0xE4C0)))
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; // 2nd version e.g. ASR/ASL/LSR/LSL/ROR/ROL/ROXL/ROXR <EA> shift a word 1 bit
; if((*OpCode & (unsigned short int)(0x00C0)) == (unsigned short int)(0x00C0)) // if bits 7,6 == 1,1
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #192,D0
       cmp.w     #192,D0
       bne       DisassembleInstruction_72
; {
; // test direction by testing bit 8
; if((*OpCode & (unsigned short int)(0xFEC0)) == (unsigned short int)(0xE0C0))    //asr/asl
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65216,D0
       cmp.w     #57536,D0
       bne.s     DisassembleInstruction_77
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_76
; strcpyInstruction("ASL") ;
       pea       @m68kde~1_244.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_77
DisassembleInstruction_76:
; else
; strcpyInstruction("ASR") ;
       pea       @m68kde~1_245.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_77:
; // test direction by testing bit 8
; if((*OpCode & (unsigned short int)(0xFEC0)) == (unsigned short int)(0xE2C0))    //lsr/lsl
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65216,D0
       cmp.w     #58048,D0
       bne.s     DisassembleInstruction_81
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_80
; strcpyInstruction("LSL") ;
       pea       @m68kde~1_246.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_81
DisassembleInstruction_80:
; else
; strcpyInstruction("LSR") ;
       pea       @m68kde~1_247.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_81:
; // test direction by testing bit 8
; if((*OpCode & (unsigned short int)(0xFEC0)) == (unsigned short int)(0xE6C0))    //ror/rol
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65216,D0
       cmp.w     #59072,D0
       bne.s     DisassembleInstruction_85
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_84
; strcpyInstruction("ROL") ;
       pea       @m68kde~1_248.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_85
DisassembleInstruction_84:
; else
; strcpyInstruction("ROR") ;
       pea       @m68kde~1_249.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_85:
; // test direction by testing bit 8
; if((*OpCode & (unsigned short int)(0xFEC0)) == (unsigned short int)(0xE4C0))    //roxr/roxl
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65216,D0
       cmp.w     #58560,D0
       bne.s     DisassembleInstruction_89
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_88
; strcpyInstruction("ROXL") ;
       pea       @m68kde~1_250.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_89
DisassembleInstruction_88:
; else
; strcpyInstruction("ROXR") ;
       pea       @m68kde~1_251.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_89:
; strcatInstruction("  ") ;
       pea       @m68kde~1_252.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0, 0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
       bra       DisassembleInstruction_73
DisassembleInstruction_72:
; }
; // first version of above instructions, bit 5 is 0
; else
; {
; // test instruction and direction by testing bits 4,3
; if((*OpCode & (unsigned short int)(0x0018)) == (unsigned short int)(0x0))    //asr/asl
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #24,D0
       bne.s     DisassembleInstruction_93
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_92
; strcpyInstruction("ASL") ;
       pea       @m68kde~1_253.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_93
DisassembleInstruction_92:
; else
; strcpyInstruction("ASR") ;
       pea       @m68kde~1_254.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_93:
; // test instruction and direction by testing bits 4,3
; if((*OpCode & (unsigned short int)(0x0018)) == (unsigned short int)(0x0008))    //lsr/lsl
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #24,D0
       cmp.w     #8,D0
       bne.s     DisassembleInstruction_97
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_96
; strcpyInstruction("LSL") ;
       pea       @m68kde~1_255.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_97
DisassembleInstruction_96:
; else
; strcpyInstruction("LSR") ;
       pea       @m68kde~1_256.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_97:
; // test instruction and direction by testing bits 4,3
; if((*OpCode & (unsigned short int)(0x0018)) == (unsigned short int)(0x0018))    //ror/rol
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #24,D0
       cmp.w     #24,D0
       bne.s     DisassembleInstruction_101
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_100
; strcpyInstruction("ROL") ;
       pea       @m68kde~1_257.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_101
DisassembleInstruction_100:
; else
; strcpyInstruction("ROR") ;
       pea       @m68kde~1_258.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_101:
; // test instruction and direction by testing bits 4,3
; if((*OpCode & (unsigned short int)(0x0018)) == (unsigned short int)(0x0010))    //roxr/roxl
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #24,D0
       cmp.w     #16,D0
       bne.s     DisassembleInstruction_105
; if((*OpCode & (unsigned short int)(0x0100)) == (unsigned short int)(0x0100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #256,D0
       cmp.w     #256,D0
       bne.s     DisassembleInstruction_104
; strcpyInstruction("ROXL") ;
       pea       @m68kde~1_259.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_105
DisassembleInstruction_104:
; else
; strcpyInstruction("ROXR") ;
       pea       @m68kde~1_260.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_105:
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; if((*OpCode & (unsigned short int)(0x0020)) == (unsigned short int)(0)) {   // if shift count defined by #value (bit 5 = 0), e.g. asl #3,d0
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #32,D0
       bne       DisassembleInstruction_106
; sprintf(TempString,"#$%X,D%X",
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_261.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
       bra       DisassembleInstruction_107
DisassembleInstruction_106:
; ((*OpCode >> 9) & (unsigned short int)(0x0007)),
; (*OpCode & (unsigned short int)(0x0007))) ;
; }
; else {                                                                      // if shift is for example ASR D1,D2
; sprintf(TempString,"D%X,D%X",
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_262.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_107:
; ((*OpCode >> 9) & (unsigned short int)(0x0007)),
; (*OpCode & (unsigned short int)(0x0007))) ;
; }
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_73:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BCC and BSR and BRA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000 )) == (unsigned short int)(0x6000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #24576,D0
       bne       DisassembleInstruction_108
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; Condition = ((*OpCode >> 8) & (unsigned short int)(0xF)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       and.w     #15,D0
       move.b    D0,-23(A6)
; strcpyInstruction("B") ;
       pea       @m68kde~1_263.L
       jsr       (A3)
       addq.w    #4,A7
; DecodeBranchCondition(Condition) ;
       move.b    -23(A6),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _DecodeBranchCondition
       addq.w    #4,A7
; Displacement8Bit = (*OpCode & (unsigned short int)(0xFF)) ;
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #255,D0
       move.b    D0,-5(A6)
; if(Displacement8Bit == (unsigned short int)(0))  {           // if 16 bit displacement
       move.b    -5(A6),D0
       ext.w     D0
       tst.w     D0
       bne.s     DisassembleInstruction_110
; sprintf(TempString, "$%X", (int)(OpCode) + (int)(OpCode[1]) +  2) ;
       move.l    D2,D1
       move.l    D2,A0
       move.l    D0,-(A7)
       move.w    2(A0),D0
       ext.l     D0
       add.l     D0,D1
       move.l    (A7)+,D0
       addq.l    #2,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_264.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2 ;
       move.l    #2,(A2)
       bra.s     DisassembleInstruction_111
DisassembleInstruction_110:
; }
; else
; sprintf(TempString, "$%X", (int)(OpCode) + Displacement8Bit + 2) ;           // 8 bit displacement
       move.l    D2,D1
       move.l    D0,-(A7)
       move.b    -5(A6),D0
       ext.w     D0
       ext.l     D0
       add.l     D0,D1
       move.l    (A7)+,D0
       addq.l    #2,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_265.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_111:
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_108:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BCHG dn,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x0140))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #320,D0
       bne       DisassembleInstruction_112
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("BCHG ") ;
       pea       @m68kde~1_266.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "D%d,", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_267.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_112:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BCHG #data,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0 )) == (unsigned short int)(0x0840))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #2112,D0
       bne       DisassembleInstruction_114
; strcpyInstruction("BCHG ") ;
       pea       @m68kde~1_268.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "#$%X,", OpCode[1]) ;
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_269.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2 ;
       move.l    #2,(A2)
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,1,0) ;
       clr.l     -(A7)
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_114:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BCLR  dn,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x0180))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #384,D0
       bne       DisassembleInstruction_116
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("BCLR ") ;
       pea       @m68kde~1_270.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "D%d,", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_271.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_116:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BCLR #data,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0 )) == (unsigned short int)(0x0880))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #2176,D0
       bne       DisassembleInstruction_118
; strcpyInstruction("BCLR ") ;
       pea       @m68kde~1_272.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "#$%X,", OpCode[1]) ;
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_273.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2 ;
       move.l    #2,(A2)
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,1,0) ;
       clr.l     -(A7)
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_118:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BSET dn,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x01C0))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #448,D0
       bne       DisassembleInstruction_120
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("BSET ") ;
       pea       @m68kde~1_274.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "D%d,", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_275.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_120:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BSET #data,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0 )) == (unsigned short int)(0x08C0))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #2240,D0
       bne       DisassembleInstruction_122
; strcpyInstruction("BSET ") ;
       pea       @m68kde~1_276.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "#$%X,", OpCode[1]) ;
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_277.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2 ;
       move.l    #2,(A2)
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,1,0) ;
       clr.l     -(A7)
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_122:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BTST dn,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x0100))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #256,D0
       bne       DisassembleInstruction_124
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("BTST ") ;
       pea       @m68kde~1_278.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "D%d,", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_279.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_124:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is BTST #data,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0 )) == (unsigned short int)(0x0800))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #2048,D0
       bne       DisassembleInstruction_126
; strcpyInstruction("BTST ") ;
       pea       @m68kde~1_280.L
       jsr       (A3)
       addq.w    #4,A7
; sprintf(TempString, "#$%X,", OpCode[1]) ;
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_281.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2 ;
       move.l    #2,(A2)
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,1,0) ;
       clr.l     -(A7)
       pea       1
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_126:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is CHK.W <EA>,DN
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x4180))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #16768,D0
       bne       DisassembleInstruction_128
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("CHK ") ;
       pea       @m68kde~1_282.L
       jsr       (A3)
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",D%d", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_283.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_128:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is CLR <EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x4200))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #16896,D0
       bne       DisassembleInstruction_130
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("CLR") ;
       pea       @m68kde~1_284.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_130:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is CMP, CMPA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000 )) == (unsigned short int)(0xB000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #45056,D0
       bne       DisassembleInstruction_135
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; OpMode = (*OpCode >> 6) & (unsigned short int)(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #7,D0
       move.w    D0,D3
; if((OpMode == (unsigned short int)(0x0003)) || (OpMode == (unsigned short int)(0x0007)))    {
       cmp.w     #3,D3
       beq.s     DisassembleInstruction_136
       cmp.w     #7,D3
       bne       DisassembleInstruction_134
DisassembleInstruction_136:
; if(OpMode == (unsigned short int)(0x0003))
       cmp.w     #3,D3
       bne.s     DisassembleInstruction_137
; strcpyInstruction("CMPA.W ") ;
       pea       @m68kde~1_285.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_138
DisassembleInstruction_137:
; else
; strcpyInstruction("CMPA.L ") ;
       pea       @m68kde~1_286.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_138:
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",A%d", ((*OpCode >> 9) & (unsigned short int)(0x0007))) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_287.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       bra.s     DisassembleInstruction_135
DisassembleInstruction_134:
; }
; else {
; strcpyInstruction("CMP") ;
       pea       @m68kde~1_288.L
       jsr       (A3)
       addq.w    #4,A7
; Decode3BitOperandMode(OpCode) ;
       move.l    D2,-(A7)
       jsr       _Decode3BitOperandMode
       addq.w    #4,A7
DisassembleInstruction_135:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is CMPM
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF138 )) == (unsigned short int)(0xB108))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61752,D0
       cmp.w     #45320,D0
       bne       DisassembleInstruction_141
; {
; OpMode = (*OpCode >> 6) & (unsigned short int)(0x0003) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       move.w    D0,D3
; if((OpMode >= (unsigned short int)(0x0000)) && (OpMode <= (unsigned short int)(0x0002)))
       cmp.w     #0,D3
       blo       DisassembleInstruction_141
       cmp.w     #2,D3
       bhi       DisassembleInstruction_141
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("CMPM") ;
       pea       @m68kde~1_289.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; sprintf(TempString, "(A%d)+,(A%d)+", (*OpCode & (unsigned short int)(0x7)) , ((*OpCode >> 9) & (unsigned short int)(0x7)));
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_290.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_141:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is DBCC
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF0F8 )) == (unsigned short int)(0x50C8))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61688,D0
       cmp.w     #20680,D0
       bne       DisassembleInstruction_143
; {
; InstructionSize = 2;
       move.l    #2,(A2)
; strcpy(Instruction,"DB") ;
       pea       @m68kde~1_291.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Condition = ((*OpCode >> 8) & (unsigned short int)(0x000F)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       and.w     #15,D0
       move.b    D0,-23(A6)
; DecodeBranchCondition(Condition) ;
       move.b    -23(A6),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _DecodeBranchCondition
       addq.w    #4,A7
; sprintf(TempString, "D%d,%+d(PC) to Addr:$%X",(*OpCode & (unsigned short int)(0x7)), (int)(OpCode[1]), (int)(OpCode) + (int)(OpCode[1]) +  2) ;
       move.l    D2,D1
       move.l    D2,A0
       move.l    D0,-(A7)
       move.w    2(A0),D0
       ext.l     D0
       add.l     D0,D1
       move.l    (A7)+,D0
       addq.l    #2,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_292.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #20,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_143:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is DIVS
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x81C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #33216,D0
       bne       DisassembleInstruction_145
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"DIVS ") ;
       pea       @m68kde~1_293.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_294.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode3BitDataRegister(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode3BitDataRegister
       addq.w    #4,A7
DisassembleInstruction_145:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is DIVU
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0 )) == (unsigned short int)(0x80C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #32960,D0
       bne       DisassembleInstruction_147
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"DIVU ") ;
       pea       @m68kde~1_295.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_296.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode3BitDataRegister(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode3BitDataRegister
       addq.w    #4,A7
DisassembleInstruction_147:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is EOR
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000 )) == (unsigned short int)(0xB000))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #45056,D0
       bne       DisassembleInstruction_151
; OpMode = (*OpCode >> 6) & (unsigned short int)(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #7,D0
       move.w    D0,D3
; EAMode = (*OpCode >> 3) & (unsigned short int)(0x0007) ;    // mode cannot be 1 for EOR as it it used by CMPM instruction as a differentiator
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       and.w     #7,D0
       move.w    D0,-20(A6)
; if( (OpMode >= (unsigned short int)(0x0004)) &&
       cmp.w     #4,D3
       blo.s     DisassembleInstruction_151
       cmp.w     #6,D3
       bhi.s     DisassembleInstruction_151
       move.w    -20(A6),D0
       cmp.w     #1,D0
       beq.s     DisassembleInstruction_151
; (OpMode <= (unsigned short int)(0x0006)) &&
; (EAMode != (unsigned short int)(0x0001)))
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("EOR") ;
       pea       @m68kde~1_297.L
       jsr       (A3)
       addq.w    #4,A7
; Decode3BitOperandMode(OpCode);
       move.l    D2,-(A7)
       jsr       _Decode3BitOperandMode
       addq.w    #4,A7
DisassembleInstruction_151:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is EOR to CCR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x0A3C))   {
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #2620,D0
       bne.s     DisassembleInstruction_153
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "EORI #$%2X,CCR", OpCode[1] & (unsigned short int)(0x00FF)) ;
       move.l    D2,A0
       move.w    2(A0),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_298.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
; InstructionSize += 1;
       addq.l    #1,(A2)
DisassembleInstruction_153:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is EORI #data,SR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode  == (unsigned short int)(0x0A7C))   {
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #2684,D0
       bne.s     DisassembleInstruction_155
; InstructionSize = 2;
       move.l    #2,(A2)
; sprintf(Instruction, "EORI #$%X,SR", OpCode[1]);
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_299.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_155:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is EXG
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF100 )) == (unsigned short int)(0xC100))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61696,D0
       cmp.w     #49408,D0
       bne       DisassembleInstruction_163
; Rx = ((*OpCode >> 9) & (unsigned short int)(0x7)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,-16(A6)
; Ry = (*OpCode & (unsigned short int)(0x7)) ;
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,-14(A6)
; EXGOpMode = ((*OpCode >> 3) & (unsigned short int)(0x1F)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       and.w     #31,D0
       move.w    D0,-12(A6)
; if(EXGOpMode == (unsigned short int)(0x0008))   {
       move.w    -12(A6),D0
       cmp.w     #8,D0
       bne.s     DisassembleInstruction_159
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "EXG D%d,D%d", Rx, Ry) ;
       move.w    -14(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -16(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_300.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
       bra       DisassembleInstruction_163
DisassembleInstruction_159:
; }
; else if(EXGOpMode == (unsigned short int)(0x0009))  {
       move.w    -12(A6),D0
       cmp.w     #9,D0
       bne.s     DisassembleInstruction_161
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "EXG A%d,A%d", Rx, Ry) ;
       move.w    -14(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -16(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_301.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
       bra.s     DisassembleInstruction_163
DisassembleInstruction_161:
; }
; else if(EXGOpMode == (unsigned short int)(0x0011))  {
       move.w    -12(A6),D0
       cmp.w     #17,D0
       bne.s     DisassembleInstruction_163
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "EXG D%d,A%d", Rx, Ry) ;
       move.w    -14(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -16(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_302.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_163:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is EXT
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFE38)) == (unsigned short int)(0x4800))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65080,D0
       cmp.w     #18432,D0
       bne       DisassembleInstruction_165
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"EXT") ;
       pea       @m68kde~1_303.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; if((*OpCode & (unsigned short int)(0x00C0)) == (unsigned short int)(0x00C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #192,D0
       cmp.w     #192,D0
       bne.s     DisassembleInstruction_167
; strcatInstruction(".L ") ;
       pea       @m68kde~1_304.L
       jsr       _strcatInstruction
       addq.w    #4,A7
       bra.s     DisassembleInstruction_168
DisassembleInstruction_167:
; else
; strcatInstruction(".W ") ;
       pea       @m68kde~1_305.L
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_168:
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_165:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ILLEGAL $4afc
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x4AFC)) {
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #19196,D0
       bne.s     DisassembleInstruction_169
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"ILLEGAL ($4AFC)") ;
       pea       @m68kde~1_306.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
DisassembleInstruction_169:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is JMP
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x4EC0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #20160,D0
       bne.s     DisassembleInstruction_171
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"JMP ") ;
       pea       @m68kde~1_307.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_171:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is JSR
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x4E80))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #20096,D0
       bne.s     DisassembleInstruction_173
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"JSR ") ;
       pea       @m68kde~1_308.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_173:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is LEA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0)) == (unsigned short int)(0x41C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #16832,D0
       bne       DisassembleInstruction_175
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"LEA ") ;
       pea       @m68kde~1_309.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",A%d", ((*OpCode >> 9) & (unsigned short int)(0x7)));
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_310.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString);
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_175:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is LINK.W
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFF8)) == (unsigned short int)(0x4E50))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65528,D0
       cmp.w     #20048,D0
       bne       DisassembleInstruction_177
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"LINK ") ;
       pea       @m68kde~1_311.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; sprintf(TempString, "A%d,#%d", ((*OpCode) & (unsigned short int)(0x7)),OpCode[1]);
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_312.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
; InstructionSize = 2 ;
       move.l    #2,(A2)
; strcatInstruction(TempString);
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_177:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVE, MOVEA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xC000)) == (unsigned short int)(0x0000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #49152,D0
       bne       DisassembleInstruction_193
; {
; Size = (*OpCode & (unsigned short int)(0x3000)) >> 12 ;   // get 2 bit size in bits 13/12 into 1,0
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #12288,D0
       lsr.w     #8,D0
       lsr.w     #4,D0
       move.w    D0,-30(A6)
; OpMode = (*OpCode >> 3) & (unsigned short int)(0x0007);   // get 3 bit source mode operand
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       and.w     #7,D0
       move.w    D0,D3
; SourceReg = (*OpCode) & (unsigned short int)(0x0007);     // get 3 bit source register number
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,-10(A6)
; DataSize = 0 ;
       moveq     #0,D7
; // if source addressing mode is d16(a0) or d8(a0,d0)
; if((OpMode == (unsigned short int)(0x0005)) || (OpMode == (unsigned short int)(0x0006)))
       cmp.w     #5,D3
       beq.s     DisassembleInstruction_183
       cmp.w     #6,D3
       bne.s     DisassembleInstruction_181
DisassembleInstruction_183:
; DataSize = 1;  // source operands has 1 word after EA
       moveq     #1,D7
DisassembleInstruction_181:
; // if source addressing mode is a 16 or 32 bit address
; if((OpMode == (unsigned short int)(0x0007))) {
       cmp.w     #7,D3
       bne.s     DisassembleInstruction_187
; if(SourceReg == (unsigned short int)(0x0000))         // short address
       move.w    -10(A6),D0
       bne.s     DisassembleInstruction_186
; DataSize = 1 ;
       moveq     #1,D7
       bra.s     DisassembleInstruction_187
DisassembleInstruction_186:
; else
; DataSize = 2 ;
       moveq     #2,D7
DisassembleInstruction_187:
; }
; // if source addressing mode is # then figure out size
; if((OpMode == (unsigned short int)(0x0007)) && (SourceReg == (unsigned short int)(0x0004)))    {
       cmp.w     #7,D3
       bne.s     DisassembleInstruction_191
       move.w    -10(A6),D0
       cmp.w     #4,D0
       bne.s     DisassembleInstruction_191
; if((Size == (unsigned short int)(1)) || (Size == (unsigned short int)(3)))
       move.w    -30(A6),D0
       cmp.w     #1,D0
       beq.s     DisassembleInstruction_192
       move.w    -30(A6),D0
       cmp.w     #3,D0
       bne.s     DisassembleInstruction_190
DisassembleInstruction_192:
; DataSize = 1;
       moveq     #1,D7
       bra.s     DisassembleInstruction_191
DisassembleInstruction_190:
; else
; DataSize = 2 ;
       moveq     #2,D7
DisassembleInstruction_191:
; //printf("DataSize = %d",DataSize) ;
; }
; if(Size != 0)
       move.w    -30(A6),D0
       beq       DisassembleInstruction_193
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; if(Size == 1)
       move.w    -30(A6),D0
       cmp.w     #1,D0
       bne.s     DisassembleInstruction_195
; strcpyInstruction("MOVE.B ") ;
       pea       @m68kde~1_313.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_198
DisassembleInstruction_195:
; else if(Size == 2)
       move.w    -30(A6),D0
       cmp.w     #2,D0
       bne.s     DisassembleInstruction_197
; strcpyInstruction("MOVE.L ") ;
       pea       @m68kde~1_314.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_198
DisassembleInstruction_197:
; else
; strcpyInstruction("MOVE.W ") ;
       pea       @m68kde~1_315.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_198:
; Decode6BitEA(OpCode,0,0,1) ;
       pea       1
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_316.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; // tell next function how many words lie between opcode and destination, could be 1 or 2 e.g. with # addressing move.bwl #$data,<EA>
; // but subtract 1 to make the maths correct in the called function
; Decode6BitEA(OpCode,2,(DataSize),0) ;
       clr.l     -(A7)
       and.l     #65535,D7
       move.l    D7,-(A7)
       pea       2
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_193:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVE <EA>,CCR
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x44C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #17600,D0
       bne.s     DisassembleInstruction_199
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"MOVE ") ;
       pea       @m68kde~1_317.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",CCR") ;
       pea       @m68kde~1_318.L
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_199:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVE SR,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x40C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #16576,D0
       bne.s     DisassembleInstruction_201
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"MOVE SR,") ;
       pea       @m68kde~1_319.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_201:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVE <EA>,SR
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x46C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #18112,D0
       bne.s     DisassembleInstruction_203
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"MOVE ") ;
       pea       @m68kde~1_320.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",SR") ;
       pea       @m68kde~1_321.L
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_203:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVE USP,An
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFF0)) == (unsigned short int)(0x4E60))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65520,D0
       cmp.w     #20064,D0
       bne       DisassembleInstruction_208
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; Register = (*OpCode & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,-22(A6)
; if((*OpCode & (unsigned short int)(0x0008)) == (unsigned short int)(0x0008))        // transfer sp to address regier
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #8,D0
       cmp.w     #8,D0
       bne.s     DisassembleInstruction_207
; sprintf(Instruction, "MOVE USP,A%d", Register);
       move.w    -22(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_322.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
       bra.s     DisassembleInstruction_208
DisassembleInstruction_207:
; else
; sprintf(Instruction, "MOVE A%d,USP", Register);
       move.w    -22(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_323.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_208:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVEM
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFB80)) == (unsigned short int)(0x4880))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #64384,D0
       cmp.w     #18560,D0
       bne       DisassembleInstruction_230
; {
; OpMode = (*OpCode >> 3) & (unsigned short int)(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       and.w     #7,D0
       move.w    D0,D3
; if( (OpMode != (unsigned short int)(0x0)) &&
       tst.w     D3
       beq       DisassembleInstruction_230
       cmp.w     #1,D3
       beq       DisassembleInstruction_230
       tst.w     D3
       beq       DisassembleInstruction_230
; (OpMode != (unsigned short int)(0x1)) &&
; (OpMode != (unsigned short int)(0x0)))
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpy(Instruction,"MOVEM") ;
       pea       @m68kde~1_324.L
       pea       _Instruction.L
       jsr       _strcpy
       addq.w    #8,A7
; InstructionSize ++ ;
       addq.l    #1,(A2)
; if((*OpCode & (unsigned short int)(0x0040)) == (unsigned short int)(0x0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #64,D0
       bne.s     DisassembleInstruction_213
; strcatInstruction(".W ") ;
       pea       @m68kde~1_325.L
       jsr       _strcatInstruction
       addq.w    #4,A7
       bra.s     DisassembleInstruction_214
DisassembleInstruction_213:
; else
; strcatInstruction(".L ") ;
       pea       @m68kde~1_326.L
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_214:
; // movem  reg,-(An) if bit 10 = 0
; if((*OpCode & (unsigned short int)(0x0400))  == (unsigned short int)(0x0000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #1024,D0
       bne       DisassembleInstruction_215
; {
; Mask = 0x8000 ;                     // bit 15 = 1
       move.w    #32768,-2(A6)
; DoneSlash = 0 ;
       clr.w     D6
; for(i = 0; i < 16; i ++)    {
       clr.l     D4
DisassembleInstruction_217:
       cmp.l     #16,D4
       bge       DisassembleInstruction_219
; printf("") ;    // fixes bug otherwise the address registers doen't get printed (don't know why), something to do with sprintf I guess
       pea       @m68kde~1_327.L
       jsr       _printf
       addq.w    #4,A7
; if((OpCode[1] & Mask) == Mask)    {
       move.l    D2,A0
       move.w    2(A0),D0
       and.w     -2(A6),D0
       cmp.w     -2(A6),D0
       bne       DisassembleInstruction_220
; if(i < 8 )  {
       cmp.l     #8,D4
       bge.s     DisassembleInstruction_222
; if(DoneSlash == 0)  {
       tst.w     D6
       bne.s     DisassembleInstruction_224
; sprintf(TempString, "D%d", i) ;
       move.l    D4,-(A7)
       pea       @m68kde~1_328.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; DoneSlash = 1;
       moveq     #1,D6
       bra.s     DisassembleInstruction_225
DisassembleInstruction_224:
; }
; else
; sprintf(TempString, "/D%d", i) ;
       move.l    D4,-(A7)
       pea       @m68kde~1_329.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_225:
       bra       DisassembleInstruction_227
DisassembleInstruction_222:
; }
; else   {
; if(DoneSlash == 0)  {
       tst.w     D6
       bne.s     DisassembleInstruction_226
; sprintf(TempString, "A%d", i-8) ;
       move.l    D4,D1
       subq.l    #8,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_330.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; DoneSlash = 1;
       moveq     #1,D6
       bra.s     DisassembleInstruction_227
DisassembleInstruction_226:
; }
; else
; sprintf(TempString, "/A%d", i-8) ;
       move.l    D4,D1
       subq.l    #8,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_331.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_227:
; }
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_220:
; }
; Mask = Mask >> 1 ;
       move.w    -2(A6),D0
       asr.w     #1,D0
       move.w    D0,-2(A6)
       addq.l    #1,D4
       bra       DisassembleInstruction_217
DisassembleInstruction_219:
; }
; strcatInstruction(",") ;
       pea       @m68kde~1_332.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
       bra       DisassembleInstruction_230
DisassembleInstruction_215:
; }
; //movem  (An)+,reg
; else    {
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; strcatInstruction(",") ;
       pea       @m68kde~1_333.L
       jsr       _strcatInstruction
       addq.w    #4,A7
; Mask = 0x0001 ;                     // bit 0 = 1
       move.w    #1,-2(A6)
; DoneSlash = 0 ;
       clr.w     D6
; for(i = 0; i < 16 ; i ++)    {
       clr.l     D4
DisassembleInstruction_228:
       cmp.l     #16,D4
       bge       DisassembleInstruction_230
; if((OpCode[1] & Mask) == Mask)    {
       move.l    D2,A0
       move.w    2(A0),D0
       and.w     -2(A6),D0
       cmp.w     -2(A6),D0
       bne       DisassembleInstruction_231
; if(i < 8)   {       // data registers in bits 7-0
       cmp.l     #8,D4
       bge.s     DisassembleInstruction_233
; if(DoneSlash == 0)  {
       tst.w     D6
       bne.s     DisassembleInstruction_235
; sprintf(TempString, "D%d", i) ;
       move.l    D4,-(A7)
       pea       @m68kde~1_334.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; DoneSlash = 1;
       moveq     #1,D6
       bra.s     DisassembleInstruction_236
DisassembleInstruction_235:
; }
; else
; sprintf(TempString, "/D%d", i) ;
       move.l    D4,-(A7)
       pea       @m68kde~1_335.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_236:
       bra       DisassembleInstruction_238
DisassembleInstruction_233:
; }
; else    {
; if(DoneSlash == 0)  {
       tst.w     D6
       bne.s     DisassembleInstruction_237
; sprintf(TempString, "A%d", i-8) ;
       move.l    D4,D1
       subq.l    #8,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_336.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; DoneSlash = 1;
       moveq     #1,D6
       bra.s     DisassembleInstruction_238
DisassembleInstruction_237:
; }
; else
; sprintf(TempString, "/A%d", i-8) ;
       move.l    D4,D1
       subq.l    #8,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_337.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_238:
; }
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_231:
; }
; Mask = Mask << 1 ;
       move.w    -2(A6),D0
       asl.w     #1,D0
       move.w    D0,-2(A6)
       addq.l    #1,D4
       bra       DisassembleInstruction_228
DisassembleInstruction_230:
; }
; }
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVEP
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF038)) == (unsigned short int)(0x0008))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61496,D0
       cmp.w     #8,D0
       bne       DisassembleInstruction_247
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; DataRegister = (*OpCode >> 9) & (unsigned short int)(0x0007);
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,D5
; AddressRegister = (*OpCode & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,-8(A6)
; OpMode = (*OpCode >> 6) & (unsigned short int)(0x0007)  ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #7,D0
       move.w    D0,D3
; InstructionSize++ ;
       addq.l    #1,(A2)
; if(OpMode == (unsigned short int)(0x4)) // transfer word from memory to register
       cmp.w     #4,D3
       bne.s     DisassembleInstruction_241
; sprintf(Instruction, "MOVEP.W $%X(A%d),D%d", OpCode[1], AddressRegister, DataRegister) ;
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.w    -8(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_338.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #20,A7
       bra       DisassembleInstruction_247
DisassembleInstruction_241:
; else if(OpMode == (unsigned short int)(0x5)) // transfer long from memory to register
       cmp.w     #5,D3
       bne.s     DisassembleInstruction_243
; sprintf(Instruction, "MOVEP.L $%X(A%d),D%d", OpCode[1], AddressRegister, DataRegister) ;
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.w    -8(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_339.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #20,A7
       bra       DisassembleInstruction_247
DisassembleInstruction_243:
; else if(OpMode == (unsigned short int)(0x6)) // transfer long from register to memory
       cmp.w     #6,D3
       bne.s     DisassembleInstruction_245
; sprintf(Instruction, "MOVEP.W D%d,$%X(A%d)", DataRegister, OpCode[1], AddressRegister ) ;
       move.w    -8(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       pea       @m68kde~1_340.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #20,A7
       bra.s     DisassembleInstruction_247
DisassembleInstruction_245:
; else if(OpMode == (unsigned short int)(0x7)) // transfer long from register to memory
       cmp.w     #7,D3
       bne.s     DisassembleInstruction_247
; sprintf(Instruction, "MOVEP.L D%d,$%X(A%d)", DataRegister, OpCode[1], AddressRegister ) ;
       move.w    -8(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       and.l     #65535,D5
       move.l    D5,-(A7)
       pea       @m68kde~1_341.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #20,A7
DisassembleInstruction_247:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MOVEQ
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF100)) == (unsigned short int)(0x7000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61696,D0
       cmp.w     #28672,D0
       bne       DisassembleInstruction_249
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; DataRegister = (*OpCode >> 9) & (unsigned short int)(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,D5
; sprintf(Instruction, "MOVEQ #$%X,D%d", (*OpCode & (unsigned short int)(0x00FF)), DataRegister) ;
       and.l     #65535,D5
       move.l    D5,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_342.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_249:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MULS.W
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0)) == (unsigned short int)(0xC1C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #49600,D0
       bne       DisassembleInstruction_251
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; DataRegister = (*OpCode >> 9) & (unsigned short int)(0x0007);
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,D5
; strcpyInstruction("MULS ");
       pea       @m68kde~1_343.L
       jsr       (A3)
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",D%d", DataRegister) ;
       and.l     #65535,D5
       move.l    D5,-(A7)
       pea       @m68kde~1_344.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString);
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_251:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is MULU.W
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1C0)) == (unsigned short int)(0xC0C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61888,D0
       cmp.w     #49344,D0
       bne       DisassembleInstruction_253
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; DataRegister = (*OpCode >> 9) & (unsigned short int)(0x0007);
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,D5
; strcpyInstruction("MULU ");
       pea       @m68kde~1_345.L
       jsr       (A3)
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",D%d", DataRegister) ;
       and.l     #65535,D5
       move.l    D5,-(A7)
       pea       @m68kde~1_346.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString);
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_253:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is NBCD <EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x4800))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #18432,D0
       bne.s     DisassembleInstruction_255
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("NBCD ");
       pea       @m68kde~1_347.L
       jsr       (A3)
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_255:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is NEG <EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFF00)) == (unsigned short int)(0x4400))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #17408,D0
       bne       DisassembleInstruction_259
; {
; if(((*OpCode >> 6) & (unsigned short int)(0x0003)) != (unsigned short int)(0x0003))
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       cmp.w     #3,D0
       beq       DisassembleInstruction_259
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("NEG");
       pea       @m68kde~1_348.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_259:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is NEGX <EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFF00)) == (unsigned short int)(0x4000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #16384,D0
       bne       DisassembleInstruction_263
; {
; if(((*OpCode >> 6) & (unsigned short int)(0x0003)) != (unsigned short int)(0x0003))
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       cmp.w     #3,D0
       beq       DisassembleInstruction_263
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("NEGX");
       pea       @m68kde~1_349.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_263:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is NOP
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x4E71))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20081,D0
       bne.s     DisassembleInstruction_265
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("NOP");
       pea       @m68kde~1_350.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_265:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is NOT <EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFF00)) == (unsigned short int)(0x4600))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #17920,D0
       bne       DisassembleInstruction_269
; {
; if(((*OpCode >> 6) & (unsigned short int)(0x0003)) != (unsigned short int)(0x0003))
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       cmp.w     #3,D0
       beq       DisassembleInstruction_269
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("NOT");
       pea       @m68kde~1_351.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_269:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is OR <EA>,Dn or OR Dn,<EA>
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000)) == (unsigned short int)(0x8000))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #32768,D0
       bne       DisassembleInstruction_273
; {
; OpMode = (*OpCode >> 6) & (unsigned short int)(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #7,D0
       move.w    D0,D3
; if( (OpMode <= (unsigned short int)(0x0002)) ||
       cmp.w     #2,D3
       bls.s     DisassembleInstruction_275
       cmp.w     #4,D3
       blo.s     DisassembleInstruction_273
       cmp.w     #6,D3
       bhi.s     DisassembleInstruction_273
DisassembleInstruction_275:
; ((OpMode >= (unsigned short int)(0x0004)) && (OpMode <= (unsigned short int)(0x0006))))
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("OR") ;
       pea       @m68kde~1_352.L
       jsr       (A3)
       addq.w    #4,A7
; Decode3BitOperandMode(OpCode) ;
       move.l    D2,-(A7)
       jsr       _Decode3BitOperandMode
       addq.w    #4,A7
DisassembleInstruction_273:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ORI to CCR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x003C))   {
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #60,D0
       bne.s     DisassembleInstruction_276
; sprintf(Instruction, "ORI #$%2X,CCR", OpCode[1] & (unsigned short int)(0x00FF)) ;
       move.l    D2,A0
       move.w    2(A0),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_353.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
; InstructionSize = 2;
       move.l    #2,(A2)
DisassembleInstruction_276:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is ORI #data,SR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode  == (unsigned short int)(0x007c))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #124,D0
       bne.s     DisassembleInstruction_278
; {
; InstructionSize = 2;
       move.l    #2,(A2)
; sprintf(Instruction, "ORI  #$%X,SR", OpCode[1]);
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_354.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_278:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is PEA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0)) == (unsigned short int)(0x4840))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #18496,D0
       bne.s     DisassembleInstruction_280
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("PEA ");
       pea       @m68kde~1_355.L
       jsr       (A3)
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_280:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is reset
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode  == (unsigned short int)(0x4E70))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20080,D0
       bne.s     DisassembleInstruction_282
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "RESET");
       pea       @m68kde~1_356.L
       pea       _Instruction.L
       jsr       (A5)
       addq.w    #8,A7
DisassembleInstruction_282:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is RTE
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode  == (unsigned short int)(0x4E73))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20083,D0
       bne.s     DisassembleInstruction_284
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "RTE");
       pea       @m68kde~1_357.L
       pea       _Instruction.L
       jsr       (A5)
       addq.w    #8,A7
DisassembleInstruction_284:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is RTR
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x4E77))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20087,D0
       bne.s     DisassembleInstruction_286
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("RTR");
       pea       @m68kde~1_358.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_286:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is RTS
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x4E75))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20085,D0
       bne.s     DisassembleInstruction_288
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("RTS");
       pea       @m68kde~1_359.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_288:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is STOP
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode  == (unsigned short int)(0x4E72))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20082,D0
       bne.s     DisassembleInstruction_290
; {
; InstructionSize = 2;
       move.l    #2,(A2)
; sprintf(Instruction, "STOP #$%X", OpCode[1]);
       move.l    D2,A0
       move.w    2(A0),D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_360.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_290:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is SBCD
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF1F0 )) == (unsigned short int)(0x8100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61936,D0
       cmp.w     #33024,D0
       bne       DisassembleInstruction_295
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; DestBits = (*OpCode >> 9) & (unsigned short int )(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       asr.w     #1,D0
       and.w     #7,D0
       move.w    D0,-32(A6)
; SourceBits = (*OpCode & (unsigned short int )(0x0007));
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,-34(A6)
; Mode = (*OpCode >> 3) & (unsigned short int )(0x0001) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       ext.l     D0
       and.l     #1,D0
       move.l    D0,-28(A6)
; if(Mode == 0)
       move.l    -28(A6),D0
       bne.s     DisassembleInstruction_294
; sprintf(Instruction, "SBCD D%d,D%d", SourceBits, DestBits) ;
       move.w    -32(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -34(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_361.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
       bra.s     DisassembleInstruction_295
DisassembleInstruction_294:
; else
; sprintf(Instruction, "SBCD -(A%d),-(A%d)", SourceBits, DestBits) ;
       move.w    -32(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       move.w    -34(A6),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_362.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_295:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is Scc
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF0C0 )) == (unsigned short int)(0x50C0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61632,D0
       cmp.w     #20672,D0
       bne       DisassembleInstruction_298
; {
; EAMode = (*OpCode >> 3) & (unsigned short int)(0x0007) ;    // mode cannot be 1 for Scc as it it used by DBcc instruction as a differentiator
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #3,D0
       and.w     #7,D0
       move.w    D0,-20(A6)
; if(EAMode != (unsigned short int)(0x0001))
       move.w    -20(A6),D0
       cmp.w     #1,D0
       beq       DisassembleInstruction_298
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; Condition = ((*OpCode >> 8) & (unsigned short int)(0xF)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #8,D0
       and.w     #15,D0
       move.b    D0,-23(A6)
; strcpyInstruction("S") ;
       pea       @m68kde~1_363.L
       jsr       (A3)
       addq.w    #4,A7
; DecodeBranchCondition(Condition) ;
       move.b    -23(A6),D1
       and.w     #255,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _DecodeBranchCondition
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0);
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_298:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is SUB or SUBA
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF000 )) == (unsigned short int)(0x9000))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61440,D0
       cmp.w     #36864,D0
       bne       DisassembleInstruction_303
; OpMode = ((*OpCode >> 6) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #7,D0
       move.w    D0,D3
; InstructionSize = 1;
       move.l    #1,(A2)
; if((OpMode == (unsigned short int)(0x0003)) || (OpMode == (unsigned short int)(0x0007)))      // if destination is an address register then use ADDA otherwise use ADD
       cmp.w     #3,D3
       beq.s     DisassembleInstruction_304
       cmp.w     #7,D3
       bne       DisassembleInstruction_302
DisassembleInstruction_304:
; {
; if(OpMode == (unsigned short int)(0x0003))
       cmp.w     #3,D3
       bne.s     DisassembleInstruction_305
; strcpyInstruction("SUBA.W ") ;
       pea       @m68kde~1_364.L
       jsr       (A3)
       addq.w    #4,A7
       bra.s     DisassembleInstruction_306
DisassembleInstruction_305:
; else
; strcpyInstruction("SUBA.L ") ;
       pea       @m68kde~1_365.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_306:
; Decode6BitEA(OpCode,0,0,0)  ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
; sprintf(TempString, ",A%X", (*OpCode >> 9) & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_366.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
       bra.s     DisassembleInstruction_303
DisassembleInstruction_302:
; }
; else {
; strcpyInstruction("SUB") ;
       pea       @m68kde~1_367.L
       jsr       (A3)
       addq.w    #4,A7
; Decode3BitOperandMode(OpCode) ;
       move.l    D2,-(A7)
       jsr       _Decode3BitOperandMode
       addq.w    #4,A7
DisassembleInstruction_303:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is SUBQ
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF100 )) == (unsigned short int)(0x5100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61696,D0
       cmp.w     #20736,D0
       bne       DisassembleInstruction_309
; {
; OpMode = (*OpCode >> 6) & (unsigned short int)(0x0003) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       move.w    D0,D3
; if(OpMode <= (unsigned short int)(0x0002))
       cmp.w     #2,D3
       bhi       DisassembleInstruction_309
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("SUBQ") ;
       pea       @m68kde~1_368.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode);                                  // add .b, .w, .l size indicator to instruction string
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; sprintf(TempString, "#%1X,", ((*OpCode >> 9) & (unsigned short int)(0x0007)));    // print 3 bit #data in positions 11,10,9 in opcode
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_369.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #12,A7
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;                                           // decode EA
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_309:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is SUBX
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xF130 )) == (unsigned short int)(0x9100))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #61744,D0
       cmp.w     #37120,D0
       bne       DisassembleInstruction_313
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; OpMode = ((*OpCode >> 6) & (unsigned short int)(0x0003)) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       move.w    D0,D3
; if(OpMode != (unsigned short int)(0x0003)) // if size = 11 then it's SUBA not SUBX
       cmp.w     #3,D3
       beq       DisassembleInstruction_313
; {
; strcpyInstruction("SUBX") ;
       pea       @m68kde~1_370.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode);                                  // add .b, .w, .l size indicator to instruction string
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; if((*OpCode & (unsigned short int)(0x0008)) == (unsigned short int)(0))    // if bit 3 of opcode is 0 indicates data registers are used as source and destination
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #8,D0
       bne       DisassembleInstruction_315
; sprintf(TempString, "D%1X,D%1X", (*OpCode & 0x0007), ((*OpCode >> 9) & 0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_371.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
       bra       DisassembleInstruction_316
DisassembleInstruction_315:
; else        // -(ax),-(ay) mode used
; sprintf(TempString, "-(A%1X),-(A%1X)", (*OpCode & 0x0007), ((*OpCode >> 9) & 0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       asr.w     #8,D1
       asr.w     #1,D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @m68kde~1_372.L
       move.l    A4,-(A7)
       jsr       (A5)
       add.w     #16,A7
DisassembleInstruction_316:
; strcatInstruction(TempString) ;
       move.l    A4,-(A7)
       jsr       _strcatInstruction
       addq.w    #4,A7
DisassembleInstruction_313:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is SWAP
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFF8 )) == (unsigned short int)(0x4840))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65528,D0
       cmp.w     #18496,D0
       bne.s     DisassembleInstruction_317
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; DataRegister = *OpCode & (unsigned short int)(0x0007) ;
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #7,D0
       move.w    D0,D5
; sprintf(Instruction, "SWAP D%d", DataRegister) ;
       and.l     #65535,D5
       move.l    D5,-(A7)
       pea       @m68kde~1_373.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_317:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is TAS
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFC0 )) == (unsigned short int)(0x4AC0))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65472,D0
       cmp.w     #19136,D0
       bne.s     DisassembleInstruction_321
; {
; if(*OpCode != (unsigned short int)(0x4AFC))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #19196,D0
       beq.s     DisassembleInstruction_321
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("TAS ") ;
       pea       @m68kde~1_374.L
       jsr       (A3)
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_321:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is TRAP
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFF0 )) == (unsigned short int)(0x4E40))   {
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65520,D0
       cmp.w     #20032,D0
       bne.s     DisassembleInstruction_323
; sprintf(Instruction, "TRAP #%d", *OpCode & (unsigned short int)(0x000F)) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #15,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_375.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_323:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is TRAPV
; /////////////////////////////////////////////////////////////////////////////////
; if(*OpCode == (unsigned short int)(0x4E76))
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #20086,D0
       bne.s     DisassembleInstruction_325
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("TRAPV") ;
       pea       @m68kde~1_376.L
       jsr       (A3)
       addq.w    #4,A7
DisassembleInstruction_325:
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is TST
; /////////////////////////////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFF00 )) == (unsigned short int)(0x4A00))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65280,D0
       cmp.w     #18944,D0
       bne       DisassembleInstruction_329
; {
; Size = (*OpCode >> 6) & (unsigned short int)(0x0003) ;
       move.l    D2,A0
       move.w    (A0),D0
       asr.w     #6,D0
       and.w     #3,D0
       move.w    D0,-30(A6)
; if((*OpCode != (unsigned short int)(0x4AFC)) && (Size != (unsigned short int)(0x0003)))       { // test for size to eliminate TAS instruction which shares similar opcode
       move.l    D2,A0
       move.w    (A0),D0
       cmp.w     #19196,D0
       beq       DisassembleInstruction_329
       move.w    -30(A6),D0
       cmp.w     #3,D0
       beq       DisassembleInstruction_329
; InstructionSize = 1;
       move.l    #1,(A2)
; strcpyInstruction("TST") ;
       pea       @m68kde~1_377.L
       jsr       (A3)
       addq.w    #4,A7
; Decode2BitOperandSize(*OpCode) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       jsr       _Decode2BitOperandSize
       addq.w    #4,A7
; Decode6BitEA(OpCode,0,0,0) ;
       clr.l     -(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       move.l    D2,-(A7)
       jsr       _Decode6BitEA
       add.w     #16,A7
DisassembleInstruction_329:
; }
; }
; /////////////////////////////////////////////////////////////////////////////////
; // if instruction is UNLK
; //////////////////////////////////////////////////////////
; if((*OpCode & (unsigned short int)(0xFFF8 )) == (unsigned short int)(0x4E58))
       move.l    D2,A0
       move.w    (A0),D0
       and.w     #65528,D0
       cmp.w     #20056,D0
       bne.s     DisassembleInstruction_331
; {
; InstructionSize = 1;
       move.l    #1,(A2)
; sprintf(Instruction, "UNLK A%d", *OpCode & (unsigned short int)(0x0007)) ;
       move.l    D2,A0
       move.w    (A0),D1
       and.w     #7,D1
       and.l     #65535,D1
       move.l    D1,-(A7)
       pea       @m68kde~1_378.L
       pea       _Instruction.L
       jsr       (A5)
       add.w     #12,A7
DisassembleInstruction_331:
; }
; FormatInstruction() ;
       jsr       _FormatInstruction
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
       section   const
@m68kde~1_1:
       dc.b      13,10,0
@m68kde~1_2:
       dc.b      13,83,119,105,116,99,104,101,115,32,83,87,91
       dc.b      55,45,48,93,32,61,32,0
@m68kde~1_3:
       dc.b      48,0
@m68kde~1_4:
       dc.b      49,0
@m68kde~1_5:
       dc.b      13,10,69,110,116,101,114,32,83,116,97,114,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_6:
       dc.b      13,10,60,69,83,67,62,32,61,32,65,98,111,114
       dc.b      116,44,32,83,80,65,67,69,32,116,111,32,67,111
       dc.b      110,116,105,110,117,101,0
@m68kde~1_7:
       dc.b      13,10,37,48,56,88,32,32,37,48,52,88,32,32,32
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,37,115,0
@m68kde~1_8:
       dc.b      13,10,37,48,56,88,32,32,37,48,52,88,32,37,48
       dc.b      52,88,32,32,32,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,37,115,0
@m68kde~1_9:
       dc.b      13,10,37,48,56,88,32,32,37,48,52,88,32,37,48
       dc.b      52,88,32,37,48,52,88,32,32,32,32,32,32,32,32
       dc.b      32,32,32,32,32,32,37,115,0
@m68kde~1_10:
       dc.b      13,10,37,48,56,88,32,32,37,48,52,88,32,37,48
       dc.b      52,88,32,37,48,52,88,32,37,48,52,88,32,32,32
       dc.b      32,32,32,32,32,32,37,115,0
@m68kde~1_11:
       dc.b      13,10,37,48,56,88,32,32,37,48,52,88,32,37,48
       dc.b      52,88,32,37,48,52,88,32,37,48,52,88,32,37,48
       dc.b      52,88,32,32,32,32,37,115,0
@m68kde~1_12:
       dc.b      13,10,68,117,109,112,32,77,101,109,111,114,121
       dc.b      32,66,108,111,99,107,58,32,60,69,83,67,62,32
       dc.b      116,111,32,65,98,111,114,116,44,32,60,83,80
       dc.b      65,67,69,62,32,116,111,32,67,111,110,116,105
       dc.b      110,117,101,0
@m68kde~1_13:
       dc.b      13,10,69,110,116,101,114,32,83,116,97,114,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_14:
       dc.b      13,10,37,48,56,120,32,0
@m68kde~1_15:
       dc.b      37,48,50,88,0
@m68kde~1_16:
       dc.b      32,32,0
@m68kde~1_17:
       dc.b      13,10,0
@m68kde~1_18:
       dc.b      13,10,70,105,108,108,32,77,101,109,111,114,121
       dc.b      32,66,108,111,99,107,0
@m68kde~1_19:
       dc.b      13,10,69,110,116,101,114,32,83,116,97,114,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_20:
       dc.b      13,10,69,110,116,101,114,32,69,110,100,32,65
       dc.b      100,100,114,101,115,115,58,32,0
@m68kde~1_21:
       dc.b      13,10,69,110,116,101,114,32,70,105,108,108,32
       dc.b      68,97,116,97,58,32,0
@m68kde~1_22:
       dc.b      13,10,70,105,108,108,105,110,103,32,65,100,100
       dc.b      114,101,115,115,101,115,32,91,36,37,48,56,88
       dc.b      32,45,32,36,37,48,56,88,93,32,119,105,116,104
       dc.b      32,36,37,48,50,88,0
@m68kde~1_23:
       dc.b      13,10,85,115,101,32,72,121,112,101,114,84,101
       dc.b      114,109,105,110,97,108,32,116,111,32,83,101
       dc.b      110,100,32,84,101,120,116,32,70,105,108,101
       dc.b      32,40,46,104,101,120,41,13,10,0
@m68kde~1_24:
       dc.b      13,10,76,111,97,100,32,70,97,105,108,101,100
       dc.b      32,97,116,32,65,100,100,114,101,115,115,32,61
       dc.b      32,91,36,37,48,56,88,93,13,10,0
@m68kde~1_25:
       dc.b      13,10,83,117,99,99,101,115,115,58,32,68,111
       dc.b      119,110,108,111,97,100,101,100,32,37,100,32
       dc.b      98,121,116,101,115,13,10,0
@m68kde~1_26:
       dc.b      13,10,69,120,97,109,105,110,101,32,97,110,100
       dc.b      32,67,104,97,110,103,101,32,77,101,109,111,114
       dc.b      121,0
@m68kde~1_27:
       dc.b      13,10,60,69,83,67,62,32,116,111,32,83,116,111
       dc.b      112,44,32,60,83,80,65,67,69,62,32,116,111,32
       dc.b      65,100,118,97,110,99,101,44,32,39,45,39,32,116
       dc.b      111,32,71,111,32,66,97,99,107,44,32,60,68,65
       dc.b      84,65,62,32,116,111,32,99,104,97,110,103,101
       dc.b      0
@m68kde~1_28:
       dc.b      13,10,69,110,116,101,114,32,65,100,100,114,101
       dc.b      115,115,58,32,0
@m68kde~1_29:
       dc.b      13,10,91,37,48,56,120,93,32,58,32,37,48,50,120
       dc.b      32,32,0
@m68kde~1_30:
       dc.b      13,10,87,97,114,110,105,110,103,32,67,104,97
       dc.b      110,103,101,32,70,97,105,108,101,100,58,32,87
       dc.b      114,111,116,101,32,91,37,48,50,120,93,44,32
       dc.b      82,101,97,100,32,91,37,48,50,120,93,0
@m68kde~1_31:
       dc.b      13,10,76,111,97,100,105,110,103,32,80,114,111
       dc.b      103,114,97,109,32,70,114,111,109,32,83,80,73
       dc.b      32,70,108,97,115,104,46,46,46,46,0
@m68kde~1_32:
       dc.b      36,37,48,56,88,32,32,0
@m68kde~1_33:
       dc.b      37,48,50,88,0
@m68kde~1_34:
       dc.b      32,0
@m68kde~1_35:
       dc.b      32,32,0
@m68kde~1_36:
       dc.b      46,0
@m68kde~1_37:
       dc.b      37,99,0
@m68kde~1_38:
       dc.b      0
@m68kde~1_39:
       dc.b      13,10,13,10,32,68,48,32,61,32,36,37,48,56,88
       dc.b      32,32,65,48,32,61,32,36,37,48,56,88,0
@m68kde~1_40:
       dc.b      13,10,32,68,49,32,61,32,36,37,48,56,88,32,32
       dc.b      65,49,32,61,32,36,37,48,56,88,0
@m68kde~1_41:
       dc.b      13,10,32,68,50,32,61,32,36,37,48,56,88,32,32
       dc.b      65,50,32,61,32,36,37,48,56,88,0
@m68kde~1_42:
       dc.b      13,10,32,68,51,32,61,32,36,37,48,56,88,32,32
       dc.b      65,51,32,61,32,36,37,48,56,88,0
@m68kde~1_43:
       dc.b      13,10,32,68,52,32,61,32,36,37,48,56,88,32,32
       dc.b      65,52,32,61,32,36,37,48,56,88,0
@m68kde~1_44:
       dc.b      13,10,32,68,53,32,61,32,36,37,48,56,88,32,32
       dc.b      65,53,32,61,32,36,37,48,56,88,0
@m68kde~1_45:
       dc.b      13,10,32,68,54,32,61,32,36,37,48,56,88,32,32
       dc.b      65,54,32,61,32,36,37,48,56,88,0
@m68kde~1_46:
       dc.b      13,10,32,68,55,32,61,32,36,37,48,56,88,32,32
       dc.b      65,55,32,61,32,36,37,48,56,88,0
@m68kde~1_47:
       dc.b      13,10,13,10,85,83,80,32,61,32,36,37,48,56,88
       dc.b      32,32,40,65,55,41,32,85,115,101,114,32,83,80
       dc.b      0
@m68kde~1_48:
       dc.b      13,10,83,83,80,32,61,32,36,37,48,56,88,32,32
       dc.b      40,65,55,41,32,83,117,112,101,114,118,105,115
       dc.b      111,114,32,83,80,0
@m68kde~1_49:
       dc.b      13,10,32,83,82,32,61,32,36,37,48,52,88,32,32
       dc.b      32,0
@m68kde~1_50:
       dc.b      32,32,32,91,0
@m68kde~1_51:
       dc.b      13,10,32,80,67,32,61,32,36,37,48,56,88,32,32
       dc.b      0
@m68kde~1_52:
       dc.b      37,115,0
@m68kde~1_53:
       dc.b      91,66,82,69,65,75,80,79,73,78,84,93,0
@m68kde~1_54:
       dc.b      13,10,0
@m68kde~1_55:
       dc.b      13,10,87,80,37,100,32,61,32,37,115,0
@m68kde~1_56:
       dc.b      13,10,13,10,13,10,13,10,13,10,13,10,83,105,110
       dc.b      103,108,101,32,83,116,101,112,32,32,58,91,79
       dc.b      78,93,0
@m68kde~1_57:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      115,32,58,91,68,105,115,97,98,108,101,100,93
       dc.b      0
@m68kde~1_58:
       dc.b      13,10,80,114,101,115,115,32,60,83,80,65,67,69
       dc.b      62,32,116,111,32,69,120,101,99,117,116,101,32
       dc.b      78,101,120,116,32,73,110,115,116,114,117,99
       dc.b      116,105,111,110,0
@m68kde~1_59:
       dc.b      13,10,80,114,101,115,115,32,60,69,83,67,62,32
       dc.b      116,111,32,82,101,115,117,109,101,32,80,114
       dc.b      111,103,114,97,109,0
@m68kde~1_60:
       dc.b      13,10,73,108,108,101,103,97,108,32,68,97,116
       dc.b      97,32,82,101,103,105,115,116,101,114,32,58,32
       dc.b      85,115,101,32,68,48,45,68,55,46,46,46,46,46
       dc.b      13,10,0
@m68kde~1_61:
       dc.b      13,10,68,37,99,32,61,32,0
@m68kde~1_62:
       dc.b      13,10,73,108,108,101,103,97,108,32,65,100,100
       dc.b      114,101,115,115,32,82,101,103,105,115,116,101
       dc.b      114,32,58,32,85,115,101,32,65,48,45,65,55,46
       dc.b      46,46,46,46,13,10,0
@m68kde~1_63:
       dc.b      13,10,65,37,99,32,61,32,0
@m68kde~1_64:
       dc.b      13,10,85,115,101,114,32,83,80,32,61,32,0
@m68kde~1_65:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,101,103
       dc.b      105,115,116,101,114,46,46,46,46,0
@m68kde~1_66:
       dc.b      13,10,83,121,115,116,101,109,32,83,80,32,61
       dc.b      32,0
@m68kde~1_67:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,101,103
       dc.b      105,115,116,101,114,46,46,46,46,0
@m68kde~1_68:
       dc.b      13,10,80,67,32,61,32,0
@m68kde~1_69:
       dc.b      13,10,83,82,32,61,32,0
@m68kde~1_70:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,101,103
       dc.b      105,115,116,101,114,58,32,85,115,101,32,65,48
       dc.b      45,65,55,44,32,68,48,45,68,55,44,32,83,83,80
       dc.b      44,32,85,83,80,44,32,80,67,32,111,114,32,83
       dc.b      82,13,10,0
@m68kde~1_71:
       dc.b      13,10,13,10,78,117,109,32,32,32,32,32,65,100
       dc.b      100,114,101,115,115,32,32,32,32,32,32,73,110
       dc.b      115,116,114,117,99,116,105,111,110,0
@m68kde~1_72:
       dc.b      13,10,45,45,45,32,32,32,32,32,45,45,45,45,45
       dc.b      45,45,45,45,32,32,32,32,45,45,45,45,45,45,45
       dc.b      45,45,45,45,0
@m68kde~1_73:
       dc.b      13,10,78,111,32,66,114,101,97,107,80,111,105
       dc.b      110,116,115,32,83,101,116,0
@m68kde~1_74:
       dc.b      13,10,37,51,100,32,32,32,32,32,36,37,48,56,120
       dc.b      0
@m68kde~1_75:
       dc.b      32,32,32,32,37,115,0
@m68kde~1_76:
       dc.b      13,10,0
@m68kde~1_77:
       dc.b      13,10,78,117,109,32,32,32,32,32,65,100,100,114
       dc.b      101,115,115,0
@m68kde~1_78:
       dc.b      13,10,45,45,45,32,32,32,32,32,45,45,45,45,45
       dc.b      45,45,45,45,0
@m68kde~1_79:
       dc.b      13,10,78,111,32,87,97,116,99,104,80,111,105
       dc.b      110,116,115,32,83,101,116,0
@m68kde~1_80:
       dc.b      13,10,37,51,100,32,32,32,32,32,36,37,48,56,120
       dc.b      0
@m68kde~1_81:
       dc.b      13,10,0
@m68kde~1_82:
       dc.b      13,10,69,110,116,101,114,32,66,114,101,97,107
       dc.b      32,80,111,105,110,116,32,78,117,109,98,101,114
       dc.b      58,32,0
@m68kde~1_83:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,97,110
       dc.b      103,101,32,58,32,85,115,101,32,48,32,45,32,55
       dc.b      0
@m68kde~1_84:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,67,108,101,97,114,101,100,46,46,46,46,46
       dc.b      13,10,0
@m68kde~1_85:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,119,97,115,110,39,116,32,83,101,116,46,46
       dc.b      46,46,46,0
@m68kde~1_86:
       dc.b      13,10,69,110,116,101,114,32,87,97,116,99,104
       dc.b      32,80,111,105,110,116,32,78,117,109,98,101,114
       dc.b      58,32,0
@m68kde~1_87:
       dc.b      13,10,73,108,108,101,103,97,108,32,82,97,110
       dc.b      103,101,32,58,32,85,115,101,32,48,32,45,32,55
       dc.b      0
@m68kde~1_88:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,67,108,101,97,114,101,100,46,46,46,46,46
       dc.b      13,10,0
@m68kde~1_89:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,87,97,115,32,110,111,116,32,83,101,116,46
       dc.b      46,46,46,46,0
@m68kde~1_90:
       dc.b      13,10,78,111,32,70,82,69,69,32,66,114,101,97
       dc.b      107,32,80,111,105,110,116,115,46,46,46,46,46
       dc.b      0
@m68kde~1_91:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_92:
       dc.b      13,10,69,114,114,111,114,32,58,32,66,114,101
       dc.b      97,107,32,80,111,105,110,116,115,32,67,65,78
       dc.b      78,79,84,32,98,101,32,115,101,116,32,97,116
       dc.b      32,79,68,68,32,97,100,100,114,101,115,115,101
       dc.b      115,0
@m68kde~1_93:
       dc.b      13,10,69,114,114,111,114,32,58,32,66,114,101
       dc.b      97,107,32,80,111,105,110,116,115,32,67,65,78
       dc.b      78,79,84,32,98,101,32,115,101,116,32,102,111
       dc.b      114,32,82,79,77,32,105,110,32,82,97,110,103
       dc.b      101,32,58,32,91,36,48,45,36,48,48,48,48,55,70
       dc.b      70,70,93,0
@m68kde~1_94:
       dc.b      13,10,69,114,114,111,114,58,32,66,114,101,97
       dc.b      107,32,80,111,105,110,116,32,65,108,114,101
       dc.b      97,100,121,32,69,120,105,115,116,115,32,97,116
       dc.b      32,65,100,100,114,101,115,115,32,58,32,37,48
       dc.b      56,120,13,10,0
@m68kde~1_95:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      32,83,101,116,32,97,116,32,65,100,100,114,101
       dc.b      115,115,58,32,91,36,37,48,56,120,93,44,32,73
       dc.b      110,115,116,114,117,99,116,105,111,110,32,61
       dc.b      32,37,115,0
@m68kde~1_96:
       dc.b      13,10,0
@m68kde~1_97:
       dc.b      13,10,78,111,32,70,82,69,69,32,87,97,116,99
       dc.b      104,32,80,111,105,110,116,115,46,46,46,46,46
       dc.b      0
@m68kde~1_98:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,65,100,100,114,101,115,115,58,32,0
@m68kde~1_99:
       dc.b      13,10,69,114,114,111,114,58,32,87,97,116,99
       dc.b      104,32,80,111,105,110,116,32,65,108,114,101
       dc.b      97,100,121,32,83,101,116,32,97,116,32,65,100
       dc.b      100,114,101,115,115,32,58,32,37,48,56,120,13
       dc.b      10,0
@m68kde~1_100:
       dc.b      13,10,87,97,116,99,104,32,80,111,105,110,116
       dc.b      32,83,101,116,32,97,116,32,65,100,100,114,101
       dc.b      115,115,58,32,91,36,37,48,56,120,93,0
@m68kde~1_101:
       dc.b      13,10,0
@m68kde~1_102:
       dc.b      13,10,13,10,13,10,13,10,64,66,82,69,65,75,80
       dc.b      79,73,78,84,0
@m68kde~1_103:
       dc.b      13,10,83,105,110,103,108,101,32,83,116,101,112
       dc.b      32,58,32,91,79,78,93,0
@m68kde~1_104:
       dc.b      13,10,66,114,101,97,107,80,111,105,110,116,115
       dc.b      32,58,32,91,69,110,97,98,108,101,100,93,0
@m68kde~1_105:
       dc.b      13,10,80,114,101,115,115,32,60,83,80,65,67,69
       dc.b      62,32,116,111,32,69,120,101,99,117,116,101,32
       dc.b      78,101,120,116,32,73,110,115,116,114,117,99
       dc.b      116,105,111,110,0
@m68kde~1_106:
       dc.b      13,10,80,114,101,115,115,32,60,69,83,67,62,32
       dc.b      116,111,32,82,101,115,117,109,101,32,85,115
       dc.b      101,114,32,80,114,111,103,114,97,109,13,10,0
@m68kde~1_107:
       dc.b      13,10,85,110,107,110,111,119,110,32,67,111,109
       dc.b      109,97,110,100,46,46,46,46,46,13,10,0
@m68kde~1_108:
       dc.b      13,10,80,114,111,103,114,97,109,32,69,110,100
       dc.b      101,100,32,40,84,82,65,80,32,35,49,53,41,46
       dc.b      46,46,46,0
@m68kde~1_109:
       dc.b      13,10,75,105,108,108,32,65,108,108,32,66,114
       dc.b      101,97,107,32,80,111,105,110,116,115,46,46,46
       dc.b      40,121,47,110,41,63,0
@m68kde~1_110:
       dc.b      13,10,75,105,108,108,32,65,108,108,32,87,97
       dc.b      116,99,104,32,80,111,105,110,116,115,46,46,46
       dc.b      40,121,47,110,41,63,0
@m68kde~1_111:
       dc.b      13,10,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,45,45,45,45,45,45,45,45,45
       dc.b      45,45,45,45,45,45,0
@m68kde~1_112:
       dc.b      13,10,32,32,68,101,98,117,103,103,101,114,32
       dc.b      67,111,109,109,97,110,100,32,83,117,109,109
       dc.b      97,114,121,0
@m68kde~1_113:
       dc.b      13,10,32,32,46,40,114,101,103,41,32,32,32,32
       dc.b      32,32,32,45,32,67,104,97,110,103,101,32,82,101
       dc.b      103,105,115,116,101,114,115,58,32,101,46,103
       dc.b      32,65,48,45,65,55,44,68,48,45,68,55,44,80,67
       dc.b      44,83,83,80,44,85,83,80,44,83,82,0
@m68kde~1_114:
       dc.b      13,10,32,32,66,68,47,66,83,47,66,67,47,66,75
       dc.b      32,32,45,32,66,114,101,97,107,32,80,111,105
       dc.b      110,116,58,32,68,105,115,112,108,97,121,47,83
       dc.b      101,116,47,67,108,101,97,114,47,75,105,108,108
       dc.b      0
@m68kde~1_115:
       dc.b      13,10,32,32,67,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,67,111,112,121,32,80,114,111,103
       dc.b      114,97,109,32,102,114,111,109,32,70,108,97,115
       dc.b      104,32,116,111,32,77,97,105,110,32,77,101,109
       dc.b      111,114,121,0
@m68kde~1_116:
       dc.b      13,10,32,32,68,73,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,68,105,115,97,115,115,101,109,98
       dc.b      108,101,32,80,114,111,103,114,97,109,0
@m68kde~1_117:
       dc.b      13,10,32,32,68,85,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,68,117,109,112,32,77,101,109,111
       dc.b      114,121,32,67,111,110,116,101,110,116,115,32
       dc.b      116,111,32,83,99,114,101,101,110,0
@m68kde~1_118:
       dc.b      13,10,32,32,69,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,69,110,116,101,114,32,83,116,114
       dc.b      105,110,103,32,105,110,116,111,32,77,101,109
       dc.b      111,114,121,0
@m68kde~1_119:
       dc.b      13,10,32,32,70,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,70,105,108,108,32,77,101,109,111
       dc.b      114,121,32,119,105,116,104,32,68,97,116,97,0
@m68kde~1_120:
       dc.b      13,10,32,32,71,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,71,111,32,80,114,111,103,114,97
       dc.b      109,32,83,116,97,114,116,105,110,103,32,97,116
       dc.b      32,65,100,100,114,101,115,115,58,32,36,37,48
       dc.b      56,88,0
@m68kde~1_121:
       dc.b      13,10,32,32,76,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,76,111,97,100,32,80,114,111,103
       dc.b      114,97,109,32,40,46,72,69,88,32,102,105,108
       dc.b      101,41,32,102,114,111,109,32,76,97,112,116,111
       dc.b      112,0
@m68kde~1_122:
       dc.b      13,10,32,32,77,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,77,101,109,111,114,121,32,69,120
       dc.b      97,109,105,110,101,32,97,110,100,32,67,104,97
       dc.b      110,103,101,0
@m68kde~1_123:
       dc.b      13,10,32,32,80,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,80,114,111,103,114,97,109,32,70
       dc.b      108,97,115,104,32,77,101,109,111,114,121,32
       dc.b      119,105,116,104,32,85,115,101,114,32,80,114
       dc.b      111,103,114,97,109,0
@m68kde~1_124:
       dc.b      13,10,32,32,82,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,68,105,115,112,108,97,121,32,54
       dc.b      56,48,48,48,32,82,101,103,105,115,116,101,114
       dc.b      115,0
@m68kde~1_125:
       dc.b      13,10,32,32,83,32,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,84,111,103,103,108,101,32,79,78
       dc.b      47,79,70,70,32,83,105,110,103,108,101,32,83
       dc.b      116,101,112,32,77,111,100,101,0
@m68kde~1_126:
       dc.b      13,10,32,32,84,77,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,84,101,115,116,32,77,101,109,111
       dc.b      114,121,0
@m68kde~1_127:
       dc.b      13,10,32,32,84,83,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,84,101,115,116,32,83,119,105,116
       dc.b      99,104,101,115,58,32,83,87,55,45,48,0
@m68kde~1_128:
       dc.b      13,10,32,32,84,68,32,32,32,32,32,32,32,32,32
       dc.b      32,32,45,32,84,101,115,116,32,68,105,115,112
       dc.b      108,97,121,115,58,32,76,69,68,115,32,97,110
       dc.b      100,32,55,45,83,101,103,109,101,110,116,0
@m68kde~1_129:
       dc.b      13,10,32,32,87,68,47,87,83,47,87,67,47,87,75
       dc.b      32,32,45,32,87,97,116,99,104,32,80,111,105,110
       dc.b      116,58,32,68,105,115,112,108,97,121,47,83,101
       dc.b      116,47,67,108,101,97,114,47,75,105,108,108,0
@m68kde~1_130:
       dc.b      13,10,35,0
@m68kde~1_131:
       dc.b      13,10,80,114,111,103,114,97,109,32,82,117,110
       dc.b      110,105,110,103,46,46,46,46,46,0
@m68kde~1_132:
       dc.b      13,10,80,114,101,115,115,32,60,82,69,83,69,84
       dc.b      62,32,98,117,116,116,111,110,32,60,75,101,121
       dc.b      48,62,32,111,110,32,68,69,49,32,116,111,32,115
       dc.b      116,111,112,0
@m68kde~1_133:
       dc.b      13,10,69,114,114,111,114,58,32,80,114,101,115
       dc.b      115,32,39,71,39,32,102,105,114,115,116,32,116
       dc.b      111,32,115,116,97,114,116,32,112,114,111,103
       dc.b      114,97,109,0
@m68kde~1_134:
       dc.b      13,10,83,105,110,103,108,101,32,83,116,101,112
       dc.b      32,32,58,91,79,78,93,0
@m68kde~1_135:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      115,32,58,91,68,105,115,97,98,108,101,100,93
       dc.b      0
@m68kde~1_136:
       dc.b      13,10,80,114,101,115,115,32,39,71,39,32,116
       dc.b      111,32,84,114,97,99,101,32,80,114,111,103,114
       dc.b      97,109,32,102,114,111,109,32,97,100,100,114
       dc.b      101,115,115,32,36,37,88,46,46,46,46,46,0
@m68kde~1_137:
       dc.b      13,10,80,117,115,104,32,60,82,69,83,69,84,32
       dc.b      66,117,116,116,111,110,62,32,116,111,32,83,116
       dc.b      111,112,46,46,46,46,46,0
@m68kde~1_138:
       dc.b      13,10,83,105,110,103,108,101,32,83,116,101,112
       dc.b      32,58,32,91,79,70,70,93,0
@m68kde~1_139:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      115,32,58,91,69,110,97,98,108,101,100,93,0
@m68kde~1_140:
       dc.b      13,10,80,114,101,115,115,32,60,69,83,67,62,32
       dc.b      116,111,32,82,101,115,117,109,101,32,85,115
       dc.b      101,114,32,80,114,111,103,114,97,109,46,46,46
       dc.b      46,46,0
@m68kde~1_141:
       dc.b      13,10,83,105,110,103,108,101,32,83,116,101,112
       dc.b      32,32,58,91,79,70,70,93,0
@m68kde~1_142:
       dc.b      13,10,66,114,101,97,107,32,80,111,105,110,116
       dc.b      115,32,58,91,69,110,97,98,108,101,100,93,0
@m68kde~1_143:
       dc.b      13,10,80,114,111,103,114,97,109,32,82,117,110
       dc.b      110,105,110,103,46,46,46,46,46,0
@m68kde~1_144:
       dc.b      13,10,80,114,101,115,115,32,60,82,69,83,69,84
       dc.b      62,32,98,117,116,116,111,110,32,60,75,101,121
       dc.b      48,62,32,111,110,32,68,69,49,32,116,111,32,115
       dc.b      116,111,112,0
@m68kde~1_145:
       dc.b      13,10,13,10,80,114,111,103,114,97,109,32,65
       dc.b      66,79,82,84,32,33,33,33,33,33,33,13,10,0
@m68kde~1_146:
       dc.b      37,115,13,10,0
@m68kde~1_147:
       dc.b      13,10,13,10,80,114,111,103,114,97,109,32,65
       dc.b      66,79,82,84,32,33,33,33,33,33,0
@m68kde~1_148:
       dc.b      13,10,85,110,104,97,110,100,108,101,100,32,73
       dc.b      110,116,101,114,114,117,112,116,58,32,73,82
       dc.b      81,37,100,32,33,33,33,33,33,0
@m68kde~1_149:
       dc.b      65,68,68,82,69,83,83,32,69,82,82,79,82,58,32
       dc.b      49,54,32,111,114,32,51,50,32,66,105,116,32,84
       dc.b      114,97,110,115,102,101,114,32,116,111,47,102
       dc.b      114,111,109,32,97,110,32,79,68,68,32,65,100
       dc.b      100,114,101,115,115,46,46,46,46,0
@m68kde~1_150:
       dc.b      85,110,104,97,110,100,108,101,100,32,84,114
       dc.b      97,112,32,33,33,33,33,33,0
@m68kde~1_151:
       dc.b      66,85,83,32,69,114,114,111,114,33,0
@m68kde~1_152:
       dc.b      65,68,68,82,69,83,83,32,69,114,114,111,114,33
       dc.b      0
@m68kde~1_153:
       dc.b      73,76,76,69,71,65,76,32,73,78,83,84,82,85,67
       dc.b      84,73,79,78,0
@m68kde~1_154:
       dc.b      68,73,86,73,68,69,32,66,89,32,90,69,82,79,0
@m68kde~1_155:
       dc.b      39,67,72,75,39,32,73,78,83,84,82,85,67,84,73
       dc.b      79,78,0
@m68kde~1_156:
       dc.b      84,82,65,80,86,32,73,78,83,84,82,85,67,84,73
       dc.b      79,78,0
@m68kde~1_157:
       dc.b      80,82,73,86,73,76,69,71,69,32,86,73,79,76,65
       dc.b      84,73,79,78,0
@m68kde~1_158:
       dc.b      85,78,73,78,73,84,73,65,76,73,83,69,68,32,73
       dc.b      82,81,0
@m68kde~1_159:
       dc.b      83,80,85,82,73,79,85,83,32,73,82,81,0
@m68kde~1_160:
       dc.b      13,10,83,116,97,114,116,32,65,100,100,114,101
       dc.b      115,115,32,105,110,32,77,101,109,111,114,121
       dc.b      58,32,0
@m68kde~1_161:
       dc.b      13,10,69,110,116,101,114,32,83,116,114,105,110
       dc.b      103,32,40,69,83,67,32,116,111,32,101,110,100
       dc.b      41,32,58,0
@m68kde~1_162:
       dc.b      13,10,83,116,97,114,116,32,65,100,100,114,101
       dc.b      115,115,58,32,0
@m68kde~1_163:
       dc.b      13,10,69,110,100,32,65,100,100,114,101,115,115
       dc.b      58,32,0
@m68kde~1_164:
       dc.b      68,69,49,45,54,56,107,32,66,117,103,32,86,49
       dc.b      46,55,55,0
@m68kde~1_165:
       dc.b      67,111,112,121,114,105,103,104,116,32,40,67
       dc.b      41,32,80,74,32,68,97,118,105,101,115,32,50,48
       dc.b      49,54,0
@m68kde~1_166:
       dc.b      13,10,82,117,110,110,105,110,103,46,46,46,46
       dc.b      46,0
@m68kde~1_167:
       dc.b      82,117,110,110,105,110,103,46,46,46,46,46,0
@m68kde~1_168:
       dc.b      66,121,58,32,80,74,32,68,97,118,105,101,115
       dc.b      0
@m68kde~1_169:
       dc.b      13,10,37,115,0
@m68kde~1_170:
       dc.b      13,10,37,115,0
@m68kde~1_171:
       dc.b      46,66,32,0
@m68kde~1_172:
       dc.b      46,87,32,0
@m68kde~1_173:
       dc.b      46,76,32,0
@m68kde~1_174:
       dc.b      35,36,37,88,0
@m68kde~1_175:
       dc.b      35,36,37,88,0
@m68kde~1_176:
       dc.b      35,36,37,88,0
@m68kde~1_177:
       dc.b      35,36,37,88,0
@m68kde~1_178:
       dc.b      35,36,37,88,0
@m68kde~1_179:
       dc.b      35,36,37,88,0
@m68kde~1_180:
       dc.b      35,36,37,88,0
@m68kde~1_181:
       dc.b      40,0
@m68kde~1_182:
       dc.b      41,0
@m68kde~1_183:
       dc.b      40,0
@m68kde~1_184:
       dc.b      41,43,0
@m68kde~1_185:
       dc.b      45,40,0
@m68kde~1_186:
       dc.b      41,0
@m68kde~1_187:
       dc.b      37,100,40,65,37,100,41,0
@m68kde~1_188:
       dc.b      37,100,40,65,37,100,44,0
@m68kde~1_189:
       dc.b      68,0
@m68kde~1_190:
       dc.b      65,0
@m68kde~1_191:
       dc.b      37,100,0
@m68kde~1_192:
       dc.b      46,87,41,0
@m68kde~1_193:
       dc.b      46,76,41,0
@m68kde~1_194:
       dc.b      36,37,88,0
@m68kde~1_195:
       dc.b      36,37,88,0
@m68kde~1_196:
       dc.b      37,100,40,80,67,41,0
@m68kde~1_197:
       dc.b      37,100,40,80,67,44,0
@m68kde~1_198:
       dc.b      68,0
@m68kde~1_199:
       dc.b      65,0
@m68kde~1_200:
       dc.b      37,100,0
@m68kde~1_201:
       dc.b      46,87,41,0
@m68kde~1_202:
       dc.b      46,76,41,0
@m68kde~1_203:
       dc.b      44,0
@m68kde~1_204:
       dc.b      44,0
@m68kde~1_205:
       dc.b      67,67,0
@m68kde~1_206:
       dc.b      67,83,0
@m68kde~1_207:
       dc.b      69,81,0
@m68kde~1_208:
       dc.b      71,69,0
@m68kde~1_209:
       dc.b      71,84,0
@m68kde~1_210:
       dc.b      72,73,0
@m68kde~1_211:
       dc.b      76,69,0
@m68kde~1_212:
       dc.b      76,83,0
@m68kde~1_213:
       dc.b      76,84,0
@m68kde~1_214:
       dc.b      77,73,0
@m68kde~1_215:
       dc.b      78,69,0
@m68kde~1_216:
       dc.b      80,76,0
@m68kde~1_217:
       dc.b      86,83,0
@m68kde~1_218:
       dc.b      86,67,0
@m68kde~1_219:
       dc.b      82,65,0
@m68kde~1_220:
       dc.b      83,82,0
@m68kde~1_221:
       dc.b      32,0
@m68kde~1_222:
       dc.b      85,110,107,110,111,119,110,0
@m68kde~1_223:
       dc.b      65,66,67,68,32,68,37,100,44,68,37,100,0
@m68kde~1_224:
       dc.b      65,66,67,68,32,45,40,65,37,100,41,44,45,40,65
       dc.b      37,100,41,0
@m68kde~1_225:
       dc.b      65,68,68,65,46,87,32,0
@m68kde~1_226:
       dc.b      65,68,68,65,46,76,32,0
@m68kde~1_227:
       dc.b      44,65,37,88,0
@m68kde~1_228:
       dc.b      65,68,68,0
@m68kde~1_229:
       dc.b      65,68,68,73,0
@m68kde~1_230:
       dc.b      65,78,68,73,0
@m68kde~1_231:
       dc.b      67,77,80,73,0
@m68kde~1_232:
       dc.b      69,79,82,73,0
@m68kde~1_233:
       dc.b      79,82,73,0
@m68kde~1_234:
       dc.b      83,85,66,73,0
@m68kde~1_235:
       dc.b      44,0
@m68kde~1_236:
       dc.b      65,78,68,73,32,35,36,37,88,44,83,82,0
@m68kde~1_237:
       dc.b      65,68,68,81,0
@m68kde~1_238:
       dc.b      35,37,49,88,44,0
@m68kde~1_239:
       dc.b      65,68,68,88,0
@m68kde~1_240:
       dc.b      68,37,88,44,68,37,88,0
@m68kde~1_241:
       dc.b      45,40,65,37,88,41,44,45,40,65,37,88,41,0
@m68kde~1_242:
       dc.b      65,78,68,0
@m68kde~1_243:
       dc.b      65,78,68,73,32,35,36,37,50,88,44,67,67,82,0
@m68kde~1_244:
       dc.b      65,83,76,0
@m68kde~1_245:
       dc.b      65,83,82,0
@m68kde~1_246:
       dc.b      76,83,76,0
@m68kde~1_247:
       dc.b      76,83,82,0
@m68kde~1_248:
       dc.b      82,79,76,0
@m68kde~1_249:
       dc.b      82,79,82,0
@m68kde~1_250:
       dc.b      82,79,88,76,0
@m68kde~1_251:
       dc.b      82,79,88,82,0
@m68kde~1_252:
       dc.b      32,32,0
@m68kde~1_253:
       dc.b      65,83,76,0
@m68kde~1_254:
       dc.b      65,83,82,0
@m68kde~1_255:
       dc.b      76,83,76,0
@m68kde~1_256:
       dc.b      76,83,82,0
@m68kde~1_257:
       dc.b      82,79,76,0
@m68kde~1_258:
       dc.b      82,79,82,0
@m68kde~1_259:
       dc.b      82,79,88,76,0
@m68kde~1_260:
       dc.b      82,79,88,82,0
@m68kde~1_261:
       dc.b      35,36,37,88,44,68,37,88,0
@m68kde~1_262:
       dc.b      68,37,88,44,68,37,88,0
@m68kde~1_263:
       dc.b      66,0
@m68kde~1_264:
       dc.b      36,37,88,0
@m68kde~1_265:
       dc.b      36,37,88,0
@m68kde~1_266:
       dc.b      66,67,72,71,32,0
@m68kde~1_267:
       dc.b      68,37,100,44,0
@m68kde~1_268:
       dc.b      66,67,72,71,32,0
@m68kde~1_269:
       dc.b      35,36,37,88,44,0
@m68kde~1_270:
       dc.b      66,67,76,82,32,0
@m68kde~1_271:
       dc.b      68,37,100,44,0
@m68kde~1_272:
       dc.b      66,67,76,82,32,0
@m68kde~1_273:
       dc.b      35,36,37,88,44,0
@m68kde~1_274:
       dc.b      66,83,69,84,32,0
@m68kde~1_275:
       dc.b      68,37,100,44,0
@m68kde~1_276:
       dc.b      66,83,69,84,32,0
@m68kde~1_277:
       dc.b      35,36,37,88,44,0
@m68kde~1_278:
       dc.b      66,84,83,84,32,0
@m68kde~1_279:
       dc.b      68,37,100,44,0
@m68kde~1_280:
       dc.b      66,84,83,84,32,0
@m68kde~1_281:
       dc.b      35,36,37,88,44,0
@m68kde~1_282:
       dc.b      67,72,75,32,0
@m68kde~1_283:
       dc.b      44,68,37,100,0
@m68kde~1_284:
       dc.b      67,76,82,0
@m68kde~1_285:
       dc.b      67,77,80,65,46,87,32,0
@m68kde~1_286:
       dc.b      67,77,80,65,46,76,32,0
@m68kde~1_287:
       dc.b      44,65,37,100,0
@m68kde~1_288:
       dc.b      67,77,80,0
@m68kde~1_289:
       dc.b      67,77,80,77,0
@m68kde~1_290:
       dc.b      40,65,37,100,41,43,44,40,65,37,100,41,43,0
@m68kde~1_291:
       dc.b      68,66,0
@m68kde~1_292:
       dc.b      68,37,100,44,37,43,100,40,80,67,41,32,116,111
       dc.b      32,65,100,100,114,58,36,37,88,0
@m68kde~1_293:
       dc.b      68,73,86,83,32,0
@m68kde~1_294:
       dc.b      44,0
@m68kde~1_295:
       dc.b      68,73,86,85,32,0
@m68kde~1_296:
       dc.b      44,0
@m68kde~1_297:
       dc.b      69,79,82,0
@m68kde~1_298:
       dc.b      69,79,82,73,32,35,36,37,50,88,44,67,67,82,0
@m68kde~1_299:
       dc.b      69,79,82,73,32,35,36,37,88,44,83,82,0
@m68kde~1_300:
       dc.b      69,88,71,32,68,37,100,44,68,37,100,0
@m68kde~1_301:
       dc.b      69,88,71,32,65,37,100,44,65,37,100,0
@m68kde~1_302:
       dc.b      69,88,71,32,68,37,100,44,65,37,100,0
@m68kde~1_303:
       dc.b      69,88,84,0
@m68kde~1_304:
       dc.b      46,76,32,0
@m68kde~1_305:
       dc.b      46,87,32,0
@m68kde~1_306:
       dc.b      73,76,76,69,71,65,76,32,40,36,52,65,70,67,41
       dc.b      0
@m68kde~1_307:
       dc.b      74,77,80,32,0
@m68kde~1_308:
       dc.b      74,83,82,32,0
@m68kde~1_309:
       dc.b      76,69,65,32,0
@m68kde~1_310:
       dc.b      44,65,37,100,0
@m68kde~1_311:
       dc.b      76,73,78,75,32,0
@m68kde~1_312:
       dc.b      65,37,100,44,35,37,100,0
@m68kde~1_313:
       dc.b      77,79,86,69,46,66,32,0
@m68kde~1_314:
       dc.b      77,79,86,69,46,76,32,0
@m68kde~1_315:
       dc.b      77,79,86,69,46,87,32,0
@m68kde~1_316:
       dc.b      44,0
@m68kde~1_317:
       dc.b      77,79,86,69,32,0
@m68kde~1_318:
       dc.b      44,67,67,82,0
@m68kde~1_319:
       dc.b      77,79,86,69,32,83,82,44,0
@m68kde~1_320:
       dc.b      77,79,86,69,32,0
@m68kde~1_321:
       dc.b      44,83,82,0
@m68kde~1_322:
       dc.b      77,79,86,69,32,85,83,80,44,65,37,100,0
@m68kde~1_323:
       dc.b      77,79,86,69,32,65,37,100,44,85,83,80,0
@m68kde~1_324:
       dc.b      77,79,86,69,77,0
@m68kde~1_325:
       dc.b      46,87,32,0
@m68kde~1_326:
       dc.b      46,76,32,0
@m68kde~1_327:
       dc.b      0
@m68kde~1_328:
       dc.b      68,37,100,0
@m68kde~1_329:
       dc.b      47,68,37,100,0
@m68kde~1_330:
       dc.b      65,37,100,0
@m68kde~1_331:
       dc.b      47,65,37,100,0
@m68kde~1_332:
       dc.b      44,0
@m68kde~1_333:
       dc.b      44,0
@m68kde~1_334:
       dc.b      68,37,100,0
@m68kde~1_335:
       dc.b      47,68,37,100,0
@m68kde~1_336:
       dc.b      65,37,100,0
@m68kde~1_337:
       dc.b      47,65,37,100,0
@m68kde~1_338:
       dc.b      77,79,86,69,80,46,87,32,36,37,88,40,65,37,100
       dc.b      41,44,68,37,100,0
@m68kde~1_339:
       dc.b      77,79,86,69,80,46,76,32,36,37,88,40,65,37,100
       dc.b      41,44,68,37,100,0
@m68kde~1_340:
       dc.b      77,79,86,69,80,46,87,32,68,37,100,44,36,37,88
       dc.b      40,65,37,100,41,0
@m68kde~1_341:
       dc.b      77,79,86,69,80,46,76,32,68,37,100,44,36,37,88
       dc.b      40,65,37,100,41,0
@m68kde~1_342:
       dc.b      77,79,86,69,81,32,35,36,37,88,44,68,37,100,0
@m68kde~1_343:
       dc.b      77,85,76,83,32,0
@m68kde~1_344:
       dc.b      44,68,37,100,0
@m68kde~1_345:
       dc.b      77,85,76,85,32,0
@m68kde~1_346:
       dc.b      44,68,37,100,0
@m68kde~1_347:
       dc.b      78,66,67,68,32,0
@m68kde~1_348:
       dc.b      78,69,71,0
@m68kde~1_349:
       dc.b      78,69,71,88,0
@m68kde~1_350:
       dc.b      78,79,80,0
@m68kde~1_351:
       dc.b      78,79,84,0
@m68kde~1_352:
       dc.b      79,82,0
@m68kde~1_353:
       dc.b      79,82,73,32,35,36,37,50,88,44,67,67,82,0
@m68kde~1_354:
       dc.b      79,82,73,32,32,35,36,37,88,44,83,82,0
@m68kde~1_355:
       dc.b      80,69,65,32,0
@m68kde~1_356:
       dc.b      82,69,83,69,84,0
@m68kde~1_357:
       dc.b      82,84,69,0
@m68kde~1_358:
       dc.b      82,84,82,0
@m68kde~1_359:
       dc.b      82,84,83,0
@m68kde~1_360:
       dc.b      83,84,79,80,32,35,36,37,88,0
@m68kde~1_361:
       dc.b      83,66,67,68,32,68,37,100,44,68,37,100,0
@m68kde~1_362:
       dc.b      83,66,67,68,32,45,40,65,37,100,41,44,45,40,65
       dc.b      37,100,41,0
@m68kde~1_363:
       dc.b      83,0
@m68kde~1_364:
       dc.b      83,85,66,65,46,87,32,0
@m68kde~1_365:
       dc.b      83,85,66,65,46,76,32,0
@m68kde~1_366:
       dc.b      44,65,37,88,0
@m68kde~1_367:
       dc.b      83,85,66,0
@m68kde~1_368:
       dc.b      83,85,66,81,0
@m68kde~1_369:
       dc.b      35,37,49,88,44,0
@m68kde~1_370:
       dc.b      83,85,66,88,0
@m68kde~1_371:
       dc.b      68,37,49,88,44,68,37,49,88,0
@m68kde~1_372:
       dc.b      45,40,65,37,49,88,41,44,45,40,65,37,49,88,41
       dc.b      0
@m68kde~1_373:
       dc.b      83,87,65,80,32,68,37,100,0
@m68kde~1_374:
       dc.b      84,65,83,32,0
@m68kde~1_375:
       dc.b      84,82,65,80,32,35,37,100,0
@m68kde~1_376:
       dc.b      84,82,65,80,86,0
@m68kde~1_377:
       dc.b      84,83,84,0
@m68kde~1_378:
       dc.b      85,78,76,75,32,65,37,100,0
       section   bss
       xdef      _i
_i:
       ds.b      4
       xdef      _x
_x:
       ds.b      4
       xdef      _y
_y:
       ds.b      4
       xdef      _z
_z:
       ds.b      4
       xdef      _PortA_Count
_PortA_Count:
       ds.b      4
       xdef      _Trace
_Trace:
       ds.b      4
       xdef      _GoFlag
_GoFlag:
       ds.b      4
       xdef      _Echo
_Echo:
       ds.b      4
       xdef      _d0
_d0:
       ds.b      4
       xdef      _d1
_d1:
       ds.b      4
       xdef      _d2
_d2:
       ds.b      4
       xdef      _d3
_d3:
       ds.b      4
       xdef      _d4
_d4:
       ds.b      4
       xdef      _d5
_d5:
       ds.b      4
       xdef      _d6
_d6:
       ds.b      4
       xdef      _d7
_d7:
       ds.b      4
       xdef      _a0
_a0:
       ds.b      4
       xdef      _a1
_a1:
       ds.b      4
       xdef      _a2
_a2:
       ds.b      4
       xdef      _a3
_a3:
       ds.b      4
       xdef      _a4
_a4:
       ds.b      4
       xdef      _a5
_a5:
       ds.b      4
       xdef      _a6
_a6:
       ds.b      4
       xdef      _PC
_PC:
       ds.b      4
       xdef      _SSP
_SSP:
       ds.b      4
       xdef      _USP
_USP:
       ds.b      4
       xdef      _SR
_SR:
       ds.b      2
       xdef      _BreakPointAddress
_BreakPointAddress:
       ds.b      32
       xdef      _BreakPointInstruction
_BreakPointInstruction:
       ds.b      16
       xdef      _BreakPointSetOrCleared
_BreakPointSetOrCleared:
       ds.b      32
       xdef      _InstructionSize
_InstructionSize:
       ds.b      4
       xdef      _WatchPointAddress
_WatchPointAddress:
       ds.b      32
       xdef      _WatchPointSetOrCleared
_WatchPointSetOrCleared:
       ds.b      32
       xdef      _WatchPointString
_WatchPointString:
       ds.b      800
       xdef      _Instruction
_Instruction:
       ds.b      100
       xdef      _TempString
_TempString:
       ds.b      100
       xref      _strcpy
       xref      LDIV
       xref      _go
       xref      _putch
       xref      _getch
       xref      _tolower
       xref      _sprintf
       xref      _strcat
       xref      _toupper
       xref      _printf
