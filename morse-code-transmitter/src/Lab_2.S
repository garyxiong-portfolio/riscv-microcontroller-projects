.section .rodata
.align 2

InputLUT:
    .asciz "AE"

.align 2
# A-Z patterns, played most-significant bit first; each bit lasts one delay unit.
MorseLUT:
    .half 0x17, 0x1D5, 0x75D, 0x75    # A, B, C, D
    .half 0x1, 0x15D, 0x1DD, 0x55    # E, F, G, H
    .half 0x5, 0x1777, 0x1D7, 0x175    # I, J, K, L
    .half 0x77, 0x1D, 0x777, 0x5DD    # M, N, O, P
    .half 0x1DD7, 0x5D, 0x15, 0x7    # Q, R, S, T
    .half 0x57, 0x157, 0x177, 0x757    # U, V, W, X
    .half 0x1D77, 0x775    # Y, Z

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
    .equ GPIO_LEDBAR_LED_7, 0x00400000

    li t0, GPIO_ALL_LED_PINS
    li t1, GPIO_BASE_CTRL_ADDR
    sw t0, GPIO_OUTPUT_EN(t1)

    sw x0, GPIO_OUTPUT_VAL(t1)

InputPointer:
    la s1, InputLUT

NextChar:
    lbu a0, 0(s1)
    addi s1, s1, 1
    snez a1, a0
    bnez a1, CHAR2MORSE
    jal ra, DELAY
    jal ra, DELAY
    jal ra, DELAY
    jal ra, DELAY
    j InputPointer

# Align the first set bit with the sign bit before playback.
clearZeros:
    slli a1, a1, 1
    bgt a1, x0, clearZeros
    j PROCESSCHAR

# a0: uppercase ASCII letter; a1: Morse pattern from the 16-bit table.
CHAR2MORSE:

    la t2, MorseLUT
    addi t3, a0, -0x41
    add t3, t3, t3
    add t2, t3, t2
    lh a1, 0(t2)
    bgt a1, x0, clearZeros

PROCESSCHAR:
    blt a1, x0, TURN_ON
    bgt a1, x0, TURN_OFF

# Leave three delay units between characters.
CHARDELAY:
    sw x0, GPIO_OUTPUT_VAL(t1)
    jal ra, DELAY
    jal ra, DELAY
    jal ra, DELAY
    j NextChar

TURN_ON:
    jal ra, LED_ON
    j PROCESSCHAR

TURN_OFF:
    jal ra, LED_OFF
    j PROCESSCHAR

LED_ON:

    addi sp, sp, -4
    sw   ra, 0(sp)

    li t2, GPIO_LEDBAR_LED_7
    sw t2, GPIO_OUTPUT_VAL(t1)
    jal ra, DELAY
    slli a1, a1, 1

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

LED_OFF:

    addi sp, sp, -4
    sw   ra, 0(sp)

    sw x0, GPIO_OUTPUT_VAL(t1)
    jal ra, DELAY
    slli a1, a1, 1

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# Approximately 500 ms at 16 MHz.
DELAY:

    li t4, 0x28B0AA

    loop1:
    addi t4, t4, -0x1
    beqz t4, break
    j loop1

    break:
    ret

End:
    .end
