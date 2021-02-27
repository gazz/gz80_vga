#include "../gz80_bios/bios_include.asm" 

#target bin
#code _CODE, 0x2082, 0x100
#code _CODE

; app entry point
	jr main

TXT .asciz "VGA TEST!"

main:
	call cleardisplay

runloop:
	ld b, 0
	ld c, 0
	call set_carret_raw

	ld hl, TXT
	call mstringout

	call longwait

	jr runloop

exit:
	;halt
	jp app_ret