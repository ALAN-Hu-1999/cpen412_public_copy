; ANALOG.ASM - Read slidebar and copy to bar graph display and LEDs

; Although this program can be run in Single-step and Auto-step mode,
; Run mode is preferred.

; If you click the mouse on the slider button and keep the mousebutton
; down, you can move the slider control up and down. The BARGRAPH will
; display the slider position in analog form. The LED display indicates
; the slider position in binary (0 - 255).

; Author: Peter J. Fondse (pfondse@hetnet.nl)

LEDS    equ     $E003       ; I/O address of LED display
SLIDER  equ     $E005       ; I/O address of slider
BAR     equ     $E007       ; I/O address of bar display

        org     $400

; auto-initialize periperals
        trap     #15
        dc.w     32         ; show LEDs
        trap     #15
        dc.w     33         ; show slider
        trap     #15
        dc.w     34         ; show bar display

repeat  move.b  SLIDER,D0   ; read track bar position
        move.b  D0,LEDS     ; write to LED display
        move.b  D0,BAR      ; write to BAR display
        bra     repeat      ; repeat