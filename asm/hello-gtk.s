# Hello GTK+ in  Assembly
#
# as -g hello-gtk.s -o hello-gtk.s.o
# gcc hello-gtk.s.o `pkg-config --libs gtk+-2.0` -g -o test
# ./test
#
# Author: Pengu1n , Date: 20090508
#

 .section .data

 # Strings
 APP_TITLE:
 .ascii "GTK+ in ASM\0"

 HELLO_ASM:
 .ascii "Hello ........ ASM!\0"

 BUTTON_CLICKED_INFO:
 .ascii "Hello button clicked!\n\0"
 .equ BUTTON_CLICKED_INFO_LEN, . - BUTTON_CLICKED_INFO    # '.' means current address

 # Constants
 .equ GTK_WINDOW_TOPLEVEL, 0
 .equ NULL, 0

 # GTK+ Signal name
 signal_button_clicked:
 .ascii "clicked\0"

 signal_delete_event:
 .ascii "delete_event\0"

 .section .bss

 .equ WORD_SIZE, 4
 .lcomm main_window, WORD_SIZE
 .lcomm hello_button, WORD_SIZE

 .section .text

 .global main
 .type main, @function

main:

 pushl %ebp
 movl  %esp, %ebp   # args is here, but howto get &argc ?

 # TODO: pass &argc, &argv to gtk_init
 pushl $NULL
 pushl $NULL
 call  gtk_init
 addl  $8, %esp

 pushl $GTK_WINDOW_TOPLEVEL
 call  gtk_window_new
 addl  $4, %esp
 movl  %eax, main_window

 pushl $APP_TITLE
 pushl main_window
 call  gtk_window_set_title
 addl  $8, %esp

 # Setup destory singal handler
 pushl $NULL
 pushl $NULL
 pushl $NULL
 pushl $destroy_handler
 pushl $signal_delete_event
 pushl main_window
 call g_signal_connect_data    # g_signal_connect is just a macro,
                               # so we must call g_signal_connect_data directly
 addl $24, %esp

 pushl $HELLO_ASM
 call  gtk_button_new_with_label
 addl  $4, %esp
 movl  %eax, hello_button

 # Setup destory singal handler
 pushl $NULL
 pushl $NULL
 pushl $NULL
 pushl $button_clicked_cb
 pushl $signal_button_clicked
 pushl hello_button
 call g_signal_connect_data
 addl $24, %esp

 pushl hello_button
 pushl main_window
 call gtk_container_add
 addl  $8, %esp

 pushl main_window
 call gtk_widget_show_all
 addl  $4, %esp

 call gtk_main

 movl $1, %eax
 movl $0, %ebx
 int  $0x80

 .type destroy_handler, @function
destroy_handler:

 pushl %ebp
 movl  %esp, %ebp

 call gtk_main_quit

 movl $0, %eax
 leave
 ret

 .type button_clicked_cb, @function
button_clicked_cb:

 pushl %ebp
 movl %esp, %ebp

 movl $4, %eax          # syscall __NR_write
 movl $1, %ebx          # stdout
 movl $BUTTON_CLICKED_INFO, %ecx
 movl $BUTTON_CLICKED_INFO_LEN, %edx
 int $0x80

 movl $0, %eax
 leave
 ret

