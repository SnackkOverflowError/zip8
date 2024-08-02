const std = @import("std");

const CpuCore = @import("chip_8.zig").CpuCore;

// I think SYS is a NOOP
test "test SYS" {}

// test a draw and screen clear
test "test DRAW and CLS" {}

// test jumping to a specific mem location
test "test JP" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{ 0x14, 0x20 };

    cpu.loadROM(mem);

    // this should execute the first op code
    try cpu.cycle();

    std.debug.print("program counter: 0x{X:0>3}\n", .{cpu.program_counter});
    try std.testing.expect(cpu.program_counter == 0x420);
    std.debug.print("test JP SUCCEEDED --------------------------\n", .{});
}

// testing submodule CALL and RET
test "test CALL and RET" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{ 0x14, 0x20 };
    cpu.loadROM(mem);

    std.debug.print("test CALL and RET SUCCEEDED --------------------------\n", .{});
}

// testing loading a value into a register
test "test LD" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{ 0x60, 0x69 };
    cpu.loadROM(mem);

    // this should execute the first op code
    try cpu.cycle();
    // test that the program counter went up by 2
    try std.testing.expect(cpu.program_counter == 0x202);

    // test that the
    try std.testing.expect(cpu.registers[0] == 0x69);
    std.debug.print("test LD SUCCEEDED --------------------------\n", .{});
}

test "test LD - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x22, // load 0x22 into r0
        0x81, 0x00, // load r0 into r1
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the 2nd op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x022);
    // ensure that the second LD worked as expected
    try std.testing.expect(cpu.registers[1] == 0x22);

    std.debug.print("test LD - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test SE - 1 register" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x42, // load 0x42 into r0 -- 0x200
        0x30, 0x42, // skip if r0 == 0x42 -- 0x202
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: SE
    try cpu.cycle();
    // normally the program counter after 2 cycles should point to 0x204
    // but we have a SE in there
    try std.testing.expect(cpu.program_counter == 0x206);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x42);
    std.debug.print("test SE - 1 register SUCCEEDED --------------------------\n", .{});
}

test "test SNE - 1 register" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x21, // load 0x21 into r0 -- 0x200
        0x40, 0x42, // skip if r0 != 0x42 -- 0x202
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: SNE
    try cpu.cycle();
    // normally the program counter after 2 cycles should point to 0x204
    // but we have a SE in there
    try std.testing.expect(cpu.program_counter == 0x206);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x21);
    std.debug.print("test SNE - 1 register SUCCEEDED --------------------------\n", .{});
}

test "test SE - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x21, // load 0x21 into r0 -- 0x200
        0x61, 0x21, // load 0x21 into r1 -- 0x202
        0x50, 0x10, // skip if r0 == r1 -- 0x204
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: SNE
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    try cpu.cycle();
    // normally the program counter after 2 cycles should point to 0x206
    // but we have a SE in there
    try std.testing.expect(cpu.program_counter == 0x208);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x21);
    try std.testing.expect(cpu.registers[1] == 0x21);
    std.debug.print("test SE - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test SNE - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x21, // load 0x21 into r0 -- 0x200
        0x61, 0x22, // load 0x22 into r1 -- 0x202
        0x90, 0x10, // skip if r0 != r1 -- 0x204
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: SNE
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    try cpu.cycle();
    // normally the program counter after 3 cycles should point to 0x206
    // but we have a SE in there
    try std.testing.expect(cpu.program_counter == 0x208);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x21);
    try std.testing.expect(cpu.registers[1] == 0x22);
    std.debug.print("test SNE - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test ADD - 1 register" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x70, 0x10,
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);

    // ensure that ADD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x10);
    std.debug.print("test ADD SUCCEEDED --------------------------\n", .{});
}
