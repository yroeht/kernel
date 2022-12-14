	.code16
	.section .bits16.code
	.globl _start
_start:
	cld
	mov %dl, (drive_num)

	call clear
	mov $banner_msg, %si
	call print_string16

	# read disk geometry
	mov $0x8, %ah
	int $0x13
	jc error
	and $0x3f, %cx
	mov %cx, (sectors_per_cylinder)
	mov %dh, (heads)
	xor %di, %di
	xor %ax, %ax
	mov %ax, %es

	mov (drive_num), %dx
	xor %dh, %dh
	call init_drive
	jc error

	# prepare to read drive
	mov $0x0002, %cx # sector 2 cylinder 0
	mov (number_extra_sectors), %ax
	mov $_start, %bx
	add (size_of_sector), %bx

read_loop:
	push %ax
	test %al, %al
	call read_sector
	jc error
	pop %ax
	dec %ax
	jz end_read
	add (size_of_sector), %bx
	jnc skip_inc_es
	push %ax
	mov %es, %ax
	add (es_step), %ax
	mov %ax, %es
	pop %ax
skip_inc_es:
	inc %cl
	cmp (sectors_per_cylinder), %cl
	jle read_loop
	# second head sectors start at 0 not 1
	mov $1, %cl
	inc %dh
	cmp (heads), %dh
	jle skip_inc_cylinder
	xor %dh, %dh
	inc %ch
skip_inc_cylinder:
	call init_drive
	jmp read_loop
end_read:

	call pmode_switch

error:
	mov $error_msg, %si
	call print_string16
	call newline
error_loop:
	jmp error_loop

	#include "print16.S"
	#include "drive.S"

error_msg:
	.string "Error...\r\n"
banner_msg:
	.string "Welcome to 16 bits Real Mode!\r\n"
size_of_sector:
	.short 512
sectors_per_cylinder:
	.long 0
es_step:
	.short 0x1000
	.globl drive_num
drive_num:
	.short 0
heads:
	.short 0

	.org 510, 0
	.short 0xaa55


