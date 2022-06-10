#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define StartOfExceptionVectorTable 0x08030000

/**********************************************************************************************
**	Parallel port addresses
**********************************************************************************************/

#define PortA   *(volatile unsigned char *)(0x00400000)
#define PortB   *(volatile unsigned char *)(0x00400002)
#define PortC   *(volatile unsigned char *)(0x00400004)
#define PortD   *(volatile unsigned char *)(0x00400006)
#define PortE   *(volatile unsigned char *)(0x00400008)

/*********************************************************************************************
**	Hex 7 seg displays port addresses
*********************************************************************************************/

#define HEX_A        *(volatile unsigned char *)(0x00400010)
#define HEX_B        *(volatile unsigned char *)(0x00400012)
#define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
#define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only

/**********************************************************************************************
**	LCD display port addresses
**********************************************************************************************/

#define LCDcommand   *(volatile unsigned char *)(0x00400020)
#define LCDdata      *(volatile unsigned char *)(0x00400022)

/********************************************************************************************
**	Timer Port addresses
*********************************************************************************************/

#define Timer1Data      *(volatile unsigned char *)(0x00400030)
#define Timer1Control   *(volatile unsigned char *)(0x00400032)
#define Timer1Status    *(volatile unsigned char *)(0x00400032)

#define Timer2Data      *(volatile unsigned char *)(0x00400034)
#define Timer2Control   *(volatile unsigned char *)(0x00400036)
#define Timer2Status    *(volatile unsigned char *)(0x00400036)

#define Timer3Data      *(volatile unsigned char *)(0x00400038)
#define Timer3Control   *(volatile unsigned char *)(0x0040003A)
#define Timer3Status    *(volatile unsigned char *)(0x0040003A)

#define Timer4Data      *(volatile unsigned char *)(0x0040003C)
#define Timer4Control   *(volatile unsigned char *)(0x0040003E)
#define Timer4Status    *(volatile unsigned char *)(0x0040003E)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/*********************************************************************************************
**	PIA 1 and 2 port addresses
*********************************************************************************************/

#define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
#define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
#define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
#define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)

#define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
#define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
#define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
#define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)


/*********************************************************************************************************************************
(( DO NOT initialise global variables here, do it main even if you want 0
(( it's a limitation of the compiler
(( YOU HAVE BEEN WARNED
*********************************************************************************************************************************/

unsigned int i, x, y, z, PortA_Count;
unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;

/*******************************************************************************************
** Function Prototypes
*******************************************************************************************/
void Wait1ms(void);
void Wait3ms(void);
void Init_LCD(void) ;
void LCDOutchar(int c);
void LCDOutMess(char *theMessage);
void LCDClearln(void);
void LCDline1Message(char *theMessage);
void LCDline2Message(char *theMessage);
int sprintf(char *out, const char *format, ...) ;

/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/

void Timer_ISR()
{
   	if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
   	    Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
   	}

  	if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
   	    Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
   	}

   	if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
   	    Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
   	}

   	if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
   	    Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
   	}
}

/*****************************************************************************************
**	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void ACIA_ISR()
{}

/***************************************************************************************
**	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void PIA_ISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 2 on DE1 board. Add your own response here
************************************************************************************/
void Key2PressISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 1 on DE1 board. Add your own response here
************************************************************************************/
void Key1PressISR()
{}

/************************************************************************************
**   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
************************************************************************************/
void Wait1ms(void)
{
    int  i ;
    for(i = 0; i < 1000; i ++)
        ;
}

/************************************************************************************
**  Subroutine to give the 68000 something useless to do to waste 3 mSec
**************************************************************************************/
void Wait3ms(void)
{
    int i ;
    for(i = 0; i < 3; i++)
        Wait1ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
**  Sets it for parallel port and 2 line display mode (if I recall correctly)
*********************************************************************************************/
void Init_LCD(void)
{
    LCDcommand = 0x0c ;
    Wait3ms() ;
    LCDcommand = 0x38 ;
    Wait3ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
    RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do not call this function directly, instead you call the normal putchar() function
**  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
**  call _putch() also
*********************************************************************************************************/

int _putch( int c)
{
    while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal getchar() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
**  call _getch() also
*********************************************************************************************************/
int _getch( void )
{
    char c ;
    while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
}

/******************************************************************************
**  Subroutine to output a single character to the 2 row LCD display
**  It is assumed the character is an ASCII code and it will be displayed at the
**  current cursor position
*******************************************************************************/
void LCDOutchar(int c)
{
    LCDdata = (char)(c);
    Wait1ms() ;
}

/**********************************************************************************
*subroutine to output a message at the current cursor position of the LCD display
************************************************************************************/
void LCDOutMessage(char *theMessage)
{
    char c ;
    while((c = *theMessage++) != 0)     // output characters from the string until NULL
        LCDOutchar(c) ;
}

/******************************************************************************
*subroutine to clear the line by issuing 24 space characters
*******************************************************************************/
void LCDClearln(void)
{
    int i ;
    for(i = 0; i < 24; i ++)
        LCDOutchar(' ') ;       // write a space char to the LCD display
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 1 and clear that line
*******************************************************************************/
void LCDLine1Message(char *theMessage)
{
    LCDcommand = 0x80 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0x80 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 2 and clear that line
*******************************************************************************/
void LCDLine2Message(char *theMessage)
{
    LCDcommand = 0xC0 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0xC0 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/*********************************************************************************************************************************
**  IMPORTANT FUNCTION
**  This function install an exception handler so you can capture and deal with any 68000 exception in your program
**  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
**  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
**  Calling this function allows you to deal with Interrupts for example
***********************************************************************************************************************************/

void InstallExceptionHandler( void (*function_ptr)(), int level)
{
    volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor

    RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
}

void main()
{
    unsigned char   data_option = 'U';  //Char U will be unassigned value in case system reset without sram cleaned
    unsigned char   data_pattern = 'U';
    unsigned int    input_data = NULL;
    unsigned int    num_of_bits = NULL;
    unsigned int    start_address = NULL;
    unsigned int    start_address_valid = 0;
    unsigned int    end_address = NULL;
    unsigned int    end_address_valid = 0;
    unsigned int    *address_ptr = NULL;
    unsigned int    address_counter = 0;
    
    Init_RS232();
    scanflush();

    //Option of carrying out a test using byte words or longwords
    while((data_option != 'A' && data_option != 'B' && data_option != 'C') || data_option == 'U')
    {
        printf("\r\nChoose the data type you want to test\n");
        printf("A-BYTES    B-WORDS    C-LONG WORDS\n");
        scanf("%c", &data_option);
        if(data_option != 'A' && data_option != 'B' && data_option != 'C')
            printf("Input Not Valid\n");
    }
    switch(data_option)
    {
        case 'A':
            num_of_bits = 8;
            break;
        case 'B':
            num_of_bits = 16;
            break;
        case 'C':
            num_of_bits = 32;
            break;
        default:
            printf("\r\nFunction Exception of Wrong Data type");
            break;
    }
    printf("\r\nData Option Choosen. # of bits is %i\n", num_of_bits);

    //Option of choosing data patterns
    while((data_pattern != 'A' && data_pattern != 'B' && data_pattern != 'C' && data_pattern != 'D') || data_pattern == 'U')
    {
        printf("\r\nChoose the data pattern you want to use\n");
        printf("A-55    B-AA    C-FF    D-00\n");
        scanf("%c", &data_pattern);
        if(data_pattern != 'A' && data_pattern != 'B' && data_pattern != 'C' && data_pattern != 'D')
            printf("\r\nInput Not Valid\n");
    }
    switch(data_pattern)
    {
        case 'A':
            input_data = 0x55;
            break;
        case 'B':
            input_data = 0xAA;
            break;
        case 'C':
            input_data = 0xFF;
            break;
        case 'D':
            input_data = 0x00;
            break;
        default:
            printf("\r\nFucntion Exception of Wrong Data Pattern");
            break;
    }
    printf("\r\nData Pattern Choosen. The Pattern is %02X\n", input_data);

    //Prompt for a start and end address 
    while(!start_address_valid)
    {
        printf("\r\nPlease enter Start Address\n");
        scanf("%x", &start_address);
        printf(start_address);
        printf("\n");
        if(start_address < 0x08020000)
            printf("\r\nStart Address must > 0x08020000");
        else if((num_of_bits >= 16) && (start_address % 2 != 0))
            printf("\r\nFor data type WORDS & LONG WORDS, address must be even");
        else
            start_address_valid = 1;  
    }

    while(!end_address_valid)
    {
        printf("\r\nPlease enter End Address\n");
        scanf("%x", &end_address);
        if(end_address > 0x08030000)
            printf("End Address must < 0x08030000\n");
        else if((num_of_bits >= 16) && (start_address % 2 != 0))
            printf("For data type WORDS & LONG WORDS, address must be even\n");
        else
            end_address_valid = 1;  
    }

    //READ AND WRITE BIT
    switch(num_of_bits)
    {
        case 8:
            for(address_ptr = start_address; address_ptr <= end_address; address_ptr += 1)
            {
                *address_ptr = input_data;
                if(address_counter % 1280 == 0)
                {
                    printf("\r\nCurrent Progress: Address %08x Write Data %02X Read Data %02X",
                    address_ptr, input_data, *address_ptr);
                }
                address_counter++;
            }
        break;
        case 16:
            for(address_ptr = start_address; *address_ptr <= end_address; address_ptr += 2)
            {
                *address_ptr = input_data;
                *(address_ptr + 1) = input_data;
                if(address_counter % 1280 == 0)
                {
                    printf("\r\nCurrent Progress: Address %08x Write Data %02X%02X Read Data %02X%02X",
                    address_ptr, input_data, input_data, *address_ptr, *(address_ptr + 1));
                }
                address_counter++;
                address_counter++;
            }
        break;
        case 32:
            for(address_ptr = start_address; address_ptr <= end_address; address_ptr += 4)
            {
                *address_ptr = input_data;
                *(address_ptr + 1) = input_data;
                *(address_ptr + 2) = input_data;
                *(address_ptr + 3) = input_data;
                if(address_counter % 1280 == 0)
                {
                    printf("\r\nCurrent Progress: Address %08x Write Data %02X%02X%02X%02X Read Data %02X%02X%02X%02X",
                    address_ptr, input_data, input_data, input_data, input_data, *address_ptr, *(address_ptr + 1), *(address_ptr + 2), *(address_ptr + 3));
                }
                address_counter++;
                address_counter++;
                address_counter++;
                address_counter++;
            }
        break;
        default:
            printf("\r\nFucntion Exception on READ and WRITE stage");
        break;
    }
    printf("\r\nTest Completed. Press KEY0 to Restart");
    while(1);
}