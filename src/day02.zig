const std = @import("std");

const data = @embedFile("data/day02.txt");
const data_test = @embedFile("data/day02.test.txt");

const Submarine = struct {
    horizontal: i32,
    depth: i32,
    aim: i32,

    const deltas = std.StaticStringMap([2]i32).initComptime(.{
        .{ "forward", .{ 1, 0 } },
        .{ "down", .{ 0, 1 } },
        .{ "up", .{ 0, -1 } },
    });

    const deltasP2 = std.StaticStringMap([3]i32).initComptime(.{
        .{ "forward", .{ 1, 1, 0 } },
        .{ "down", .{ 0, 0, 1 } },
        .{ "up", .{ 0, 0, -1 } },
    });

    fn new() Submarine {
        return Submarine{ .horizontal = 0, .depth = 0, .aim = 0 };
    }

    fn move(self: *Submarine, command: []const u8, p2: bool) !void {
        var split = std.mem.splitScalar(u8, command, ' ');
        const dir_str = split.next().?;
        const magnitude_str = split.next().?;

        const magnitude = try std.fmt.parseInt(i32, magnitude_str, 10);
        if (!p2) {
            const dx, const dy = deltas.get(dir_str).?;
            self.horizontal += magnitude * dx;
            self.depth += magnitude * dy;
        } else {
            const dx, const dy, const dz = deltasP2.get(dir_str).?;
            self.horizontal += magnitude * dx;
            self.depth += magnitude * dy * self.aim;
            self.aim += magnitude * dz;
        }
    }

    fn checksum(self: Submarine) i32 {
        return self.horizontal * self.depth;
    }
};

pub fn main() !void {
    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !i32 {
    return try solve(input, false);
}

fn partTwo(input: []const u8) !i32 {
    return try solve(input, true);
}

fn solve(input: []const u8, p2: bool) !i32 {
    var submarine = Submarine.new();
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |command| {
        try submarine.move(command, p2);
    }
    return submarine.checksum();
}

test "p1" {
    const ans = try partOne(data_test);
    try std.testing.expectEqual(150, ans);
}

test "p2" {
    const ans = try partTwo(data_test);
    try std.testing.expectEqual(900, ans);
}
