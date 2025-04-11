const std = @import("std");
const print = std.debug.print;

const Zip8Errors = error{IncorrectNumberArgs};

pub fn getFilePath(allocator: std.mem.Allocator) ![:0]u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    //    for (args) |arg| {
    //        print("{s}\n", .{arg});
    //    }

    //    print("args len: {}\n", .{args.len});
    if (args.len != 2) {
        print("There are an incorect number of args: {d}", .{args.len});
        return Zip8Errors.IncorrectNumberArgs;
    }

    //    print("file path: {s}\n", .{args[1]});
    //    print("file path: {}\n", .{@TypeOf(args[1])});
    const path = try allocator.dupeZ(u8, args[1]);
    return path;
}

pub fn getProgMem(path: [:0]u8, allocator: std.mem.Allocator) ![]u8 {
    //    print("getting file {s}\n", .{path});
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return err;
    };
    defer file.close();
    //    print("after file close defer \n", .{});

    const metadata = try file.metadata();
    //    print("size of file in bytes: {}\n", .{metadata.size()});

    const prog_mem = try allocator.alloc(u8, metadata.size());
    const size = try file.readAll(prog_mem);
    _ = size;

    //    print("read in {} bytes\n", .{size});
    //    print("type of prog_mem: {}\n", .{@TypeOf(prog_mem)});
    return prog_mem;
}
