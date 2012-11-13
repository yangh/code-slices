# Demo how to access traditional argc, argv in Assembly
#
# as -g demo-argc-argv.s -o demo-argc-argv.s.o
# gcc demo-argc-argv.s.o -g -o test
# ./test
#
# Author: cjacker, Date: 20090923
#

.section .data

output:
.asciz "There are %d params\n"

output2:
.asciz "%s\n"

.section .text

.global _start

start:

    nop
    #movl (%esp), %ecx
    pushl %ecx
    pushl $output
    call printf

    addl $4, %esp
    popl %ecx
    movl %esp, %ebp
    addl $4, %ebp

para_loop:

    pushl %ecx
    pushl (%ebp)
    pushl $output2
    call printf

    addl $8, %esp
    popl %ecx
    addl $4, %ebp

    loop para_loop

    pushl $0
    call exit

