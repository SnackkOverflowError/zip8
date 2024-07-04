const std = @import("std");

const print = std.debug.print;

pub const CpuCore = struct {
    registers: [16]u8 = [_]u8{0} ** 16,
    I: u16 = 0,
    delay_timer: u8 = 0,
    sound_timer: u8 = 0,

    pub fn processInstruction(self: *CpuCore, op_code: [2]u8) !void {
        print("hex: 0x{X:0>2}{X:0>2}", .{ op_code[0], op_code[1] });

        const first_nib = op_code[0] & 0b11110000;

        switch (first_nib) {
            0x00 => {
                const instr: u16 = combineOpCode(op_code);
                switch (instr) {
                    0x00E0 => {
                        print(" --- CLS  --- ", .{});
                        try self.CLS();
                    },
                    0x00EE => {
                        print(" --- RET  --- ", .{});
                    },
                    else => {
                        const addr = instr & 0x0FFF;
                        print(" --- SYS 0x{X:0>3}  --- addr: {}", .{ addr, addr });
                    },
                }
            },
            0x10 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- JMP 0x{X:0>3} --- addr: {}", .{ addr, addr });
            },
            0x20 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- CALL 0x{X:0>3} --- addr: {}", .{ addr, addr });
            },
            0x30 => {
                const reg = op_code[0] & 0x0F;
                print(" --- SE V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
            },
            0x40 => {
                const reg = op_code[0] & 0x0F;
                print(" --- SNE V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
            },
            0x50 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                if (last_nib == 0x00) {
                    print(" --- SE V{}, V{}", .{ reg1, reg2 });
                } else {
                    print(" --- NOOP ---", .{});
                }
            },
            0x60 => {
                const reg = op_code[0] & 0x0F;
                print(" --- LD V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
            },
            0x70 => {
                const reg = op_code[0] & 0x0F;
                print(" --- ADD V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
            },
            0x80 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                switch (last_nib) {
                    0x00 => {
                        print(" --- LD V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x01 => {
                        print(" --- OR V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x02 => {
                        print(" --- AND V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x03 => {
                        print(" --- XOR V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x04 => {
                        print(" --- ADD V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x05 => {
                        print(" --- SUB V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x06 => {
                        print(" --- SHR V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x07 => {
                        print(" --- SUBN V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    0x0E => {
                        print(" --- SHL V{}, V{} --- ", .{ reg1, reg2 });
                    },
                    else => {
                        print(" --- NOOP ---", .{});
                    },
                }
            },
            0x90 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                if (last_nib == 0x00) {
                    print(" --- SNE V{}, V{}", .{ reg1, reg2 });
                } else {
                    print(" --- NOOP ---", .{});
                }
            },
            0xA0 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- LD I,  0x{X:0>3}  --- addr: {}", .{ addr, addr });
            },
            0xB0 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- LD I,  0x{X:0>3}  --- addr: {}", .{ addr, addr });
            },
            0xC0 => {
                const reg1 = op_code[0] & 0x0F;
                print(" --- RND V{}, 0x{X:0>2} --- val: {}", .{ reg1, op_code[1], op_code[1] });
            },
            0xD0 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                print(" --- DRW V{}, V{}, {} --- ", .{ reg1, reg2, last_nib });
            },
            0xE0 => {
                const reg1 = op_code[0] & 0x0F;
                switch (op_code[1]) {
                    0x9E => {
                        print(" --- SKP V{}", .{reg1});
                    },
                    0xA1 => {
                        print(" --- SKNP V{}", .{reg1});
                    },
                    else => {
                        print(" --- NOOP ----", .{});
                    },
                }
            },
            0xF0 => {
                const reg1 = op_code[0] & 0x0F;
                switch (op_code[1]) {
                    0x07 => {
                        print(" --- LD V{}, DT --- ", .{reg1});
                    },
                    0x0A => {
                        print(" --- LD V{}, K --- ", .{reg1});
                    },
                    0x15 => {
                        print(" --- LD DT, V{} --- ", .{reg1});
                    },
                    0x18 => {
                        print(" --- LD ST, V{} --- ", .{reg1});
                    },
                    0x1E => {
                        print(" --- ADD I, V{}  --- ", .{reg1});
                    },
                    0x29 => {
                        print(" --- LD F, V{} --- ", .{reg1});
                    },
                    0x33 => {
                        print(" --- LD B, V{} --- ", .{reg1});
                    },
                    0x55 => {
                        print(" --- LD [I], V{} --- ", .{reg1});
                    },
                    0x65 => {
                        print(" --- LD V{}, [I] --- ", .{reg1});
                    },
                    else => {
                        print(" --- NOOP ---", .{});
                    },
                }
            },
            else => {
                print(" --- NOOP ---", .{});
            },
        }

        print("\n", .{});
    }

    fn CLS(self: *CpuCore) !void {
        _ = self;
    }
};

fn combineOpCode(op_code: [2]u8) u16 {
    return @as(u16, op_code[0]) << 8 | op_code[1];
}

test "test combinOpCode" {
    try std.testing.expect(combineOpCode(.{ 0x00, 0xE0 }) == 0x00E0);
    try std.testing.expect(combineOpCode(.{ 0xF3, 0x1E }) == 0xF31E);
}
