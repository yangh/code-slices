# Hello-world in Assembly
#
# as -g hello-world.s -o hello-world.s.o
# ld hello-world.s.o -g -o test
# ./test
#
# Author: Penguin, Date: 20130426
#

.data
 # Constants
 .equ SYS_write, 4
 .equ SYS_exit, 1
 .equ STDOUT, 1

HELLO_STR:
 .ascii "Hello World!\n\0"
 .equ HELLO_STR_LEN, . - HELLO_STR

.text
.globl _start

_start:

    #write(fd, buf, count)
    movl    $SYS_write, %eax
    movl    $STDOUT, %ebx
    movl    $HELLO_STR, %ecx
    movl    $HELLO_STR_LEN, %edx
    int     $0x80

exit:
    movl    $SYS_exit, %eax
    xorl    %ebx, %ebx
    int     $0x80
        
    ret
