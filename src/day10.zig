const std = @import("std");

const data = @embedFile("data/day10.txt");
const data_test = @embedFile("data/day10.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    var total_points: u32 = 0;
    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    while (line_it.next()) |line| {
        stack.clearRetainingCapacity();

        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                else => {
                    const open = stack.pop().?;
                    const expected: u8 = expectedClose(open);
                    if (expected != c) {
                        const points: u32 = switch (c) {
                            ')' => 3,
                            ']' => 57,
                            '}' => 1197,
                            else => 25137,
                        };
                        total_points += points;
                        break;
                    }
                },
            }
        }
    }
    return total_points;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var stack = std.ArrayList(u8).init(allocator);
    defer stack.deinit();

    var scores = std.ArrayList(u64).init(allocator);
    defer scores.deinit();

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    while (line_it.next()) |line| {
        stack.clearRetainingCapacity();

        var corrupted = false;
        for (line) |c| {
            switch (c) {
                '(', '[', '{', '<' => try stack.append(c),
                else => {
                    const open = stack.pop().?;
                    const expected: u8 = expectedClose(open);
                    if (expected != c)
                        corrupted = true;
                },
            }
        }
        if (corrupted)
            continue;

        var points: u64 = 0;
        while (stack.pop()) |open| {
            const expected = expectedClose(open);
            const add: u64 = switch (expected) {
                ')' => 1,
                ']' => 2,
                '}' => 3,
                else => 4,
            };
            points = points * 5 + add;
        }
        try scores.append(points);
    }

    std.sort.pdq(u64, scores.items, {}, std.sort.asc(u64));
    return scores.items[@divTrunc(scores.items.len, 2)];
}

fn expectedClose(c: u8) u8 {
    return switch (c) {
        '(' => ')',
        '[' => ']',
        '{' => '}',
        else => '>',
    };
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(26397, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(288957, ans);
}
