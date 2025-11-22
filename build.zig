const std = @import("std");

pub fn build(b: *std.Build) void {

    // TODO:
    // Add automation for the following:
    // 1. Install OpenJDK by running: winget install OpenJDK
    // 2. This installs it to "C:\Program Files\Microsoft\jdk-<latest jdk version>" and automatically sets the JAVA_HOME and Path system environment variables
    // 4. Download and extract the zip of the command line tools: https://developer.android.com/studio#command-line-tools-only to C:\Android\cmdline-tools
    // 5. Use the command line tools to install the tools needed for native android development
    //  a. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin --licenses (accept the licenses, requires user input, find a way to make it auto)
    //  b. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin --list and parse the latest versions for "platform-tools", "build-tools" and "ndk"
    //  c. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin "platform-tools" "build-tools;<version parsed in step b>" "ndk;<version parsed in step b>"
    //    quick info:
    //     1. platform-tools contains

    // -------- CONFIG --------
    const ndk_path = "C:/Android/cmdline-tools/bin/ndk/25.2.9519653";

    // Define the Android target (ARM64, API level 21)
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .android,
        },
    });

    // Create the shared library (NativeActivity expects libmain.so)
    const lib = b.addSharedLibrary(.{ .name = "main", .root_source_file = b.path("main.zig"), .target = target, .optimize = std.builtin.OptimizeMode.Debug });

    // Include directory for headers
    lib.addIncludePath(.{ .cwd_relative = ndk_path ++ "/sources/android/native_app_glue" });
    lib.addIncludePath(.{ .cwd_relative = ndk_path ++ "/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include" });
    lib.addIncludePath(.{ .cwd_relative = ndk_path ++ "/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/aarch64-linux-android" });

    // Add the actual C implementation of android_native_app_glue
    lib.addCSourceFile(.{ .file = .{ .cwd_relative = ndk_path ++ "/sources/android/native_app_glue/android_native_app_glue.c" }, .flags = &.{"-fPIC"} });

    // Output result
    b.installArtifact(lib);
}
