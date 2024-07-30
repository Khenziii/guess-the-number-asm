# In this section, constants are defined.
# `rodata` stands for `read-only data`.
.section .rodata
startup_message: .asciz "I have generated a number in range 0-100, can you figure out which one is it?\n"
prompt: .asciz "Your guess: "
number_smaller_message: .asciz "Generated number is smaller than your guess!\n"
number_larger_message: .asciz "Generated number is larger than your guess!\n"
final_message: .asciz "You got the number right! It took you %d tries.\n"

# This section contains uninitialized variables.
.section .bss
# Our random number is in range 0-100, meaning that it fits into one byte.
# One byte consists of 8 bits, which is enough to store an non-negative int with value up to 255.
.lcomm random_number, 1

.section .text


# Prints to standard output.
# args: string message, int message_length
.global print
print:
    mov %rsi, %rdx # message length (14 bytes)
    mov %rdi, %rsi # pointer to our string
    mov $1, %rdi # file descriptor; 1 is stdout
    mov $1, %rax # syscall number for sys_write
    syscall

    ret

# Exits with a 0 status code.
.global exit
exit:
    # exit(int status)
    mov $60, %rax # syscall number for sys_exit (60)
    xor %rdi, %rdi # exit status 0
    syscall


.global _start
_start:
    mov $startup_message, %rdi
    mov $78, %rsi
    call print

    call exit
    
