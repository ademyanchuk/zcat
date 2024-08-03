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
        zcat_log.err("while processing arguments: {s}", .{@errorName(e)});
        return;
    };
    defer std.process.argsFree(allocator, args);

    // TODO: add reading from stdin!
    if (args.len == 1) {
        zcat_log.warn("Cat for stdin is not implemented yet", .{});
        return;
    }
    // Instantiate writer (we use only stdout in the program)
    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    var writer = bw.writer();

    for (args[1..]) |filename| {
        // Open file
        const file = openFileZ(filename) catch |err| switch (err) {
            // Here we try to gracefully handle most relevant
            // errors and will just return rest
            error.FileNotFound => {
                zcat_log.err("File not found: {s}", .{filename});
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
        // read and write logic
        readWriteLoop(file, &bw, &writer) catch |err| switch (err) {
            error.IsDir => {
                zcat_log.err("{s}: Is a directory", .{filename});
                return;
            },
            else => return err,
        };
    }
}

/// Buffered read and write loop, bw is buffered writer
fn readWriteLoop(fin: std.fs.File, bw: anytype, writer: anytype) !void {

    // Reader buffered, cause otherwise reads and writes are syscalls
    var reader = std.io.bufferedReader(fin.reader());
    // 4096 -> to have equal size buffer with bufferedWriter/Reader funcs
    var buffer: [4096]u8 = undefined;

    while (true) {
        const num_read_bytes = try reader.read(&buffer);
        if (num_read_bytes == 0) {
            break;
        }
        // don't handle errors here as we are using stdout
        // and errors are mostly relevant to File
        // might change later
        _ = try writer.write(buffer[0..num_read_bytes]);
    }
    try bw.flush();
}
/// Will bubble-up all errors from building a path and
/// opening a file.
fn openFileZ(filename: [*:0]const u8) !std.fs.File {
    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const path = try std.fs.realpathZ(filename, &path_buffer);

    return std.fs.openFileAbsolute(path, .{ .mode = .read_only });
}

// TODO: add tests which I am trying from comand line
// so we have real tests
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
