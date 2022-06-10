; C:\M68KV6.0 - 800BY480\ASSIGNMENT6\PARTB_PROJ\DAC_ADC_MAIN.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; #define TRUE 1
; #define FALSE 0
; #define SUCCESS 1
; #define FAILURE 0
; #define ACK 1
; #define NO_ACK 0
; #define ADC_DAC_DEVICE_ADDR       0x48 // A2, A1, A0 all tied to GND
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; /*************************************************************
; ** I2C Controller registers
; **************************************************************/
; #define I2C_PSC_LOW         (*(volatile unsigned char *)(0x00408000))
; #define I2C_PSC_HIGH        (*(volatile unsigned char *)(0x00408002))
; #define I2C_CONTROL         (*(volatile unsigned char *)(0x00408004))
; #define I2C_TX_RX           (*(volatile unsigned char *)(0x00408006))
; #define I2C_CMD_STATUS      (*(volatile unsigned char *)(0x00408008))
; void InitI2C(void)
; {
       section   code
       xdef      _InitI2C
_InitI2C:
; // Prescaler for 100 Khz I2C clock
; // = (25 MHz) / (5 * 100 KHz)  - 1 = 0x0031
; I2C_PSC_LOW = 0x31U;
       move.b    #49,4227072
; I2C_PSC_HIGH = 0x00U;
       clr.b     4227074
; // Enable I2C core, disable interrupt generation
; I2C_CONTROL = 0x80U;
       move.b    #128,4227076
       rts
; }
; void I2C_SetStartBitCommand(unsigned char* cmd_buf)
; {
       xdef      _I2C_SetStartBitCommand
_I2C_SetStartBitCommand:
       link      A6,#0
; *cmd_buf |= (0x01U << 7);
       move.l    8(A6),A0
       or.b      #128,(A0)
       unlk      A6
       rts
; }
; void I2C_SetStopBitCommand(unsigned char* cmd_buf)
; {
       xdef      _I2C_SetStopBitCommand
_I2C_SetStopBitCommand:
       link      A6,#0
; *cmd_buf |= (0x01U << 6);
       move.l    8(A6),A0
       or.b      #64,(A0)
       unlk      A6
       rts
; }
; void I2C_SetReadBitCommand(unsigned char* cmd_buf)
; {
       xdef      _I2C_SetReadBitCommand
_I2C_SetReadBitCommand:
       link      A6,#0
; *cmd_buf |= (0x01U << 5);
       move.l    8(A6),A0
       or.b      #32,(A0)
       unlk      A6
       rts
; }
; void I2C_SetWriteBitCommand(unsigned char* cmd_buf)
; {
       xdef      _I2C_SetWriteBitCommand
_I2C_SetWriteBitCommand:
       link      A6,#0
; *cmd_buf |= (0x01U << 4);
       move.l    8(A6),A0
       or.b      #16,(A0)
       unlk      A6
       rts
; }
; void I2C_SetAckBitCommand(unsigned char* cmd_buf)
; {
       xdef      _I2C_SetAckBitCommand
_I2C_SetAckBitCommand:
       link      A6,#0
; *cmd_buf |= (0x01U << 3);
       move.l    8(A6),A0
       or.b      #8,(A0)
       unlk      A6
       rts
; }
; void I2C_PerformCommand(unsigned char cmd)
; {
       xdef      _I2C_PerformCommand
_I2C_PerformCommand:
       link      A6,#0
; I2C_CMD_STATUS = cmd;
       move.b    11(A6),4227080
       unlk      A6
       rts
; }
; void I2C_WaitForTransmissionComplete(void)
; {
       xdef      _I2C_WaitForTransmissionComplete
_I2C_WaitForTransmissionComplete:
; // Wait For transfer in progress TIP to be complete
; while(I2C_CMD_STATUS & 0x02U);
I2C_WaitForTransmissionComplete_1:
       move.b    4227080,D0
       and.b     #2,D0
       beq.s     I2C_WaitForTransmissionComplete_3
       bra       I2C_WaitForTransmissionComplete_1
I2C_WaitForTransmissionComplete_3:
       rts
; }
; unsigned char DidDeviceACK(void)
; {
       xdef      _DidDeviceACK
_DidDeviceACK:
; return (I2C_CMD_STATUS & 0x80U) ? NO_ACK : ACK;
       move.b    4227080,D0
       and.b     #128,D0
       beq.s     DidDeviceACK_1
       clr.b     D0
       bra.s     DidDeviceACK_2
DidDeviceACK_1:
       moveq     #1,D0
DidDeviceACK_2:
       rts
; }
; unsigned char I2C_WriteByte(unsigned char data, unsigned char with_start_bit, unsigned char with_stop_bit)
; {
       xdef      _I2C_WriteByte
_I2C_WriteByte:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       -1(A6),A2
; unsigned char cmd_buf = 0x00U;
       clr.b     (A2)
; I2C_TX_RX = data;  // Place data to transmit in transmit register
       move.b    11(A6),4227078
; if (with_start_bit)
       tst.b     15(A6)
       beq.s     I2C_WriteByte_1
; {
; I2C_SetStartBitCommand(&cmd_buf);       // Set START Bit in command register
       move.l    A2,-(A7)
       jsr       _I2C_SetStartBitCommand
       addq.w    #4,A7
I2C_WriteByte_1:
; }
; if (with_stop_bit)
       tst.b     19(A6)
       beq.s     I2C_WriteByte_3
; {
; I2C_SetStopBitCommand(&cmd_buf);        // Set STOP Bit in command register
       move.l    A2,-(A7)
       jsr       _I2C_SetStopBitCommand
       addq.w    #4,A7
I2C_WriteByte_3:
; }
; I2C_SetWriteBitCommand(&cmd_buf);           // Set Write bit in command register
       move.l    A2,-(A7)
       jsr       _I2C_SetWriteBitCommand
       addq.w    #4,A7
; I2C_PerformCommand(cmd_buf);                // Perform the write command 
       move.b    (A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _I2C_PerformCommand
       addq.w    #4,A7
; I2C_WaitForTransmissionComplete();          // Wait for I2C transmission to complete
       jsr       _I2C_WaitForTransmissionComplete
; return DidDeviceACK();             
       jsr       _DidDeviceACK
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; void I2C_ReadByte(unsigned int with_nack, unsigned char with_stop_bit, unsigned char* byte_read)
; {
       xdef      _I2C_ReadByte
_I2C_ReadByte:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       -1(A6),A2
; unsigned char cmd_buf = 0x00U;
       clr.b     (A2)
; if (with_nack)
       tst.l     8(A6)
       beq.s     I2C_ReadByte_1
; {
; I2C_SetAckBitCommand(&cmd_buf); // NOTE: Send NACK after reception of data by setting ACK = ‘1’ 
       move.l    A2,-(A7)
       jsr       _I2C_SetAckBitCommand
       addq.w    #4,A7
I2C_ReadByte_1:
; }
; if (with_stop_bit)
       tst.b     15(A6)
       beq.s     I2C_ReadByte_3
; {
; I2C_SetStopBitCommand(&cmd_buf); 
       move.l    A2,-(A7)
       jsr       _I2C_SetStopBitCommand
       addq.w    #4,A7
I2C_ReadByte_3:
; }
; I2C_SetReadBitCommand(&cmd_buf);
       move.l    A2,-(A7)
       jsr       _I2C_SetReadBitCommand
       addq.w    #4,A7
; I2C_PerformCommand(cmd_buf);        // Perform read command     
       move.b    (A2),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _I2C_PerformCommand
       addq.w    #4,A7
; I2C_WaitForTransmissionComplete();  
       jsr       _I2C_WaitForTransmissionComplete
; *byte_read = I2C_TX_RX;     // Read valid data from RX register
       move.l    16(A6),A0
       move.b    4227078,(A0)
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; unsigned char I2C_ReadADCChannel(unsigned char adc_channel, unsigned char * adc_val)
; {
       xdef      _I2C_ReadADCChannel
_I2C_ReadADCChannel:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _I2C_WriteByte.L,A2
; // Prepend R/~W bit to device address.
; unsigned char address_byte_write = ADC_DAC_DEVICE_ADDR << 1;  // Prepend ~W bit to device address.
       move.b    #144,D4
; unsigned char address_byte_read = address_byte_write | 0x01U; // Prepend R bit to device address.
       move.b    D4,D0
       or.b      #1,D0
       move.b    D0,-1(A6)
; unsigned char control_byte = 0x00U; 
       clr.b     D3
; unsigned char err = NO_ACK;
       clr.b     D2
; if(adc_channel > 3)
       move.b    11(A6),D0
       cmp.b     #3,D0
       bls.s     I2C_ReadADCChannel_1
; {
; printf("\r\nMust select ADC channel between 0 and 3");
       pea       @dac_ad~1_1.L
       jsr       _printf
       addq.w    #4,A7
; while(1);
I2C_ReadADCChannel_3:
       bra       I2C_ReadADCChannel_3
I2C_ReadADCChannel_1:
; }
; else
; {
; control_byte = adc_channel; // Read single-ended ADC channel w/o auto increment, analog output disabled
       move.b    11(A6),D3
; }
; // Write to control register first
; if (err == I2C_WriteByte(address_byte_write, TRUE, FALSE)) return err; // With start bit
       clr.l     -(A7)
       pea       1
       and.l     #255,D4
       move.l    D4,-(A7)
       jsr       (A2)
       add.w     #12,A7
       cmp.b     D0,D2
       bne.s     I2C_ReadADCChannel_6
       move.b    D2,D0
       bra       I2C_ReadADCChannel_8
I2C_ReadADCChannel_6:
; if (err == I2C_WriteByte(control_byte, FALSE, FALSE)) return err;
       clr.l     -(A7)
       clr.l     -(A7)
       and.l     #255,D3
       move.l    D3,-(A7)
       jsr       (A2)
       add.w     #12,A7
       cmp.b     D0,D2
       bne.s     I2C_ReadADCChannel_9
       move.b    D2,D0
       bra       I2C_ReadADCChannel_8
I2C_ReadADCChannel_9:
; // Now request read of ADC conversion
; if (err == I2C_WriteByte(address_byte_read, TRUE, FALSE)) return err; // With repeated start condition
       clr.l     -(A7)
       pea       1
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       add.w     #12,A7
       cmp.b     D0,D2
       bne.s     I2C_ReadADCChannel_11
       move.b    D2,D0
       bra.s     I2C_ReadADCChannel_8
I2C_ReadADCChannel_11:
; // Read ADC conversion 
; I2C_ReadByte(FALSE, FALSE, adc_val); // Ignore previously converted byte
       move.l    12(A6),-(A7)
       clr.l     -(A7)
       clr.l     -(A7)
       jsr       _I2C_ReadByte
       add.w     #12,A7
; I2C_ReadByte(TRUE, TRUE, adc_val);   // With NACK and STOP condition
       move.l    12(A6),-(A7)
       pea       1
       pea       1
       jsr       _I2C_ReadByte
       add.w     #12,A7
; return SUCCESS;
       moveq     #1,D0
I2C_ReadADCChannel_8:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
       section   const
@dac_ad~1_1:
       dc.b      13,10,77,117,115,116,32,115,101,108,101,99,116
       dc.b      32,65,68,67,32,99,104,97,110,110,101,108,32
       dc.b      98,101,116,119,101,101,110,32,48,32,97,110,100
       dc.b      32,51,0
       xref      _printf
