.section .text
.align 2
.globl _start

.equ GPIO_BASE_CTRL_ADDR,   0x10012000
.equ GPIO_OUTPUT_EN,        0x08
.equ GPIO_OUTPUT_VAL,       0x0C
.equ GPIO_INPUT_VAL,        0x00
.equ GPIO_INPUT_EN,         0x04
.equ GPIO_PUE,              0x10
.equ GPIO_FALL_IE,          0x20
.equ GPIO_FALL_IP,          0x24

.equ GPIO_LEDBAR_PINS,  0x00FC0C00
.equ GPIO_LED1,         0x00000400
.equ GPIO_LED2,         0x00000800
.equ GPIO_LED3,         0x00040000
.equ GPIO_LED4,         0x00080000
.equ GPIO_LED5,         0x00100000
.equ GPIO_LED6,         0x00200000
.equ GPIO_LED7,         0x00400000
.equ GPIO_LED8,         0x00800000
.equ GPIO_S1,           0x00001000

.equ PLIC_ENABLE_1,         0x0C002000
.equ PLIC_THRESHOLD,        0x0C200000
.equ PLIC_CLAIM,            0x0C200004

.equ GPIO12_IRQ_ID,         20
.equ GPIO12_PRIORITY_ADDR,  0x0C000050

_start:

li s0, GPIO_BASE_CTRL_ADDR
addi s1, s0, GPIO_OUTPUT_VAL

li a7, 123
li a4, 0

      # Install the handler and enable machine external interrupts.
      la t0, S1_interrupt

      csrw mtvec, t0

      li t0, (1 << 11)

      csrs mie, t0

      csrr t0, mstatus
      li t1, (1 << 3)

      or t0, t0, t1

      csrw mstatus, t0

lw t1, GPIO_INPUT_EN(s0)
li t0, GPIO_S1
or t1, t1, t0
sw t1, GPIO_INPUT_EN(s0)

lw t1, GPIO_PUE(s0)
li t0, GPIO_S1
or t1, t1, t0
sw t1, GPIO_PUE(s0)

lw t1, GPIO_OUTPUT_EN(s0)
li t0, GPIO_LEDBAR_PINS
or t1, t1, t0
sw t1, GPIO_OUTPUT_EN(s0)

jal clear_leds

# S1 is active low, so a press triggers a falling-edge interrupt.
lw t1, GPIO_FALL_IE(s0)
li t0, GPIO_S1
or t1, t1, t0
sw t1, GPIO_FALL_IE(s0)

li t0, GPIO_S1
sw t0, GPIO_FALL_IP(s0)

li t0, PLIC_ENABLE_1
lw t1, 0(t0)
li t2, (1 << GPIO12_IRQ_ID)
or t1, t1, t2
sw t1, 0(t0)

# Set S1 priority above the PLIC threshold.
li t0, GPIO12_PRIORITY_ADDR
li t1, 7
sw t1, 0(t0)

li t0, PLIC_THRESHOLD
li t1, 6
sw t1, 0(t0)

main_program:

li t0, GPIO_LEDBAR_PINS
sw t0, 0(s1)

jal delay100ms
jal clear_leds
jal delay100ms
jal RandomNum

j main_program

# Preserve the interrupted context while displaying the countdown.
S1_interrupt:

addi sp, sp, -32
sw ra,  0(sp)
sw t0,  4(sp)
sw t1,  8(sp)
sw t2, 12(sp)
sw t3, 16(sp)
sw a0, 20(sp)
sw t4, 24(sp)

li t0, PLIC_CLAIM
lw t1, 0(t0)
sw t1, 28(sp)

li t2, GPIO12_IRQ_ID
bne t1, t2, isr_finish_only

# a4 holds 50-250 tenths of a second; subtract 10 per one-second delay.
Scale:

li t2, 201
remu t3, a7, t2
addi a4, t3, 50

countdown_loop:
blez a4, countdown_done

mv a0, a4
jal showOnLedbar

jal delay1s

addi a4, a4, -10
j countdown_loop

countdown_done:
li a4, 0
jal clear_leds

# Clear the GPIO pending flag, then complete the original PLIC claim.
isr_finish_only:
li t0, GPIO_S1
sw t0, GPIO_FALL_IP(s0)

li t0, PLIC_CLAIM
lw t1, 28(sp)
sw t1, 0(t0)

lw ra,  0(sp)
lw t0,  4(sp)
lw t1,  8(sp)
lw t2, 12(sp)
lw t3, 16(sp)
lw a0, 20(sp)
lw t4, 24(sp)
addi sp, sp, 32
mret

# Update a7 using XOR feedback from bits 15, 13, 12, and 10.
RandomNum:
li t0, 0x8000
and t1, a7, t0

li t0, 0x2000
and t3, a7, t0
slli t3, t3, 2
xor t3, t1, t3

li t0, 0x1000
and t1, a7, t0
slli t1, t1, 3
xor t3, t3, t1

andi t1, a7, 0x0400
slli t1, t1, 5
xor t3, t3, t1

srli t3, t3, 15
slli a7, a7, 1
or a7, a7, t3

ret

# Map a0 bits 0-1 to GPIO10-11 and bits 2-7 to GPIO18-23.
showOnLedbar:
addi sp, sp, -12
sw ra, 8(sp)
sw t0, 4(sp)
sw t1, 0(sp)

andi t0, a0, 0x03
slli t0, t0, 10

andi t1, a0, 0xFC
slli t1, t1, 16

or t0, t0, t1
sw t0, 0(s1)

lw t1, 0(sp)
lw t0, 4(sp)
lw ra, 8(sp)
addi sp, sp, 12
ret

# Preserve GPIO outputs outside the LED bar.
clear_leds:
addi sp, sp, -8
sw t0, 4(sp)
sw t1, 0(sp)

lw t0, 0(s1)
li t1, GPIO_LEDBAR_PINS
not t1, t1
and t0, t0, t1
sw t0, 0(s1)

lw t1, 0(sp)
lw t0, 4(sp)
addi sp, sp, 8
ret

# Base delay is approximately 10 ms; timing depends on the hardware.
baseDelay:
li t4, 80000

baseDelayLoop:
addi t4, t4, -1
bnez t4, baseDelayLoop
ret

delay10ms:
addi sp, sp, -4
sw ra, 0(sp)
jal ra, baseDelay
lw ra, 0(sp)
addi sp, sp, 4
ret

delay100ms:
addi sp, sp, -8
sw ra, 4(sp)
sw t0, 0(sp)
li t0, 10

delay100msLoop:
jal ra, delay10ms
addi t0, t0, -1
bnez t0, delay100msLoop

lw t0, 0(sp)
lw ra, 4(sp)
addi sp, sp, 8
ret

delay1s:
addi sp, sp, -8
sw ra, 4(sp)
sw t0, 0(sp)
li t0, 10

delay1sLoop:
jal ra, delay100ms
addi t0, t0, -1
bnez t0, delay1sLoop

lw t0, 0(sp)
lw ra, 4(sp)
addi sp, sp, 8
ret
