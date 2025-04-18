const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zip8",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("notcurses");
    exe.linkLibC(); // Required for C interop
    exe.addCSourceFiles(.{
        .files = &.{}, // Empty slice if no C source files are needed
        .flags = &.{},
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test_suite.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_unit_tests.linkSystemLibrary("notcurses");
    exe_unit_tests.linkLibC(); // Required for C interop
    exe_unit_tests.addCSourceFiles(.{
        .files = &.{}, // Empty slice if no C source files are needed
        .flags = &.{},
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
