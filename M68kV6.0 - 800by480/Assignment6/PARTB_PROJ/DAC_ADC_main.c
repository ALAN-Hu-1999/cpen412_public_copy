#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define TRUE 1
#define FALSE 0
#define SUCCESS 1
#define FAILURE 0
#define ACK 1
#define NO_ACK 0

#define ADC_DAC_DEVICE_ADDR       0x48 // A2, A1, A0 all tied to GND

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

unsigned char DidDeviceACK(void)
{
    return (I2C_CMD_STATUS & 0x80U) ? NO_ACK : ACK;
}



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

void I2C_ReadByte(unsigned int with_nack, unsigned char with_stop_bit, unsigned char* byte_read)
{
    unsigned char cmd_buf = 0x00U;

    if (with_nack)
    {
        I2C_SetAckBitCommand(&cmd_buf); // NOTE: Send NACK after reception of data by setting ACK = ‘1’ 
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