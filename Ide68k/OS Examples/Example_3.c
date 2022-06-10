/*
 * EXAMPLE_3.C
 *
 * This program checks the accuracy of the uC/OS-II built-in timer.
 *
 * This program is basically the same as example 2 but uses a timer task.
 *
 * NOTE: You must wait 10 seconds before the first line is printed.
 */

#include <ucos_ii.h>
#include <stdio.h>
#include <time.h>

/* Timer */
OS_TMR *Timer;

/* Prototypes */
void TimerCallbackFunc(void *, void *);

void main()
{
    INT8U err;

    OSInit();
    Timer = OSTmrCreate(0, 100, OS_TMR_OPT_PERIODIC, TimerCallbackFunc, OS_NULL, OS_NULL, &err);
    OSTmrStart(Timer, &err);
    OSStart();
}

void TimerCallbackFunc(void *ptmr, void *arg)
{
    time_t t;

    t = time(NULL);
    printf("%s", ctime(&t));
}
