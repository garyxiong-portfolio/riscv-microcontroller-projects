.section .text
.align 2
.globl _start

_start:

    .equ GPIO_BASE_CTRL_ADDR,   0x10012000
    .equ GPIO_OUTPUT_EN,        0x08
    .equ GPIO_OUTPUT_VAL,       0x0C
    .equ GPIO_INPUT_VAL,        0x00
    .equ GPIO_INPUT_EN,         0x04
    .equ GPIO_PUE,              0x10

    li s0, GPIO_BASE_CTRL_ADDR
    addi s1, s0, GPIO_OUTPUT_VAL
    addi s2, s0, GPIO_INPUT_VAL

    .equ GPIO_LEDBAR_PINS,      0x00FC0C00
    .equ GPIO_LED1,             0x00000400
    .equ GPIO_LED2,             0x00000800
    .equ GPIO_LED3,             0x00040000
    .equ GPIO_LED4,             0x00080000
    .equ GPIO_LED5,             0x00100000
    .equ GPIO_LED6,             0x00200000
    .equ GPIO_LED7,             0x00400000
    .equ GPIO_LED8,             0x00800000

    li      t0, GPIO_LEDBAR_PINS
    li      t1, GPIO_BASE_CTRL_ADDR
    addi    t1, t1, GPIO_OUTPUT_EN
    sw      t0, 0(t1)

    .equ GPIO_S1,               0x00001000
    .equ GPIO_S2,               0x00002000
    .equ GPIO_BOTH_BUTTONS,     0x00003000

    li t0, GPIO_BOTH_BUTTONS
    addi t1, s0, GPIO_INPUT_EN
    sw t0, 0(t1)

    li t0, GPIO_BOTH_BUTTONS
    addi t1, s0, GPIO_PUE
    sw t0, 0(t1)

LEDS_OFF:

    sw zero, 0(s1)

# a7 holds the PRNG state and must start with a nonzero seed.
InitRandomNum:

    li a7, 0xABCD

# Count on the LED bar until S1 is pressed. Buttons are active low.
Task_1:

    li s3, 0

Task_1_Loop:
    li t5, GPIO_S1
    lw s4, 0(s2)
    and s4, s4, t5
    beqz s4, Task_2

    addi a0, s3, 0
    jal ra, SHOW_ON_LEDBAR
    jal ra, DELAY_100MS
    addi s3, s3, 1
    andi s3, s3, 0xFF
    j Task_1_Loop

# After S1 is released, wait 2-10 seconds before starting the reaction timer.
Task_2:

    S1_PRESSED:
    lw t0, 0(s2)
    li t1, GPIO_S1
    and t0, t0, t1
    beqz t0, S1_PRESSED

    sw zero, 0(s1)

    jal ra, RandomNum
    jal ra, Scale

    addi s4, a0, 0

    WAIT_RANDOMLY:
    beqz s4, START_TASK2
    jal ra, DELAY_1S
    addi s4, s4, -1
    j WAIT_RANDOMLY

    START_TASK2:

    li t0, GPIO_LEDBAR_PINS
    sw t0, 0(s1)

    li s5, 0

    # Count in approximately 10 ms units until S2 is pressed; wrap at 256.
    CHECK_REACTION:
    jal ra, DELAY_10MS

    lw t0, 0(s2)
    li t1, GPIO_S2
    and t0, t0, t1
    beqz t0, DISPLAY_TIMETAKEN

    addi s5, s5, 1
    andi s5, s5, 0xFF
    addi a0, s5, 0
    jal ra, SHOW_ON_LEDBAR

    j CHECK_REACTION

    DISPLAY_TIMETAKEN:
    addi a0, s5, 0
    jal ra, SHOW_ON_LEDBAR

    S2_RELEASED:
    lw t0, 0(s2)
    li t1, GPIO_S2
    and t0, t0, t1
    beqz t0, S2_RELEASED

    # Hold the result until S1 is pressed and released.
    WAITINGFORS1:
    lw t0, 0(s2)
    li t1, GPIO_S1
    and t0, t0, t1
    bnez t0, WAITINGFORS1

    TIMETOGOBACKTOS1FORREAL:
    lw t0, 0(s2)
    li t1, GPIO_S1
    and t0, t0, t1
    beqz t0, TIMETOGOBACKTOS1FORREAL

    sw zero, 0(s1)
    j Task_1

# Return a delay of 2-10 seconds in a0 from the PRNG state in a7.
Scale:

    addi sp, sp, -8
    sw ra, 4(sp)
    sw t0, 0(sp)

    li t0, 9
    remu a0, a7, t0
    addi a0, a0, 2

    lw t0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

# Update a7 using XOR feedback from bits 15, 13, 12, and 10.
RandomNum:
    addi sp, sp, -16
    sw ra, 12(sp)

    li s4, 0x8000
    and t1, a7, s4

    li s4, 0x2000
    and t3, a7, s4

    slli t3, t3, 2
    xor t3, t1, t3

    li s4, 0x1000
    and t1, a7, s4

    slli t1, t1, 3
    xor t3, t3, t1

    andi t1, a7, 0x0400
    slli t1, t1, 5
    xor t3, t3, t1

    srli t3, t3, 15
    slli a7, a7, 1
    or a7, a7, t3

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# Map a0 bits 0-1 to GPIO10-11 and bits 2-7 to GPIO18-23.
SHOW_ON_LEDBAR:

    addi sp, sp, -8
    sw ra, 4(sp)
    sw t0, 0(sp)

    andi t0, a0, 0x03
    slli t0, t0, 10

    andi t1, a0, 0xFC
    slli t1, t1, 16

    or t0, t0, t1
    sw t0, 0(s1)

    lw t0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

# Base delay is approximately 10 ms; timing depends on the hardware.
Delay:

li t4, 80000
Delay_Loop:
    addi t4, t4, -1
    bnez t4, Delay_Loop
    ret

DELAY_10MS:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal ra, Delay
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

DELAY_100MS:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw t0, 0(sp)

    li t0, 10
Delay100_Loop:
    jal ra, DELAY_10MS
    addi t0, t0, -1
    bnez t0, Delay100_Loop

    lw t0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

DELAY_1S:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw t0, 0(sp)

    li t0, 10
Delay1S_Loop:
    jal ra, DELAY_100MS
    addi t0, t0, -1
    bnez t0, Delay1S_Loop

    lw t0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret

End:
    .end
