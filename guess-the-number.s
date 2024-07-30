.section .data
msg:    .asciz "Hello, World!\n"    # The message to print

.section .text
.global _start

_start:
    # write(int fd, const void *buf, size_t count)
    mov     $1, %rax               # syscall number for sys_write (1)
    mov     $1, %rdi               # file descriptor 1 is stdout
    mov     $msg, %rsi             # pointer to the message
    mov     $14, %rdx              # message length (14 bytes)
    syscall                        # make the syscall

    # exit(int status)
    mov     $60, %rax              # syscall number for sys_exit (60)
    xor     %rdi, %rdi             # exit status 0
    syscall                        # make the syscall

