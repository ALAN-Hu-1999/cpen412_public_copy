; C:\M68KV6.0 - 800BY480\ASSIGNMENT6\PARTB_PROJ\PART_B.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*
; * EXAMPLE_1.C
; *
; * This is a minimal program to verify multitasking.
; *
; */
; #include <stdio.h>
; #include <Bios.h>
; #include <ucos_ii.h>
; #include <stdlib.h>
; #define STACKSIZE  256
; void CanBusTest(void);
; /* 
; ** Stacks for each task are allocated here in the application in this case = 256 bytes
; ** but you can change size if required
; */
; OS_STK Task1Stk[STACKSIZE];
; OS_STK Task2Stk[STACKSIZE];
; OS_STK Task3Stk[STACKSIZE];
; OS_STK Task4Stk[STACKSIZE];
; OS_STK Task5Stk[STACKSIZE];
; OS_EVENT *CANMutex;
; /* Prototypes for our tasks/threads*/
; void Task1(void *);	/* (void *) means the child task expects no data from parent*/
; void Task2(void *);
; void Task3(void *);
; void Task4(void *);
; void Task5(void *);
; void CanBus0_Transmit(
; unsigned int* TxData1, 
; unsigned int* TxData2, 
; unsigned int* TxData3, 
; unsigned int* TxData4,
; unsigned int* TxData5,
; unsigned int* TxData6,
; unsigned int* TxData7,
; unsigned int* TxData8);
; unsigned char I2C_ReadADCChannel(unsigned char adc_channel, unsigned char * adc_val);
; void ADC_DAC_TEST(void);
; void InitI2C(void);
; void CanBus1_Receive(
; unsigned int* RxData1, 
; unsigned int* RxData2, 
; unsigned int* RxData3, 
; unsigned int* RxData4,
; unsigned int* RxData5,
; unsigned int* RxData6,
; unsigned int* RxData7,
; unsigned int* RxData8);
; void Init_CanBus_Controller0(void);
; void Init_CanBus_Controller1(void);
; void CanBusTest(void);
; /* 
; ** Our main application which has to
; ** 1) Initialise any peripherals on the board, e.g. RS232 for hyperterminal + LCD
; ** 2) Call OSInit() to initialise the OS
; ** 3) Create our application task/threads
; ** 4) Call OSStart()
; */
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count;
; unsigned char receied_data1, receied_data2, receied_data3, receied_data4, receied_data5, receied_data6, receied_data7, receied_data8;
; unsigned char adc_reading = 0xAAU;
; unsigned char light_reading = 0x0;
; unsigned char therm_reading = 0x0;
; unsigned char zero = 0x0;
; void main(void)
; {        
       section   code
       xdef      _main
_main:
       move.l    A2,-(A7)
       lea       _OSTaskCreate.L,A2
; // initialise board hardware by calling our routines from the BIOS.C source file
; Init_RS232();
       jsr       _Init_RS232
; InitI2C();
       jsr       _InitI2C
; Init_LCD();
       jsr       _Init_LCD
; //Init_CanBus_Controller0();
; //Init_CanBus_Controller1();
; /* display welcome message on LCD display */
; Oline0("Altera DE1/68K");
       pea       @part_b_1.L
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("Micrium uC/OS-II RTOS");
       pea       @part_b_2.L
       jsr       _Oline1
       addq.w    #4,A7
; OSInit();		// call to initialise the OS
       jsr       _OSInit
; CanBusTest();
       jsr       _CanBusTest
; /* 
; ** Now create the 4 child tasks and pass them no data.
; ** the smaller the numerical priority value, the higher the task priority 
; */
; Timer1Count = Timer2Count = 0;
       clr.b     _Timer2Count.L
       clr.b     _Timer1Count.L
; OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 11);     
       pea       11
       lea       _Task1Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task1.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 12);     // lowest priority task
       pea       12
       lea       _Task2Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task2.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
       pea       13
       lea       _Task3Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task3.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14);
       pea       14
       lea       _Task4Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task4.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task5, OS_NULL, &Task5Stk[STACKSIZE], 15);
       pea       15
       lea       _Task5Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task5.L
       jsr       (A2)
       add.w     #16,A7
; OSStart();  // call to start the OS scheduler, (never returns from this function)
       jsr       _OSStart
       move.l    (A7)+,A2
       rts
; }
; /*
; ** IMPORTANT : Timer 1 interrupts must be started by the highest priority task 
; ** that runs first which is Task2
; */
; // Transmit & receive slider switches values
; void Task1(void *pdata)
; {
       xdef      _Task1
_Task1:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _zero.L,A2
; INT8U err;
; Timer1_Init();
       jsr       _Timer1_Init
; for (;;) {
Task1_1:
; // PortA = Timer2Count++;
; // suspect that the if the LED is not assigned, LED will display the value of the slider
; // from "analog.asm"
; OSMutexPend(CANMutex, 0, &err);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       pea       4194304
       pea       _therm_reading.L
       pea       _light_reading.L
       pea       _adc_reading.L
       jsr       _CanBus0_Transmit
       add.w     #32,A7
; OSMutexPost(CANMutex);
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
; printf("Slider switchs: %02X\n", PortA);   // checking if port C is the slider switch
       move.b    4194304,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @part_b_3.L
       jsr       _printf
       addq.w    #8,A7
; OSTimeDly(10);
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task1_1
; }
; }
; /*
; ** Task 2 below was created with the highest priority so it must start timer1
; ** so that it produces interrupts for the 100hz context switches
; */
; // Transmit & receive ADC reading 
; void Task2(void *pdata)
; {
       xdef      _Task2
_Task2:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _zero.L,A2
; // unsigned char received_reading = 0x0;
; // ADC value at Ch1. ??
; INT8U err;
; for (;;) {
Task2_1:
; // read and transmit ADC value to CAN bus
; I2C_ReadADCChannel(1, &adc_reading);
       pea       _adc_reading.L
       pea       1
       jsr       _I2C_ReadADCChannel
       addq.w    #8,A7
; // transimit the ADC reading to CAN bus using can0
; OSMutexPend(CANMutex, 0, &err);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       pea       4194304
       pea       _therm_reading.L
       pea       _light_reading.L
       pea       _adc_reading.L
       jsr       _CanBus0_Transmit
       add.w     #32,A7
; OSMutexPost(CANMutex);
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
; printf("    ADC reading:    %d\n", adc_reading);
       move.b    _adc_reading.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @part_b_4.L
       jsr       _printf
       addq.w    #8,A7
; // receive the ADC reading from CAN bus using can1
; // CanBus1_Receive(&received_reading, &zero, &zero, &zero, &zero, &zero, &zero, &zero);
; OSTimeDly(20); //wait for 200ms
       pea       20
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task2_1
; }
; }
; // Transmit & receive light sensor reading 
; void Task3(void *pdata)
; {
       xdef      _Task3
_Task3:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _zero.L,A2
; INT8U err;
; // unsigned char received_reading = 0x0;
; // light sensor value at Ch0. ??
; for (;;) {
Task3_1:
; // read and transmit ADC value to CAN bus
; I2C_ReadADCChannel(2, &light_reading);
       pea       _light_reading.L
       pea       2
       jsr       _I2C_ReadADCChannel
       addq.w    #8,A7
; // transimit the ADC reading to CAN bus using can0
; OSMutexPend(CANMutex, 0, &err);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       pea       4194304
       pea       _therm_reading.L
       pea       _light_reading.L
       pea       _adc_reading.L
       jsr       _CanBus0_Transmit
       add.w     #32,A7
; OSMutexPost(CANMutex);
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
; // receive the ADC reading from CAN bus using can1
; // CanBus1_Receive(&received_reading, &zero, &zero, &zero, &zero, &zero, &zero, &zero);
; printf("        light sensor reading:   %d\n", light_reading);
       move.b    _light_reading.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @part_b_5.L
       jsr       _printf
       addq.w    #8,A7
; OSTimeDly(50); //wait for 500ms
       pea       50
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task3_1
; }
; }
; void Task4(void *pdata)
; {
       xdef      _Task4
_Task4:
       link      A6,#-4
       move.l    A2,-(A7)
       lea       _zero.L,A2
; INT8U err;
; // unsigned char received_reading = 0x0;
; // Thermister value at Ch2. ??
; for (;;) {
Task4_1:
; // read and transmit ADC value to CAN bus
; I2C_ReadADCChannel(0, &therm_reading);
       pea       _therm_reading.L
       clr.l     -(A7)
       jsr       _I2C_ReadADCChannel
       addq.w    #8,A7
; // transimit the ADC reading to CAN bus using can0
; OSMutexPend(CANMutex, 0, &err);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; CanBus0_Transmit(&adc_reading, &light_reading, &therm_reading, &PortA, &zero, &zero, &zero, &zero);
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       move.l    A2,-(A7)
       pea       4194304
       pea       _therm_reading.L
       pea       _light_reading.L
       pea       _adc_reading.L
       jsr       _CanBus0_Transmit
       add.w     #32,A7
; OSMutexPost(CANMutex);
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
; // receive the ADC reading from CAN bus using can1
; // CanBus1_Receive(&received_reading, &zero, &zero, &zero, &zero, &zero, &zero, &zero);
; printf("            Thermister reading:     %d\n", therm_reading);
       move.b    _therm_reading.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @part_b_6.L
       jsr       _printf
       addq.w    #8,A7
; OSTimeDly(200); //wait for 2s
       pea       200
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task4_1
; }
; }
; void Task5(void *pdata)
; {
       xdef      _Task5
_Task5:
       link      A6,#-4
; INT8U err; 
; for(;;){
Task5_1:
; OSMutexPend(CANMutex, 0, &err);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; CanBus1_Receive(&receied_data1, &receied_data2, &receied_data3, &receied_data4, &receied_data5, &receied_data6, &receied_data7, &receied_data8);
       pea       _receied_data8.L
       pea       _receied_data7.L
       pea       _receied_data6.L
       pea       _receied_data5.L
       pea       _receied_data4.L
       pea       _receied_data3.L
       pea       _receied_data2.L
       pea       _receied_data1.L
       jsr       _CanBus1_Receive
       add.w     #32,A7
; printf("ADC: %d, light sensor: %d, \nthermister: %d, slider: %d\n", receied_data1, receied_data2, receied_data3, receied_data4);
       move.b    _receied_data4.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    _receied_data3.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    _receied_data2.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    _receied_data1.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @part_b_7.L
       jsr       _printf
       add.w     #20,A7
; OSMutexPost(CANMutex);
       move.l    _CANMutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
; OSTimeDly(5); // get reading every second, might need mutex
       pea       5
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task5_1
; }
; }
       section   const
@part_b_1:
       dc.b      65,108,116,101,114,97,32,68,69,49,47,54,56,75
       dc.b      0
@part_b_2:
       dc.b      77,105,99,114,105,117,109,32,117,67,47,79,83
       dc.b      45,73,73,32,82,84,79,83,0
@part_b_3:
       dc.b      83,108,105,100,101,114,32,115,119,105,116,99
       dc.b      104,115,58,32,37,48,50,88,10,0
@part_b_4:
       dc.b      32,32,32,32,65,68,67,32,114,101,97,100,105,110
       dc.b      103,58,32,32,32,32,37,100,10,0
@part_b_5:
       dc.b      32,32,32,32,32,32,32,32,108,105,103,104,116
       dc.b      32,115,101,110,115,111,114,32,114,101,97,100
       dc.b      105,110,103,58,32,32,32,37,100,10,0
@part_b_6:
       dc.b      32,32,32,32,32,32,32,32,32,32,32,32,84,104,101
       dc.b      114,109,105,115,116,101,114,32,114,101,97,100
       dc.b      105,110,103,58,32,32,32,32,32,37,100,10,0
@part_b_7:
       dc.b      65,68,67,58,32,37,100,44,32,108,105,103,104
       dc.b      116,32,115,101,110,115,111,114,58,32,37,100
       dc.b      44,32,10,116,104,101,114,109,105,115,116,101
       dc.b      114,58,32,37,100,44,32,115,108,105,100,101,114
       dc.b      58,32,37,100,10,0
       section   data
       xdef      _adc_reading
_adc_reading:
       dc.b      170
       xdef      _light_reading
_light_reading:
       dc.b      0
       xdef      _therm_reading
_therm_reading:
       dc.b      0
       xdef      _zero
_zero:
       dc.b      0
       section   bss
       xdef      _Task1Stk
_Task1Stk:
       ds.b      512
       xdef      _Task2Stk
_Task2Stk:
       ds.b      512
       xdef      _Task3Stk
_Task3Stk:
       ds.b      512
       xdef      _Task4Stk
_Task4Stk:
       ds.b      512
       xdef      _Task5Stk
_Task5Stk:
       ds.b      512
       xdef      _CANMutex
_CANMutex:
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
       xdef      _receied_data1
_receied_data1:
       ds.b      1
       xdef      _receied_data2
_receied_data2:
       ds.b      1
       xdef      _receied_data3
_receied_data3:
       ds.b      1
       xdef      _receied_data4
_receied_data4:
       ds.b      1
       xdef      _receied_data5
_receied_data5:
       ds.b      1
       xdef      _receied_data6
_receied_data6:
       ds.b      1
       xdef      _receied_data7
_receied_data7:
       ds.b      1
       xdef      _receied_data8
_receied_data8:
       ds.b      1
       xref      _CanBus0_Transmit
       xref      _Init_LCD
       xref      _Timer1_Init
       xref      _Init_RS232
       xref      _CanBus1_Receive
       xref      _OSInit
       xref      _OSStart
       xref      _OSTaskCreate
       xref      _OSMutexPost
       xref      _Oline0
       xref      _OSMutexPend
       xref      _CanBusTest
       xref      _Oline1
       xref      _InitI2C
       xref      _OSTimeDly
       xref      _printf
       xref      _I2C_ReadADCChannel
