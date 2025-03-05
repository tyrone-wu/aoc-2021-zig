const std = @import("std");

const data = @embedFile("data/day05.txt");
const data_test = @embedFile("data/day05.test.txt");

const VentLine = struct {
    x1: i32,
    y1: i32,
    x2: i32,
    y2: i32,

    fn new(input: []const u8) !VentLine {
        var split = std.mem.splitSequence(u8, input, " -> ");
        const x1, const y1 = try parsePoint(split.next().?);
        const x2, const y2 = try parsePoint(split.next().?);
        return VentLine{
            .x1 = x1,
            .y1 = y1,
            .x2 = x2,
            .y2 = y2,
        };
    }

    fn parsePoint(input: []const u8) ![2]i32 {
        var split = std.mem.splitScalar(u8, input, ',');
        const x = try std.fmt.parseInt(i32, split.next().?, 10);
        const y = try std.fmt.parseInt(i32, split.next().?, 10);
        return .{ x, y };
    }

    fn isHorzOrVert(self: VentLine) bool {
        return self.x1 == self.x2 or self.y1 == self.y2;
    }

    fn recordVent(self: VentLine, map: *std.AutoHashMap(u32, u8), p2: bool) !void {
        if (!p2 and !self.isHorzOrVert())
            return;

        var x = self.x1;
        var y = self.y1;
        const dx: i32 = if (self.x1 == self.x2) 0 else if (self.x1 < self.x2) 1 else -1;
        const dy: i32 = if (self.y1 == self.y2) 0 else if (self.y1 < self.y2) 1 else -1;
        const range: usize = @max(@abs(self.x1 - self.x2), @abs(self.y1 - self.y2)) + 1;
        for (0..range) |_| {
            const hash: u32 = @intCast((x << 16) | y);
            const overlaps = map.get(hash) orelse 0;
            try map.put(hash, overlaps + 1);
            x += dx;
            y += dy;
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    return try solve(allocator, input, false);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    return try solve(allocator, input, true);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, p2: bool) !u32 {
    const vent_lines = try parseInput(allocator, input);
    defer allocator.free(vent_lines);

    var vent_map = std.AutoHashMap(u32, u8).init(allocator);
    defer vent_map.deinit();

    for (vent_lines) |vent_line| {
        try vent_line.recordVent(&vent_map, p2);
    }

    var dangerous_areas: u32 = 0;
    var overlaps_it = vent_map.valueIterator();
    while (overlaps_it.next()) |overlaps| {
        if (overlaps.* >= 2)
            dangerous_areas += 1;
    }
    return dangerous_areas;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const VentLine {
    const size = std.mem.count(u8, input, "\n");
    const vent_lines = try allocator.alloc(VentLine, size);
    errdefer allocator.free(vent_lines);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const vent_line = try VentLine.new(line);
        vent_lines[i] = vent_line;
    }
    return vent_lines;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(5, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(12, ans);
}
