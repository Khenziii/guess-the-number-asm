# In this section, constants are defined.
# `rodata` stands for `read-only data`.
.section .rodata
startup_message: .asciz "I have generated a number in range 0-100, can you figure out which one is it?"
prompt: .asciz "Your guess: "
number_smaller_message: .asciz "Generated number is smaller than your guess!"
number_larger_message: .asciz "Generated number is larger than your guess!"
final_message: .asciz "You got the number right! It took you %d tries."
final_message_format: .asciz "%d"

# This section contains uninitialized variables.
.section .bss
# Our random number is in range 0-100, meaning that it fits into one byte.
# One byte consists of 8 bits, which is enough to store an non-negative int with value up to 255.
.lcomm random_number, 1

.section .text
.global _start

_start:
    # ...

