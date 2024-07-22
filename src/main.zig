const std = @import("std");

pub fn main() !void {
    // need allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // argsAlloc to work on Windows
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // instantiate writers
    var stdout = std.io.getStdOut().writer();
    var stderr = std.io.getStdErr().writer();

    for (args) |arg| {
        try stdout.print("{s}\n", .{arg});
    }

    // Implement only cat path/to/file for now
    if (args.len != 2) {
        try stderr.print(
            \\Tiny zig cat
            \\Invalid number of arguments!
            \\Use: zcat path/to/file
        , .{});
    }

    // TODO: read file
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
