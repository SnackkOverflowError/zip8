const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;

pub fn processOp(cpu: *Cpu, opcode: u16) void {
    // seperate the opcode into 4 parts
    const opcode_sections: [4]u4 = split_op(opcode);

    switch (opcode_sections[0]) {
        0, 1, 2, 0xA, 0xB => block1(opcode_sections, cpu), // -nnn
        3, 4, 6, 7, 0xC => block2(opcode_sections, cpu), // -xkk
        5, 8, 9 => block3(opcode_sections, cpu), // -xy-
        0xE, 0xF => block4(opcode_sections, cpu), // -x--
        0xD => DRW(cpu, cpu.V[opcode_sections[1]], cpu.V[opcode_sections[2]], opcode_sections[3]), // -xyn
    }
}

fn block1(opcode_sections: [4]u4, cpu: *Cpu) void {
    // 00E0 - CLS
    if (opcode_sections[0] == 0 and opcode_sections[1] == 0 and opcode_sections[2] == 0xE and opcode_sections[3] == 0) {
        CLS(cpu);
        return;
    }
    // 00EE - RET
    if (opcode_sections[0] == 0 and opcode_sections[1] == 0 and opcode_sections[2] == 0xE and opcode_sections[3] == 0xE) {
        RET(cpu);
        return;
    }

    const address: u16 = form_nnn(opcode_sections);
    switch (opcode_sections[0]) {
        0 => SYS(cpu, address),
        1 => JP(cpu, address),
        2 => CALL(cpu, address),
        0xA => LD(&cpu.I, address),
        0xB => JP(cpu, address + @as(u16, @intCast(cpu.V[0]))),
        else => {
            // error
            std.debug.print("should not have reached here: block 1: {}", .{opcode_sections[0]});
        },
    }
}

fn block2(opcode_sections: [4]u4, cpu: *Cpu) void {
    // form the byte kk
    const kk: u8 = form_byte(opcode_sections[2], opcode_sections[3]);
    const x = opcode_sections[2];
    switch (opcode_sections[0]) {
        3 => SE(cpu, cpu.V[x], kk),
        4 => SNE(cpu, cpu.V[x], kk),
        6 => LD(&cpu.V[x], kk),
        7 => ADD(&cpu.V[x], kk),
        0xC => RND(cpu, &cpu.V[x], kk),
        else => {},
    }
}

fn block3(opcode_sections: [4]u4, cpu: *Cpu) void {
    const x: u4 = opcode_sections[1];
    const y: u4 = opcode_sections[2];
    switch (opcode_sections[0]) {
        5 => switch (opcode_sections[3]) {
            0 => SE(cpu, cpu.V[x], cpu.V[y]),
            else => {},
        },
        9 => switch (opcode_sections[3]) {
            0 => SNE(cpu, cpu.V[x], cpu.V[y]),
            else => {},
        },
        8 => switch (opcode_sections[3]) {
            0 => LD(&cpu.V[x], cpu.V[y]),
            1 => OR(&cpu.V[x], cpu.V[y]),
            2 => AND(&cpu.V[x], cpu.V[y]),
            3 => XOR(&cpu.V[x], cpu.V[y]),
            4 => ADD(&cpu.V[x], cpu.V[y]),
            5 => SUB(&cpu.V[x], cpu.V[y], &cpu.V[0xF]),
            6 => SHR(&cpu.V[x], cpu.V[y]),
            7 => SUBN(&cpu.V[x], cpu.V[y], &cpu.V[0xF]),
            8 => SHL(&cpu.V[x], cpu.V[y]),
            else => {},
        },
    }
}
fn block4(opcode_sections: [4]u4, cpu: *Cpu) void {
    const x: u4 = opcode_sections[1];
    const y: u8 = form_byte(opcode_sections[2], opcode_sections[3]);
    switch (opcode_sections[0]) {
        0xE => switch (y) {
            0x9E => SKP(cpu, cpu.V[x]),
            0xA1 => SKNP(cpu, cpu.V[x]),
            else => {},
        },
        0xF => switch (y) {
            0x07 => LD(&cpu.V[x], cpu.delay),
            0x0A => {
                // All execution stops until a key is pressed, then the value of that key is stored in Vx.
            },
            0x15 => LD(&cpu.delay, cpu.V[x]),
            0x18 => LD(&cpu.sound, cpu.V[x]),
            0x1E => ADD(&cpu.I, cpu.V[x]),
            0x29 => LD(&cpu.I, cpu.V[x] * 5), // Set I = location of sprite for digit Vx.
            0x33 => BCD(cpu, cpu.V[x]),
            // Store registers V0 through Vx in memory starting at location I.
            0x55 => @memcpy(cpu.ram[cpu.I .. cpu.I + x + 1], cpu.V[0 .. x + 1]),
            // Read registers V0 through Vx from memory starting at location I.
            0x65 => @memcpy(cpu.V[0 .. x + 1], cpu.ram[cpu.I .. cpu.I + x + 1]),
            else => {},
        },
        else => {},
    }
}

fn RET(cpu: *Cpu) void {
    cpu.PC = cpu.Stack[cpu.SP];
    cpu.SP -= 1;
}

fn CLS(cpu: *Cpu) void {
    _ = cpu;
}

fn CALL(cpu: *Cpu, address: u16) void {
    cpu.SP += 1;
    cpu.Stack[cpu.SP] = cpu.PC;
    cpu.PC = address;
}

fn SYS(cpu: *Cpu, address: u16) void {
    cpu.PC = address;
}

fn JP(cpu: *Cpu, address: u16) void {
    cpu.PC = address;
}

fn SE(cpu: *Cpu, a: u8, b: u8) void {
    if (a == b) cpu.PC += 1;
}

fn SNE(cpu: *Cpu, a: u8, b: u8) void {
    if (a != b) cpu.PC += 1;
}

fn DRW(cpu: *Cpu, x: u8, y: u8, n: u4) void {
    _ = cpu;
    _ = x;
    _ = y;
    _ = n;
}

fn SKP(cpu: *Cpu, k: u8) void {
    _ = cpu;
    _ = k;
}
fn SKNP(cpu: *Cpu, k: u8) void {
    _ = cpu;
    _ = k;
}

fn RND(cpu: *Cpu, a: *u8, b: u8) void {
    a.* = cpu.rng.int(u8) & b;
}

// The interpreter takes the decimal value of x, and places the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.
fn BCD(cpu: *Cpu, x: u8) void {
    cpu.ram[cpu.I] = x / 100;
    cpu.ram[cpu.I + 1] = (x / 10) % 10;
    cpu.ram[cpu.I + 2] = x % 10;
}

fn LD(a: *u8, b: u8) void {
    a.* = b;
}
fn ADD(a: *u8, b: u8) void {
    a.* += b;
}
fn SUB(a: *u8, b: u8, vf: *u8) void {
    if (a > b) {
        vf.* = 1;
    } else {
        vf.* = 0;
    }
    a.* = a - b;
}
fn SUBN(a: *u8, b: u8, vf: *u8) void {
    if (b > a) {
        vf.* = 1;
    } else {
        vf.* = 0;
    }
    a.* = b - a;
}

fn OR(a: *u8, b: u8) void {
    a.* |= b;
}
fn AND(a: *u8, b: u8) void {
    a.* &= b;
}
fn XOR(a: *u8, b: u8) void {
    a.* ^= b;
}
fn SHR(a: *u8, vf: *u8) void {
    if (a & 0x80 != 0) {
        vf.* = 1;
    } else {
        vf.* = 0;
    }
    a.* = a << 1;
}

fn SHL(a: *u8, vf: *u8) void {
    if (a & 0x01 != 0) {
        vf.* = 1;
    } else {
        vf.* = 0;
    }
    a.* = a >> 1;
}

fn split_op(op: u16) [4]u4 {
    return .{
        @as(u4, @truncate((op >> 12) & 0xF)),
        @as(u4, @truncate((op >> 8) & 0xF)),
        @as(u4, @truncate((op >> 4) & 0xF)),
        @as(u4, @truncate((op >> 0) & 0xF)),
    };
}

// use the last 3 sections to form a u16
fn form_nnn(op: [4]u4) u16 {
    return (@as(u16, op[1]) << 8) | (@as(u16, op[2]) << 4) | (@as(u16, op[3]));
}

fn form_byte(a: u4, b: u4) u16 {
    return @as(u8, a << 4) | (@as(u8, b));
}
