// DAYTIME.C - a program to display the time of day

// This program can be compiled by loading "daytime.prj" in the
// "Project|Open project" menu.

// Its main purpose is to show how 68000 I/O devices can be programmed from
// a C-program (using an array of 7-segment displays)

// The time and date information is obtained by calling time(). This function
// calls __time in cstart.asm. This is essentially a systemcall (trap #15  dc.w 40)
// that returns the number of seconds since Jan 1, 1970, 00:00:00 UTC. (UNIX time).
// The function localtime() breaks this down in seconds, minutes, hours, day, month,
// year etc. after adjustment for timezone and daylight saving time.

// The 'const' qualifier makes sure that the pointer 'display' and the array 'bitpat'
// are stored in ROM.

// Although this program can be run in Single-step and Auto-step mode, Run mode is
// preferred.

// Author: Peter J. Fondse (pfondse@hetnet.nl)

#include <time.h>

// Pointer to I/O device
short *const display = (short *) 0xE010; // display[0] is leftmost digit etc.

// bit pattern for 7-segment display digit 0..9
short const bitpat[] = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F };

void main(void)
{
    time_t t;
    struct tm *tp;

    // activate 7 segment display
    _trap(15);
    _word(35);

    for (;;) {
        time(&t);
        tp = localtime(&t);
        display[0] = bitpat[tp->tm_hour / 10];
        display[1] = bitpat[tp->tm_hour % 10] | ((tp->tm_sec << 7) & 0x80);
        display[2] = bitpat[tp->tm_min / 10];
        display[3] = bitpat[tp->tm_min % 10];
    }
}
