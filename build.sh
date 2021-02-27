zasm -uwy vga.asm || { echo 'assembly failed' ; exit 1; }
xxd vga.bin
# python /darbi/pyWorkspace/z80_upload_ram/flash.py /dev/cu.usbserial-AG0JNMSW move_around.bin --baud 76800 --norun
python /darbi/pyWorkspace/z80_upload_ram/flash.py /dev/cu.usbserial-AG0JNMSW vga.bin --baud 76800