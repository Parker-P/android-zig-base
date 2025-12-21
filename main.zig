const android = @cImport({
    @cInclude("jni.h");
    @cInclude("android/log.h");
});

export fn JNI_OnLoad(vm: *anyopaque, reserved: ?*anyopaque) callconv(.c) c_int {
    _ = vm;
    _ = reserved;
    _ = android.__android_log_print(android.ANDROID_LOG_INFO, "ZIG", "Library loaded!", "");
    return 0x00010006; // JNI_VERSION_1_6
}

export fn Java_com_example_minimalnative_MainActivity_onCreateNative(env: ?*android.JNIEnv, class: android.jclass, activity: android.jobject) void {
    _ = class; // unused, but required for static method
    _ = activity; // you can use this if needed

    if (env) |jni_env| {
        _ = android.__android_log_print(android.ANDROID_LOG_INFO, "ZIG", "onCreateNative called!", "");
        _ = jni_env;
        // Add your actual native logic here, e.g. set up UI, etc.
    }
}
