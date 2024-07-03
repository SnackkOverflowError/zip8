const std = @import("std");

const print = std.debug.print;

pub const CpuCore = struct {
    registers: [16]u8 = [_]u8{0} ** 16,
    I: u16 = 0,
    delay_timer: u8 = 0,
    sound_timer: u8 = 0,

    pub fn printOpCode(self: CpuCore, op_code: [2]u8) !void {
        _ = self;
        print("hex: 0x{X:0>2}{X:0>2}", .{ op_code[0], op_code[1] });

        const first_nib = op_code[0] & 0b11110000;

        switch (first_nib) {
            //            0x00 => {},
            0x10 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- JUMP 0x{X:0>3} --- addr: {}", .{ addr, addr });
            },
            0x20 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- CALL 0x{X:0>3} --- addr: {}", .{ addr, addr });
            },

            //            0x30 => {},
            //            0x40 => {},
            //            0x50 => {},
            //            0x60 => {},
            //            0x70 => {},
            //            0x80 => {},
            //            0x90 => {},
            //            0xA0 => {},
            //            0xC0 => {},
            //            0xD0 => {},
            //            0xE0 => {},
            //            0xF0 => {},
            else => {
                print(" --- NOT IMPLEMENTED", .{});
            },
        }

        print("\n", .{});
    }
};

fn combineOpCode(op_code: [2]u8) u16 {
    return @as(u16, op_code[0]) << 8 | op_code[1];
}

test "test combinOpCode" {
    try std.testing.expect(combineOpCode(.{ 0x00, 0xE0 }) == 0x00E0);
    try std.testing.expect(combineOpCode(.{ 0xF3, 0x1E }) == 0xF31E);
}
