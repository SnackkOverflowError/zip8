# Zip-8: a CHIP-8 emulator written in Zig

## Why do this?
Mostly because I hate myself, partially to see whether I enjoy working on emulators.

## What is done? 
- I've tested that I can render arbitrary pixels to the terminal window.
- I've tested that I can load the program file into memory
- I've tested that I can take input from the keyboard
- I've written most of the instructions, except DRW
## What is left? 
- Need to integrate the chip 8 test suite to test all the instructions
- Need to write the implementation for the DRW instruction

## Overall ideas and plans:
- Using the [not-curses C library](https://notcurses.com/) to render to the terminal screen using the kitty terminal protocol
- I'd like to include the [CHIP-8 test suit](https://github.com/Timendus/chip8-test-suite)
- Following [this](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#0.0) chip-8 documentation

