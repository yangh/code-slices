# Demo how to access traditional argc, argv in Assembly
#
# as -g args.s -o args.s.o
# ld args.s.o -g -o test
# ./test arg1 arg2 arg3 ...
#
# Author: Penguin, Date: 20100428
#

.data
 # Constants
 .equ SYS_write, 4
 .equ SYS_exit, 1
 .equ STDOUT, 1
 .equ ASCII_LF, 10      # New line char

.text
.globl _start

_start:

    popl    %ecx        # argc

lewp:
    popl    %ecx        # argv
    test    %ecx, %ecx
    jz      exit

    movl    %ecx, %ebx
    xorl    %edx, %edx

strlen:
    movb    (%ebx), %al
    inc     %edx
    inc     %ebx
    test    %al, %al
    jnz     strlen
    movb    $ASCII_LF, -1(%ebx)

    #write(STDOUT, argv[i], strlen(argv[i]));
    movl    $SYS_write, %eax
    movl    $STDOUT, %ebx
    int     $0x80

    jmp     lewp

exit:
    movl    $SYS_exit, %eax
    xorl    %ebx, %ebx
    int     $0x80
        
    ret
