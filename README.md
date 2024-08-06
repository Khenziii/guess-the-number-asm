## guess-the-number-asm

A simple number guessing game written in [GAS](https://en.wikipedia.org/wiki/GNU_Assembler) (GNU Assembler). It uses the x86_64 instruction set and AT&T syntax (the default for GAS). It also makes various `syscall`s to the Linux kernel.

## Installation

> [!WARNING]  
> As mentioned, you need to use x86_64 Linux to properly run this program.

You can download a pre-built binary from [releases](https://github.com/Khenziii/guess-the-number-asm/releases), or build it yourself:

```shell
$ as guess-the-number.s -o guess-the-number.o
$ ld guess-the-number.o -o guess-the-number
```

