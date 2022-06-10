#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define TRUE 1
#define FALSE 0
#define SUCCESS 1
#define FAILURE 0
#define ACK 1
#define NO_ACK 0

#define EEPROM_DEVICE_ADDR_BLOCK0 0x50 // Block 0, A1 and A0 inputs tied to GND
#define ADC_DAC_DEVICE_ADDR       0x48 // A2, A1, A0 all tied to GND

#define StartOfExceptionVectorTable 0x0B000000

//Function for assignment 5 referenced from Boran Gungor(51382745) & Timothy Nguyen(80663560)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/*************************************************************
** I2C Controller registers
**************************************************************/

#define I2C_PSC_LOW         (*(volatile unsigned char *)(0x00408000))
#define I2C_PSC_HIGH        (*(volatile unsigned char *)(0x00408002))
#define I2C_CONTROL         (*(volatile unsigned char *)(0x00408004))
#define I2C_TX_RX           (*(volatile unsigned char *)(0x00408006))
#define I2C_CMD_STATUS      (*(volatile unsigned char *)(0x00408008))

unsigned char I2C_GenerateSineWave();

/*********************************************************************************************************************************
(( DO NOT initialise global variables here, do it main even if you want 0
(( it's a limitation of the compiler
(( YOU HAVE BEEN WARNED
*********************************************************************************************************************************/

unsigned char rx_buf[131072];  // Receiver buffer for testing multiple byte EEPROM reads
unsigned char cmp_buf[131072]; // Compare buffer for testing multiple byte EEPROM reads

/*******************************************************************************************
** Function Prototypes
*******************************************************************************************/
void Wait1ms(void);
void Wait3ms(void);

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

void Wait25ms(void)
{
    int i ;
    for(i = 0; i < 25; i++)
        Wait1ms() ;
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

void InitI2C(void)
{
    // Prescaler for 100 Khz I2C clock
    // = (25 MHz) / (5 * 100 KHz)  - 1 = 0x0031
    I2C_PSC_LOW = 0x31U;
    I2C_PSC_HIGH = 0x00U;

    // Enable I2C core, disable interrupt generation
    I2C_CONTROL = 0x80U;
}

void I2C_SetStartBitCommand(unsigned char* cmd_buf)
{
    *cmd_buf |= (0x01U << 7);
}

void I2C_SetStopBitCommand(unsigned char* cmd_buf)
{
    *cmd_buf |= (0x01U << 6);
}

void I2C_SetReadBitCommand(unsigned char* cmd_buf)
{
    *cmd_buf |= (0x01U << 5);
}

void I2C_SetWriteBitCommand(unsigned char* cmd_buf)
{
    *cmd_buf |= (0x01U << 4);
}

void I2C_SetAckBitCommand(unsigned char* cmd_buf)
{
    *cmd_buf |= (0x01U << 3);
}

void I2C_PerformCommand(unsigned char cmd)
{
    I2C_CMD_STATUS = cmd;
}

void I2C_WaitForTransmissionComplete(void)
{
    // Wait For transfer in progress TIP to be complete
    while(I2C_CMD_STATUS & 0x02U);
}

/**
 * @brief Did the slave device acknowledge the message?
 *
 * @return ACK: Yes
 *         NO_ACK: No
 */
unsigned char DidDeviceACK(void)
{
    return (I2C_CMD_STATUS & 0x80U) ? NO_ACK : ACK;
}

/**
 * @brief Write a byte to I2C device using I2C Controller
 *
 * @param data            Data to write to I2C device
 * @param with_start_bit  TRUE: with start condition, FALSE: w/o start condition
 * @param with_stop_bit   TRUE: with stop condition, FALSE: w/o stop condition
 * @return ACK:    I2C device acknowledged
 *         NO_ACK: I2C device did not acknowledge
 */
unsigned char I2C_WriteByte(unsigned char data, unsigned char with_start_bit, unsigned char with_stop_bit)
{
    unsigned char cmd_buf = 0x00U;
    I2C_TX_RX = data;  // Place data to transmit in transmit register

    if (with_start_bit)
    {
        I2C_SetStartBitCommand(&cmd_buf);       // Set START Bit in command register
    }

    if (with_stop_bit)
    {
        I2C_SetStopBitCommand(&cmd_buf);        // Set STOP Bit in command register
    }

    I2C_SetWriteBitCommand(&cmd_buf);           // Set Write bit in command register
    I2C_PerformCommand(cmd_buf);                // Perform the write command
    I2C_WaitForTransmissionComplete();          // Wait for I2C transmission to complete

    return DidDeviceACK();
}

/**
 * @brief Read a byte from I2C device using I2C Controller
 *
 * @param with_nack_bit   TRUE: send NACK bit on data reception, FALSE: send ACK bit on data reception
 * @param with_stop_bit   TRUE: with stop condition, FALSE: w/o stop condition
 * @param byte_read       Byte read back from I2C device
 */
void I2C_ReadByte(unsigned int with_nack, unsigned char with_stop_bit, unsigned char* byte_read)
{
    unsigned char cmd_buf = 0x00U;

    if (with_nack)
    {
        I2C_SetAckBitCommand(&cmd_buf); // NOTE: Send NACK after reception of data by setting ACK = â€˜1â
    }

    if (with_stop_bit)
    {
        I2C_SetStopBitCommand(&cmd_buf);
    }

    I2C_SetReadBitCommand(&cmd_buf);
    I2C_PerformCommand(cmd_buf);        // Perform read command
    I2C_WaitForTransmissionComplete();

    *byte_read = I2C_TX_RX;     // Read valid data from RX register
}

/**
 * @brief Write a byte to the 128KB EEPROM device
 *
 * @param memory_addr   Address within EEPROM to write byte to [0x00000 to 0x01FFFF]
 * @param data          Byte to be written
 * @return NO_ACK:  EEPROM device did not acknowledge
 *         SUCCESS: Byte written successfully to EEPROM
 */
unsigned char I2C_WriteByteEEPROM(unsigned int memory_addr, unsigned char data)
{
    unsigned char control_byte_write = EEPROM_DEVICE_ADDR_BLOCK0 << 1; // Prepend ~W bit to device address.
    unsigned char memory_address_hi = (memory_addr & 0xFF00U) >> 8;
    unsigned char memory_address_lo = memory_addr & 0xFFU;
    unsigned char err = NO_ACK;

    if (memory_addr > 0x01FFFFU)
    {
        printf("\r\n EEPROM address out of range");
        while(1);
    }
    else if (memory_addr & 0x010000U)
    {
        // If A16 = 1, specify that we're writing to Block 1 [0x10000 - 0x1FFFF]
        control_byte_write |= 0x08U;
    }

    // Write control byte, memory address (HI and LO), and byte of data in sequence
    if (err == I2C_WriteByte(control_byte_write, TRUE, FALSE)) return err; // With start bit
    if (err == I2C_WriteByte(memory_address_hi, FALSE, FALSE)) return err;
    if (err == I2C_WriteByte(memory_address_lo, FALSE, FALSE)) return err;
    if (err == I2C_WriteByte(data, FALSE, TRUE)) return err;                // With stop bit

    // Wait for internal write to complete via acknowledge polling
    while(I2C_WriteByte(control_byte_write, TRUE, TRUE) == NO_ACK);
    printf("\r\n[%02X] written to EEPROM address [%05X]", data, memory_addr);

    return SUCCESS;
}

/**
 * @brief Read a byte from the 128KB EEPROM device.
 *
 * @param memory_addr    Address within EEPROM to write byte to [0x00000 to 0x01FFFF]
 * @param byte_read_back Byte read back from EEPROM device
 * @return NO_ACK:  EEPROM device did not acknowledge back
 *         SUCCESS: Successul read from EEPROM
 */
unsigned char I2C_ReadByteEEPROM(unsigned int memory_addr, unsigned char* byte_read_back)
{
    // Prepend R/~W bit to device address.
    unsigned char control_byte_write = EEPROM_DEVICE_ADDR_BLOCK0 << 1; // Prepend ~W bit to device address.
    unsigned char control_byte_read = control_byte_write | 0x01U;       // Prepend R bit to device address.
    unsigned char memory_address_hi = (memory_addr & 0xFF00U) >> 8;
    unsigned char memory_address_lo = memory_addr & 0xFFU;
    unsigned char err = NO_ACK;

    if (memory_addr > 0x01FFFFU)
    {
        printf("\r\n EEPROM address out of range");
        while(1);
    }
    else if (memory_addr & 0x010000U)
    {
        // If A16 = 1, specify that we're reading from Block 1 [0x10000 - 0x1FFFF]
        control_byte_write |= 0x08U;
        control_byte_read |= 0x08U;
    }

    // Write memory address to read fromto internal address pointer first
    if (err == I2C_WriteByte(control_byte_write, TRUE, FALSE)) return err; // With start bit
    if (err == I2C_WriteByte(memory_address_hi, FALSE, FALSE)) return err;
    if (err == I2C_WriteByte(memory_address_lo, FALSE, FALSE)) return err;

    // Now request read from memory location
    if (err == I2C_WriteByte(control_byte_read, TRUE, FALSE)) return err; // With repeated start condition

    // Read from memory address
    I2C_ReadByte(TRUE, TRUE, byte_read_back); // With NACK and STOP condition
    printf("\r\nRead [%02X] from EEPROM address [%05X]", *byte_read_back, memory_addr);
    return SUCCESS;
}

/**
 * @brief Write multiple bytes to 128 KB EEPROM
 *
 * @param starting_memory_addr  Starting address within EEPROM to write bytes to [0x00000 to 0x01FFFF]
 * @param num_of_bytes Number of bytes to write to EEPROM
 * @return SUCCESS Bytes successfully written to device
 *         NO_ACK  EEPROM did not acknowledge device
 */
unsigned char I2C_WriteMultipleBytesEEPROM(unsigned int starting_memory_addr, unsigned int num_of_bytes)
{
    unsigned char control_byte_write = EEPROM_DEVICE_ADDR_BLOCK0 << 1; // Prepend ~W bit to device address.
    unsigned char memory_address_hi, memory_address_lo;
    unsigned int current_memory_addr = starting_memory_addr;
    unsigned int bytes_written = 0, page_bytes_written = 0, page_bytes_to_write = 0;
    unsigned char page_bytes_available; // Number of bytes available to write sequentially in page
    unsigned char err = NO_ACK;
    unsigned char data = 0x00U;

    if (starting_memory_addr > 0x01FFFFU)
    {
        printf("\r\nMemory address greater than 0x01FFFF");
        while(1);
    }

    // Iterate through each page of the EEPROM until all bytes have been written
    for(bytes_written = 0; bytes_written < num_of_bytes; bytes_written += page_bytes_written)
    {
        // Determine number of available bytes in the current page without wrap around
        // starting at current memory address (Maximum = 128 bytes).
        page_bytes_available = 128U - (current_memory_addr % 128U);

        // Determine number of bytes to write to current page
        page_bytes_to_write = (num_of_bytes - bytes_written) < page_bytes_available ?
                              (num_of_bytes - bytes_written) : page_bytes_available;

        // Wrap around if we went over the EEPROM boundary
        if (current_memory_addr > 0x01FFFFU)
        {
            current_memory_addr = 0x00000U;
        }

        // Determine block number required in control byte
        if (current_memory_addr & 0x010000U)
        {
            // If A16 = 1, specify that we're writing to Block 1 [0x10000 - 0x1FFFF]
            control_byte_write |= 0x08U;
        }
        else
        {
            // If A16 = 0, specify that we're writing to Block 0 [0x00000 - 0x0FFFF]
            control_byte_write &= ~0x08U;
        }

        // Separate high and low byte of 16-bit memory address
        memory_address_hi = (current_memory_addr & 0xFF00U) >> 8;
        memory_address_lo = current_memory_addr & 0xFFU;

         // Write control byte, memory address (HI and LO), and byte(s) of data in sequence
        if (err == I2C_WriteByte(control_byte_write, TRUE, FALSE)) return err; // With start bit
        if (err == I2C_WriteByte(memory_address_hi, FALSE, FALSE)) return err;
        if (err == I2C_WriteByte(memory_address_lo, FALSE, FALSE)) return err;

        for (page_bytes_written = 0; page_bytes_written < page_bytes_to_write; page_bytes_written++)
        {
            if(page_bytes_written < page_bytes_to_write - 1U)
            {
                if (err == I2C_WriteByte(data, FALSE, FALSE)) return err; // Write data w/o stop bit
            }
            else
            {
                if (err == I2C_WriteByte(data, FALSE, TRUE)) return err;  // Write last byte of data w/ stop bit
            }

            data++; // Increment data byte for testing
        }

        // Wait for internal write to complete via acknowledge polling
        while(I2C_WriteByte(control_byte_write, TRUE, TRUE) == NO_ACK);
        printf("\r\n%d bytes written to EEPROM starting at address [%05X]",
                page_bytes_written, current_memory_addr);

        current_memory_addr += page_bytes_written;
    }

    printf("\r\n%d bytes successfully written to the EEPROM", num_of_bytes);
    return SUCCESS;
}

/**
 * @brief Read multiple bytes from 128 KB EEPROM
 *
 * @param starting_memory_addr Starting memory address within EEPROM to read bytes [0x00000 to 0x01FFFF]
 * @param num_of_bytes         Number of bytes to read
 * @param data_buf             Buffer where bytes read are stored to
 * @return SUCCESS Bytes successfully read from device
 *         NO_ACK  EEPROM did not acknowledge device
 */
unsigned char I2C_ReadMultipleBytesEEPROM(unsigned int starting_memory_addr, unsigned int num_of_bytes, unsigned char * data_buf)
{
     // Prepend R/~W bit to device address.
    unsigned char control_byte_write = EEPROM_DEVICE_ADDR_BLOCK0 << 1; // Prepend ~W bit to device address.
    unsigned char control_byte_read = control_byte_write | 0x01U;      // Prepend R bit to device address.
    unsigned int current_memory_addr = starting_memory_addr;
    unsigned char memory_address_hi, memory_address_lo;
    unsigned int bytes_read = 0, block_bytes_read = 0, block_bytes_to_read = 0;
    unsigned int block_bytes_available; // Number of bytes available in block to be read from sequentially
    unsigned char err = NO_ACK;

    if (starting_memory_addr > 0x01FFFFU)
    {
        printf("\r\nMemory address greater than 0x01FFFF");
        while(1);
    }

    // Iterate through each block until all bytes have been read
    for (bytes_read = 0; bytes_read < num_of_bytes; bytes_read += block_bytes_read)
    {
        // Determine number of bytes available to read from block sequentially without wrap around
        // starting at current memory address (Maximum = 64 KB)
        block_bytes_available = 0x10000U - (current_memory_addr % 0x10000U);

         // Determine number of bytes to read from current block
        block_bytes_to_read = (num_of_bytes - bytes_read) < block_bytes_available ?
                              (num_of_bytes - bytes_read) : block_bytes_available;

        // Determine block number required in control byte
        if (current_memory_addr & 0x010000U)
        {
            // If A16 = 1, specify that we're reading from Block 1 [0x10000 - 0x1FFFF]
            control_byte_write |= 0x08U;
            control_byte_read |= 0x08U;
        }
        else
        {
            // If A16 = 0, specify that we're writing to Block 0 [0x00000 - 0x0FFFF]
            control_byte_write &= ~0x08U;
            control_byte_read &= ~0x08U;
        }

        // Separate high and low byte of 16-bit memory address
        memory_address_hi = (current_memory_addr & 0xFF00U) >> 8;
        memory_address_lo = current_memory_addr & 0xFFU;

         // Write memory address to read from to internal address pointer first
        if (err == I2C_WriteByte(control_byte_write, TRUE, FALSE)) return err; // With start condition
        if (err == I2C_WriteByte(memory_address_hi, FALSE, FALSE)) return err;
        if (err == I2C_WriteByte(memory_address_lo, FALSE, FALSE)) return err;

        // Now request read from memory location
        if (err == I2C_WriteByte(control_byte_read, TRUE, FALSE)) return err; // With repeated start condition

        // Read bytes from EEPROM block
        for (block_bytes_read = 0; block_bytes_read < block_bytes_to_read; block_bytes_read++)
        {
            if (block_bytes_read < block_bytes_to_read - 1U)
            {
                I2C_ReadByte(FALSE, FALSE, data_buf + bytes_read + block_bytes_read); // With ACK and no STOP condition
            }
            else
            {
                I2C_ReadByte(TRUE, TRUE, data_buf + bytes_read + block_bytes_read); // With NACK and STOP condition
            }
        }

        printf("\r\n%d bytes read starting at memory address [%05X]", block_bytes_read, current_memory_addr);

        // If we were reading from block 0, read from block 1 now and vice-versa
        current_memory_addr = current_memory_addr < 0x10000U ? 0x10000U : 0x00000U;
    }

    printf("\r\n%d bytes successfully read from EEPROM", bytes_read);
    return SUCCESS;
}

/**
 * @brief Read the ADC value of a channel
 *
 * @param adc_channel ADC Channel # (0-3)
 * @param adc_val     Corresponding ADC value
 * @return unsigned char SUCCESS: ADC value successfully read
 *                       NO_ACK:  ADC/DAC device did not acknowledge 68K
 */
unsigned char I2C_ReadADCChannel(unsigned char adc_channel, unsigned char * adc_val)
{
    // Prepend R/~W bit to device address.
    unsigned char address_byte_write = ADC_DAC_DEVICE_ADDR << 1;  // Prepend ~W bit to device address.
    unsigned char address_byte_read = address_byte_write | 0x01U; // Prepend R bit to device address.
    unsigned char control_byte = 0x00U;
    unsigned char err = NO_ACK;

    if(adc_channel > 3)
    {
        printf("\r\nMust select ADC channel between 0 and 3");
        while(1);
    }
    else
    {
        control_byte = adc_channel; // Read single-ended ADC channel w/o auto increment, analog output disabled
    }

    // Write to control register first
    if (err == I2C_WriteByte(address_byte_write, TRUE, FALSE)) return err; // With start bit
    if (err == I2C_WriteByte(control_byte, FALSE, FALSE)) return err;

     // Now request read of ADC conversion
    if (err == I2C_WriteByte(address_byte_read, TRUE, FALSE)) return err; // With repeated start condition

     // Read ADC conversion
    I2C_ReadByte(FALSE, FALSE, adc_val); // Ignore previously converted byte
    I2C_ReadByte(TRUE, TRUE, adc_val);   // With NACK and STOP condition
    return SUCCESS;
}

/**
 * @brief Generate sine wave
 *
 * @return SUCCESS: Sine wave generated successfully
 *         NO_ACK:  ADC/DAC device not acknowledge 68K
 */
unsigned char I2C_GenerateSineWave()
{
    // C 8-bit Sine Table
    // Taken from https://www.electro-tech-online.com/threads/sine-look-up-table-for-generating-sine-wave-using-pwm.96302/
    const unsigned char sinetable[256] = {
    128,131,134,137,140,143,146,149,152,156,159,162,165,168,171,174,
    176,179,182,185,188,191,193,196,199,201,204,206,209,211,213,216,
    218,220,222,224,226,228,230,232,234,236,237,239,240,242,243,245,
    246,247,248,249,250,251,252,252,253,254,254,255,255,255,255,255,
    255,255,255,255,255,255,254,254,253,252,252,251,250,249,248,247,
    246,245,243,242,240,239,237,236,234,232,230,228,226,224,222,220,
    218,216,213,211,209,206,204,201,199,196,193,191,188,185,182,179,
    176,174,171,168,165,162,159,156,152,149,146,143,140,137,134,131,
    128,124,121,118,115,112,109,106,103,99, 96, 93, 90, 87, 84, 81,
    79, 76, 73, 70, 67, 64, 62, 59, 56, 54, 51, 49, 46, 44, 42, 39,
    37, 35, 33, 31, 29, 27, 25, 23, 21, 19, 18, 16, 15, 13, 12, 10,
    9, 8, 7, 6, 5, 4, 3, 3, 2, 1, 1, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 3, 4, 5, 6, 7, 8,
    9, 10, 12, 13, 15, 16, 18, 19, 21, 23, 25, 27, 29, 31, 33, 35,
    37, 39, 42, 44, 46, 49, 51, 54, 56, 59, 62, 64, 67, 70, 73, 76,
    79, 81, 84, 87, 90, 93, 96, 99, 103,106,109,112,115,118,121,124
    };
    unsigned char address_byte_write = ADC_DAC_DEVICE_ADDR << 1; // Prepend ~W bit to device address.
    unsigned char err = NO_ACK;
    unsigned char control_byte = 0x40; // Enable analog output
    unsigned int cycle = 0, num_of_cycles = 3;
    unsigned int i = 0;

    // Write to control register first
    if (err == I2C_WriteByte(address_byte_write, TRUE, FALSE)) return err; // With start bit
    if (err == I2C_WriteByte(control_byte, FALSE, FALSE)) return err;

    // Generate sine-wave
    for (cycle = 0; cycle < num_of_cycles; cycle++)
    {
        for(i = 0; i < 256; i++)
        {
            if ((cycle == num_of_cycles - 1) && (i == 255))
            {
                // Write last byte of data with stop bit
                if (err == I2C_WriteByte(sinetable[i], FALSE, TRUE)) return err;
            }
            else
            {
               if (err == I2C_WriteByte(sinetable[i], FALSE, FALSE)) return err; // W/o stop bit
            }

            Wait25ms();
        }
    }

    return SUCCESS;
}


void main()
{
    unsigned int memory_addr_test, memory_addr_test_multiple_bytes;
    unsigned int data_to_write_long;
    unsigned char data_to_write;
    unsigned char data_read_back = 0xFFU;
    unsigned int bytes_to_read;
    unsigned int i = 0;
    unsigned char fake_data = 0;
    unsigned char adc_reading = 0xAAU;

    Init_RS232();   // Initialise the RS232 port for use with hyper terminal
    InitI2C();      // Initialize I2C controller

    scanflush();

    memset(rx_buf, 0, 131072); // Clear rx buffer

    // Generate Sine Wave on LED
    printf("\r\nGenerating sine wave on LED");
    //I2C_GenerateSineWave();
    printf("\r\nPress m to continue");
    while(getchar() != 'm');

    // Read through each ADC channel
    while(1)
    {
        for(i = 0; i < 4; i++)
        {
            if(I2C_ReadADCChannel(i, &adc_reading) != NO_ACK)
            {
                printf("[Ch. %d] %d ", i, adc_reading);
            }
            else
            {
                printf("\r\nADC/DAC did not acknowledge back");
                while(1);
            }
        }
        printf("\r\n");
    }

    while(1);

}