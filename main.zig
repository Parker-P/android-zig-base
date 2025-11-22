const std = @import("std");
const android = @cImport({
    @cInclude("android_native_app_glue.h");
});

// pub export fn ANativeActivity_onCreate(
//     activity: ?*android.ANativeActivity,
//     saved_state: ?*anyopaque,
//     saved_state_size: usize,
// ) void {
//     std.debug.print("Zig NativeActivity started! {any}{any}{any}\n", .{ activity, saved_state, saved_state_size });
//     android.app_dummy(); // required by glue code
// }
