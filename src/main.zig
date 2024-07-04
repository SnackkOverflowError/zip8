const std = @import("std");
const CpuCore = @import("chip_8.zig").CpuCore;

const print = std.debug.print;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    print("debug print\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    for (args) |arg| {
        print("{s}\n", .{arg});
    }

    print("args len: {}\n", .{args.len});
    if (args.len != 2) return;

    print("file path: {s}\n", .{args[1]});
    const path = args[1];

    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return;
    };
    defer file.close();

    const metadata = try file.metadata();

    print("size of file in bytes: {}\n", .{metadata.size()});

    const prog_mem = try gpa.allocator().alloc(u8, metadata.size());
    defer gpa.allocator().free(prog_mem);

    const size = try file.readAll(prog_mem);

    print("read in {} bytes\n", .{size});

    var cpu: CpuCore = CpuCore{};

    var i: usize = 0;
    while (i < size) {
        try cpu.processInstruction(.{ prog_mem[i], prog_mem[i + 1] });
        i += 2;
    }
}
