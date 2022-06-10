/*
 * EXAMPLE_1.C
 *
 * This is a minimal program to verify multitasking.
 *
 */

#include <stdio.h>
#include <Bios.h>
#include <ucos_ii.h>
#include <stdlib.h>

#define STACKSIZE  256

void CanBusTest(void);

/* 
** Stacks for each task are allocated here in the application in this case = 256 bytes
** but you can change size if required
*/

OS_STK Task1Stk[STACKSIZE];
OS_STK Task2Stk[STACKSIZE];
OS_STK Task3Stk[STACKSIZE];
OS_STK Task4Stk[STACKSIZE];
OS_STK Task5Stk[STACKSIZE];
OS_EVENT *CANMutex;


/* Prototypes for our tasks/threads*/
void Task1(void *);	/* (void *) means the child task expects no data from parent*/
void Task2(void *);
void Task3(void *);
void Task4(void *);
void Task5(void *);
void CanBus0_Transmit(
    unsigned int* TxData1, 
    unsigned int* TxData2, 
    unsigned int* TxData3, 
    unsigned int* TxData4,
    unsigned int* TxData5,
    unsigned int* TxData6,
    unsigned int* TxData7,
    unsigned int* TxData8);
unsigned char I2C_ReadADCChannel(unsigned char adc_channel, unsigned char * adc_val);
void ADC_DAC_TEST(void);
void InitI2C(void);
void CanBus1_Receive(
    unsigned int* RxData1, 
    unsigned int* RxData2, 
    unsigned int* RxData3, 
    unsigned int* RxData4,
    unsigned int* RxData5,
    unsigned int* RxData6,
    unsigned int* RxData7,
    unsigned int* RxData8);
void Init_CanBus_Controller0(void);
void Init_CanBus_Controller1(void);
void CanBusTest(void);
/* 
** Our main application which has to
** 1) Initialise any peripherals on the board, e.g. RS232 for hyperterminal + LCD
** 2) Call OSInit() to initialise the OS
** 3) Create our application task/threads
** 4) Call OSStart()
*/

unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count;
unsigned char receied_data1, receied_data2, receied_data3, receied_data4, receied_data5, receied_data6, receied_data7, receied_data8;

unsigned char adc_reading = 0xAAU;
unsigned char light_reading = 0x0;
unsigned char therm_reading = 0x0;
unsigned char zero = 0x0;

void main(void)
{        
    
    // initialise board hardware by calling our routines from the BIOS.C source file
    Init_RS232();
    InitI2C();
    Init_LCD();
    //Init_CanBus_Controller0();
    //Init_CanBus_Controller1();
 
/* display welcome message on LCD display */

    Oline0("Altera DE1/68K");
    Oline1("Micrium uC/OS-II RTOS");

    OSInit();		// call to initialise the OS

    CanBusTest();

/* 
** Now create the 4 child tasks and pass them no data.
** the smaller the numerical priority value, the higher the task priority 
*/

    Timer1Count = Timer2Count = 0;

    OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 11);     
    OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 12);     // lowest priority task
    OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
    OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14);
    OSTaskCreate(Task5, OS_NULL, &Task5Stk[STACKSIZE], 15);

    OSStart();  // call to start the OS scheduler, (never returns from this function)
}

/*
** IMPORTANT : Timer 1 interrupts must be started by the highest priority task 
** that runs first which is Task2
*/

// Transmit & receive slider switches values
void Task1(void *pdata)
{
    INT8U err;
    Timer1_Init();
    for (;;) {
       // PortA = Timer2Count++;
       // suspect that the if the LED is not assigned, LED will display the value of the slider
       // from "analog.asm"
       OSMutexPend(CANMutex, 0, &err);
       CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
       OSMutexPost(CANMutex);
       printf("Slider switchs: %02X\n", PortA);   // checking if port C is the slider switch
       OSTimeDly(10);
    }
}

/*
** Task 2 below was created with the highest priority so it must start timer1
** so that it produces interrupts for the 100hz context switches
*/

// Transmit & receive ADC reading 
void Task2(void *pdata)
{
    // unsigned char received_reading = 0x0;
    // ADC value at Ch1. ??
    INT8U err;
    for (;;) {
       // read and transmit ADC value to CAN bus
        I2C_ReadADCChannel(1, &adc_reading);
        // transimit the ADC reading to CAN bus using can0
        OSMutexPend(CANMutex, 0, &err);
        CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
        OSMutexPost(CANMutex);
        printf("    ADC reading:    %d\n", adc_reading);
        // receive the ADC reading from CAN bus using can1
        // CanBus1_Receive(&received_reading, &zero, &zero, &zero, &zero, &zero, &zero, &zero);
        OSTimeDly(20); //wait for 200ms
    }
}

// Transmit & receive light sensor reading 
void Task3(void *pdata)
{
    INT8U err;
    // unsigned char received_reading = 0x0;
    // light sensor value at Ch0. ??
    for (;;) {
       // read and transmit ADC value to CAN bus

        I2C_ReadADCChannel(2, &light_reading);
        // transimit the ADC reading to CAN bus using can0
        OSMutexPend(CANMutex, 0, &err);
        CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
        OSMutexPost(CANMutex);
        // receive the ADC reading from CAN bus using can1
        // CanBus1_Receive(&received_reading, &zero, &zero, &zero, &zero, &zero, &zero, &zero);
        printf("        light sensor reading:   %d\n", light_reading);
        OSTimeDly(50); //wait for 500ms

    }
}

void Task4(void *pdata)
{
    INT8U err;
    // unsigned char received_reading = 0x0;
    // Thermister value at Ch2. ??
    for (;;) {
       // read and transmit ADC value to CAN bus
        I2C_ReadADCChannel(0, &therm_reading);
        // transimit the ADC reading to CAN bus using can0
        OSMutexPend(CANMutex, 0, &err);
        CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
        OSMutexPost(CANMutex);

        // receive the ADC reading from CAN bus using can1
        // CanBus1_Receive(&received_reading, &zero, &zero, &zero, &zero, &zero, &zero, &zero);
        printf("            Thermister reading:     %d\n", therm_reading);
        OSTimeDly(200); //wait for 2s

    }
}

void Task5(void *pdata)
{
    INT8U err; 
    for(;;){
        OSMutexPend(CANMutex, 0, &err);
        CanBus1_Receive(&receied_data1, &receied_data2, &receied_data3, &receied_data4, &receied_data5, &receied_data6, &receied_data7, &receied_data8);
        printf("ADC: %d, light sensor: %d, \nthermister: %d, slider: %d\n", receied_data1, receied_data2, receied_data3, receied_data4);
        OSMutexPost(CANMutex);
        OSTimeDly(5); // get reading every second, might need mutex
    }
}