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

test "test ADD - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x21, // load 0x21 into r0 -- 0x200
        0x61, 0x01, // load 0x01 into r0 -- 0x200
        0x81, 0x04, // r1 += r0 -- 0x202
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    // this should execute the third op code: ADD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    // TODO test for overflow

    // ensure that ADD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x21);
    // ensure that ADD worked as expected
    try std.testing.expect(cpu.registers[1] == 0x22);
    std.debug.print("test ADD - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test SUB - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x22, // load into r0 -- 0x200
        0x61, 0x21, // load into r1 -- 0x202
        0x81, 0x05, // r1 -= r0 -- 0x204
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    // this should execute the third op code: AND
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    // TODO test for underflow

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0x22);
    // ensure that AND worked as expected
    try std.testing.expect(cpu.registers[1] == 0x00);
    std.debug.print("test SUB - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test OR - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0b10101010, // load 0x21 into r0 -- 0x200
        0x61, 0b01010101, // load 0x21 into r0 -- 0x200
        0x81, 0x01, // r1 |= r0 -- 0x202
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    // this should execute the third op code: AND
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0b10101010);
    // ensure that OR worked as expected
    try std.testing.expect(cpu.registers[1] == 0xFF);
    std.debug.print("test OR - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test AND - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0b10101011, // load into r0 -- 0x200
        0x61, 0b01010101, // load into r0 -- 0x202
        0x81, 0x02, // r1 &= r0 -- 0x204
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    // this should execute the third op code: AND
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0b10101011);
    // ensure that AND worked as expected
    try std.testing.expect(cpu.registers[1] == 0x01);
    std.debug.print("test AND - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test XOR - 2 registers" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0b10101011, // load into r0 -- 0x200
        0x61, 0b01010101, // load into r1 -- 0x202
        0x81, 0x03, // r1 ^= r0 -- 0x204
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // this should execute the second op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);
    // this should execute the third op code: XOR
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[0] == 0b10101011);
    // ensure that AND worked as expected
    try std.testing.expect(cpu.registers[1] == 0b11111110);
    std.debug.print("test XOR - 2 registers SUCCEEDED --------------------------\n", .{});
}

test "test SHR - 1 register" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x61, 0b10010001, // load into r1 -- 0x200
        0x81, 0x06, // r1 SHR 1 -- 0x202
        0x81, 0x06, // r1 SHR 1 -- 0x204
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    try std.testing.expect(cpu.registers[1] == 0b10010001);

    // this should execute the second op code: SHR
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);

    // ensure that SHR worked as expected
    try std.testing.expect(cpu.registers[1] == 0b01001000);
    try std.testing.expect(cpu.registers[0xF] == 0x1);

    // execute the second SHR
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    // ensure that SHR worked as expected
    try std.testing.expect(cpu.registers[1] == 0b00100100);
    try std.testing.expect(cpu.registers[0xF] == 0x0);

    std.debug.print("test SHR - 1 register SUCCEEDED --------------------------\n", .{});
}

test "test SHL - 1 register" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x61, 0b01001001, // load into r1 -- 0x202
        0x81, 0x0E, // r1 SHL 1 -- 0x204
        0x81, 0x0E, // r1 SHL 1 -- 0x206
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    // ensure that LD worked as expected
    try std.testing.expect(cpu.registers[1] == 0b01001001);
    // this should execute the third op code: AND
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);

    try std.testing.expect(cpu.registers[1] == 0b10010010);
    try std.testing.expect(cpu.registers[0xF] == 0x0);

    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    try std.testing.expect(cpu.registers[1] == 0b00100100);
    try std.testing.expect(cpu.registers[0xF] == 0x01);

    std.debug.print("test SHL - 1 register SUCCEEDED --------------------------\n", .{});
}

test "test LD - I, addr" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0xA1, 0x02, // load into I -- 0x200
    };
    cpu.loadROM(mem);

    // this should execute the first op code: LD
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    try std.testing.expect(cpu.I == 0x102);

    std.debug.print("test LD - I, addr  SUCCEEDED --------------------------\n", .{});
}

test "test JP - V0, addr" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0x60, 0x06, // load 2 into V0 - 0x200
        0xB2, 0x00, // JP V0 + 0x200 -- 0x202
        0x61, 0x69, // LD 0x69 into V1 -- 0x204
        0x61, 0x42, // LD 0x42 into V1 -- 0x206
    };
    cpu.loadROM(mem);

    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    try std.testing.expect(cpu.registers[0] == 0x06);

    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    try cpu.cycle();
    try std.testing.expect(cpu.registers[1] == 0x42);

    std.debug.print("test JP - V0, addr  SUCCEEDED --------------------------\n", .{});
}

test "test RND - VX, byte" {
    var cpu: CpuCore = .{};

    const mem: []const u8 = &.{
        0xC0, 0xFF, // RND -- 0x200
        0xC0, 0xFF, // RND -- 0x200
        0xC0, 0x00, // RND -- 0x200
    };
    cpu.loadROM(mem);

    // this should execute the first op code: RND
    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x202);
    const reg_0_og: u8 = cpu.registers[0];

    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x204);

    try std.testing.expect(cpu.registers[0] != reg_0_og);

    try cpu.cycle();
    try std.testing.expect(cpu.program_counter == 0x206);

    try std.testing.expect(cpu.registers[0] != 0x00);

    std.debug.print("test RND - VX, byte  SUCCEEDED --------------------------\n", .{});
}
