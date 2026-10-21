.section .text
.globl _start
.align  2

_start:

.equ GPIO_BASE_CTRL_ADDR,   0x10012000
.equ GPIO_OUTPUT_EN,        0x08
.equ GPIO_OUTPUT_VAL,       0x0C

.equ GPIO_7SEGLED_PINS, 0x0000023F
.equ GPIO_LEDBAR_PINS,  0x00FC0C00
.equ GPIO_ALL_LED_PINS, 0x00FC3E3F
.equ GPIO_LEDBAR_LED_1, 0x00000800

li t0, GPIO_ALL_LED_PINS
li t1, GPIO_BASE_CTRL_ADDR
sw t0, GPIO_OUTPUT_EN(t1)

sw x0, GPIO_OUTPUT_VAL(t1)

li t2, GPIO_LEDBAR_LED_1
sw t2, GPIO_OUTPUT_VAL(t1)

turnoff:
sw x0, GPIO_OUTPUT_VAL(t1)
j begin

turnon:
sw t2, GPIO_OUTPUT_VAL(t1)

begin:
# Approximately 500 ms at 16 MHz with a three-instruction delay loop.
li t4, 0x28B0AA

loop1:
addi t4, t4, -0x1
beqz t4, break
j loop1

break:
lw t5, GPIO_OUTPUT_VAL(t1)
beqz t5, turnon
j turnoff
