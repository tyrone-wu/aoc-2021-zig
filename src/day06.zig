const std = @import("std");

const data = @embedFile("data/day06.txt");
const data_test = @embedFile("data/day06.test.txt");

pub fn main() !void {
    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u64 {
    return try solve(input, 80);
}

fn partTwo(input: []const u8) !u64 {
    return try solve(input, 256);
}

fn solve(input: []const u8, days: u16) !u64 {
    var fishes = parseInput(input);
    var buffer: [10]u64 = undefined;

    for (0..days) |_| {
        for (&buffer) |*t| {
            t.* = 0;
        }

        for (fishes, 0..) |count, timer| {
            if (timer == 0) {
                buffer[6] += count;
                buffer[8] += count;
            } else {
                buffer[timer - 1] += count;
            }
        }
        fishes = buffer;
    }

    var sum: u64 = 0;
    for (fishes) |count| {
        sum += count;
    }
    return sum;
}

fn parseInput(input: []const u8) [10]u64 {
    var fishes: [10]u64 = undefined;
    for (&fishes) |*t| {
        t.* = 0;
    }

    var i: usize = 0;
    while (i < input.len - 1) : (i += 2) {
        fishes[input[i] - '0'] += 1;
    }
    return fishes;
}

test "p1" {
    const ans = try partOne(data_test);
    try std.testing.expectEqual(5934, ans);
}

test "p2" {
    const ans = try partTwo(data_test);
    try std.testing.expectEqual(26984457539, ans);
}
