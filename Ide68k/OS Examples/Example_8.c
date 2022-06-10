/*                                                                                     *
 * EXAMPLE_8.C                                                                         *
 *                                                                                     *
 * This program has 3 tasks, a high-priority interrupt task and two normal tasks,      *
 * task #1, the LED-display task and task #2 the bar-display task. Tasks #1 and #2 are *
 * simply to verify that the program is running.                                       *
 *                                                                                     *
 * Initially the interrupt task is suspended until resumed by the interrupt service    *
 * routine for autovector-interrupt level 4. (Vector #28, at address 0x0070).          *
 * The interrupt service routine must be written in assembly (see file example_8.a68)  *
 * because it requires an operation (save all CPU registers) that cannot be expressed  *
 * in C.                                                                               *
 *                                                                                .    *
 * When an autovector-interrupt level 4 is received (click on the small button marked  *
 * I4 at the top of the Visual Simulator window) a .wav file ("bigben.wav") is played. *
 *                                                                                     *                                                 *
 */

#include <ucos_ii.h>

#define STK_SIZE   256                    /* Size of each task's stack (# of WORDs)   */
#define PLAY_WAV   5                      /* Play .wav file command for sound device  */

INT8U *const Leds = (INT8U *)0xE003;      /* Pointers to I/O devices */
INT8U *const Bar = (INT8U *)0xE007;
INT8U *const Sound = (INT8U *)0xE031;
INT8U **const SoundFile = (INT8U **)0xE032;

OS_STK Int4Stk[STK_SIZE];                 /* Tasks stacks */
OS_STK Task1Stk[STK_SIZE];
OS_STK Task2Stk[STK_SIZE];

void SimInit(void);                       /* Prototypes     */
void Int4ISR(void);
void Int4Task(void *);
void Task1(void *);
void Task2(void *);

void main(void)
{
    SimInit();
    OSInit();
    OSVectSet(28, Int4ISR);
    OSTaskCreate(Int4Task, OS_NULL, &Int4Stk[STK_SIZE], 4);
    OSTaskCreate(Task1, OS_NULL, &Task1Stk[STK_SIZE], 20);
    OSTaskCreate(Task2, OS_NULL, &Task2Stk[STK_SIZE], 21);
    OSStart();
}

void SimInit()
{
    _trap(15);      // show LEDS window
    _word(32);
    _trap(15);      // show bar window
    _word(34);
}

void Int4Task(void *pdata)
{
    *SoundFile = "bigben.wav";
    for (;;) {
        OSTaskSuspend(OS_PRIO_SELF);
        *Sound = PLAY_WAV;
    }
}

void Task1(void *pdata)
{
    for (;;) {
         if ((*Leds >>= 1) == 0x00) *Leds = 0x80;
         OSTimeDly(10);
    }
}

void Task2(void *pdata)
{
    for (;;) {
         (*Bar)++;
         OSTimeDly(1);
    }
}