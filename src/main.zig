const std = @import("std");

const Cpu = @import("cpu.zig").Cpu;
const Display = @import("display.zig").Display;
const input = @import("input.zig");
const operations = @import("operations.zig");

const print = std.debug.print;

const Zip8Errors = error{IncorrectNumberArgs};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const path: [:0]u8 = try getFilePath(allocator);
    //print("got path: {s}\n", .{path});
    defer allocator.free(path);

    const prog_mem = try getProgMem(path, allocator);
    //print("got prog mem\n", .{});
    defer allocator.free(prog_mem);
    //print("after defer\n", .{});

    // make a screen
    var display: Display = try Display.init();

    var cpu: Cpu = try Cpu.init(prog_mem, &display);
    try cpu.display.display(cpu.getScreen());

    std.time.sleep(2 * std.time.ns_per_s);
    const key_state = input.getKeyboardState(cpu.display.nc);
    print("quit: {}, keys: 0b{b:0>16}", .{ key_state[1], key_state[0] });

    std.time.sleep(5 * std.time.ns_per_s);
    try display.destroy();

    std.process.exit(0);
}

fn getFilePath(allocator: std.mem.Allocator) ![:0]u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    for (args) |arg| {
        print("{s}\n", .{arg});
    }

    print("args len: {}\n", .{args.len});
    if (args.len != 2) {
        print("There are an incorect number of args: {d}", .{args.len});
        return Zip8Errors.IncorrectNumberArgs;
    }

    print("file path: {s}\n", .{args[1]});
    print("file path: {}\n", .{@TypeOf(args[1])});
    const path = try allocator.dupeZ(u8, args[1]);
    return path;
}

fn getProgMem(path: [:0]u8, allocator: std.mem.Allocator) ![]u8 {
    print("getting file {s}\n", .{path});
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return err;
    };
    defer file.close();
    print("after file close defer \n", .{});

    const metadata = try file.metadata();
    print("size of file in bytes: {}\n", .{metadata.size()});

    const prog_mem = try allocator.alloc(u8, metadata.size());
    const size = try file.readAll(prog_mem);

    print("read in {} bytes\n", .{size});
    print("type of prog_mem: {}\n", .{@TypeOf(prog_mem)});
    return prog_mem;
}
