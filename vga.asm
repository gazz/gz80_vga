ClearDisplay equ 0xf5
PIOOut equ 0x5C2
ApplicationReturn equ 0x39B
; set caret anywhere on the screen
; b - offset, 64 (0x40) is 2nd line
; c - offset on the line
SetCaretRaw_bios equ 0x11A

OutHex equ $04EE
NumToHex equ $0293
DisableCursor equ $050A
Wait_PS2ScanCode equ $056B
StringOut equ 0xc2

; there are RAM mapped
STATE_KEYSTROKE equ $203E
STATE_SCANCODE equ $2042
Wait equ 0x60

; PIO direct access
PORTA 	equ 0x4
PORTB 	equ 0x5
PORTAC 	equ 0x6
PORTBC 	equ 0x7

PORT2A 	equ 0xc
PORT2B 	equ 0xd
PORT2AC equ 0xe
PORT2BC equ 0xf


#target bin
#code _CODE, 0x2082, 0x100
#code _CODE

; app entry point
	jr main

TXT .asciz "VGA TEST!"

main:
	call ClearDisplay

runloop:

	ld hl, TXT
	call StringOut

	; wait for input
	call Wait_PS2ScanCode

	jr runloop

exit:
	;halt
	jp ApplicationReturn