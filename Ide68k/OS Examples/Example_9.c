/*
*********************************************************************************************************
*                                                uC/OS-II
*                                          The Real-Time Kernel
*
*                           (c) Copyright 1992-2002, Jean J. Labrosse, Weston, FL
*                                           All Rights Reserved
*
*                                               EXAMPLE #1
*********************************************************************************************************
*/

/*
*********************************************************************************************************
*                                                NOTES
*
* This program is basically Example #1 in the book "MicroC/OS-II, The Real Time Kernel" adapted to run on
* IDE68K instead of an IBM PC with MS-DOS.
*
* The program creates 7 almost identical tasks that print their arguments, passed at creation time, at a
* random position on the display. The color corresponds to the argument value, 1 is blue (RGB = '001'),
* 2 is green (RGB = '010'), 3 is cyan (RGB = '011') and so on. The display is not the memory mapped display
* of the IBM PC but the much slower "drawpad" device of the simulator, in reality a bitmap in Windows.
* Characters are printed with a size of 20 x 10 (h x w) pixels. With a drawpad size set to 800 x 500 (w x h)
* pixels, this corresponds to a text display of 25 lines, 80 characters per line.
*
* Another file, called display.c must be added to the project list. (See the project list for
* Example_9.prj). This file can be regarded as the display driver for the "drawpad" device. It isolates
* the drawpad specific I/O operations from the task program
*
* Set drawpad dimensions to 800 x 500 pixels (Peripherals->Configure peripherals)
*
*
*********************************************************************************************************
*/

#include <stdio.h>
#include <stdlib.h>
#include <ucos_ii.h>
#include "display.h"

/*
*********************************************************************************************************
*                                               CONSTANTS
*********************************************************************************************************
*/

#define  TASK_STK_SIZE   256                     /* Size of each task's stacks (# of WORDs)            */
#define  N_TASKS           7                     /* Number of identical tasks (share the same code)    */

/*
*********************************************************************************************************
*                                               VARIABLES
*********************************************************************************************************
*/

OS_STK TaskStk[N_TASKS + 1][TASK_STK_SIZE];          /* Tasks stacks                                   */
INT8U TaskData[N_TASKS + 1];                         /* Parameters to pass to each task                */
OS_EVENT *DisplayMutex;
extern INT32U _romsize;                              /* Memory usage (computed in os_boot.asm)         */
extern INT32U _ramsize;

/*
*********************************************************************************************************
*                                           FUNCTION PROTOTYPES
*********************************************************************************************************
*/

void SimInit(void);
void DisplayInit(void);
void TaskStart(void *);
void TaskFunc(void *);
INT8U *Processor(void);
void OutChar(INT8U, INT8U, INT8U, INT8U);
void OutStr(INT8U, INT8U, INT8U *, INT8U);

/*
*********************************************************************************************************
*                                                MAIN
*********************************************************************************************************
*/

void main(void)
{
    INT8U err;

    SimInit();
    OSInit();                                              /* Initialize uC/OS-II                      */
    OSTaskCreate(TaskStart,
                 OS_NULL,
                 &TaskStk[0][TASK_STK_SIZE],
                 10);
    OSStart();                                             /* Start multitasking                       */
}

/*
*********************************************************************************************************
*                                              AUTO-INITIALIZE PERIPHERALS
*********************************************************************************************************
*/
void SimInit()
{
    _trap(15);
    _word(36);                                             /* Show drawpad window */
}

/*
*********************************************************************************************************
*                                              STARTUP TASK
*********************************************************************************************************
*/
void TaskStart(void *pdata)
{
    INT8U i;
    INT8U str[20];

    /* Initialization and task creation */
    DisplayInit();                                         /* Initialize the display                   */
    #if OS_TASK_STAT_EN > 0
        OSStatInit();                                      /* Initialize uC/OS-II's statistics task    */
    #endif
    for (i = 1; i <= N_TASKS; i++) {                       /* Create N_TASKS identical tasks           */
        OSTaskCreate(TaskFunc,
                     (void *)&TaskData[i],
                     &TaskStk[i][TASK_STK_SIZE],
                     i + 10);
        TaskData[i] = i + '0';                             /* Task displays its own letter and color   */
    }
    /* Update display (loop) */
    for (;;) {
        sprintf(str, "%3d", OSTaskCtr);                    /* Display # of tasks running               */
        OutStr(18, 22, str, FGND_WHITE + BGND_BLACK);
        sprintf(str, "%3d", OSCtxSwCtr);                   /* Display # of context switches per second */
        OutStr(18, 23, str, FGND_WHITE + BGND_BLACK);
        OSCtxSwCtr = 0;                                    /* Reset context switch counter             */
        #if OS_TASK_STAT_EN > 0
            sprintf(str, "%6d", (INT8S) OSCPUUsage);       /* Display CPU usage in %                   */
            OutStr(40, 22, str, FGND_WHITE + BGND_BLACK);
        #endif
        sprintf(str, "%6d", _ramsize);                     /* Display # of bytes used for RAM          */
        OutStr(40, 23, str, FGND_WHITE + BGND_BLACK);
        sprintf(str, "%6d", _romsize);                     /* Display # of bytes used for ROM          */
        OutStr(67, 23, str, FGND_WHITE + BGND_BLACK);
        OSTimeDlyHMSM(0, 0, 1, 0);                         /* Wait one second                          */
    }
}

/*
*********************************************************************************************************
*                                                  TASKS
*********************************************************************************************************
*/

void TaskFunc(void *pdata)
{
    INT8U c;
    INT8U x, y;
    INT8U color;
    INT8U ticks;

    for (;;) {
        x = rand() % 80;                            /* X position where character will be printed       */
        y = 5 + rand() % 16;                        /* Y position where character will be printed       */
        c = *(INT8U *) pdata;                       /* Character from task data                         */
        color = *(INT8U *) pdata - '0';             /* Color from task data, 1=BLUE, 2=Green, etc.      */
        ticks = 10 + 2 * (*(INT8U *) pdata - '0');  /* Delay clock ticks                                */
        OutChar(x, y, c, color + BGND_BLACK);       /* Display character on the screen                  */
        OSTimeDly(ticks);
    }
}

/*
*********************************************************************************************************
*                                        INITIALIZE THE DISPLAY
*
* Because there is only one task running, DispStr() can be used instead of OutStr(); no mutex required
*
*********************************************************************************************************
*/

void DisplayInit(void)
{
    INT8U str[16];

                 /* 00000000001111111111222222222233333333334444444444555555555566666666667777777777 */
                 /* 01234567890123456789012345678901234567890123456789012345678901234567890123456789 */
    DispStr(0, 0,  "                         uC/OS-II, The Real-Time Kernel                         ", FGND_WHITE + BGND_RED);
    DispStr(0, 1,  "                                Jean J. Labrosse                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 2,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 3,  "                                    EXAMPLE #1                                  ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 4,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 5,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 6,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 7,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 8,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 9,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 10, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 11, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 12, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 13, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 14, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 15, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 16, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 17, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 18, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 19, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 20, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 21, "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 22, " Tasks          :             CPU Usage:       %         Processor:             ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 23, " Task switch/sec:             RAM Usage:       bytes     ROM Usage:       bytes ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 24, "                         <-PRESS Ctrl+Break TO QUIT->                           ", FGND_BLACK + BGND_CYAN);
                 /* 00000000001111111111222222222233333333334444444444555555555566666666667777777777 */
                 /* 01234567890123456789012345678901234567890123456789012345678901234567890123456789 */
    DispStr(68, 22, Processor(), FGND_WHITE + BGND_BLACK);                    /* Display CPU type                  */
    sprintf(str, "V%1d.%02d.%02d", OSVersion() / 10000, (OSVersion() % 10000) / 100, OSVersion() % 100 );
    DispStr(70, 24, str, FGND_BLACK + BGND_CYAN);                            /* Display OS version                */
}

/*
*********************************************************************************************************
*                                              OUTPUT FUNCTIONS TO DISPLAY
*
*  Because the display is a shared device, access must be protected with a mutex
*
*  This is implemented by two functions OutChar() and OutStr() that are wrappers around the hardware
*  driver functions DispChr() and DispStr()
*
*********************************************************************************************************
*/

void OutChar(INT8U x, INT8U y, INT8U c, INT8U color)
{
    INT8U err;

    OSMutexPend(DisplayMutex, 0, &err);                            /* Acquire mutex for display            */
    DispChar(x, y, c, color);                                      /* Send char to display                 */
    OSMutexPost(DisplayMutex);                                     /* Release mutex                        */
}

void OutStr(INT8U x, INT8U y, INT8U *s, INT8U color)
{
    INT8U err;

    OSMutexPend(DisplayMutex, 0, &err);                            /* Acquire mutex for display            */
    DispStr(x, y, s, color);                                       /* Send string to display               */
    OSMutexPost(DisplayMutex);                                     /* Release mutex                        */
}

/*
*********************************************************************************************************
*                                              GET PROCESSOR TYPE
*
*  System call to get processor type (68000, 68020 or CPU32) and FPU present status
*
*
*********************************************************************************************************
*/

INT8U *Processor(void)
{
    _trap(15);
    _word(9);
    switch (_D0) {
    case 0:
        return "68000";
    case 20:
        return "68020";
    case 120:
        return "68020+FPU";
    case 32:
        return "CPU32";
    case 132:
        return "CPU32+FPU";;
    }
    return "";
}
