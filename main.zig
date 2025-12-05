// main.zig — literally 15 lines total
const android = @cImport({
    @cInclude("android/log.h");
});

export fn JNI_OnLoad(vm: *anyopaque, reserved: ?*anyopaque) callconv(.C) c_int {
    _ = vm;
    _ = reserved;
    _ = android.__android_log_print(android.ANDROID_LOG_INFO, "ZIG", "Library loaded!", "");
    return 0x00010006; // JNI_VERSION_1_6
}
