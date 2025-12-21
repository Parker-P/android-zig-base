const std = @import("std");

pub fn build(b: *std.Build) void {

    // TODO:
    // Add automation for the following:
    // 1. cd to the directory where this file is
    // 2. Install OpenJDK by running: winget install OpenJDK
    // 3. This installs it to "C:\Program Files\Microsoft\jdk-<latest jdk version>" and automatically sets the JAVA_HOME and Path system environment variables which the following steps need to work
    // 4. Install msys64 and add the path to the binaries (C:\msys64\usr\bin) to the Path environment variable: winget install msys2.msys2
    // 5. Download and extract the zip of the command line tools: https://developer.android.com/studio#command-line-tools-only to C:\Android\cmdline-tools
    // 6. Use the command line tools to install the tools needed for native android development
    //  a. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin --licenses (accept the licenses, requires user input, find a way to make it auto)
    //  b. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin --list and parse the latest versions for "platform-tools", "build-tools", "ndk" and "platform"
    //  c. sdkmanager --sdk_root=C:\Android\cmdline-tools\bin "platform-tools" "build-tools;<version parsed in step b>" "ndk;<version parsed in step b>" "platforms;android-32"
    //    quick info:
    //     1. platform-tools contains tools to debug and push packages to android devices
    //     2. build-tools and platforms contain tools to package the application into a valid APK (android has a strict system in place to make sure it's not a harmful package, which includes stuff like packages signature checks)
    //     3. ndk contains the C/C++ includes needed to actually develop your app, which you will include in your codebase
    //     4. the latest platforms' versions' android.jar (used to link evertyhing together to make an apk) is bugged, please keep android-32 - tested and working
    // 7. Add the build-tools directory C:\Android\cmdline-tools\bin and C:\Android\cmdline-tools\bin\build-tools\<version parsed in step 6b> to the Path system environment variable
    // 8. aapt2 compile -o compiled_res.zip --dir res
    // 9. aapt2 link -o unsigned.apk -I C:\Android\cmdline-tools\bin\platforms\android-32\android.jar --manifest AndroidManifest.xml compiled_res.zip
    // 10. javac -d . -source 8 -target 8 -bootclasspath C:\Android\cmdline-tools\bin\platforms\android-32\android.jar -classpath C:\Android\cmdline-tools\bin\platforms\android-32\android.jar -Xlint:-options .\MainActivity.java
    // 11. xcopy /y .\com\example\minimalnative\MainActivity.class .
    // 11. java -cp "C:\Android\cmdline-tools\bin\build-tools\33.0.2\lib\d8.jar" com.android.tools.r8.D8 --min-api 24 --output . .\MainActivity.class
    // 12. zip -X -0 unsigned.apk classes.dex

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

    // Steps that actually worked:

    // 13. mkdir lib\arm64-v8a
    // 14. xcopy /Y zig-out\lib\libmain.so lib\arm64-v8a\libmain.so
    // 15. zip -X -0 unsigned.apk lib/arm64-v8a/libmain.so
    // 16. zipalign -f -p -v 4 unsigned.apk aligned.apk
    // 17. if you don't have a key, use this command to make one:
    //     keytool -genkeypair -keystore my-upload-key.jks -alias my-app-key -keyalg RSA -keysize 4096 -validity 20000 -dname "CN=Paolo Parker, O=KissMyApp, C=US"
    //     Save the file somewhere on your servers because you will never be able to update your app on the play store if you don't have it
    // 18. apksigner sign --ks my-upload-key.jks --ks-key-alias my-app-key --v4-signing-enabled true --out final.apk aligned.apk
    // 20
    // 19. adb install final.apk
}
