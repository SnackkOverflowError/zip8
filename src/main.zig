const std = @import("std");

const Cpu = @import("cpu.zig").Cpu;
const Display = @import("display.zig").Display;
const input = @import("input.zig");
const operations = @import("operations.zig");
const utils = @import("utils.zig");

const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const path: [:0]u8 = try utils.getFilePath(allocator);
    //print("got path: {s}\n", .{path});
    defer allocator.free(path);

    const prog_mem = try utils.getProgMem(path, allocator);
    defer allocator.free(prog_mem);

    // make a screen
    //var display: Display = try Display.init();

    var cpu: Cpu = try Cpu.init(prog_mem, null);
    //try cpu.display.display(cpu.getScreen());
    for (0..39) |i| {
        try cpu.cycle();
        print("index: {}\n", .{i});
        cpu.printScreen();
        // std.time.sleep(1 * std.time.ns_per_s);
    }

    std.time.sleep(2 * std.time.ns_per_s);

    if (cpu.display) |disp| {
        try disp.destroy();
    }
    std.process.exit(0);
}
