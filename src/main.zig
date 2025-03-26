const std = @import("std");

const Cpu = @import("cpu.zig").Cpu;

const print = std.debug.print;

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

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(gpa.allocator(), args);
    for (args) |arg| {
        print("{s}\n", .{arg});
    }

    print("args len: {}\n", .{args.len});
    if (args.len != 2) {
        print("There are an incorect number of args: {d}", .{args.len});
        return;
    }

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
    print("type of prog_mem: {}\n", .{@TypeOf(prog_mem)});

    const cpu: Cpu = try Cpu.Init(prog_mem);
    _ = cpu;

    std.process.exit(0);
}
