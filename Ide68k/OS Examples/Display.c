/*
*********************************************************************************************************
*                                          IDE68K DISPLAY SUPPORT FUNCTIONS
*
*                          (c) Copyright 1992-2002, Jean J. Labrosse, Weston, FL
*                                           All Rights Reserved
*
* File : DISPLAY.C
* By   : Peter J. Fondse
*********************************************************************************************************
*/

#include <ucos_ii.h>
#include "display.h"

/*
*********************************************************************************************************
*                                               CONSTANTS
*********************************************************************************************************
*/

/*
*********************************************************************************************************
*                                       LOCAL GLOBAL VARIABLES
*********************************************************************************************************
*/

/*$PAGE*/
/*
*********************************************************************************************************
*                                            CLEAR A COLUMN
*
* Description : This function clears one of the 80 columns on the display
*
* Arguments   : x            corresponds to the desired column to clear.  Valid column numbers are from
*                            0 to 79. Column 0 corresponds to the leftmost column.
*
*               color        specifies the background color to use
*                            (see display.h for available choices)
*
* Returns     : None
*********************************************************************************************************
*/

DISPLAY *const display = (DISPLAY *) 0x0000E020;


void DispClrCol(INT8U x, INT8U color)
{
    INT8U y;

    display->ctrl = 0x81 | (color & 0x70); // textbgr(color);
    for (y = 0; y < DISP_MAX_Y; y++) {
	display->x = 10 * x;
	display->y = 20 * y;
    	display->ctrl = 0x0080; // gotoxy(x,y);
        display->ctrl = 0x8000 | ((INT16U) ' ' << 8) | (color & 0x70) | FIXED_PITCH | 2;
    }
}
/*$PAGE*/
/*
*********************************************************************************************************
*                                             CLEAR A ROW
*
* Description : This function clears one of the 25 lines on the display.
*
* Arguments   : y            corresponds to the desired row to clear.  Valid row numbers are from
*                            0 to 24.  Row 0 corresponds to the topmost line.
*
*               color        specifies the background color to use
*                            (see display.h for available choices)
*
* Returns     : None
*********************************************************************************************************
*/
void DispClrRow (INT8U y, INT8U color)
{
    INT8U x;

    display->ctrl = 0x81 | (color & 0x70); // textbgr(color);
    display->x = 0;
    display->y = 20 * y;
    display->ctrl = 0x0080; // gotoxy(x,y);
    for (x = 0; x < DISP_MAX_X; x++) {
        display->ctrl = 0x8000 | ((INT16U) ' ' << 8) | (color & 0x70) | FIXED_PITCH | 2;
    }
}

/*$PAGE*/
/*
*********************************************************************************************************
*                                              CLEAR SCREEN
*
* Description : This function clears the display.
*
* Arguments   : color   specifies the background color to use
*                       (see display.h for available choices)
*
* Returns     : None
*********************************************************************************************************
*/
void DispClrScr(INT8U color)
{
    display->ctrl = (color & 0x70);
}

/*$PAGE*/
/*
*********************************************************************************************************
*                           DISPLAY A SINGLE CHARACTER AT 'X' & 'Y' COORDINATE
*
* Description : This function writes a single character anywhere on the display. Each character on the
*               screen is composed of two bytes: the ASCII character to appear on the screen followed
*               by a video attribute.
*
* Arguments   : x      corresponds to the desired column on the screen.  Valid columns numbers are from
*                      0 to 79.  Column 0 corresponds to the leftmost column.
*               y      corresponds to the desired row on the screen.  Valid row numbers are from 0 to 24.
*                      Line 0 corresponds to the topmost row.
*               c      Is the ASCII character to display.  You can also specify a character with a
*                      numeric value higher than 128.  In this case, special character based graphics
*                      will be displayed.
*               color  specifies the foreground/background color to use (see display.h for available choices)
*
* Returns     : None
*********************************************************************************************************
*/
void DispChar(INT8U x, INT8U y, INT8U c, INT8U color)
{
    display->x = 10 * x;
    display->y = 20 * y;
    display->ctrl = 0x0080; // gotoxy(x,y);
    display->ctrl = 0x0081 | (color & 0x70); // textbgr(color);
    display->ctrl = 0x8000 | ((INT16U) c << 8) | ((color & 0x07) << 4) | FIXED_PITCH | 2;
}

/*$PAGE*/
/*
*********************************************************************************************************
*                                 DISPLAY A STRING  AT 'X' & 'Y' COORDINATE
*
* Description : This function writes an ASCII string anywhere on the display.
*
* Arguments   : x      corresponds to the desired column on the screen.  Valid columns numbers are from
*                      0 to 79.  Column 0 corresponds to the leftmost column.
*               y      corresponds to the desired row on the screen.  Valid row numbers are from 0 to 24.
*                      Line 0 corresponds to the topmost row.
*               s      Is the ASCII string to display.
*               color  specifies the foreground/background color to use (see display for available choices)
*
* Returns     : None
*********************************************************************************************************
*/
void DispStr(INT8U x, INT8U y, INT8U *s, INT8U color)
{
    display->x = 10 * x;
    display->y = 20 * y;
    display->ctrl = 0x0080; // gotoxy(x,y);
    display->ctrl = 0x0081 | (color & 0x70); // textbgr(color);
	while (*s) display->ctrl = 0x8000 | ((INT16U) *s++ << 8) | ((color & 0x07) << 4) | FIXED_PITCH | 2;
}