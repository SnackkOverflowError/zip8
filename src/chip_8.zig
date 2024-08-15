const std = @import("std");

const print = std.debug.print;
var prng = std.rand.DefaultPrng.init(42);

const sprites: [80]u8 = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

pub const CpuCore = struct {
    registers: [16]u8 = [_]u8{0} ** 16,
    I: u16 = 0,
    delay_timer: u8 = 0,
    sound_timer: u8 = 0,
    program_counter: u16 = 0x0200,
    stack: [16]u16 = [_]u8{0} ** 16,
    stack_pointer: u8 = 0,
    keys: u16 = 0,

    screen_buffer: [32][8]u8 = [_][8]u8{
        [_]u8{0} ** 8,
    } ** 32,

    memory: [4096]u8 = [_]u8{0} ** 4096,

    pub fn loadROM(self: *CpuCore, rom: []const u8) void {
        // load program memory
        const memsize: usize = rom.len;
        const end: usize = 0x200 + memsize;
        @memcpy(self.memory[0x200..end], rom[0..memsize]);

        // load sprites
        @memcpy(self.memory[0..80], sprites);

        self.program_counter = 0x200;
    }

    pub fn cycle(self: *CpuCore) !void {
        const op_code: [2]u8 = [2]u8{ self.memory[self.program_counter], self.memory[self.program_counter + 1] };
        self.program_counter += 2;
        try self.processInstruction(op_code);
    }

    fn processInstruction(self: *CpuCore, op_code: [2]u8) !void {
        print("hex: 0x{X:0>2}{X:0>2}", .{ op_code[0], op_code[1] });

        const first_nib = op_code[0] & 0b11110000;
        const instr: u16 = combineOpCode(op_code);

        switch (first_nib) {
            0x00 => {
                switch (instr) {
                    0x00E0 => {
                        print(" --- CLS  --- ", .{});
                        self.CLS();
                    },
                    0x00EE => {
                        print(" --- RET  --- ", .{});
                        self.RET();
                    },
                    else => {
                        const addr = instr & 0x0FFF;
                        print(" --- SYS 0x{X:0>3}  --- addr: {d:0>4} --- {b:0>16}", .{ addr, addr, instr });
                        print(" --- NO OP ---");
                    },
                }
            },
            0x10 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- JMP 0x{X:0>3} --- addr: {}", .{ addr, addr });
                self.JMP(addr);
            },
            0x20 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- CALL 0x{X:0>3} --- addr: {}", .{ addr, addr });
                self.CALL(addr);
            },
            0x30 => {
                const reg = op_code[0] & 0x0F;
                print(" --- SE V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
                self.SE(self.registers[reg], op_code[1]);
            },
            0x40 => {
                const reg = op_code[0] & 0x0F;
                print(" --- SNE V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
                self.SNE(self.registers[reg], op_code[1]);
            },
            0x50 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                if (last_nib == 0x00) {
                    print(" --- SE V{}, V{}", .{ reg1, reg2 });
                    self.SE(self.registers[reg1], self.registers[reg2]);
                } else {
                    print(" --- NOOP --- {b:0>16}", .{instr});
                }
            },
            0x60 => {
                const reg = op_code[0] & 0x0F;
                print(" --- LD V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
                LD(&self.registers[reg], op_code[1]);
            },
            0x70 => {
                const reg = op_code[0] & 0x0F;
                print(" --- ADD V{}, 0x{X:0>3} --- val: {}", .{ reg, op_code[1], op_code[1] });
                ADD(&self.registers[reg], op_code[1]);
            },
            0x80 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                switch (last_nib) {
                    0x00 => {
                        print(" --- LD V{}, V{} --- ", .{ reg1, reg2 });
                        LD(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x01 => {
                        print(" --- OR V{}, V{} --- ", .{ reg1, reg2 });
                        OR(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x02 => {
                        print(" --- AND V{}, V{} --- ", .{ reg1, reg2 });
                        AND(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x03 => {
                        print(" --- XOR V{}, V{} --- ", .{ reg1, reg2 });
                        XOR(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x04 => {
                        print(" --- ADD V{}, V{} --- ", .{ reg1, reg2 });
                        self.ADDC(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x05 => {
                        print(" --- SUB V{}, V{} --- ", .{ reg1, reg2 });
                        self.SUBC(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x06 => {
                        print(" --- SHR V{}, V{} --- ", .{ reg1, reg2 });
                        self.SHR(&self.registers[reg1]);
                    },
                    0x07 => {
                        print(" --- SUBN V{}, V{} --- ", .{ reg1, reg2 });
                        self.SUBN(&self.registers[reg1], self.registers[reg2]);
                    },
                    0x0E => {
                        print(" --- SHL V{}, V{} --- ", .{ reg1, reg2 });
                        self.SHL(&self.registers[reg1]);
                    },
                    else => {
                        print(" --- NOOP --- {b:0>16}", .{instr});
                    },
                }
            },
            0x90 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                if (last_nib == 0x00) {
                    print(" --- SNE V{}, V{}", .{ reg1, reg2 });
                    self.SNE(self.registers[reg1], self.registers[reg2]);
                } else {
                    print(" --- NOOP --- {b:0>16}", .{instr});
                }
            },
            0xA0 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- LD I,  0x{X:0>3}  --- addr: {}", .{ addr, addr });
                LD_16(&self.I, addr);
            },
            0xB0 => {
                const addr: u16 = combineOpCode(op_code) & 0x0FFF;
                print(" --- JP V0,  0x{X:0>3}  --- V0: 0x{X:0>3}", .{ addr, self.registers[0] });
                self.JMP(addr + self.registers[0]);
            },
            0xC0 => {
                const reg1 = op_code[0] & 0x0F;
                print(" --- RND V{}, 0x{X:0>2} --- val: {}", .{ reg1, op_code[1], op_code[1] });
                RND(&self.registers[reg1], op_code[1]);
            },
            0xD0 => {
                const reg1 = op_code[0] & 0x0F;
                const reg2 = (op_code[1] & 0xF0) >> 4;
                const last_nib = op_code[1] & 0x0F;
                print(" --- DRW V{}, V{}, {} --- ", .{ reg1, reg2, last_nib });
                //self.DRW();
            },
            0xE0 => {
                const reg1 = op_code[0] & 0x0F;
                switch (op_code[1]) {
                    0x9E => {
                        print(" --- SKP V{}", .{reg1});
                        self.SKP(self.registers[reg1]);
                    },
                    0xA1 => {
                        print(" --- SKNP V{}", .{reg1});
                        self.SKNP(self.registers[reg1]);
                    },
                    else => {
                        print(" --- NOOP --- {b:0>16}", .{instr});
                    },
                }
            },
            0xF0 => {
                const reg1 = op_code[0] & 0x0F;
                switch (op_code[1]) {
                    0x07 => {
                        print(" --- LD V{}, DT --- ", .{reg1});
                        LD(&self.registers[reg1], self.delay_timer);
                    },
                    0x0A => {
                        print(" --- LD V{}, K --- ", .{reg1});
                        //TODO wait for keypress
                        const val: u8 = 0;
                        LD(&self.registers[reg1], val);
                    },
                    0x15 => {
                        print(" --- LD DT, V{} --- ", .{reg1});
                        LD(&self.delay_timer, self.registers[reg1]);
                    },
                    0x18 => {
                        print(" --- LD ST, V{} --- ", .{reg1});
                        LD(&self.sound_timer, self.registers[reg1]);
                    },
                    0x1E => {
                        print(" --- ADD I, V{}  --- ", .{reg1});
                        ADD_16(&self.I, @intCast(self.registers[reg1]));
                    },
                    0x29 => {
                        print(" --- LD F, V{} --- ", .{reg1});
                        self.SET_SPRITE(self.registers[reg1]);
                    },
                    0x33 => {
                        print(" --- LD B, V{} --- ", .{reg1});
                        self.BCD(self.registers[reg1]);
                    },
                    0x55 => {
                        print(" --- LD [I], V{} --- ", .{reg1});
                        self.STORE_TO_MEM(reg1);
                    },
                    0x65 => {
                        print(" --- LD V{}, [I] --- ", .{reg1});
                        self.LOAD_FROM_MEM(reg1);
                    },
                    else => {
                        print(" --- NOOP --- {b:0>16}", .{instr});
                    },
                }
            },
            else => {
                print(" --- NOOP --- {b:0>16}", .{instr});
            },
        }

        print("\n", .{});
    }

    fn CLS(self: *CpuCore) void {
        self.screen_buffer = [4][8]u8{
            [_]u8{0} ** 8,
            [_]u8{0} ** 8,
            [_]u8{0} ** 8,
            [_]u8{0} ** 8,
        };
    }
    fn RET(self: *CpuCore) !void {
        // the pc is already incremented to the next instr
        // after the CALL instr
        self.program_counter = self.stack[self.stack_pointer];
        // lets fill the stack with invalid mem addresses so that
        // we have errors rather than weird behaviour if theres
        // an error
        self.stack[self.stack_pointer] = -1;
        self.stack_pointer -= 1;
    }

    fn CALL(self: *CpuCore, addr: u8) void {
        self.stack_pointer += 1;
        // the pc is already incremented to the next instr
        // after the CALL instr
        self.stack[self.stack_pointer] = self.program_counter;
        self.program_counter = addr;
    }

    fn JMP(self: *CpuCore, addr: u16) void {
        self.program_counter = addr;
    }

    fn SKP(self: *CpuCore, b: u8) void {
        if (self.keys & (1 << b) != 0) {
            self.program_counter += 2;
        }
    }

    fn SKNP(self: *CpuCore, b: u8) void {
        if (self.keys & (1 << b) == 0) {
            self.program_counter += 2;
        }
    }

    fn SE(self: *CpuCore, a: u8, b: u8) void {
        if (a == b) {
            self.program_counter += 2;
        }
    }

    fn SNE(self: *CpuCore, a: u8, b: u8) void {
        if (a != b) {
            self.program_counter += 2;
        }
    }

    fn DRW(self: *CpuCore, x: u8, y: u8, n: u8) void {
        const offset: u8 = x % 8;
        const x_pos: u8 = x / 8;
        var i: u8 = 0;
        while (i < n) {
            // transform the byte at I into two bytes using the offset
            const first_byte: u8 = self.memory[self.I] >> offset;
            const second_byte: u8 = self.memory[self.I] << offset;

            self.screen_buffer[y][x_pos] ^= first_byte;
            self.screen_buffer[y][x_pos + 1] ^= second_byte;
            // TODO detect collisions

            i += 1;
        }
    }

    fn SET_SPRITE(self: *CpuCore, a: u8) void {
        if (a <= 0xF) {
            self.I = a * 4;
        }
    }

    fn BCD(self: *CpuCore, val: u8) void {
        const hundreds: u8 = val / 100;
        const tens: u8 = (val % 100) / 10;
        const ones: u8 = (val % 10);

        self.memory[self.I] = hundreds;
        self.memory[self.I + 1] = tens;
        self.memory[self.I + 2] = ones;
    }

    fn STORE_TO_MEM(self: *CpuCore, reg: u8) void {
        var j: usize = 0;
        while (j <= reg) {
            self.memory[self.I + j] = self.registers[j];
            j += 1;
        }
    }
    fn LOAD_FROM_MEM(self: *CpuCore, reg: u8) void {
        var j: usize = 0;
        while (j <= reg) {
            self.registers[j] = self.memory[self.I + j];
            j += 1;
        }
    }

    fn LD(a: *u8, b: u8) void {
        a.* = b;
    }

    fn LD_16(a: *u16, b: u16) void {
        a.* = b;
    }

    fn RND(a: *u8, b: u8) void {
        const rand = prng.random();

        a.* = rand.uintAtMost(u8, 255) & b;
    }

    fn ADD(a: *u8, b: u8) void {
        a.* +|= b;
    }

    fn ADD_16(a: *u16, b: u16) void {
        a.* +|= b;
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

    // ADD with carry
    fn ADDC(self: *CpuCore, a: *u8, b: u8) void {
        if (a.* + b > 0xFF) {
            self.registers[0x0F] = 0x1;
        } else {
            self.registers[0x0F] = 0x0;
        }
        a.* +|= b;
    }

    fn SUBC(self: *CpuCore, a: *u8, b: u8) void {
        if (a.* > b) {
            self.registers[0x0F] = 0x1;
        } else {
            self.registers[0x0F] = 0x0;
        }
        a.* -|= b;
    }

    fn SHR(self: *CpuCore, a: *u8) void {
        if (a.* & 0x1 == 0x1) {
            self.registers[0x0F] = 0x1;
        } else {
            self.registers[0x0F] = 0x0;
        }
        a.* = a.* >> 1;
    }

    fn SHL(self: *CpuCore, a: *u8) void {
        if (a.* & 0x80 == 0x80) {
            self.registers[0x0F] = 0x1;
        } else {
            self.registers[0x0F] = 0x0;
        }
        a.* = a.* << 1;
    }

    fn SUBN(self: *CpuCore, a: *u8, b: u8) void {
        if (b > a.*) {
            self.registers[0x0F] = 0x1;
        } else {
            self.registers[0x0F] = 0x0;
        }
        a.* = b -| a.*;
    }
};

fn combineOpCode(op_code: [2]u8) u16 {
    return @as(u16, op_code[0]) << 8 | op_code[1];
}

test "test combinOpCode" {
    try std.testing.expect(combineOpCode(.{ 0x00, 0xE0 }) == 0x00E0);
    try std.testing.expect(combineOpCode(.{ 0xF3, 0x1E }) == 0xF31E);
}
