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
test "one file ok" {
    const allocator = testing.allocator;
    const exe_path = build_opts.cli_exe_path;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const file_content = "Example of data with length < 4096 bytes";
    try tmp.dir.writeFile(.{ .sub_path = "file1.txt", .data = file_content });

    const exec_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ exe_path, "file1.txt" },
        .cwd_dir = tmp.dir,
    });
    defer {
        allocator.free(exec_result.stdout);
        allocator.free(exec_result.stderr);
    }
    try testing.expectEqualStrings(file_content, exec_result.stdout);
}
test "one bigger file ok" {
    const allocator = testing.allocator;
    const exe_path = build_opts.cli_exe_path;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    // 4096 is our app read and write buffers size
    const file_content = "Example of data with length > 4096 bytes" ** 1000;
    try tmp.dir.writeFile(.{ .sub_path = "file1.txt", .data = file_content });

    const exec_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ exe_path, "file1.txt" },
        .cwd_dir = tmp.dir,
    });
    defer {
        allocator.free(exec_result.stdout);
        allocator.free(exec_result.stderr);
    }
    try testing.expectEqualStrings(file_content, exec_result.stdout);
}
test "two big files ok" {
    const allocator = testing.allocator;
    const exe_path = build_opts.cli_exe_path;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    // 4096 is our app read and write buffers size
    const file1_content = "Example of data with length > 4096 bytes\n" ** 500;
    try tmp.dir.writeFile(.{ .sub_path = "file1.txt", .data = file1_content });
    const file2_content = "Some content for the second file\n" ** 500;
    try tmp.dir.writeFile(.{ .sub_path = "file2.txt", .data = file2_content });

    const exec_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ exe_path, "file1.txt", "file2.txt" },
        .cwd_dir = tmp.dir,
    });
    defer {
        allocator.free(exec_result.stdout);
        allocator.free(exec_result.stderr);
    }
    try testing.expectEqualStrings(file1_content ++ file2_content, exec_result.stdout);
}
