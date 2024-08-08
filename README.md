# Zip-8: a CHIP-8 emulator written in zig

## Why do this?
mostly because I hate myself, partially to see whether I enjoy working on emulators.

## what is done? 
Through *Test Driven Development* I have confirmed that the following instructions work:
 - 1nnn - JP addr
 - 3xkk - SE Vx, byte
 - 4xkk - SNE Vx, byte
 - 5xy0 - SE Vx, Vy
 - 6xkk - LD Vx, byte
 - 7xkk - ADD Vx, byte
 - 8xy0 - LD Vx, Vy
 - 8xy1 - OR Vx, Vy
 - 8xy2 - AND Vx, Vy
 - 8xy3 - XOR Vx, Vy
 - 8xy4 - ADD Vx, Vy
 - 8xy5 - SUB Vx, Vy
 - 8xy6 - SHR Vx {, Vy}
 - 8xyE - SHL Vx {, Vy}
 - 9xy0 - SNE Vx, Vy

## what is left? 
 - 00E0 - CLS
 - 00EE - RET
 - 0nnn - SYS addr
 - 2nnn - CALL addr
 - 8xy7 - SUBN Vx, Vy
 - Annn - LD I, addr
 - Bnnn - JP V0, addr
 - Cxkk - RND Vx, byte
 - Dxyn - DRW Vx, Vy, nibble
 - Ex9E - SKP Vx
 - ExA1 - SKNP Vx
 - Fx07 - LD Vx, DT
 - Fx0A - LD Vx, K
 - Fx15 - LD DT, Vx
 - Fx18 - LD ST, Vx
 - Fx1E - ADD I, Vx
 - Fx29 - LD F, Vx
 - Fx33 - LD B, Vx
 - Fx55 - LD \[I\], Vx
 - Fx65 - LD Vx, \[I\]

## overall ideas and plans:
I'm leaning towards using [libvaxis](https://github.com/rockorager/libvaxis) for rendering to the screen.
I'd like to include the [CHIP-8 test suit](https://github.com/Timendus/chip8-test-suite)
Following [this](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#0.0) chip-8 documentation

