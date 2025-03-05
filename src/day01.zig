const std = @import("std");

const data = @embedFile("data/day01.txt");
const data_test = @embedFile("data/day01.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u16 {
    return try solve(allocator, input, 1);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u16 {
    return try solve(allocator, input, 3);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, window_size: u8) !u16 {
    const measurements = try parseInput(allocator, input);
    defer allocator.free(measurements);

    var incrs: u16 = 0;
    for (measurements[window_size..], 0..) |measurement, i| {
        if (measurement > measurements[i])
            incrs += 1;
    }
    return incrs;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const u16 {
    const size = std.mem.count(u8, input, "\n");
    const measurements = try allocator.alloc(u16, size);
    errdefer allocator.free(measurements);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const measurement = try std.fmt.parseInt(u16, line, 10);
        measurements[i] = measurement;
    }
    return measurements;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(7, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(5, ans);
}
