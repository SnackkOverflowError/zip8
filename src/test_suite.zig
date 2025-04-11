const std = @import("std");

const Cpu = @import("cpu.zig").Cpu;
const Display = @import("display.zig").Display;
const input = @import("input.zig");
const operations = @import("operations.zig");
const utils = @import("utils.zig");

const print = std.debug.print;
const expect = std.testing.expect;

test "splash_screen" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //const path: [:0]u8 = "../../test_programs/1-chip8-logo.ch8"[0..];

    const prog_mem = try utils.getProgMem(path, allocator);
    defer allocator.free(prog_mem);

    // make a screen
    var display: Display = try Display.init();

    var cpu: Cpu = try Cpu.init(prog_mem, &display);
    //try cpu.display.display(cpu.getScreen());
    for (0..39) |_| {
        try cpu.cycle();
    }

    std.time.sleep(2 * std.time.ns_per_s);

    try cpu.display.destroy();
}
