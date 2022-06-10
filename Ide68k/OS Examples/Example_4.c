/*
* EXAMPLE_4.C
*
* This program uses a 1 second timer to cycle led's 0 and 1.
*
*/

#include <ucos_ii.h>

/* Pointer to I/O device */
INT8U *const LEDS = (INT8U *) 0xE003;

/* Prototype */
void BlinkLEDS(void *, void *);
void SimInit(void);

/* Timer */
OS_TMR *LEDTimer;

void main()
{
    INT8U err;

    SimInit();
    OSInit();
    *LEDS = 0x01;
    LEDTimer = OSTmrCreate(0, 10, OS_TMR_OPT_PERIODIC, BlinkLEDS, OS_NULL, OS_NULL, &err);
    OSTmrStart(LEDTimer, &err);
    OSStart();
}

void SimInit()
{
    _trap(15);        /* Show LEDs window */
    _word(32);
}

void BlinkLEDS(void *ptmr, void *arg)
{
    *LEDS ^= 0x03;
}
