/*                                                                                     *
 * EXAMPLE_7.C                                                                         *
 *                                                                                     *
 * This program has 3 tasks, task #1, the LED-display task, sends a query to task #2,  *
 * the slider-read task, pending on the query mailbox. After reception of the query    *
 * message, task #2 reads the slider position and posts it back to task #1. Task #1    *
 * shifts the active LED one position to the right and then waits for the number of    *
 * timer ticks derived from the slider position received from task #2. A flag is set   *
 * every eight shifts to signal this event to task #3. Task #3 waits on this flag and  *
 * when set, generates a short tone on the PC speaker.                                 *
 *                                                                                     *
 */

#include <ucos_ii.h>

#define STACKSIZE    256
#define SOUNDFLAG    0x01

/* Pointers to I/O devices */
INT8U *const Leds = (INT8U *)0xE003;
INT8U *const Slider = (INT8U *)0xE005;
INT8U *const Sound = (INT8U *)0xE031;

/* Mailboxes between slider and Led's */
OS_EVENT *MboxQuery;
OS_EVENT *MboxReply;

/* Flags */
OS_FLAG_GRP *Flags;

/* Stacks  */
OS_STK SliderReadStack[STACKSIZE];
OS_STK LedsWriteStack[STACKSIZE];
OS_STK SoundGenStack[STACKSIZE];

/* Prototypes */
void SimInit(void);
void SliderRead(void *);
void LedsWrite(void *);
void SoundGen(void *);

void main(void)
{
    INT8U err;

    SimInit();
    OSInit();
    MboxQuery = OSMboxCreate(OS_NULL);
    MboxReply = OSMboxCreate(OS_NULL);
    Flags = OSFlagCreate(0x00, &err);
    OSTaskCreate(LedsWrite, OS_NULL, &LedsWriteStack[STACKSIZE], 10);
    OSTaskCreate(SliderRead, OS_NULL, &SliderReadStack[STACKSIZE], 11);
    OSTaskCreate(SoundGen, OS_NULL, &SoundGenStack[STACKSIZE], 12);
    OSStart();
}

void SimInit()
{
    _trap(15);      // show LEDS window
    _word(32);
    _trap(15);      // show slider window
    _word(33);
}

void LedsWrite(void *pdata)
{
    INT8U *speed;
    INT8U err;
    INT16U ticks;

    for (;;) {
       OSMboxPost(MboxQuery, (void *) 1);                   /* query slider control                          */
       speed = (INT8U *) OSMboxPend(MboxReply, 0, &err);    /* wait for slider position                      */
       ticks = 2000 / ((INT16U) *speed + 50);               /* compute delay ticks from slider position      */
       if ((*Leds >>= 1) == 0) {
           *Leds = 0x80;                                    /* rotate "ON" led through led array             */
           OSFlagPost(Flags, SOUNDFLAG, OS_FLAG_SET, &err); /* signal flag every 8 steps                     */
       }
       OSTimeDly(ticks);
    }
}

void SliderRead(void *pdata)
{
    INT8U err;

    for (;;) {
       OSMboxPend(MboxQuery, 0, &err);                      /* wait until leds-task asks for slider position  */
       OSMboxPost(MboxReply, Slider);                       /* send slider position to leds                   */
    }
}

void SoundGen(void *pdata)
{
    INT8U err;

    for (;;) {
       OSFlagPend(Flags, SOUNDFLAG, OS_FLAG_WAIT_SET_ALL | OS_FLAG_CONSUME, 0, &err); /* wait until leds-task signals flag  */
       *Sound = 0;                                                                    /* say "ping"                         */
    }
}
