const std = @import("std");

pub fn main() !void {
    // program-level logger
    const zcat_log = std.log.scoped(.zcat);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // argsAlloc to work on Windows
    const args = std.process.argsAlloc(allocator) catch |e| {
        // We know (frome reading std) that argsAlloc potential
        // errors are mostly allocator oom errors and one is
        // math overflow if args are unreasonably long (> usize.max)
        // so we send user a message and exit
        zcat_log.err("while processing arguments: {!}", .{e});
        return;
    };
    defer std.process.argsFree(allocator, args);

    // Open file
    const filename = args[1];
    const file = openFileZ(filename) catch |err| switch (err) {
        // Here we try to gracefully handle most relevant
        // errors and will just return rest
        error.FileNotFound => {
            zcat_log.err("File not found: {s}", .{filename});
            return;
        },
        // TODO: move this to reader, as open a directory is not an error, but reading it is
        error.IsDir => {
            zcat_log.err("{s}: Is a directory", .{filename});
            return;
        },
        error.AccessDenied => {
            zcat_log.err("{s}: Access denied", .{filename});
            return;
        },
        error.InvalidWtf8 => {
            zcat_log.err("{s}: Invalid wtf8", .{filename});
            return;
        },
        error.NetworkNotFound => {
            zcat_log.err("{s}: Windows network path error", .{filename});
            return;
        },
        else => return err,
    };
    defer file.close();

    // Reader and Writer
    // buffered, cause otherwise reads and writes are syscalls
    var reader = std.io.bufferedReader(file.reader());
    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    const writer = bw.writer();
    // 4096 -> to have equal size buffer with bufferedWriter/Reader funcs
    var buffer: [4096]u8 = undefined;

    while (true) {
        const num_read_bytes = try reader.read(&buffer);
        if (num_read_bytes == 0) {
            break;
        }
        _ = try writer.write(&buffer);
    }
    try bw.flush();
}

/// Will bubble-up all errors from building a path and
/// opening a file.
pub fn openFileZ(filename: [*:0]const u8) !std.fs.File {
    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const path = try std.fs.realpathZ(filename, &path_buffer);

    return std.fs.openFileAbsolute(path, .{ .mode = .read_only });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
