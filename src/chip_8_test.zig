const std = @import("std");

const CpuCore = @import("chip_8.zig").CpuCore;

// I think SYS is a NOOP
test "test SYS" {}

// test a draw and screen clear
test "test DRAW and CLS" {}

// test jumping to a specific mem location
test "test JP" {
    const cpu: CpuCore = .{};

    const mem: []u8 = [_]u8{ 0x14, 0x20 };
    cpu.loadROM(mem, mem.len);

    // this should execute the first op code
    cpu.cycle();

    try std.testing.expect(cpu.program_counter == 0x420);
}

// testing submodule CALL and RET
test "test CALL and RET" {
    const cpu: CpuCore = .{};

    const mem: []u8 = [_]u8{ 0x14, 0x20 };
    cpu.loadROM(mem, mem.len);
}

// testing loading a value into a register
test "test LD" {
    const cpu: CpuCore = .{};

    const mem: []u8 = [_]u8{ 0x60, 0x69 };
    cpu.loadROM(mem, mem.len);

    // this should execute the first op code
    cpu.cycle();

    try std.testing.expect(cpu.registers[0] == 0x69);
}

test "test SE - 1 register" {
    const cpu: CpuCore = .{};

    const mem: []u8 = [_]u8{
        0x60, 0x42, // load 0x42 into r0 -- 0x200
        0x30, 0x42, // skip if r0 == 0x42 -- 0x201
    };
    cpu.loadROM(mem, mem.len);

    // this should execute the first op code: LD
    cpu.cycle();
    // this should execute the second op code: SE
    cpu.cycle();

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x42);
    // normally the program counter after 2 cycles should point to 0x202
    // but we have a SE in there
    try std.testing.expect(cpu.program_counter == 0x203);
}

test "test SNE - 1 register" {
    const cpu: CpuCore = .{};

    const mem: []u8 = [_]u8{
        0x60, 0x21, // load 0x21 into r0 -- 0x200
        0x40, 0x42, // skip if r0 != 0x42 -- 0x201
    };
    cpu.loadROM(mem, mem.len);

    // this should execute the first op code: LD
    cpu.cycle();
    // this should execute the second op code: SE
    cpu.cycle();

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x21);
    // normally the program counter after 2 cycles should point to 0x202
    // but we have a SE in there
    try std.testing.expect(cpu.program_counter == 0x203);
}
