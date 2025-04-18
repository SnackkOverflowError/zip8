const std = @import("std");
const Display = @import("display.zig").Display;
const operations = @import("operations.zig");
const input = @import("input.zig");

const sprites = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    //
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    //
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    //
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

const rows: usize = 32;
const cols: usize = 64;

pub const Cpu = struct {
    V: [16]u8 = [_]u8{0} ** 16,
    I: u16 = 0,

    PC: u16 = 0x200,
    SP: u8 = 0,

    sound: u8 = 0,
    delay: u8 = 0,

    Stack: [16]u16 = [_]u16{0} ** 16,
    rng: std.Random,

    ram: [0xFFF]u8 = [_]u8{0} ** 0xFFF,

    rows: usize = rows,
    cols: usize = cols,
    screen: [rows][cols / 8]u8,
    display: ?*Display,

    keys: u16 = 0,

    pub fn init(prog_mem: []u8, disp: ?*Display) !Cpu {
        // create the random number generator
        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        const screen: [rows][cols / 8]u8 = [1][cols / 8]u8{[_]u8{0} ** (cols / 8)} ** rows;

        var cpu: Cpu = .{ .rng = rand, .screen = screen, .display = disp };

        // memcpy the sprites to the start of ram
        @memcpy(cpu.ram[0..sprites.len], &sprites);
        // memcpy the prog_mem to address 0x200
        @memcpy(cpu.ram[0x200 .. 0x200 + prog_mem.len], prog_mem);

        return cpu;
    }

    pub fn cycle(self: *Cpu) !void {
        if (self.display) |display| {
            // get the keystate
            const key_state = input.getKeyboardState(display.nc);
            // TODO check for quit
            self.keys = key_state[0];
        }

        // fetch op code
        const op: u16 = (@as(u16, self.ram[self.PC]) << 8) | (@as(u16, self.ram[self.PC + 1]));
        //std.debug.print("op: 0x{x:0>4}, pc: 0x{x:0>4}\n", .{ op, self.PC });
        self.PC += 2;
        // process op code
        operations.processOp(self, op);

        // display to screen
        if (self.display) |display| {
            try display.display(self.getScreen());
        }
        // delay to maintain 60hz

    }

    pub fn getScreen(self: Cpu) [rows * cols * 3]u8 {
        var screen: [rows * cols * 3]u8 = [_]u8{0} ** (rows * cols * 3);
        // set pixels to 255 or 0
        for (self.screen, 0..) |row, row_idx| {
            for (row, 0..) |val, col_idx| {
                for (0..8) |bit_idx| {
                    // determine if the bit is high
                    const mask: u8 = @as(u8, 0x1) << @as(u3, 7 - @as(u3, @truncate(bit_idx)));
                    if (mask & val != 0) {
                        // bit is high
                        screen[row_idx * cols + col_idx + 0] = 255;
                        screen[row_idx * cols + col_idx + 1] = 255;
                        screen[row_idx * cols + col_idx + 2] = 255;
                    }
                }
            }
        }
        return screen;
    }

    pub fn printScreen(self: *Cpu) void {
        for (self.screen) |row| {
            for (row) |val| {
                std.debug.print("{b:0>8}", .{val});
            }
            std.debug.print("\n", .{});
        }
    }
};
