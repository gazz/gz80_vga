#include "../gz80_bios/bios_include.asm" 

PIO2A 	equ 0x20
PIO2B 	equ 0x21
PIO2AC 	equ 0x22
PIO2BC 	equ 0x23

DSP_IRC	equ 0b00000010


VGA_DATA_ENABLE equ 0b00000001
VGA_CONTROL_ENABLE equ 0b00000010
VGA_WRITE_ENABLE equ 0b00000100
VGA_CHIP_ENABLE equ 0b00001000

#target bin
#code _CODE, 0x2082, 0x200
#code _CODE

; app entry point
	jr main

TXT .asciz "VGA TEST!"

main:           
	
	call initpio2
	call cleardisplay

	ld b, 0
	ld c, 0
	call set_carret_raw

	ld hl, TXT
	call mstringout

	call clear_vga_screen

	call gz80_welcome

runloop:

	call update_clock
	jr runloop

exit:
	;halt
	jp app_ret


initpio2:
	; set ouput mode on PIO 
	ld a, 0xf	; b00001111 is control byte for output
	; b1 addresses pio in command mode
	out PIO2AC, a
	out PIO2BC, a
	ret	


PIO2Out:
	; output to pio & wait until busy flag clears
	ld a, d
	out PIO2A, a
	ld a, e
	out PIO2B, a
	ret

freeze:
#local
stop:
	halt
	jr stop
#endlocal

instr_wait:
	push bc
	ld b, 1
#local
rep:
	call wait
	djnz rep
#endlocal
	pop bc
	ret

clear_vga_screen:
	push de
	ld hl, 0
	ld d, 3
#local
	ld a, 0
outer_loop:
	ld b, 200
inner_loop:
	call set_cell_sprite
	inc hl
	djnz inner_loop
	dec d
	jp nz, outer_loop
	;dec bc
	;jr nz, clear_next_char 
#endlocal
	pop de
	ret


set_cell_sprite:
	; a has sprite (0..128)
	; hl is onscreen sprite index (y * 30 + x)

	push bc
	push de
	push hl
	push af

	; instruction
	; 1) data enable goes low
	; 2) set data output bits to instruction 0x7
	; 3) control enable pin goes low
	; 4) write pin goes low
	; 5) chip enable pin goes low
	ld d, 0x07
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE | VGA_CHIP_ENABLE)
	call PIO2Out
	;call instr_wait

	; 6) chip enable pin goes high
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE)
	call PIO2Out
	;call instr_wait

	; arg 1 : a >> 6 
	; 7) set data output bits to arg1
	; 8) chip enable pin goes low
	pop af
	push af
	rra
	rra
	rra
	rra
	rra
	rra 
	ld d, a
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE | VGA_CHIP_ENABLE)
	call PIO2Out
	;call instr_wait

	; 9) chip enable pin goes high
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE)
	call PIO2Out
	;call instr_wait

	; arg 2 : (a << 2) + h
	; 10) set data output bits to arg2
	; 11) chip enable pin goes low
	pop af
	push af
	rla
	rla
	add a, h
	ld d, a
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE | VGA_CHIP_ENABLE)
	call PIO2Out
	;call instr_wait

	; 12) chip enable pin goes high
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE)
	call PIO2Out
	;call instr_wait

	; arg 3 : l
	; 13) set data output bits to arg2
	; 14) chip enable pin goes low
	ld d, l
	ld e, ~(VGA_CONTROL_ENABLE | VGA_DATA_ENABLE | VGA_WRITE_ENABLE | VGA_CHIP_ENABLE)
	call PIO2Out
	;call instr_wait

	; wrap up
	; 15) chip enable pin goes high
	; 16) write pin goes high
	; 17) control enable pin goes high
	; 18) data enable goes low
	ld e, ~0
	call PIO2Out
	;call instr_wait

	pop af
	pop hl
	pop de
	pop bc
	ret


	; REFERENCE
	; instruction
	; 1) data enable goes low
	; 2) set data output bits to instruction 0x7
	; 3) control enable pin goes low
	; 4) write pin goes low
	; 5) chip enable pin goes low
	; 6) chip enable pin goes high
	; arg 1
	; 7) set data output bits to arg1
	; 8) chip enable pin goes low
	; 9) chip enable pin goes high
	; arg 2
	; 10) set data output bits to arg2
	; 11) chip enable pin goes low
	; 12) chip enable pin goes high
	; arg 3
	; 13) set data output bits to arg2
	; 14) chip enable pin goes low
	; 15) chip enable pin goes high
	; wrap up
	; 16) write pin goes high
	; 17) control enable pin goes high
	; 18) data enable goes low

;def arg_calc(x, y, sprite_index):
;'	offset = y * 30 + x
;	return {"arg1": sprite_index >> 6, "arg2": ((sprite_index << 2) & 0xff) + (offset >> 8), "arg3": offset & 0xff}



vga_charout:
	ex de,hl
	call sprite_from_ascii
	call set_cell_sprite
	ex de,hl
	ret

vga_text_out:
	push de
#local
soutloop:
	ld a, (hl)
	or a
	jr z, done
	call vga_charout
	inc hl
	inc de
	jp soutloop
done:
	pop de
	ret
#endlocal

sprite_from_ascii:
	; register a contains ascii character and this function updates it to sprite corresponding the char
	sub 32
	ret

gz80_welcome:
	;call gz80_welcome_old
	call gz80_welcome_string
	ret

update_clock:
	ld hl, TMP_CLOCK_STR
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl

	; format clock
	or a
	ld a, (T_MINUTES)
	call DigitU8_ToASCII

	inc hl
	inc hl

	ld (hl), ':'
	inc hl

	or a
	ld a, (T_SECONDS)
	call DigitU8_ToASCII

	ld de, 18
	ld hl, TMP_CLOCK_STR
	call vga_text_out
	ret

TMP_CLOCK_STR .asciz "UPTIME        "
GZ80_VGA_WELCOME .asciz "GZ80 V0.42"

gz80_welcome_string:
	ld de, 0
	ld hl, GZ80_VGA_WELCOME
	call vga_text_out
	ret
