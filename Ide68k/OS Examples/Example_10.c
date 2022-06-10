/*
*********************************************************************************************************
*                                                uC/OS-II
*                                          The Real-Time Kernel
*
*                          (c) Copyright 1992-2002, Jean J. Labrosse, Weston, FL
*                                           All Rights Reserved
*
*                                               EXAMPLE #4
*********************************************************************************************************
*/

/*
*********************************************************************************************************
*                                                NOTES
*
* This program is basically Example #4 in the book "MicroC/OS-II, The Real Time Kernel" adapted to run on
* IDE68K instead of on an IBM PC with MS-DOS.
*
* The program creates 12 almost identical tasks that print the angle in degrees, the sine and the cosine
* of that angle. Every second the angle is incremented by 10 degrees. This program obviously needs
* floating point arithmetic. Chose menu-item Options->Processor and select 68020 processor with floating
* point coprocessor.
*
* In order to support floating point operations, µC/OS-II must be extended to save and restore the
* floating point registers during context switches. The functions to do this are in os_fcpu_a.asm and
* os_fcpu_c.c, these files must be inserted in the project list instead of os_cpu_a.asm and os_cpu_c.c.
* (See the project list for Example_10.prj). Also the floating point library, std68kfp.lib replaces the
* integer library std68k.lib in the project list.
*
* The display is the same "drawpad" device of 800 x 500 pixels as in example 9.
*
* Set drawpad dimensions to 800 x 500 pixels (Peripherals -> Configure peripherals)
*
*********************************************************************************************************
*/

#include <ucos_ii.h>
#include <stdio.h>
#include <math.h>
#include "display.h"

/*$PAGE*/
/*
*********************************************************************************************************
*                                               CONSTANTS
*********************************************************************************************************
*/

#define  TASK_STK_SIZE                 256       /* Size of each task's stacks (# of WORDs)        */
#define  N_TASKS                        12       /* Number of identical tasks                      */

/*
*********************************************************************************************************
*                                               VARIABLES
*********************************************************************************************************
*/

OS_STK TaskStk[N_TASKS + 1][TASK_STK_SIZE];      /* Tasks stacks                                  */
INT8U TaskData[N_TASKS + 1];                     /* Parameters to pass to each task               */
OS_EVENT *DisplayMutex;                          /* Mutex for access to display                   */
extern INT32U _ramsize;
extern INT32U _romsize;

/*
*********************************************************************************************************
*                                           FUNCTION PROTOTYPES
*********************************************************************************************************
*/

void SimInit(void);
void DisplayInit(void);
void TaskInit(void *);
void TaskFunc(void *);
INT8U *Processor(void);
void OutChar(INT8U, INT8U, INT8U, INT8U);
void OutStr(INT8U, INT8U, INT8U *, INT8U);

/*$PAGE*/
/*
*********************************************************************************************************
*                                                MAIN
*********************************************************************************************************
*/

void main()
{
    INT8U err;

    SimInit();
    OSInit();                                              /* Initialize uC/OS-II                      */
    DisplayMutex = OSMutexCreate(9, &err);                 /* Create mutex for display, PIP = 9        */
    OSTaskCreateExt(TaskInit,
                    OS_NULL,
                    &TaskStk[0][TASK_STK_SIZE],            /* TaskStk[0] for task TaskInit             */
                    10,                                    /* TaskStart priority = 10                  */
                    0,
                    &TaskStk[0][0],
                    TASK_STK_SIZE,
                    OS_NULL,
                    OS_TASK_OPT_SAVE_FP);
    OSStart();                                             /* Start multitasking                       */
}

void SimInit()
{
    _trap(15);
    _word(36);   /* Show drawpad window */
}

/*
*********************************************************************************************************
*                                              STARTUP TASK
*********************************************************************************************************
*/
void TaskInit(void *pdata)
{
    INT8U i;
    INT8U str[16];

    /* Initialization and task creation part */
    DisplayInit();                                         /* Initialize the display                   */
    #if OS_TASK_STAT_EN > 0
        OSStatInit();                                      /* Initialize uC/OS-II's statistics task    */
    #endif
    for (i = 1; i <= N_TASKS; i++) {                       /* Create N_TASKS identical tasks           */
        TaskData[i] = i;
        OSTaskCreateExt(TaskFunc,
                        (void *)&TaskData[i],
                        &TaskStk[i][TASK_STK_SIZE],        /* TaskStk[1 ... N_TASKS] for task TaskFunc */
                        10 + i,                            /* Priority = 11 ... (10 + N_TASKS)         */
                        0,
                        &TaskStk[i][0],
                        TASK_STK_SIZE,
                        OS_NULL,
                        OS_TASK_OPT_SAVE_FP);
    }
    /* Update part (loop) */
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
    INT8U taskno;
    INT8U ypos;
    INT8U str[64];
    FP64 deg;

    taskno = (INT8U) *(INT8U *)pdata;
    ypos = (INT8U) *(INT8U *)pdata + 7;
    deg = (FP64) *(INT8U *)pdata * 10;
    for (;;) {
        sprintf(str, "%2d     %8.0lf       %8.5lf     %8.5lf", taskno, deg, sin((M_PI / 180) * deg), cos((M_PI / 180) * deg));
        OutStr(18, ypos, str, FGND_WHITE + BGND_BLACK);
        if ((deg += 10.0) >= 360.0) deg = 0.0;
        OSTimeDlyHMSM(0, 0, 1, 0);
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
    DispStr(0, 3,  "                                    EXAMPLE #4                                  ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 4,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 5,  "                                                                                ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 6,  "                task        angle         sin()        cos()                    ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 7,  "                ----        -----        -------      -------                   ", FGND_WHITE + BGND_BLACK);
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
    DispStr(0, 22, " Tasks          :             CPU usage:       %         Processor:             ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 23, " Task switch/sec:             RAM usage:       bytes     ROM usage:       bytes ", FGND_WHITE + BGND_BLACK);
    DispStr(0, 24, "                         <-PRESS Ctrl+Break TO QUIT->                           ", FGND_BLACK + BGND_CYAN);
                 /* 00000000001111111111222222222233333333334444444444555555555566666666667777777777 */
                 /* 01234567890123456789012345678901234567890123456789012345678901234567890123456789 */
    DispStr(68, 22, Processor(), FGND_WHITE + BGND_BLACK);                    /* Display CPU type                  */
    sprintf(str, "V%1d.%02d.%02d", OSVersion() / 10000, (OSVersion() % 10000) / 100, OSVersion() % 100 );
    DispStr(70, 24, str, FGND_BLACK + BGND_CYAN);                    /* Display OS version                 */
}

/*
*********************************************************************************************************
*                                              OUTPUT FUNCTIONS TO DISPLAY
*
*  Because the display is a shared device, access must be protected with a mutex
*
*  This is encapsulated by two functions OutChar() and OutStr() that are wrappers around the hardware driver
*  functions DispChr() and DispStr()
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
*  System call to get processor type (68000 or 68020) and FPU present status
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