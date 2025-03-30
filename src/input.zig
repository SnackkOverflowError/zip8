const std = @import("std");
const Tuple = std.meta.Tuple;
const KeyReturn = Tuple(&.{ u32, bool });

const notcurses = @cImport({
    @cInclude("notcurses/notcurses.h");
});

pub fn getKeyboardState(nc: *notcurses.notcurses) KeyReturn {
    var ni: notcurses.ncinput = .{};
    var id: u32 = 0;

    var keys: u16 = 0;
    var quit: bool = false;

    // put a time out here??
    while (true) {
        id = notcurses.notcurses_get_nblock(nc, &ni);
        if (id == 0) break;

        const chip8_key = keyboardToChip8(id);
        if (chip8_key == 0xFE) continue;
        if (chip8_key == 0xFF) {
            quit = true;
            break;
        }
        keys |= @as(u16, 0x1) << @as(u4, @truncate(chip8_key));
    }

    return .{ keys, quit };
}
pub fn waitUntilKeyPress(nc: *notcurses.notcurses) KeyReturn {
    var ni: notcurses.ncinput = .{};
    var id: u32 = 0;

    var keys: u16 = 0;
    var quit: bool = false;

    // if you get an EOF or a key we dont track, continue.
    // once a key or quit comes in, break and return it.
    while (true) {
        id = notcurses.notcurses_get_nblock(nc, &ni);
        if (id == 0) continue;

        const chip8_key = keyboardToChip8(id);
        if (chip8_key == 0xFE) continue;
        if (chip8_key == 0xFF) {
            quit = true;
            break;
        }
        keys |= @as(u16, 0x1) << @as(u4, @truncate(chip8_key));
        break;
    }

    return .{ keys, quit };
}

fn keyboardToChip8(key: u32) usize {
    return switch (key) {
        '6' => 0x1,
        '7' => 0x2,
        '8' => 0x3,
        '9' => 0xC,
        'y' => 0x4,
        'u' => 0x5,
        'i' => 0x6,
        'o' => 0xD,
        'h' => 0x7,
        'j' => 0x8,
        'k' => 0x9,
        'l' => 0xE,
        'n' => 0xA,
        'm' => 0x0,
        ',' => 0xB,
        '.' => 0xF,
        'q' => 0xFF,
        else => 0xFE,
    };
}
