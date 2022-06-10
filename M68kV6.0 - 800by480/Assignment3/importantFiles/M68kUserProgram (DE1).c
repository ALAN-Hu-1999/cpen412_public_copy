#include <stdio.h>
#include <string.h>
#include <ctype.h>


//IMPORTANT
//
// Uncomment one of the two #defines below
// Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
// 0B000000 for running programs from dram
//
// In your labs, you will initially start by designing a system with SRam and later move to
// Dram, so these constants will need to be changed based on the version of the system you have
// building
//
// The working 68k system SOF file posted on canvas that you can use for your pre-lab
// is based around Dram so #define accordingly before building

//#define StartOfExceptionVectorTable 0x08030000
#define StartOfExceptionVectorTable 0x0B000000

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

int TestForSPITransmitDataComplete(void);
void SPI_Init(void);
void WaitForSPITransmitComplete(void);
void WaitWriteSPIComplete(void);
int WriteSPIChar(int c);
void WriteSPIData(char *memory_address, int flash_address, int size);
void ReadSPIData(char *memory_address, int flash_address, int size);
void EraseSPIFlashChip(void);
void WriteSPIInstruction(int instruction);


/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/

void Timer_ISR()
{

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

// SPI Registers
#define SPI_Control         (*(volatile unsigned char *)(0x00408020))
#define SPI_Status          (*(volatile unsigned char *)(0x00408022))
#define SPI_Data            (*(volatile unsigned char *)(0x00408024))
#define SPI_Ext             (*(volatile unsigned char *)(0x00408026))
#define SPI_CS              (*(volatile unsigned char *)(0x00408028))
#define Enable_SPI_CS() SPI_CS = 0xFE
#define Disable_SPI_CS() SPI_CS = 0xFF

//SPI FUNCTIONS:

int TestForSPITransmitDataComplete(void) {
 /* TODO replace 0 below with a test for status register SPIF bit and if set, return true */
    if(SPI_Status & 0X80)   // check SPIF flag
        return 1;
    else
        return 0;
}

void SPI_Init(void)
{
 //TODO
 //
 // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
 // Don't forget to call this routine from main() before you do anything else with SPI
 //
 // Here are some settings we want to create
 //
 // Control Reg - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed = divide by 32 = approx 700Khz
 // Ext Reg - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
 // SPI_CS Reg - control selection of slave SPI chips via their CS# signals
 // Status Reg - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag
 // CONTROL reg:     0x53    ||  Extension reg:      0x00    ||  SPI_CS Reg: 0xFE    ||  Status Reg:         0XC5
 // [7] interrupt:   0       ||  [7:6] interrupt:    00      ||  [7:0] active low CS ||  [7] SPIF:           1
 // [6] core:        1       ||  [5:2] reserved:     0000    ||                      ||  [6] WCOL:           1
 // [5] reserved:    0       ||  [1:0] speed:        11      ||                      ||  [5:4] reserved:     00
 // [4] master mode: 1       ||                              ||                      ||  [3:2] WFFULL/EMPTY: 01
 // [3:2] pol,clk:   00      ||                              ||                      ||  [1:0] RFFULL/EMPTY: 01
 // [1:0] speed:     00      ||                              ||                      ||
    SPI_Control = 0X53;
    SPI_Ext = 0X00;
    Disable_SPI_CS(); // prededined function setting SPI_CS reg
}

void WaitForSPITransmitComplete(void)
{
 // TODO : poll the status register SPIF bit looking for completion of transmission
 // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
 // just in case they were set
    while(!TestForSPITransmitDataComplete()){}   // check SPIF if data transmit is complete
    SPI_Status |= 0xC0;  // set SPIF & WCOL to clear the flag, notsure about [3:0] since we dont have access wrting them
}

void WaitWriteSPIComplete(void)
{
    Enable_SPI_CS();
    WriteSPIChar(0x05);
    while(WriteSPIChar(0x00) & 0x01);
    Disable_SPI_CS();
}

int WriteSPIChar(int c)
{
 // todo - write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
 // wait for completion of transmission
 // return the received data from Flash chip (which may not be relevent depending upon what we are doing)
 // by reading fom the SPI controller Data Register.
 // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
 //
 // modify '0' below to return back read byte from data register
 //
    // check fot the SPE flag, if set, write
    // have to write dummy valve if read
    int buffer;
    SPI_Data = c;
    // wait for transimission to complete
    WaitForSPITransmitComplete();  

    buffer = SPI_Data;
    // clear FIFO if it is full
    return buffer; 
}

void WriteSPIData(char *memory_address, int flash_address, int size)
{
    int i = 0;

    Enable_SPI_CS();
    WriteSPIChar(0x06);
    Disable_SPI_CS();

    Enable_SPI_CS();
    WriteSPIChar(0x02);
    WriteSPIChar(flash_address >> 16);
    WriteSPIChar(flash_address >> 8);
    WriteSPIChar(flash_address);
    for(i = 0; i < size; i++)
    {
        WriteSPIChar(memory_address[i]);
    }
    Disable_SPI_CS();
    WaitWriteSPIComplete();    
}

void ReadSPIData(char *memory_address, int flash_address, int size)
{
    int i = 0;

    Enable_SPI_CS();
    WriteSPIChar(0x03);
    WriteSPIChar(flash_address >> 16);
    WriteSPIChar(flash_address >> 8);
    WriteSPIChar(flash_address);
    for(i = 0; i < size; i++)
    {
        memory_address[i] = (unsigned char) WriteSPIChar(0x00); 
    }
    Disable_SPI_CS();
}

void EraseSPIFlashChip(void)
{
    // Write enable
    printf("\r\n    EraseSPIFlashChip:espfc before write 06");
    WriteSPIInstruction(0x06);
    printf("\r\n    EraseSPIFlashChip:espfc before write 07");
    // Chip Erase, c7 or 60 both work
    WriteSPIInstruction(0xC7);
    printf("\r\n    EraseSPIFlashChip:espfc wait for complete");
    WaitWriteSPIComplete();
    printf("\r\nEraseSPIFlash Complete!");
}

void WriteSPIInstruction(int instruction)
{
    Enable_SPI_CS();
    WriteSPIChar(instruction);
    Disable_SPI_CS();
}





/******************************************************************************************************************************
* Start of user program
******************************************************************************************************************************/

void main()
{
    unsigned int row, i=0, count=0, counter1=1, j=0;
    char c, text[150] ;

    unsigned char write_buffer[256];
    unsigned char read_buffer[256];
    int flash_address = 2048;

    unsigned char input_char;

    Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
    Init_RS232() ;          // initialise the RS232 port for use with hyper terminal

    //Call SPI Functions
    SPI_Init();

    printf("\r\nSelect Test Method:");
    printf("\r\nA-Auto Test     B-User Test");
    input_char = getchar();
    if(input_char == 'B')
    {
        printf("\r\nTesting SPI with User Input Value: (Exit by Press KEY[0])");
        while(1)
        {
            printf("\r\nWrite to SPI: ");
            input_char = getchar();
            putchar(input_char);
            WriteSPIData(input_char, 0, 1);
            ReadSPIData(input_char, 0, 1);
            printf("\r\nRead from SPI: %c", input_char);
        }
    }
    else if(input_char != 'A')
    {
        printf("\r\n=Invalid Input. System will run Auto Test instead.");
    }

    printf("\r\nAUTO Test Start:");
    for(i = 0; i < sizeof(read_buffer); i++)
        read_buffer[i] = 0;
    for(i = 0; i < sizeof(write_buffer); i++)
        write_buffer[i] = i;

    printf("\r\nErasing SPI Flash Chip");
    EraseSPIFlashChip();
    printf("\r\nWrite value <0:255> to flash chip");
    for(i = 0; i < 2048; i++)
    {
        WriteSPIData(write_buffer, flash_address, sizeof(write_buffer));
        flash_address += 256;
        if((i % 100) == 0)
            printf("..");
    }
    printf("\r\nWrite to Flash Chip Complete!");

    flash_address = 2048;

    printf("\r\nRead from flash chip");
    for(i = 0; i < 2048; i++)
    {
        ReadSPIData(read_buffer, flash_address, sizeof(read_buffer));
        flash_address += 256;
        if((i % 100) == 0)
            printf("..");
        for (j = 0; j < sizeof(read_buffer); j++)
        {
            if(write_buffer[j] != read_buffer[j])
            {
                printf("\r\nError found at %d. Writebuffer:%02x. Readbuffer:%02x", j, write_buffer[j], read_buffer[j]);
                printf("\r\nTest Process Terminated with MISMATCH Error. Press KEY[0]");
                while(1);
            }

        }
    }
    printf("\r\nTest Process Completed with No Error!");

    while(1)
    {
        if(_getch() == 0x1b)          // break on ESC
            break;
    }
    

   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}