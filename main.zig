const std = @import("std");
const android = @cImport({
    @cInclude("jni.h");
    @cInclude("android/log.h");
});

const LOG_TAG = "ZigNative";

// Global VM and Activity reference
var g_vm: ?*android.JavaVM = null;
var g_activity: ?android.jobject = null;

// This is your beautiful, clean entry point
export fn zigOnCreate(env: *android.JNIEnv, activity: android.jobject) void {
    _ = env; // not needed yet

    // Save activity globally if you want to show Toast later
    g_activity = activity;

    const __android_log_print = android.__android_log_print;
    __android_log_print(android.ANDROID_LOG_INFO, LOG_TAG, "Hello from Zig! App started successfully!", .{});

    // Optional: show a Toast in 1 second
    showToast("Hello from pure Zig via JNI!");
}

// Helper to show Toast from any thread
fn showToast(message: []const u8) void {
    if (g_vm == null or g_activity == null) return;

    var env: ?*android.JNIEnv = null;
    const attach_res = g_vm.?.*.AttachCurrentThread(g_vm, @ptrCast(&env), null);
    if (attach_res != 0) return;
    defer {
        if (attach_res == 0) {
            _ = g_vm.?.*.DetachCurrentThread(g_vm);
        }
    }

    const jstr = env.?.*.NewStringUTF.?(env, message.ptr);
    defer env.?.*.DeleteLocalRef.?(env, jstr);

    const toast_class = env.?.*.FindClass.?(env, "android/widget/Toast");
    const makeText = env.?.*.GetStaticMethodID.?(env, toast_class, "makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;");
    const show = env.?.*.GetMethodID.?(env, toast_class, "show", "()V");

    const toast = env.?.*.CallStaticObjectMethod.?(env, toast_class, makeText, g_activity, jstr, 0 // Toast.LENGTH_SHORT
    );
    env.?.*.CallVoidMethod.?(env, toast, show);
}

// This is the magic: register your Zig function under any name you want
export fn JNI_OnLoad(vm: *android.JavaVM, reserved: ?*anyopaque) callconv(.C) android.jint {
    _ = reserved;
    g_vm = vm;

    var env: ?*android.JNIEnv = null;
    if (vm.*.GetEnv.?(vm, @ptrCast(&env), android.JNI_VERSION_1_6) != android.JNI_OK) {
        return android.JNI_ERR;
    }

    const class_name = "com/example/minimalnative/MainActivity";
    const clazz = env.?.*.FindClass.?(env, class_name);
    if (clazz == null) return android.JNI_ERR;

    // Register your function with a clean name
    const methods = [_]android.JNINativeMethod{
        .{
            .name = "onCreate",
            .signature = "(Landroid/app/Activity;)V",
            .fnPtr = @ptrCast(&zigOnCreate),
        },
    };

    if (env.?.*.RegisterNatives.?(env, clazz, &methods, 1) < 0) {
        return android.JNI_ERR;
    }

    return android.JNI_VERSION_1_6;
}
