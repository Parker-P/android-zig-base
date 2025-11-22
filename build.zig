const std = @import("std");

pub fn build(b: *std.Build) void {

    // TODO:
    // Add automation for the following:
    // 1. Install OpenJDK by running: winget install OpenJDK
    // 2. This installs it to "C:\Program Files\Microsoft\jdk-<latest jdk version>" and automatically sets the JAVA_HOME and Path system environment variables which the following steps need to work
    // 4. Download and extract the zip of the command line tools: https://developer.android.com/studio#command-line-tools-only to C:\Android\cmdline-tools
    // 5. Use the command line tools to install the tools needed for native android development
    //  a. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin --licenses (accept the licenses, requires user input, find a way to make it auto)
    //  b. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin --list and parse the latest versions for "platform-tools", "build-tools" and "ndk"
    //  c. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin "platform-tools" "build-tools;<version parsed in step b>" "ndk;<version parsed in step b>"
    //    quick info:
    //     1. platform-tools contains tools to debug and push packages to android devices
    //     2. build-tools contains tools to package the application into a valid APK (android has a strict system in place to make sure it's not a harmful package, which includes stuff like packages signature checks)
    //     3. ndk contains the C/C++ includes needed to actually develop your app, which you will include in your codebase

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

    // Steps remaining:
    // C:\Android\ndk\25.2.9519653\toolchains\llvm\prebuilt\windows-x86_64\bin\clang \
    // --target=aarch64-none-linux-android21 \
    // -shared -fPIC -o ../lib/arm64-v8a/libmain.so main.c \
    // -I C:\Android\ndk\25.2.9519653\sources\android\native_app_glue

    // Creates libmain.so for arm64 devices.

    // For other architectures, repeat with correct target (armeabi-v7a, etc.).

    // Step 5: Compile resources
    // cd C:\MyNativeApp

    // # Compile XML into proto format
    // aapt2 compile -o compiled/ res/values/strings.xml

    // # Link resources and generate resources.arsc and minimal classes.dex
    // aapt2 link -o resources.arsc \
    //     --manifest AndroidManifest.xml \
    //     -I %ANDROID_HOME%\platforms\android-33\android.jar \
    //     compiled/

    // This produces the minimal resources.arsc and classes.dex files.

    // Step 6: Package APK
    // cd C:\MyNativeApp

    // zip -r MinimalNative.apk \
    //     AndroidManifest.xml \
    //     resources.arsc \
    //     lib/arm64-v8a/libmain.so \
    //     res/

    // Step 7: Sign APK
    // apksigner sign --ks my-release-key.jks MinimalNative.apk

    // If you don't have a key, you can generate one with keytool (from JDK).

    // Step 8: Install APK
    // adb install -r MinimalNative.apk

    // Your native activity will launch immediately.
}
