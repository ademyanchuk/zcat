const std = @import("std");
const testing = std.testing;
const build_opts = @import("build_options");

test "file not found error" {
    const allocator = testing.allocator;
    const exe_path = build_opts.cli_exe_path;
    const exec_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ exe_path, "hello" },
    });
    defer {
        allocator.free(exec_result.stdout);
        allocator.free(exec_result.stderr);
    }
    try testing.expectEqualStrings("error(zcat): File not found: hello\n", exec_result.stderr);
}
test "is dir error" {
    const allocator = testing.allocator;
    const exe_path = build_opts.cli_exe_path;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makeDir("foo");

    const exec_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ exe_path, "foo" },
        .cwd_dir = tmp.dir,
    });
    defer {
        allocator.free(exec_result.stdout);
        allocator.free(exec_result.stderr);
    }
    try testing.expectEqualStrings("error(zcat): foo: Is a directory\n", exec_result.stderr);
}
