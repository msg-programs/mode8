const std = @import("std");
const mach = @import("mach");

pub fn build(b: *std.Build) !void {

    // === DEFAULT FLUFF ======================================================
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // === DEPS SETUP ======================================================
    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
        .core = true,
    });

    const zigimg_dep = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    // const mode8 = b.addStaticLibrary(.{
    //     .name = "mode8",
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // mode8.root_module.addImport("mach", mach_dep.module("mach"));
    // b.installArtifact(mode8);

    // const unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_unit_tests = b.addRunArtifact(unit_tests);
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_unit_tests.step);

    // === DEMO PROGRAMS =======================================================

    const m8_mod = b.addModule("mode8", .{
        .root_source_file = b.path("src/root.zig"),
    });
    m8_mod.addImport("mach", mach_dep.module("mach"));

    const su_mod = b.addModule("sampleutils", .{
        .root_source_file = b.path("examples/sampleutils/root.zig"),
    });
    su_mod.addImport("zigimg", zigimg_dep.module("zigimg"));
    su_mod.addImport("mode8", m8_mod);

    // const exe = b.addExecutable(.{
    //     .name = "demo",
    //     .root_source_file = b.path("src/examples/demo/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // exe.root_module.addImport("mach", mach_dep.module("mach"));
    // exe.root_module.addImport("mode8", m8_mod);
    // exe.root_module.addImport("zigimg", zigimg_dep.module("zigimg"));
    // @import("mach").link(mach_dep.builder, exe);

    // b.installArtifact(exe);

    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());

    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run-demo", "Run the demo app");
    // run_step.dependOn(&run_cmd.step);

    const exe2 = b.addExecutable(.{
        .name = "debug",
        .root_source_file = b.path("examples/debug/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe2.root_module.addImport("mach", mach_dep.module("mach"));
    exe2.root_module.addImport("sampleutils", su_mod);
    exe2.root_module.addImport("mode8", m8_mod);
    exe2.root_module.addImport("zigimg", zigimg_dep.module("zigimg"));
    exe2.linkLibC();

    b.installArtifact(exe2);

    const run_cmd2 = b.addRunArtifact(exe2);
    run_cmd2.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd2.addArgs(args);
    }

    const run_step2 = b.step("run-debug", "Run the debug app");
    run_step2.dependOn(&run_cmd2.step);
}
