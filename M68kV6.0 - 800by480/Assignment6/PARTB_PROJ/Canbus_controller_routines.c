#include <stdio.h>
#include <stdlib.h>

/*********************************************************************************************
** These addresses and definitions were taken from Appendix 7 of the Can Controller
** application note and adapted for the 68k assignment
*********************************************************************************************/

/*
** definition for the SJA1000 registers and bits based on 68k address map areas
** assume the addresses for the 2 can controllers given in the assignment
**
** Registers are defined in terms of the following Macro for each Can controller,
** where (i) represents an registers number
*/

#define CAN0_CONTROLLER(i) (*(volatile unsigned char *)(0x00500000 + (i << 1)))
#define CAN1_CONTROLLER(i) (*(volatile unsigned char *)(0x00500200 + (i << 1)))

/* Can 0 register definitions */
#define Can0_ModeControlReg      CAN0_CONTROLLER(0)
#define Can0_CommandReg          CAN0_CONTROLLER(1)
#define Can0_StatusReg           CAN0_CONTROLLER(2)
#define Can0_InterruptReg        CAN0_CONTROLLER(3)
#define Can0_InterruptEnReg      CAN0_CONTROLLER(4) /* PeliCAN mode */
#define Can0_BusTiming0Reg       CAN0_CONTROLLER(6)
#define Can0_BusTiming1Reg       CAN0_CONTROLLER(7)
#define Can0_OutControlReg       CAN0_CONTROLLER(8)

/* address definitions of Other Registers */
#define Can0_ArbLostCapReg       CAN0_CONTROLLER(11)
#define Can0_ErrCodeCapReg       CAN0_CONTROLLER(12)
#define Can0_ErrWarnLimitReg     CAN0_CONTROLLER(13)
#define Can0_RxErrCountReg       CAN0_CONTROLLER(14)
#define Can0_TxErrCountReg       CAN0_CONTROLLER(15)
#define Can0_RxMsgCountReg       CAN0_CONTROLLER(29)
#define Can0_RxBufStartAdr       CAN0_CONTROLLER(30)
#define Can0_ClockDivideReg      CAN0_CONTROLLER(31)

/* address definitions of Acceptance Code & Mask Registers - RESET MODE */
#define Can0_AcceptCode0Reg      CAN0_CONTROLLER(16)
#define Can0_AcceptCode1Reg      CAN0_CONTROLLER(17)
#define Can0_AcceptCode2Reg      CAN0_CONTROLLER(18)
#define Can0_AcceptCode3Reg      CAN0_CONTROLLER(19)
#define Can0_AcceptMask0Reg      CAN0_CONTROLLER(20)
#define Can0_AcceptMask1Reg      CAN0_CONTROLLER(21)
#define Can0_AcceptMask2Reg      CAN0_CONTROLLER(22)
#define Can0_AcceptMask3Reg      CAN0_CONTROLLER(23)

/* address definitions Rx Buffer - OPERATING MODE - Read only register*/
#define Can0_RxFrameInfo         CAN0_CONTROLLER(16)
#define Can0_RxBuffer1           CAN0_CONTROLLER(17)
#define Can0_RxBuffer2           CAN0_CONTROLLER(18)
#define Can0_RxBuffer3           CAN0_CONTROLLER(19)
#define Can0_RxBuffer4           CAN0_CONTROLLER(20)
#define Can0_RxBuffer5           CAN0_CONTROLLER(21)
#define Can0_RxBuffer6           CAN0_CONTROLLER(22)
#define Can0_RxBuffer7           CAN0_CONTROLLER(23)
#define Can0_RxBuffer8           CAN0_CONTROLLER(24)
#define Can0_RxBuffer9           CAN0_CONTROLLER(25)
#define Can0_RxBuffer10          CAN0_CONTROLLER(26)
#define Can0_RxBuffer11          CAN0_CONTROLLER(27)
#define Can0_RxBuffer12          CAN0_CONTROLLER(28)

/* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
#define Can0_TxFrameInfo         CAN0_CONTROLLER(16)
#define Can0_TxBuffer1           CAN0_CONTROLLER(17)
#define Can0_TxBuffer2           CAN0_CONTROLLER(18)
#define Can0_TxBuffer3           CAN0_CONTROLLER(19)
#define Can0_TxBuffer4           CAN0_CONTROLLER(20)
#define Can0_TxBuffer5           CAN0_CONTROLLER(21)
#define Can0_TxBuffer6           CAN0_CONTROLLER(22)
#define Can0_TxBuffer7           CAN0_CONTROLLER(23)
#define Can0_TxBuffer8           CAN0_CONTROLLER(24)
#define Can0_TxBuffer9           CAN0_CONTROLLER(25)
#define Can0_TxBuffer10          CAN0_CONTROLLER(26)
#define Can0_TxBuffer11          CAN0_CONTROLLER(27)
#define Can0_TxBuffer12          CAN0_CONTROLLER(28)

/* read only addresses */
#define Can0_TxFrameInfoRd       CAN0_CONTROLLER(96)
#define Can0_TxBufferRd1         CAN0_CONTROLLER(97)
#define Can0_TxBufferRd2         CAN0_CONTROLLER(98)
#define Can0_TxBufferRd3         CAN0_CONTROLLER(99)
#define Can0_TxBufferRd4         CAN0_CONTROLLER(100)
#define Can0_TxBufferRd5         CAN0_CONTROLLER(101)
#define Can0_TxBufferRd6         CAN0_CONTROLLER(102)
#define Can0_TxBufferRd7         CAN0_CONTROLLER(103)
#define Can0_TxBufferRd8         CAN0_CONTROLLER(104)
#define Can0_TxBufferRd9         CAN0_CONTROLLER(105)
#define Can0_TxBufferRd10        CAN0_CONTROLLER(106)
#define Can0_TxBufferRd11        CAN0_CONTROLLER(107)
#define Can0_TxBufferRd12        CAN0_CONTROLLER(108)


/* CAN1 Controller register definitions */
#define Can1_ModeControlReg      CAN1_CONTROLLER(0)
#define Can1_CommandReg          CAN1_CONTROLLER(1)
#define Can1_StatusReg           CAN1_CONTROLLER(2)
#define Can1_InterruptReg        CAN1_CONTROLLER(3)
#define Can1_InterruptEnReg      CAN1_CONTROLLER(4) /* PeliCAN mode */
#define Can1_BusTiming0Reg       CAN1_CONTROLLER(6)
#define Can1_BusTiming1Reg       CAN1_CONTROLLER(7)
#define Can1_OutControlReg       CAN1_CONTROLLER(8)

/* address definitions of Other Registers */
#define Can1_ArbLostCapReg       CAN1_CONTROLLER(11)
#define Can1_ErrCodeCapReg       CAN1_CONTROLLER(12)
#define Can1_ErrWarnLimitReg     CAN1_CONTROLLER(13)
#define Can1_RxErrCountReg       CAN1_CONTROLLER(14)
#define Can1_TxErrCountReg       CAN1_CONTROLLER(15)
#define Can1_RxMsgCountReg       CAN1_CONTROLLER(29)
#define Can1_RxBufStartAdr       CAN1_CONTROLLER(30)
#define Can1_ClockDivideReg      CAN1_CONTROLLER(31)

/* address definitions of Acceptance Code & Mask Registers - RESET MODE */
#define Can1_AcceptCode0Reg      CAN1_CONTROLLER(16)
#define Can1_AcceptCode1Reg      CAN1_CONTROLLER(17)
#define Can1_AcceptCode2Reg      CAN1_CONTROLLER(18)
#define Can1_AcceptCode3Reg      CAN1_CONTROLLER(19)
#define Can1_AcceptMask0Reg      CAN1_CONTROLLER(20)
#define Can1_AcceptMask1Reg      CAN1_CONTROLLER(21)
#define Can1_AcceptMask2Reg      CAN1_CONTROLLER(22)
#define Can1_AcceptMask3Reg      CAN1_CONTROLLER(23)

/* address definitions Rx Buffer - OPERATING MODE - Read only register*/
#define Can1_RxFrameInfo         CAN1_CONTROLLER(16)
#define Can1_RxBuffer1           CAN1_CONTROLLER(17)
#define Can1_RxBuffer2           CAN1_CONTROLLER(18)
#define Can1_RxBuffer3           CAN1_CONTROLLER(19)
#define Can1_RxBuffer4           CAN1_CONTROLLER(20)
#define Can1_RxBuffer5           CAN1_CONTROLLER(21)
#define Can1_RxBuffer6           CAN1_CONTROLLER(22)
#define Can1_RxBuffer7           CAN1_CONTROLLER(23)
#define Can1_RxBuffer8           CAN1_CONTROLLER(24)
#define Can1_RxBuffer9           CAN1_CONTROLLER(25)
#define Can1_RxBuffer10          CAN1_CONTROLLER(26)
#define Can1_RxBuffer11          CAN1_CONTROLLER(27)
#define Can1_RxBuffer12          CAN1_CONTROLLER(28)

/* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
#define Can1_TxFrameInfo         CAN1_CONTROLLER(16)
#define Can1_TxBuffer1           CAN1_CONTROLLER(17)
#define Can1_TxBuffer2           CAN1_CONTROLLER(18)
#define Can1_TxBuffer3           CAN1_CONTROLLER(19)
#define Can1_TxBuffer4           CAN1_CONTROLLER(20)
#define Can1_TxBuffer5           CAN1_CONTROLLER(21)
#define Can1_TxBuffer6           CAN1_CONTROLLER(22)
#define Can1_TxBuffer7           CAN1_CONTROLLER(23)
#define Can1_TxBuffer8           CAN1_CONTROLLER(24)
#define Can1_TxBuffer9           CAN1_CONTROLLER(25)
#define Can1_TxBuffer10          CAN1_CONTROLLER(26)
#define Can1_TxBuffer11          CAN1_CONTROLLER(27)
#define Can1_TxBuffer12          CAN1_CONTROLLER(28)

/* read only addresses */
#define Can1_TxFrameInfoRd       CAN1_CONTROLLER(96)
#define Can1_TxBufferRd1         CAN1_CONTROLLER(97)
#define Can1_TxBufferRd2         CAN1_CONTROLLER(98)
#define Can1_TxBufferRd3         CAN1_CONTROLLER(99)
#define Can1_TxBufferRd4         CAN1_CONTROLLER(100)
#define Can1_TxBufferRd5         CAN1_CONTROLLER(101)
#define Can1_TxBufferRd6         CAN1_CONTROLLER(102)
#define Can1_TxBufferRd7         CAN1_CONTROLLER(103)
#define Can1_TxBufferRd8         CAN1_CONTROLLER(104)
#define Can1_TxBufferRd9         CAN1_CONTROLLER(105)
#define Can1_TxBufferRd10        CAN1_CONTROLLER(106)
#define Can1_TxBufferRd11        CAN1_CONTROLLER(107)
#define Can1_TxBufferRd12        CAN1_CONTROLLER(108)


/* bit definitions for the Mode & Control Register */
#define RM_RR_Bit 0x01 /* reset mode (request) bit */
#define LOM_Bit 0x02 /* listen only mode bit */
#define STM_Bit 0x04 /* self test mode bit */
#define AFM_Bit 0x08 /* acceptance filter mode bit */
#define SM_Bit  0x10 /* enter sleep mode bit */

/* bit definitions for the Interrupt Enable & Control Register */
#define RIE_Bit 0x01 /* receive interrupt enable bit */
#define TIE_Bit 0x02 /* transmit interrupt enable bit */
#define EIE_Bit 0x04 /* error warning interrupt enable bit */
#define DOIE_Bit 0x08 /* data overrun interrupt enable bit */
#define WUIE_Bit 0x10 /* wake-up interrupt enable bit */
#define EPIE_Bit 0x20 /* error passive interrupt enable bit */
#define ALIE_Bit 0x40 /* arbitration lost interr. enable bit*/
#define BEIE_Bit 0x80 /* bus error interrupt enable bit */

/* bit definitions for the Command Register */
#define TR_Bit 0x01 /* transmission request bit */
#define AT_Bit 0x02 /* abort transmission bit */
#define RRB_Bit 0x04 /* release receive buffer bit */
#define CDO_Bit 0x08 /* clear data overrun bit */
#define SRR_Bit 0x10 /* self reception request bit */

/* bit definitions for the Status Register */
#define RBS_Bit 0x01 /* receive buffer status bit */
#define DOS_Bit 0x02 /* data overrun status bit */
#define TBS_Bit 0x04 /* transmit buffer status bit */
#define TCS_Bit 0x08 /* transmission complete status bit */
#define RS_Bit 0x10 /* receive status bit */
#define TS_Bit 0x20 /* transmit status bit */
#define ES_Bit 0x40 /* error status bit */
#define BS_Bit 0x80 /* bus status bit */

/* bit definitions for the Interrupt Register */
#define RI_Bit 0x01 /* receive interrupt bit */
#define TI_Bit 0x02 /* transmit interrupt bit */
#define EI_Bit 0x04 /* error warning interrupt bit */
#define DOI_Bit 0x08 /* data overrun interrupt bit */
#define WUI_Bit 0x10 /* wake-up interrupt bit */
#define EPI_Bit 0x20 /* error passive interrupt bit */
#define ALI_Bit 0x40 /* arbitration lost interrupt bit */
#define BEI_Bit 0x80 /* bus error interrupt bit */


/* bit definitions for the Bus Timing Registers */
#define SAM_Bit 0x80                        /* sample mode bit 1 == the bus is sampled 3 times, 0 == the bus is sampled once */

/* bit definitions for the Output Control Register OCMODE1, OCMODE0 */
#define BiPhaseMode 0x00 /* bi-phase output mode */
#define NormalMode 0x02 /* normal output mode */
#define ClkOutMode 0x03 /* clock output mode */

/* output pin configuration for TX1 */
#define OCPOL1_Bit 0x20 /* output polarity control bit */
#define Tx1Float 0x00 /* configured as float */
#define Tx1PullDn 0x40 /* configured as pull-down */
#define Tx1PullUp 0x80 /* configured as pull-up */
#define Tx1PshPull 0xC0 /* configured as push/pull */

/* output pin configuration for TX0 */
#define OCPOL0_Bit 0x04 /* output polarity control bit */
#define Tx0Float 0x00 /* configured as float */
#define Tx0PullDn 0x08 /* configured as pull-down */
#define Tx0PullUp 0x10 /* configured as pull-up */
#define Tx0PshPull 0x18 /* configured as push/pull */

/* bit definitions for the Clock Divider Register */
#define DivBy1 0x07 /* CLKOUT = oscillator frequency */
#define DivBy2 0x00 /* CLKOUT = 1/2 oscillator frequency */
#define ClkOff_Bit 0x08 /* clock off bit, control of the CLK OUT pin */
#define RXINTEN_Bit 0x20 /* pin TX1 used for receive interrupt */
#define CBP_Bit 0x40 /* CAN comparator bypass control bit */
#define CANMode_Bit 0x80 /* CAN mode definition bit */

/*- definition of used constants ---------------------------------------*/
#define YES 1
#define NO 0
#define ENABLE 1
#define DISABLE 0
#define ENABLE_N 0
#define DISABLE_N 1
#define INTLEVELACT 0
#define INTEDGEACT 1
#define PRIORITY_LOW 0
#define PRIORITY_HIGH 1

/* default (reset) value for register content, clear register */
#define ClrByte 0x00

/* constant: clear Interrupt Enable Register */
#define ClrIntEnSJA ClrByte

/* definitions for the acceptance code and mask register */
#define DontCare 0xFF


/*  bus timing values for
**  bit-rate : 100 kBit/s
**  oscillator frequency : 25 MHz, 1 sample per bit, 0 tolerance %
**  maximum tolerated propagation delay : 4450 ns
**  minimum requested propagation delay : 500 ns
**
**  https://www.kvaser.com/support/calculators/bit-timing-calculator/
**  T1 	T2 	BTQ 	SP% 	SJW 	BIT RATE 	ERR% 	BTR0 	BTR1
**  17	8	25	    68	     1	      100	    0	      04	7f
*/
void Wait1ms(void);
void Wait500ms(void)
{
    int i ;
    for(i = 0; i < 500; i++)
        Wait1ms() ;
}



// initialisation for Can controller 0
void Init_CanBus_Controller0(void)
{
    // TODO - put your Canbus initialisation code for CanController 0 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)

    /* define interrupt priority & control (level-activated, see chapter 4.2.5) */
    // PX0 = PRIORITY_HIGH; /* CAN HAS A HIGH PRIORITY INTERRUPT */
    // IT0 = INTLEVELACT; /* set interrupt0 to level activated */
    // /* enable the communication interface of the SJA1000 */
    // CS = ENABLE_N; /* Enable the SJA1000 interface */
    /*- end of the definition of the communication link -------------------------*/

    /* disable interrupts, if used (not necessary after power-on) */
    // EA = DISABLE; /* disable all interrupts */
    //Can0_InterruptReg = DISABLE; /* disable external interrupt from SJA1000 */
    /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
        leave loop after a time out and signal an error */
    while((Can0_ModeControlReg & RM_RR_Bit ) == ClrByte)
    {
    /* other bits than the reset mode/request bit are unchanged */
    Can0_ModeControlReg = Can0_ModeControlReg | RM_RR_Bit ;
    }
    /* set the Clock Divider Register according to the given hardware of Figure 3
        select PeliCAN mode
        bypass CAN input comparator as external transceiver is used
        select the clock for the controller S87C654 */
    Can0_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;
    /* disable CAN interrupts, if required (always necessary after power-on)
    (write to SJA1000 Interrupt Enable / Control Register) */
    Can0_InterruptEnReg = ClrIntEnSJA;
    /* define acceptance code and mask */
    Can0_AcceptCode0Reg = ClrByte; 
    Can0_AcceptCode1Reg = ClrByte; 
    Can0_AcceptCode2Reg = ClrByte; 
    Can0_AcceptCode3Reg = ClrByte; 
    Can0_AcceptMask0Reg = DontCare; /* every identifier is accepted */
    Can0_AcceptMask1Reg = DontCare; /* every identifier is accepted */
    Can0_AcceptMask2Reg = DontCare; /* every identifier is accepted */
    Can0_AcceptMask3Reg = DontCare; /* every identifier is accepted */
    /* configure bus timing */
    /* bit-rate = 1 Mbit/s @ 24 MHz, the bus is sampled once */
    Can0_BusTiming0Reg = 0x04;
    Can0_BusTiming1Reg = 0x7f;
    /* configure CAN outputs: float on TX1, Push/Pull on TX0,
    normal output mode */
    Can0_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
    /* leave the reset mode/request i.e. switch to operating mode,
        the interrupts of the S87C654 are enabled
        but not the CAN interrupts of the SJA1000, which can be done separately
        for the different tasks in a system */
    /* clear Reset Mode bit, select dual Acceptance Filter Mode,
        switch off Self Test Mode and Listen Only Mode,
        clear Sleep Mode (wake up) */
    do /* wait until RM_RR_Bit is cleared */
    /* break loop after a time out and signal an error */
    {
        Can0_ModeControlReg = ClrByte;
    } while((Can0_ModeControlReg & RM_RR_Bit ) != ClrByte);
    //Can0_InterruptReg = ENABLE; /* enable external interrupt from SJA1000 */
    // EA = ENABLE; /* enable all interrupts */
    /*----- end of Initialization Example of the SJA1000 ------------------------*/

}

// initialisation for Can controller 1
void Init_CanBus_Controller1(void)
{
    // TODO - put your Canbus initialisation code for CanController 1 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)

    // TODO - put your Canbus initialisation code for CanController 0 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)

    /* disable interrupts, if used (not necessary after power-on) */
    // EA = DISABLE; /* disable all interrupts */
    //Can1_InterruptReg = DISABLE; /* disable external interrupt from SJA1000 */
    /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
        leave loop after a time out and signal an error */
    while((Can1_ModeControlReg & RM_RR_Bit ) == ClrByte)
    {
    /* other bits than the reset mode/request bit are unchanged */
    Can1_ModeControlReg = Can1_ModeControlReg | RM_RR_Bit ;
    }
    /* set the Clock Divider Register according to the given hardware of Figure 3
        select PeliCAN mode
        bypass CAN input comparator as external transceiver is used
        select the clock for the controller S87C654 */
    Can1_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;
    /* disable CAN interrupts, if required (always necessary after power-on)
    (write to SJA1000 Interrupt Enable / Control Register) */
    Can1_InterruptEnReg = ClrIntEnSJA;
    /* define acceptance code and mask */
    Can1_AcceptCode0Reg = ClrByte; 
    Can1_AcceptCode1Reg = ClrByte; 
    Can1_AcceptCode2Reg = ClrByte; 
    Can1_AcceptCode3Reg = ClrByte; 
    Can1_AcceptMask0Reg = DontCare; /* every identifier is accepted */
    Can1_AcceptMask1Reg = DontCare; /* every identifier is accepted */
    Can1_AcceptMask2Reg = DontCare; /* every identifier is accepted */
    Can1_AcceptMask3Reg = DontCare; /* every identifier is accepted */
    /* configure bus timing */
    /* bit-rate = 1 Mbit/s @ 24 MHz, the bus is sampled once */
    Can1_BusTiming0Reg = 0x04;
    Can1_BusTiming1Reg = 0x7f;
    /* configure CAN outputs: float on TX1, Push/Pull on TX0,
    normal output mode */
    Can1_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
    /* leave the reset mode/request i.e. switch to operating mode,
        the interrupts of the S87C654 are enabled
        but not the CAN interrupts of the SJA1000, which can be done separately
        for the different tasks in a system */
    /* clear Reset Mode bit, select dual Acceptance Filter Mode,
        switch off Self Test Mode and Listen Only Mode,
        clear Sleep Mode (wake up) */
    do /* wait until RM_RR_Bit is cleared */
    /* break loop after a time out and signal an error */
    {
        Can1_ModeControlReg = ClrByte;
    } while((Can1_ModeControlReg & RM_RR_Bit ) != ClrByte);
    //Can1_InterruptReg = ENABLE; /* enable external interrupt from SJA1000 */
    // EA = ENABLE; /* enable all interrupts */
    /*----- end of Initialization Example of the SJA1000 ------------------------*/
}

// Transmit for sending a message via Can controller 0
void CanBus0_Transmit(unsigned int* ID, unsigned int* TxData1)
{
    // TODO - put your Canbus transmit code for CanController 0 here
    // See section 4.2.2 in the application note for details (PELICAN MODE)
    /* wait until the Transmit Buffer is released */
    do
    {
        printf("\r\n[CanBus0]:Wait for Tx Begin");
    /* start a polling timer and run some tasks while waiting
    break the loop and signal an error if time too long */
    } while((Can0_StatusReg & TBS_Bit ) != TBS_Bit );
    /* Transmit Buffer is released, a message may be written into the buffer */
    /* in this example a Standard Frame message shall be transmitted */
    Can0_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
    Can0_TxBuffer1 = *ID;
    Can0_TxBuffer2 = 0x20;   /* ID2 = 20, (0010 0000) */
    Can0_TxBuffer3 = *TxData1; 

    /* Start the transmission */
    Can0_CommandReg = TR_Bit ; /* Set Transmission Request bit */

    do
    {
        printf("\r\n[CanBus0]:Wait for Tx Finish");
    } while (!(Can0_StatusReg & TCS_Bit));

    printf("[CanBus0Tx]:");

}

// Transmit for sending a message via Can controller 1
void CanBus1_Transmit(unsigned int* ID, unsigned int* TxData1)
{
    // TODO - put your Canbus transmit code for CanController 1 here
    // See section 4.2.2 in the application note for details (PELICAN MODE)
     /* wait until the Transmit Buffer is released */
    do
    {
    /* start a polling timer and run some tasks while waiting
    break the loop and signal an error if time too long */
        //printf("\r\n[CanBus1]:Wait for Tx Begin");
    } while((Can1_StatusReg & TBS_Bit ) != TBS_Bit );
    /* Transmit Buffer is released, a message may be written into the buffer */
    /* in this example a Standard Frame message shall be transmitted */
    Can1_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
    Can1_TxBuffer1 = *ID;   /* ID1 = A5, (1010 0101) */
    Can1_TxBuffer2 = 0x20;   /* ID2 = 20, (0010 0000) */
    Can1_TxBuffer3 = *TxData1; 
    /* Start the transmission */
    Can1_CommandReg = TR_Bit ; /* Set Transmission Request bit */
    do
    {
        //printf("\r\n[CanBus1]:Wait for Tx Finish");
    } while (!(Can1_StatusReg & TCS_Bit));

    printf("[CanBus1Tx]:");
}

// Receive for reading a received message via Can controller 0
void CanBus0_Receive(unsigned int* ID, unsigned int* RxData1)
{
    // TODO - put your Canbus receive code for CanController 0 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)
    do
    {
        //printf("\r\n[CanBus0]:Wait for Rx Begin");
    } while (!(Can0_StatusReg & RBS_Bit));

    *ID      = Can0_RxBuffer1;
    *RxData1 = Can0_RxBuffer3;

    Can0_CommandReg = RRB_Bit;

    printf("[CanBus0Rx]:");
}

// Receive for reading a received message via Can controller 1
void CanBus1_Receive(unsigned int* ID, unsigned int* RxData1)
{
    // TODO - put your Canbus receive code for CanController 1 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)
    do
    {
        //printf("\r\n[CanBus1]:Wait for Rx Begin");
    } while (!(Can1_StatusReg & RBS_Bit));

    *ID = Can1_RxBuffer1;
    *RxData1 = Can1_RxBuffer3;

    Can1_CommandReg = RRB_Bit;

    printf("[CanBus1Rx]:");
}


void CanBusTest(void)
{
    // initialise the two Can controllers
    unsigned int Data, ID, ID_rx = 0;

    printf("\r\nCanBus Init");
    Init_CanBus_Controller0();
    Init_CanBus_Controller1();
    
    printf("\r\n\r\n---- CANBUS Test ----\r\n") ;

    // simple application to alternately transmit and receive messages from each of two nodes

    while(1) 
    {

        printf("\r\n[CanBusTest]:CanBus0 Tx to CanBus1");
        Wait500ms();
        Data = 1;
        ID = 1;
        CanBus0_Transmit(&ID, &Data);
        Data = 2;
        ID = 2;
        CanBus0_Transmit(&ID, &Data);
        Data = 3;
        ID = 3;
        CanBus0_Transmit(&ID, &Data);
        Data = 4;
        ID = 4;
        CanBus0_Transmit(&ID, &Data);
        
        CanBus1_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus1]:Received Data: %x @ ID %d", Data, ID_rx);
        CanBus1_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus1]:Received Data: %x @ ID %d", Data, ID_rx);
        CanBus1_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus1]:Received Data: %x @ ID %d", Data, ID_rx);
        CanBus1_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus1]:Received Data: %x @ ID %d", Data, ID_rx);

        printf("\r\n");

        printf("\r\n[CanBusTest]:CanBus1 Tx to CanBus0");

        Wait500ms();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
        Data = 1;
        ID = 1;
        CanBus1_Transmit(&ID, &Data);
        Data = 2;
        ID = 2;
        CanBus1_Transmit(&ID, &Data);
        Data = 3;
        ID = 3;
        CanBus1_Transmit(&ID, &Data);
        Data = 4;
        ID = 4;
        CanBus1_Transmit(&ID, &Data);
        
        CanBus0_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus0]:Received Data: %x @ ID %d", Data, ID_rx);
        CanBus0_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus0]:Received Data: %x @ ID %d", Data, ID_rx);
        CanBus0_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus0]:Received Data: %x @ ID %d", Data, ID_rx);
        CanBus0_Receive(&ID_rx, &Data);
        printf("\r\n[CanBus0]:Received Data: %x @ ID %d", Data, ID_rx);

        printf("\r\n");
    }
}