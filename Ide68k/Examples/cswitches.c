// CSWITCHES.ASM - Read switches and copy to LEDs

// To run this program in the 68000 Visual Simulator, you must enable the
// SWITCHES and LED's windows from the Peripherals menu.

// The 'const' qualifier makes sure that the pointer 'switches' and 'leds'
// are stored in ROM.

// Although this program can be run in Single-step and Auto-step mode,
// Run mode is preferred.

// If you click the mouse on one of the switches, the corresponding LED
// will be turned on.

// This C program has the same functionality as Switches.asm

// Author: Peter J. Fondse (pfondse@hetnet.nl)

typedef unsigned char BYTE;

BYTE *const switches = (BYTE *) 0xE001;
BYTE *const leds = (BYTE *) 0xE003;

void main(void)
{
   // activate I/O devices
   _trap(15);
   _word(31);                 // show switches
   _trap(15);  
   _word(32);                 // show LEDs

   for (;;)
       *leds = *switches;
}
