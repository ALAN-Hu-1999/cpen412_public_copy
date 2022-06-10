/*
*********************************************************************************************************
*                                          DISPLAY SUPPORT FUNCTIONS
*
*                                   (c) Copyright 2010, Peter J. Fondse
*                                           pfondse@hetnet.nl
*
* File : DISPLAY.H
* By   : Peter J. Fondse
*********************************************************************************************************
*/

/*
*********************************************************************************************************
*                                               CONSTANTS
*                                                                                                       *
* Description: These #defines are used in the Disp???() functions.  The 'color' argument in these
*              function MUST specify a 'foreground' color and a 'background'.
*              If you don't specify a background color, BLACK is assumed.
*              You must specify a color combination as follows:
*
*              DispChar(0, 0, 'A', FGND_WHITE | BGND_BLUE);
*
*              to display ASCII character 'A' as white letter on blue background.
*********************************************************************************************************
*/

// color definitions:
#define FGND_BLACK 	    0
#define FGND_BLUE   	1
#define FGND_GREEN  	2
#define FGND_RED    	4
#define FGND_YELLOW 	(FGND_RED+FGND_GREEN)
#define FGND_CYAN   	(FGND_GREEN+FGND_BLUE)
#define FGND_MAGENTA	(FGND_RED+FGND_BLUE)
#define FGND_WHITE	    (FGND_RED+FGND_GREEN+FGND_BLUE)

#define BGND_BLACK   	(FGND_BLACK<<4)
#define BGND_BLUE    	(FGND_BLUE<<4)
#define BGND_GREEN  	(FGND_GREEN<<4)
#define BGND_RED    	(FGND_RED<<4)
#define BGND_YELLOW 	(FGND_YELLOW<<4)
#define BGND_CYAN   	(FGND_CYAN<<4)
#define BGND_MAGENTA	(FGND_MAGENTA<<4)
#define BGND_WHITE	    (FGND_WHITE<<4)

#define VARIABLE_PITCH  0x00
#define FIXED_PITCH     0x08

#define DISP_MAX_X      80
#define DISP_MAX_Y      25

// layout of display registers in Visual68K "drawpad"
typedef struct {
	INT16U x;				// x position in current pixel
	INT16U y;				// y position of current pixel
	INT16U ctrl;			// control word
	INT16U xmouse;			// x position of mouse cursor
	INT16U ymouse;			// y position of mouse cursor
	INT8U  iflags;			// flagbits to indicate what caused interrupt
	INT8U  imask;			// mask to set IRQ level and mouse events
} DISPLAY;

/*$PAGE*/
/*
*********************************************************************************************************
*                                           FUNCTION PROTOTYPES
*********************************************************************************************************
*/

void    DispChar(INT8U x, INT8U y, INT8U c, INT8U color);
void    DispClrCol(INT8U x, INT8U bgnd_color);
void    DispClrRow(INT8U y, INT8U bgnd_color);
void    DispClrScr(INT8U bgnd_color);
void    DispStr(INT8U x, INT8U y, INT8U *s, INT8U color);