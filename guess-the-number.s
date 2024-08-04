# In this section, constants are defined.
# `rodata` stands for `read-only data`.
.section .rodata
startup_message: .asciz "I have generated a number in range 0-100, can you figure out which one is it?\n"
prompt: .asciz "Your guess: "
number_smaller_message: .asciz "Generated number is smaller than your guess!\n"
number_larger_message: .asciz "Generated number is larger than your guess!\n"
final_message_part_one: .asciz "You got the number right! It took you "
final_message_part_two: .asciz " tries.\n"

# This section contains uninitialized variables.
.section .bss
# Our random number is in range 0-100, meaning that it fits into one byte.
# One byte consists of 8 bits, which is enough to store an non-negative int with value up to 255.
.lcomm random_number, 1
# Max 3 digits and null terminator - 4 bytes.
.lcomm random_number_string, 4
.lcomm number_of_tries, 32
.lcomm number_of_tries_string, 16

.section .text


# Function to convert an unsigned integer to a string.
# args:
# %rdi - address of the buffer to store the string
# %esi - integer to convert
# outputs:
# The buffer will contain the converted string.
int_to_string:
    push %rbp
    mov %rsp, %rbp

    # Save registers
    push %rbx
    push %rdi
    push %rsi
    push %rdx

    mov $10, %ecx # We're going to be dividing by 10. 
    xor %ebx, %ebx
    mov %esi, %eax

# Helper label for `int_to_string`.
# Repeatedly divides the integer by 10 to get it's last digit.
# After each division, the remainder is converted to ASCII and
# pushed onto the stack.
int_to_string_loop:
    xor %edx, %edx
    div %ecx # Divide eax by %ecx (10)
    add $'0', %dl # Convert remainder to ASCII
    push %rdx # Push the character on the stack
    inc %ebx # Increment digit count
    test %eax, %eax # Test if quotient is zero
    jnz int_to_string_loop # If not, continue dividing

# Yet another helper label for `int_to_string`
# This one copies characters from the stack to our buffer.
copy_digits:
    pop %rdx
    mov %dl, (%rdi)
    inc %rdi
    dec %ebx
    jnz copy_digits

    # Null-terminate the string
    movb $0, (%rdi)

    # Restore registers
    pop %rdx
    pop %rsi
    pop %rdi
    pop %rbx

    leave
    ret

# Prints to standard output.
# args:
# %rdi - message, string
# %rsi - message_length, int
print:
    mov %rsi, %rdx # pointer to message's length (in bytes)
    mov %rdi, %rsi # pointer to our string
    mov $1, %rdi # file descriptor; 1 is stdout
    mov $1, %rax # syscall number for sys_write
    syscall

    ret

# Prints the final message to standard output.
# args:
# %rdi - amount_of_tries, string
# %rsi - amount_of_tries_length, int
print_final_message:
    # Copy passed args over to other registers.
    mov %rdi, %rbx
    mov %rsi, %rcx

    mov $final_message_part_one, %rdi
    mov $38, %rsi
    call print

    mov %rbx, %rdi
    mov %rcx, %rsi
    call print

    mov $final_message_part_two, %rdi
    mov $8, %rsi
    call print

# Exits with a 0 status code.
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

    movl $19, number_of_tries
    lea number_of_tries_string(%rip), %rdi
    movl number_of_tries(%rip), %esi
    call int_to_string

    lea number_of_tries_string(%rip), %rdi
    mov $16, %rsi
    call print_final_message

    call exit
    
