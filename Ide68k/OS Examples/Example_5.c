/*
* EXAMPLE_5.C
*
* This program is basically identical to Switches.asm of Cswitches.c but uses
* tasks that communicate through a mailbox.
*
* Task #1 checks the switches at 1 second intervals. When the state of one or more
* switches has changed, a message is posted  to task #2. This task displays the message,
* that is the state of the switches, on the LED display.
*
*/

#include <ucos_ii.h>

#define STACKSIZE 256

/* Mailbox between switches and LED display */
OS_EVENT *Mailbox;

/* Stacks */
OS_STK SwitchReadStack[STACKSIZE];
OS_STK LedsWriteStack[STACKSIZE];

/* Pointers to I/O devices */
INT8U *const Switch = (INT8U *)0xE001;
INT8U *const LEDS = (INT8U *)0xE003;

/* Prototypes */
void SimInit(void);
void SwitchRead(void *);
void LedsWrite(void *);

void main(void)
{
    SimInit();
    OSInit();
    Mailbox = OSMboxCreate(OS_NULL);
    OSTaskCreate(SwitchRead, OS_NULL, &SwitchReadStack[STACKSIZE], 10);
    OSTaskCreate(LedsWrite, OS_NULL, &LedsWriteStack[STACKSIZE], 11);
    OSStart();
}

void SimInit()
{
    _trap(15);        /* Show Switches window */
    _word(31);
    _trap(15);        /* Show LEDs window */
    _word(32);
}

void SwitchRead(void *pdata)
{
    INT8U SwitchState = 0;

    for (;;) {
       if (SwitchState != *Switch) {
           SwitchState = *Switch;
           OSMboxPost(Mailbox, &SwitchState);
       }
       OSTimeDlyHMSM(0, 0, 1, 0);
    }
}

void LedsWrite(void *pdata)
{
    INT8U *msg;
    INT8U err;

    for (;;) {
       msg = (INT8U *) OSMboxPend(Mailbox, 0, &err);
       *LEDS = *msg;
    }
}
