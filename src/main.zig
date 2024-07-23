const std = @import("std");

pub fn main() !void {
    // need allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // argsAlloc to work on Windows
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // instantiate buffered writer
    // they say we want buffered, cause otherwise reads and writes are syscalls
    const stdout = std.io.getStdOut();
    var buffered_out = std.io.bufferedWriter(stdout.writer());
    // and stderr
    var stderr = std.io.getStdErr().writer();

    // Implement only cat path/to/file for now
    if (args.len != 2) {
        try stderr.print(
            \\Tiny zig cat
            \\Invalid number of arguments!
            \\Use: zcat path/to/file
        , .{});
    }

    // Open file
    const filename = args[1];
    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const path = try std.fs.realpathZ(filename, &path_buffer);

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
    defer file.close();

    // Read
    var buffered_in = std.io.bufferedReader(file.reader());
    var buffer: [4096]u8 = undefined;
    while (true) {
        const num_read_bytes = try buffered_in.read(&buffer);
        if (num_read_bytes == 0) {
            break;
        }
        _ = try buffered_out.write(&buffer);
    }
    try buffered_out.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
