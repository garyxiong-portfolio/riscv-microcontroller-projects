# RISC-V Microcontroller Projects

RISC-V assembly projects by Gary Xiong for the SiFive FE310 MCU on the SparkFun Thing Plus V. The programs use memory-mapped GPIO, software timing, subroutines, and interrupts.

## Featured project: Reaction time tester

[Watch the hardware demonstration](https://youtu.be/xcOAo_o7caQ)

The program waits for a start-button press and release, generates a pseudorandom delay of 2 to 10 seconds, then lights an LED bar as a reaction cue. It polls a second button and displays the elapsed count in binary. The nominal counting interval is 10 ms; timing depends on software execution, and the eight-bit count wraps at 256.

## Projects

| Folder | Focus |
| --- | --- |
| [led-blinker](led-blinker) | Direct GPIO configuration and a reusable software delay |
| [morse-code-transmitter](morse-code-transmitter) | ASCII lookup, bit shifts, and timed LED Morse patterns |
| [reaction-time-tester](reaction-time-tester) | Button polling, pseudorandom delays, and binary measurement display |
| [interrupt-countdown-timer](interrupt-countdown-timer) | GPIO interrupts, PLIC handling, context preservation, and countdown output |

## Build and run

Each folder is a separate PlatformIO project with its own `platformio.ini`.

1. Install PlatformIO, then open the desired project folder.
2. Build with `pio run`.
3. Connect the SparkFun Thing Plus V and use the board's configured debug/upload connection to upload with `pio run --target upload`.

The saved configuration selects `platform = sifive`, `board = sparkfun_thing_plus_v`, and `framework = freedom-e-sdk`. Each `src` folder contains the assembly program and C entry-point/header files. The external LED bar and push-button wiring must match the GPIO constants in the source.

Build outputs and editor caches are excluded. The source has not been rebuilt or re-tested on hardware as part of this documentation update.

## Attribution

The assembly programs use supplied startup and interface scaffolding. Existing third-party notices are retained. Supplied components retain their original terms; no blanket license is applied to this repository.
