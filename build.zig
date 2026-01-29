const std = @import("std");

pub fn build(project: *std.Build) void {
    const target = project.standardTargetOptions(.{});
    const optimize = project.standardOptimizeOption(.{});

    _ = project.addModule("LLIM", .{
        .target = target,
        .optimize = optimize,
    });

    const compile = project.addExecutable(.{
        .name = "LLIM",
        .root_module = project.createModule(.{
            .root_source_file = project.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    compile.root_module.linkFramework("ApplicationServices", .{});
    project.installArtifact(compile);

    const run_step = project.step("run", "Run the application");
    const run_command = project.addRunArtifact(compile);
    if (project.args) |args| {
        run_command.addArgs(args);
    }

    run_step.dependOn(&run_command.step);
}
