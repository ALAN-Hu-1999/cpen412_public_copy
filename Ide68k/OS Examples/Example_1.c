/*
 * EXAMPLE_1.C
 *
 * This is a minimal program to verify multitasking.
 *
 * Two tasks are created, Task #1 prints "This is task 1", task #2 prints "This is task 2".
 *
 * However, simple and small as it is, there is a serious flaw in the program. The device
 * to print on is a shared resource! The error can be observed as sometimes printing of
 * task #2 is interrupted and the higher priority task #1 prints "This is task #1" in the
 * middle of "This is task #2". A mutex or semaphore would be required to synchronize both tasks.
 *
 */

#include <ucos_ii.h>
#include <stdio.h>

#define STACKSIZE  256

/* Stacks */
OS_STK Task1Stk[STACKSIZE];
OS_STK Task2Stk[STACKSIZE];

/* Prototypes */
void Task1(void *);
void Task2(void *);

void main(void)
{
    OSInit();
    OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 10);
    OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 11);
    OSStart();
}

void Task1(void *pdata)
{
    for (;;) {
       printf("  This is Task #1\n");
       OSTimeDlyHMSM(0, 0, 1, 0);
    }
}

void Task2(void *pdata)
{
    for (;;) {
       printf("    This is Task #2\n");
       OSTimeDlyHMSM(0, 0, 3, 0);
    }
}
