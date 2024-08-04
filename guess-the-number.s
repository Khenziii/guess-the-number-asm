# In this section, constants are defined.
# `rodata` stands for `read-only data`.
.section .rodata
startup_message: .asciz "I have generated a number in range 0-100, can you figure out which one is it?\n"
prompt: .asciz "Your guess: "
number_smaller_message: .asciz "Generated number is smaller than your guess!\n"
number_larger_message: .asciz "Generated number is larger than your guess!\n"
final_message_part_one: .asciz "You got the number right! It took you "
final_message_part_two: .asciz " try/tries.\n"

# This section contains uninitialized variables.
.section .bss
# Our random number is in range 0-100, meaning that it fits into one byte.
# One byte consists of 8 bits, which is enough to store an non-negative int with value up to 255.
.lcomm random_number, 1
# Max 3 digits and null terminator - 4 bytes.
.lcomm random_number_string, 4
.lcomm number_of_tries, 32
.lcomm number_of_tries_string, 16
.lcomm user_guess, 32
.lcomm user_guess_string, 16

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
    div %ecx # Divide %eax by %ecx (10)
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

# Function that converts a string to an int.
# inputs:
# %rsi - pointer to the string to convert
# outputs:
# %eax - contains the output integer
string_to_int:
    # empty %eax and %edi registers
    xor %eax, %eax
    xor %edi, %edi

string_to_int_loop:
    movzbl (%rsi), %edi # Get the current character (zero-extended to 32-bit)
    test %edi, %edi # Check for null terminator
    je string_to_int_done
    
    cmpl $'0', %edi # Any character with value <'0' is not a valid digit 
    jl string_to_int_error
    
    cmpl $'9', %edi # Any character with a value >'9' is also not a valid digit
    jg string_to_int_error

    subl $'0', %edi # Convert from ASCII to decimal 
    imull $10, %eax, %eax
    addl %edi, %eax # Add current digit to total
    
    inc %rsi # Move to the next character
    jmp string_to_int_loop

string_to_int_error:
    movl $0, %eax # Return 0 on error

string_to_int_done:
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

# Exits with a 0 status code.
exit:
    # exit(int status)
    mov $60, %rax # syscall number for sys_exit (60)
    xor %rdi, %rdi # exit status 0
    syscall

# Gets a random integer using `getrandom` syscall. Maximum value of int: 8 bits.
# args:
# %bx - maximum value of the integer
# %rsi - pointer to the buffer in which the integer should be stored.
get_random_integer:
    mov $318, %rax # syscall number for `getrandom`
    mov %rsi, %rdi # pointer to the buffer
    mov $1, %rsi # amount of bytes to read (8 bits)
    mov $0, %rdx # flags (0 for blocking)
    syscall

    # The buffer contains a random 8 bit integer now. We have to
    # scale it down to 0-%bx
    mov (%rdi), %al # move the int to %al
    movzx %al, %ax # zero extend %al to %ax (16-bit)
    mul %bx # multiply %ax by %bx, result in %dx:%ax
    mov $255, %bx # load 255 into %bx
    xor %dx, %dx # clear %dx for division
    div %bx # divide %dx:%ax by 255, quotient in %ax, remainder in %dx

    mov %ax, (%rdi)
    ret

# Gets data passed via standard input. This function replaces
# the new line character with a null terminator.
# args:
# %rdx - number of bytes to read
# %rsi - pointer to the buffer which will store user's string
get_standard_input:
    mov $0, %rax # syscall number for sys_read
    mov $0, %rdi # file descriptor 0 (stdin)
    syscall

    mov %rdx, %rcx
    mov %rsi, %rdi

find_newline:
    dec %rcx # Decrement the counter
    js no_newline_found # If %rcx is negative, we've reached the end of the string

    cmpb $'\n', (%rdi) # Compare the current byte to newline
    je replace_newline # If it is newline, jump to replace it

    inc %rdi # Move to the next byte
    jmp find_newline # Repeat the scan

replace_newline:
    movb $0, (%rdi) # Replace newline with null terminator
    ret

no_newline_found:
    ret


.global _start
_start:
    mov $100, %bx
    lea random_number(%rip), %rsi
    call get_random_integer

    mov $startup_message, %rdi
    mov $78, %rsi
    call print

    # set the number of tries to 0
    lea number_of_tries(%rip), %rdi
    mov $0, %rsi
    mov %rsi, (%rdi)

guess_loop:
    # Increment `number_of_tries` by one.
    lea number_of_tries(%rip), %rdi
    movl (%rdi), %eax
    addl $1, %eax
    movl %eax, (%rdi)

    # Show the prompt.
    mov $prompt, %rdi
    mov $12, %rsi
    call print

    # Accept user input.
    mov $64, %rdx
    lea user_guess_string(%rip), %rsi
    call get_standard_input

    # Convert user input (string) to int.
    lea user_guess_string(%rip), %rsi
    call string_to_int

    # %eax contains user's guess.
    mov random_number, %esi
    cmp %eax, %esi

    # If eax less than esi, print the `random_number_smaller` message.
    jl random_number_smaller
    # If eax greater than esi, print `random_number_larger` message.
    jg random_number_larger
    # Else, jump to finish
    jmp finish

random_number_smaller:
    mov $number_smaller_message, %rdi
    mov $45, %rsi
    call print

    jmp guess_loop

random_number_larger:
    mov $number_larger_message, %rdi
    mov $44, %rsi
    call print

    jmp guess_loop

finish:
    lea number_of_tries_string(%rip), %rdi
    movl number_of_tries(%rip), %esi
    call int_to_string

    mov $final_message_part_one, %rdi
    mov $38, %rsi
    call print

    lea number_of_tries_string(%rip), %rdi
    mov $32, %rsi
    call print

    mov $final_message_part_two, %rdi
    mov $12, %rsi
    call print

    call exit

