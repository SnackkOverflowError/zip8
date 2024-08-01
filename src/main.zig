const std = @import("std");
const glfw = @import("mach-glfw");

const CpuCore = @import("chip_8.zig").CpuCore;

const App = @import("screen.zig").App;

const print = std.debug.print;

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

/// Keep our main function small. Typically handling arg parsing and initialization only
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            std.log.err("memory leak", .{});
        }
    }
    const allocator = gpa.allocator();

    // Initialize our application
    var app = try App.init(allocator);
    defer app.deinit();

    // Run the application
    try app.run();
}

pub fn old_main() !void {
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
    cpu.loadROM(prog_mem, size);

    std.process.exit(0);
}
