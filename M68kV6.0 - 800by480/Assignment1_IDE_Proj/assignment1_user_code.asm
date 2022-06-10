; C:\M68KV6.0 - 800BY480\PROGRAMS\DEBUGMONITORCODE\ASSIGNMENT1_USER_CODE.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; #define StartOfExceptionVectorTable 0x08030000
; /**********************************************************************************************
; **	Parallel port addresses
; **********************************************************************************************/
; #define PortA   *(volatile unsigned char *)(0x00400000)
; #define PortB   *(volatile unsigned char *)(0x00400002)
; #define PortC   *(volatile unsigned char *)(0x00400004)
; #define PortD   *(volatile unsigned char *)(0x00400006)
; #define PortE   *(volatile unsigned char *)(0x00400008)
; /*********************************************************************************************
; **	Hex 7 seg displays port addresses
; *********************************************************************************************/
; #define HEX_A        *(volatile unsigned char *)(0x00400010)
; #define HEX_B        *(volatile unsigned char *)(0x00400012)
; #define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
; #define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only
; /**********************************************************************************************
; **	LCD display port addresses
; **********************************************************************************************/
; #define LCDcommand   *(volatile unsigned char *)(0x00400020)
; #define LCDdata      *(volatile unsigned char *)(0x00400022)
; /********************************************************************************************
; **	Timer Port addresses
; *********************************************************************************************/
; #define Timer1Data      *(volatile unsigned char *)(0x00400030)
; #define Timer1Control   *(volatile unsigned char *)(0x00400032)
; #define Timer1Status    *(volatile unsigned char *)(0x00400032)
; #define Timer2Data      *(volatile unsigned char *)(0x00400034)
; #define Timer2Control   *(volatile unsigned char *)(0x00400036)
; #define Timer2Status    *(volatile unsigned char *)(0x00400036)
; #define Timer3Data      *(volatile unsigned char *)(0x00400038)
; #define Timer3Control   *(volatile unsigned char *)(0x0040003A)
; #define Timer3Status    *(volatile unsigned char *)(0x0040003A)
; #define Timer4Data      *(volatile unsigned char *)(0x0040003C)
; #define Timer4Control   *(volatile unsigned char *)(0x0040003E)
; #define Timer4Status    *(volatile unsigned char *)(0x0040003E)
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; /*********************************************************************************************
; **	PIA 1 and 2 port addresses
; *********************************************************************************************/
; #define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
; #define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
; #define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
; #define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)
; #define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
; #define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
; #define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
; #define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)
; /*********************************************************************************************************************************
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; unsigned int i, x, y, z, PortA_Count;
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
; /*******************************************************************************************
; ** Function Prototypes
; *******************************************************************************************/
; void Wait1ms(void);
; void Wait3ms(void);
; void Init_LCD(void) ;
; void LCDOutchar(int c);
; void LCDOutMess(char *theMessage);
; void LCDClearln(void);
; void LCDline1Message(char *theMessage);
; void LCDline2Message(char *theMessage);
; int sprintf(char *out, const char *format, ...) ;
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; void Timer_ISR()
; {
       section   code
       xdef      _Timer_ISR
_Timer_ISR:
; if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
       move.b    4194354,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_1
; Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194354
; PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
       move.b    _Timer1Count.L,D0
       addq.b    #1,_Timer1Count.L
       move.b    D0,4194304
Timer_ISR_1:
; }
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_3
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
; PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
       move.b    _Timer2Count.L,D0
       addq.b    #1,_Timer2Count.L
       move.b    D0,4194308
Timer_ISR_3:
; }
; if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
       move.b    4194362,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_5
; Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194362
; HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
       move.b    _Timer3Count.L,D0
       addq.b    #1,_Timer3Count.L
       move.b    D0,4194320
Timer_ISR_5:
; }
; if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
       move.b    4194366,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_7
; Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194366
; HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
       move.b    _Timer4Count.L,D0
       addq.b    #1,_Timer4Count.L
       move.b    D0,4194322
Timer_ISR_7:
       rts
; }
; }
; /*****************************************************************************************
; **	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void ACIA_ISR()
; {}
       xdef      _ACIA_ISR
_ACIA_ISR:
       rts
; /***************************************************************************************
; **	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void PIA_ISR()
; {}
       xdef      _PIA_ISR
_PIA_ISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 2 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key2PressISR()
; {}
       xdef      _Key2PressISR
_Key2PressISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 1 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key1PressISR()
; {}
       xdef      _Key1PressISR
_Key1PressISR:
       rts
; /************************************************************************************
; **   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; int  i ;
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
; **  Subroutine to give the 68000 something useless to do to waste 3 mSec
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
; **  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
; **  Sets it for parallel port and 2 line display mode (if I recall correctly)
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = 0x0c ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = 0x38 ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /*********************************************************************************************
; **  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
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
; while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.l     #127,D0
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
; **  NOTE you do not call this function directly, instead you call the normal getchar() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       link      A6,#-4
; char c ;
; while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to output a single character to the 2 row LCD display
; **  It is assumed the character is an ASCII code and it will be displayed at the
; **  current cursor position
; *******************************************************************************/
; void LCDOutchar(int c)
; {
       xdef      _LCDOutchar
_LCDOutchar:
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
; void LCDOutMessage(char *theMessage)
; {
       xdef      _LCDOutMessage
_LCDOutMessage:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != 0)     // output characters from the string until NULL
LCDOutMessage_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     LCDOutMessage_3
; LCDOutchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _LCDOutchar
       addq.w    #4,A7
       bra       LCDOutMessage_1
LCDOutMessage_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void LCDClearln(void)
; {
       xdef      _LCDClearln
_LCDClearln:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 24; i ++)
       clr.l     D2
LCDClearln_1:
       cmp.l     #24,D2
       bge.s     LCDClearln_3
; LCDOutchar(' ') ;       // write a space char to the LCD display
       pea       32
       jsr       _LCDOutchar
       addq.w    #4,A7
       addq.l    #1,D2
       bra       LCDClearln_1
LCDClearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void LCDLine1Message(char *theMessage)
; {
       xdef      _LCDLine1Message
_LCDLine1Message:
       link      A6,#0
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void LCDLine2Message(char *theMessage)
; {
       xdef      _LCDLine2Message
_LCDLine2Message:
       link      A6,#0
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /*********************************************************************************************************************************
; **  IMPORTANT FUNCTION
; **  This function install an exception handler so you can capture and deal with any 68000 exception in your program
; **  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
; **  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
; **  Calling this function allows you to deal with Interrupts for example
; ***********************************************************************************************************************************/
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #134414336,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; void main()
; {
       xdef      _main
_main:
       link      A6,#-12
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _scanf.L,A3
; unsigned char   data_option = 'U';  //Char U will be unassigned value in case system reset without sram cleaned
       move.b    #85,-10(A6)
; unsigned char   data_pattern = 'U';
       move.b    #85,-9(A6)
; unsigned int    input_data = NULL;
       clr.l     D3
; unsigned int    num_of_bits = NULL;
       clr.l     D5
; unsigned int    start_address = NULL;
       clr.l     -8(A6)
; unsigned int    start_address_valid = 0;
       moveq     #0,D7
; unsigned int    end_address = NULL;
       clr.l     -4(A6)
; unsigned int    end_address_valid = 0;
       clr.l     D6
; unsigned int    *address_ptr = NULL;
       clr.l     D2
; unsigned int    address_counter = 0;
       clr.l     D4
; Init_RS232();
       jsr       _Init_RS232
; scanflush();
       jsr       _scanflush
; //Option of carrying out a test using byte words or longwords
; while((data_option != 'A' && data_option != 'B' && data_option != 'C') || data_option == 'U')
main_1:
       move.b    -10(A6),D0
       cmp.b     #65,D0
       beq.s     main_5
       move.b    -10(A6),D0
       cmp.b     #66,D0
       beq.s     main_5
       move.b    -10(A6),D0
       cmp.b     #67,D0
       bne.s     main_4
main_5:
       move.b    -10(A6),D0
       cmp.b     #85,D0
       bne       main_3
main_4:
; {
; printf("\r\nChoose the data type you want to test\n");
       pea       @assign~1_1.L
       jsr       (A2)
       addq.w    #4,A7
; printf("A-BYTES    B-WORDS    C-LONG WORDS\n");
       pea       @assign~1_2.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%c", &data_option);
       pea       -10(A6)
       pea       @assign~1_3.L
       jsr       (A3)
       addq.w    #8,A7
; if(data_option != 'A' && data_option != 'B' && data_option != 'C')
       move.b    -10(A6),D0
       cmp.b     #65,D0
       beq.s     main_6
       move.b    -10(A6),D0
       cmp.b     #66,D0
       beq.s     main_6
       move.b    -10(A6),D0
       cmp.b     #67,D0
       beq.s     main_6
; printf("Input Not Valid\n");
       pea       @assign~1_4.L
       jsr       (A2)
       addq.w    #4,A7
main_6:
       bra       main_1
main_3:
; }
; switch(data_option)
       move.b    -10(A6),D0
       and.l     #255,D0
       cmp.l     #66,D0
       beq.s     main_11
       bhi.s     main_14
       cmp.l     #65,D0
       beq.s     main_10
       bra.s     main_8
main_14:
       cmp.l     #67,D0
       beq.s     main_12
       bra.s     main_8
main_10:
; {
; case 'A':
; num_of_bits = 8;
       moveq     #8,D5
; break;
       bra.s     main_9
main_11:
; case 'B':
; num_of_bits = 16;
       moveq     #16,D5
; break;
       bra.s     main_9
main_12:
; case 'C':
; num_of_bits = 32;
       moveq     #32,D5
; break;
       bra.s     main_9
main_8:
; default:
; printf("\r\nFunction Exception of Wrong Data type");
       pea       @assign~1_5.L
       jsr       (A2)
       addq.w    #4,A7
; break;
main_9:
; }
; printf("\r\nData Option Choosen. # of bits is %i\n", num_of_bits);
       move.l    D5,-(A7)
       pea       @assign~1_6.L
       jsr       (A2)
       addq.w    #8,A7
; //Option of choosing data patterns
; while((data_pattern != 'A' && data_pattern != 'B' && data_pattern != 'C' && data_pattern != 'D') || data_pattern == 'U')
main_15:
       move.b    -9(A6),D0
       cmp.b     #65,D0
       beq.s     main_19
       move.b    -9(A6),D0
       cmp.b     #66,D0
       beq.s     main_19
       move.b    -9(A6),D0
       cmp.b     #67,D0
       beq.s     main_19
       move.b    -9(A6),D0
       cmp.b     #68,D0
       bne.s     main_18
main_19:
       move.b    -9(A6),D0
       cmp.b     #85,D0
       bne       main_17
main_18:
; {
; printf("\r\nChoose the data pattern you want to use\n");
       pea       @assign~1_7.L
       jsr       (A2)
       addq.w    #4,A7
; printf("A-55    B-AA    C-FF    D-00\n");
       pea       @assign~1_8.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%c", &data_pattern);
       pea       -9(A6)
       pea       @assign~1_3.L
       jsr       (A3)
       addq.w    #8,A7
; if(data_pattern != 'A' && data_pattern != 'B' && data_pattern != 'C' && data_pattern != 'D')
       move.b    -9(A6),D0
       cmp.b     #65,D0
       beq.s     main_20
       move.b    -9(A6),D0
       cmp.b     #66,D0
       beq.s     main_20
       move.b    -9(A6),D0
       cmp.b     #67,D0
       beq.s     main_20
       move.b    -9(A6),D0
       cmp.b     #68,D0
       beq.s     main_20
; printf("\r\nInput Not Valid\n");
       pea       @assign~1_9.L
       jsr       (A2)
       addq.w    #4,A7
main_20:
       bra       main_15
main_17:
; }
; switch(data_pattern)
       move.b    -9(A6),D0
       and.l     #255,D0
       sub.l     #65,D0
       blo       main_22
       cmp.l     #4,D0
       bhs.s     main_22
       asl.l     #1,D0
       move.w    main_24(PC,D0.L),D0
       jmp       main_24(PC,D0.W)
main_24:
       dc.w      main_25-main_24
       dc.w      main_26-main_24
       dc.w      main_27-main_24
       dc.w      main_28-main_24
main_25:
; {
; case 'A':
; input_data = 0x55;
       moveq     #85,D3
; break;
       bra.s     main_23
main_26:
; case 'B':
; input_data = 0xAA;
       move.l    #170,D3
; break;
       bra.s     main_23
main_27:
; case 'C':
; input_data = 0xFF;
       move.l    #255,D3
; break;
       bra.s     main_23
main_28:
; case 'D':
; input_data = 0x00;
       clr.l     D3
; break;
       bra.s     main_23
main_22:
; default:
; printf("\r\nFucntion Exception of Wrong Data Pattern");
       pea       @assign~1_10.L
       jsr       (A2)
       addq.w    #4,A7
; break;
main_23:
; }
; printf("\r\nData Pattern Choosen. The Pattern is %02X\n", input_data);
       move.l    D3,-(A7)
       pea       @assign~1_11.L
       jsr       (A2)
       addq.w    #8,A7
; //Prompt for a start and end address 
; while(!start_address_valid)
main_30:
       tst.l     D7
       bne       main_32
; {
; printf("\r\nPlease enter Start Address\n");
       pea       @assign~1_12.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%x", &start_address);
       pea       -8(A6)
       pea       @assign~1_13.L
       jsr       (A3)
       addq.w    #8,A7
; printf(start_address);
       move.l    -8(A6),-(A7)
       jsr       (A2)
       addq.w    #4,A7
; printf("\n");
       pea       @assign~1_14.L
       jsr       (A2)
       addq.w    #4,A7
; if(start_address < 0x08020000)
       move.l    -8(A6),D0
       cmp.l     #134348800,D0
       bhs.s     main_33
; printf("\r\nStart Address must > 0x08020000");
       pea       @assign~1_15.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     main_36
main_33:
; else if((num_of_bits >= 16) && (start_address % 2 != 0))
       cmp.l     #16,D5
       blo.s     main_35
       move.l    -8(A6),-(A7)
       pea       2
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     main_35
; printf("\r\nFor data type WORDS & LONG WORDS, address must be even");
       pea       @assign~1_16.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     main_36
main_35:
; else
; start_address_valid = 1;  
       moveq     #1,D7
main_36:
       bra       main_30
main_32:
; }
; while(!end_address_valid)
main_37:
       tst.l     D6
       bne       main_39
; {
; printf("\r\nPlease enter End Address\n");
       pea       @assign~1_17.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%x", &end_address);
       pea       -4(A6)
       pea       @assign~1_13.L
       jsr       (A3)
       addq.w    #8,A7
; if(end_address > 0x08030000)
       move.l    -4(A6),D0
       cmp.l     #134414336,D0
       bls.s     main_40
; printf("End Address must < 0x08030000\n");
       pea       @assign~1_18.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     main_43
main_40:
; else if((num_of_bits >= 16) && (start_address % 2 != 0))
       cmp.l     #16,D5
       blo.s     main_42
       move.l    -8(A6),-(A7)
       pea       2
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     main_42
; printf("For data type WORDS & LONG WORDS, address must be even\n");
       pea       @assign~1_19.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     main_43
main_42:
; else
; end_address_valid = 1;  
       moveq     #1,D6
main_43:
       bra       main_37
main_39:
; }
; //READ AND WRITE BIT
; switch(num_of_bits)
       cmp.l     #16,D5
       beq       main_47
       bhi.s     main_50
       cmp.l     #8,D5
       beq.s     main_46
       bra       main_44
main_50:
       cmp.l     #32,D5
       beq       main_48
       bra       main_44
main_46:
; {
; case 8:
; for(address_ptr = start_address; address_ptr <= end_address; address_ptr += 1)
       move.l    -8(A6),D2
main_51:
       cmp.l     -4(A6),D2
       bhi       main_53
; {
; *address_ptr = input_data;
       move.l    D2,A0
       move.l    D3,(A0)
; if(address_counter % 1280 == 0)
       move.l    D4,-(A7)
       pea       1280
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     main_54
; {
; printf("\r\nCurrent Progress: Address %08x Write Data %02X Read Data %02X",
       move.l    D2,A0
       move.l    (A0),-(A7)
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       pea       @assign~1_20.L
       jsr       (A2)
       add.w     #16,A7
main_54:
; address_ptr, input_data, *address_ptr);
; }
; address_counter++;
       addq.l    #1,D4
       addq.l    #4,D2
       bra       main_51
main_53:
; }
; break;
       bra       main_45
main_47:
; case 16:
; for(address_ptr = start_address; *address_ptr <= end_address; address_ptr += 2)
       move.l    -8(A6),D2
main_56:
       move.l    D2,A0
       move.l    (A0),D0
       cmp.l     -4(A6),D0
       bhi       main_58
; {
; *address_ptr = input_data;
       move.l    D2,A0
       move.l    D3,(A0)
; *(address_ptr + 1) = input_data;
       move.l    D2,A0
       move.l    D3,4(A0)
; if(address_counter % 1280 == 0)
       move.l    D4,-(A7)
       pea       1280
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     main_59
; {
; printf("\r\nCurrent Progress: Address %08x Write Data %02X%02X Read Data %02X%02X",
       move.l    D2,A0
       move.l    4(A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       move.l    D3,-(A7)
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       pea       @assign~1_21.L
       jsr       (A2)
       add.w     #24,A7
main_59:
; address_ptr, input_data, input_data, *address_ptr, *(address_ptr + 1));
; }
; address_counter++;
       addq.l    #1,D4
; address_counter++;
       addq.l    #1,D4
       addq.l    #8,D2
       bra       main_56
main_58:
; }
; break;
       bra       main_45
main_48:
; case 32:
; for(address_ptr = start_address; address_ptr <= end_address; address_ptr += 4)
       move.l    -8(A6),D2
main_61:
       cmp.l     -4(A6),D2
       bhi       main_63
; {
; *address_ptr = input_data;
       move.l    D2,A0
       move.l    D3,(A0)
; *(address_ptr + 1) = input_data;
       move.l    D2,A0
       move.l    D3,4(A0)
; *(address_ptr + 2) = input_data;
       move.l    D2,A0
       move.l    D3,8(A0)
; *(address_ptr + 3) = input_data;
       move.l    D2,A0
       move.l    D3,12(A0)
; if(address_counter % 1280 == 0)
       move.l    D4,-(A7)
       pea       1280
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne       main_64
; {
; printf("\r\nCurrent Progress: Address %08x Write Data %02X%02X%02X%02X Read Data %02X%02X%02X%02X",
       move.l    D2,A0
       move.l    12(A0),-(A7)
       move.l    D2,A0
       move.l    8(A0),-(A7)
       move.l    D2,A0
       move.l    4(A0),-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       move.l    D3,-(A7)
       move.l    D3,-(A7)
       move.l    D3,-(A7)
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       pea       @assign~1_22.L
       jsr       (A2)
       add.w     #40,A7
main_64:
; address_ptr, input_data, input_data, input_data, input_data, *address_ptr, *(address_ptr + 1), *(address_ptr + 2), *(address_ptr + 3));
; }
; address_counter++;
       addq.l    #1,D4
; address_counter++;
       addq.l    #1,D4
; address_counter++;
       addq.l    #1,D4
; address_counter++;
       addq.l    #1,D4
       add.l     #16,D2
       bra       main_61
main_63:
; }
; break;
       bra.s     main_45
main_44:
; default:
; printf("\r\nFucntion Exception on READ and WRITE stage");
       pea       @assign~1_23.L
       jsr       (A2)
       addq.w    #4,A7
; break;
main_45:
; }
; printf("\r\nTest Completed. Press KEY0 to Restart");
       pea       @assign~1_24.L
       jsr       (A2)
       addq.w    #4,A7
; while(1);
main_66:
       bra       main_66
; }
       section   const
@assign~1_1:
       dc.b      13,10,67,104,111,111,115,101,32,116,104,101
       dc.b      32,100,97,116,97,32,116,121,112,101,32,121,111
       dc.b      117,32,119,97,110,116,32,116,111,32,116,101
       dc.b      115,116,10,0
@assign~1_2:
       dc.b      65,45,66,89,84,69,83,32,32,32,32,66,45,87,79
       dc.b      82,68,83,32,32,32,32,67,45,76,79,78,71,32,87
       dc.b      79,82,68,83,10,0
@assign~1_3:
       dc.b      37,99,0
@assign~1_4:
       dc.b      73,110,112,117,116,32,78,111,116,32,86,97,108
       dc.b      105,100,10,0
@assign~1_5:
       dc.b      13,10,70,117,110,99,116,105,111,110,32,69,120
       dc.b      99,101,112,116,105,111,110,32,111,102,32,87
       dc.b      114,111,110,103,32,68,97,116,97,32,116,121,112
       dc.b      101,0
@assign~1_6:
       dc.b      13,10,68,97,116,97,32,79,112,116,105,111,110
       dc.b      32,67,104,111,111,115,101,110,46,32,35,32,111
       dc.b      102,32,98,105,116,115,32,105,115,32,37,105,10
       dc.b      0
@assign~1_7:
       dc.b      13,10,67,104,111,111,115,101,32,116,104,101
       dc.b      32,100,97,116,97,32,112,97,116,116,101,114,110
       dc.b      32,121,111,117,32,119,97,110,116,32,116,111
       dc.b      32,117,115,101,10,0
@assign~1_8:
       dc.b      65,45,53,53,32,32,32,32,66,45,65,65,32,32,32
       dc.b      32,67,45,70,70,32,32,32,32,68,45,48,48,10,0
@assign~1_9:
       dc.b      13,10,73,110,112,117,116,32,78,111,116,32,86
       dc.b      97,108,105,100,10,0
@assign~1_10:
       dc.b      13,10,70,117,99,110,116,105,111,110,32,69,120
       dc.b      99,101,112,116,105,111,110,32,111,102,32,87
       dc.b      114,111,110,103,32,68,97,116,97,32,80,97,116
       dc.b      116,101,114,110,0
@assign~1_11:
       dc.b      13,10,68,97,116,97,32,80,97,116,116,101,114
       dc.b      110,32,67,104,111,111,115,101,110,46,32,84,104
       dc.b      101,32,80,97,116,116,101,114,110,32,105,115
       dc.b      32,37,48,50,88,10,0
@assign~1_12:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,83,116,97,114,116,32,65,100,100,114,101
       dc.b      115,115,10,0
@assign~1_13:
       dc.b      37,120,0
@assign~1_14:
       dc.b      10,0
@assign~1_15:
       dc.b      13,10,83,116,97,114,116,32,65,100,100,114,101
       dc.b      115,115,32,109,117,115,116,32,62,32,48,120,48
       dc.b      56,48,50,48,48,48,48,0
@assign~1_16:
       dc.b      13,10,70,111,114,32,100,97,116,97,32,116,121
       dc.b      112,101,32,87,79,82,68,83,32,38,32,76,79,78
       dc.b      71,32,87,79,82,68,83,44,32,97,100,100,114,101
       dc.b      115,115,32,109,117,115,116,32,98,101,32,101
       dc.b      118,101,110,0
@assign~1_17:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,69,110,100,32,65,100,100,114,101,115
       dc.b      115,10,0
@assign~1_18:
       dc.b      69,110,100,32,65,100,100,114,101,115,115,32
       dc.b      109,117,115,116,32,60,32,48,120,48,56,48,51
       dc.b      48,48,48,48,10,0
@assign~1_19:
       dc.b      70,111,114,32,100,97,116,97,32,116,121,112,101
       dc.b      32,87,79,82,68,83,32,38,32,76,79,78,71,32,87
       dc.b      79,82,68,83,44,32,97,100,100,114,101,115,115
       dc.b      32,109,117,115,116,32,98,101,32,101,118,101
       dc.b      110,10,0
@assign~1_20:
       dc.b      13,10,67,117,114,114,101,110,116,32,80,114,111
       dc.b      103,114,101,115,115,58,32,65,100,100,114,101
       dc.b      115,115,32,37,48,56,120,32,87,114,105,116,101
       dc.b      32,68,97,116,97,32,37,48,50,88,32,82,101,97
       dc.b      100,32,68,97,116,97,32,37,48,50,88,0
@assign~1_21:
       dc.b      13,10,67,117,114,114,101,110,116,32,80,114,111
       dc.b      103,114,101,115,115,58,32,65,100,100,114,101
       dc.b      115,115,32,37,48,56,120,32,87,114,105,116,101
       dc.b      32,68,97,116,97,32,37,48,50,88,37,48,50,88,32
       dc.b      82,101,97,100,32,68,97,116,97,32,37,48,50,88
       dc.b      37,48,50,88,0
@assign~1_22:
       dc.b      13,10,67,117,114,114,101,110,116,32,80,114,111
       dc.b      103,114,101,115,115,58,32,65,100,100,114,101
       dc.b      115,115,32,37,48,56,120,32,87,114,105,116,101
       dc.b      32,68,97,116,97,32,37,48,50,88,37,48,50,88,37
       dc.b      48,50,88,37,48,50,88,32,82,101,97,100,32,68
       dc.b      97,116,97,32,37,48,50,88,37,48,50,88,37,48,50
       dc.b      88,37,48,50,88,0
@assign~1_23:
       dc.b      13,10,70,117,99,110,116,105,111,110,32,69,120
       dc.b      99,101,112,116,105,111,110,32,111,110,32,82
       dc.b      69,65,68,32,97,110,100,32,87,82,73,84,69,32
       dc.b      115,116,97,103,101,0
@assign~1_24:
       dc.b      13,10,84,101,115,116,32,67,111,109,112,108,101
       dc.b      116,101,100,46,32,80,114,101,115,115,32,75,69
       dc.b      89,48,32,116,111,32,82,101,115,116,97,114,116
       dc.b      0
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
       xdef      _Timer1Count
_Timer1Count:
       ds.b      1
       xdef      _Timer2Count
_Timer2Count:
       ds.b      1
       xdef      _Timer3Count
_Timer3Count:
       ds.b      1
       xdef      _Timer4Count
_Timer4Count:
       ds.b      1
       xref      _scanf
       xref      ULDIV
       xref      _scanflush
       xref      _printf
