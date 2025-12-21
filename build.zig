const std = @import("std");

pub fn build(b: *std.Build) void {

    // -------- CONFIG --------
    const ndk_path = "/opt/android/ndk/25.2.9519653";

    // Define the Android target (ARM64, API level 21)
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .android,
        },
    });

    // Create the shared library (NativeActivity expects libmain.so)
    const lib = b.addLibrary(.{ .name = "main", .linkage = .dynamic, .root_module = b.createModule(.{ .root_source_file = b.path("main.zig"), .target = target, .optimize = std.builtin.OptimizeMode.Debug }) });

    // Links the library against Google's libc for android (BIONIC)
    lib.addObjectFile(std.Build.LazyPath{ .cwd_relative = ndk_path ++ "/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/24/libc.so" });

    // Essential: Link log for __android_log_print
    lib.linkSystemLibrary("log");

    // FIX: Add NDK sysroot as library search path (Zig finds liblog.so here)
    const sysroot_lib_path = ndk_path ++ "/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/24";
    lib.addLibraryPath(.{ .cwd_relative = sysroot_lib_path });

    // Include path for headers (android/log.h)
    const sysroot_include_path = ndk_path ++ "/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include";
    lib.addIncludePath(.{ .cwd_relative = sysroot_include_path });

    b.installArtifact(lib);
}
