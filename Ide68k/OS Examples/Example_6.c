/*                                                                                     *
 * EXAMPLE_6.C                                                                         *
 *                                                                                     *
 * This program has 3 tasks, task #1 checks the position of the slider control at      *
 * 100 milliseconds interval. When the state of slider has changed, a message is       *
 * posted to task #2. This task displays the message, that is the state of the         *
 * slider (0 - 255) on the 7 segment display. A third task (the "watchdog") flashes    *
 * led nr. 0 of the LED array at 2 seconds interval to verify that the program is      *
 * running.                                                                            *
 *                                                                                     *
 */

#include <ucos_ii.h>

#define STACKSIZE    256

/* Pointers to I/O devices */
INT8U *const Leds = (INT8U *)0xE003;
INT8U *const Slider = (INT8U *)0xE005;
INT16U *const Seg7Display = (INT16U *)0xE010;

/* bit pattern for 7 segment display 0 - 9  */
INT16U const bitpat[] = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F };

/* Mailbox between slider and 7 segment display */
OS_EVENT *Mailbox;

/* Stacks  */
OS_STK SliderReadStack[STACKSIZE];
OS_STK DisplayWriteStack[STACKSIZE];
OS_STK WatchdogStack[STACKSIZE];

/* Prototypes */
void SimInit(void);
void SliderRead(void *);
void DisplayWrite(void *);
void Watchdog(void *);
void Seg7Init(void);
void Seg7Write(INT16U, INT32U);

void main(void)
{
    SimInit();
    OSInit();
    Mailbox = OSMboxCreate(OS_NULL);
    OSTaskCreate(SliderRead, OS_NULL, &SliderReadStack[STACKSIZE], 10);
    OSTaskCreate(DisplayWrite, OS_NULL, &DisplayWriteStack[STACKSIZE], 11);
    OSTaskCreate(Watchdog, OS_NULL, &WatchdogStack[STACKSIZE], 12);
    OSStart();
}

void SimInit()
{
    _trap(15);        /* Show LEDs window */
    _word(32);
    _trap(15);        /* Show Slider window */
    _word(33);
    _trap(15);        /* Show 7-segments window */
    _word(35);
}

void SliderRead(void *pdata)
{
    INT8U SliderState = 0;

    for (;;) {
       if (SliderState != *Slider) {
           SliderState = *Slider;
           OSMboxPost(Mailbox, &SliderState);
       }
       OSTimeDlyHMSM(0, 0, 0, 100);
    }
}

void DisplayWrite(void *pdata)
{
    INT8U *msg;
    INT8U err;

    Seg7Init();
    for (;;) {
       msg = (INT8U *) OSMboxPend(Mailbox, 0, &err);
       Seg7Write(3, (INT32U) *msg);
    }
}

void Watchdog(void *pdata)
{
    for (;;) {
        *Leds = 0x00;
        OSTimeDlyHMSM(0, 0, 1, 900);
        *Leds = 0x01;
        OSTimeDlyHMSM(0, 0, 0, 100);
    }
}

void Seg7Init(void)
{
    Seg7Display[0] = 0x00;                           // digits 0 - 2 are blank
    Seg7Display[1] = 0x00;
    Seg7Display[2] = 0x00;
    Seg7Display[3] = bitpat[0];                      // last digit (3) is '0'
}

void Seg7Write(INT16U segnr, INT32U n,)
{
    INT8U i;

    for (i = 0; i <= 3; i++) Seg7Display[i] = 0x00;  // clear all digits
    if (n > 9) Seg7Write(segnr - 1, n / 10);         // call recursively for next digit
    Seg7Display[segnr] = bitpat[n % 10];             // write new bit pattern
}
