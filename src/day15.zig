const std = @import("std");

const data = @embedFile("data/day15.txt");
const data_test = @embedFile("data/day15.test.txt");

const deltas: [4][2]i16 = .{
    .{ 1, 0 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 0, -1 },
};

const Node = struct {
    risk_level: u32,
    x: u16,
    y: u16,

    fn new(risk_level: u32, x: u16, y: u16) Node {
        return Node{ .risk_level = risk_level, .x = x, .y = y };
    }

    fn compare(context: void, a: Node, b: Node) std.math.Order {
        _ = context;
        return std.math.order(a.risk_level, b.risk_level);
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
    return try solve(allocator, input, 1);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    return try solve(allocator, input, 5);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, factor: u8) !u32 {
    const map = try parseInput(allocator, input);
    defer {
        for (map) |*row| {
            allocator.free(row.*);
        }
        allocator.free(map);
    }

    const x_max = map[0].len * factor - 1;
    const y_max = map.len * factor - 1;

    const lowest_rl = try allocator.alloc(u32, map.len * map[0].len * factor * factor);
    defer allocator.free(lowest_rl);
    for (lowest_rl) |*rl| {
        rl.* = std.math.maxInt(u32);
    }
    lowest_rl[0] = 0;

    var visited = std.AutoHashMap([2]u16, void).init(allocator);
    defer visited.deinit();
    try visited.put(.{ 0, 0 }, {});

    var queue = std.PriorityQueue(Node, void, Node.compare).init(allocator, {});
    defer queue.deinit();
    try queue.add(Node.new(0, 0, 0));

    while (queue.removeOrNull()) |node| {
        const x = node.x;
        const y = node.y;
        if (node.x == x_max and node.y == y_max)
            return node.risk_level;

        for (deltas) |delta| {
            const dx, const dy = delta;
            if ((dx < 0 and x == 0) or (dx > 0 and x == x_max) or (dy < 0 and y == 0) or (dy > 0 and y == y_max))
                continue;

            const x_n: u16 = @intCast(@as(i16, @intCast(x)) + dx);
            const y_n: u16 = @intCast(@as(i16, @intCast(y)) + dy);
            if (visited.contains(.{ x_n, y_n }))
                continue;
            try visited.put(.{ x_n, y_n }, {});

            const x_map = @mod(x_n, map[0].len);
            const y_map = @mod(y_n, map.len);
            const map_rl = @mod(map[y_map][x_map] + @as(u32, @intCast(@divTrunc(x_n, map[0].len) + @divTrunc(y_n, map.len))) - 1, 9) + 1;
            const next_rl = node.risk_level + map_rl;

            const idx = y_n * (x_max + 1) + x_n;
            if (next_rl < lowest_rl[idx]) {
                lowest_rl[idx] = next_rl;
                try queue.add(Node.new(next_rl, x_n, y_n));
            }
        }
    }

    return lowest_rl[lowest_rl.len - 1];
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    const row_max = std.mem.count(u8, input, "\n");
    const col_max = std.mem.indexOfScalar(u8, input, '\n').?;

    const map = try allocator.alloc([]const u8, row_max);
    errdefer {
        for (map) |*row| {
            allocator.free(row.*);
        }
        allocator.free(map);
    }

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    var i: usize = 0;
    while (line_it.next()) |line| : (i += 1) {
        const row = try allocator.alloc(u8, col_max);
        errdefer allocator.free(row);

        for (line, 0..) |c, j| {
            row[j] = c - '0';
        }
        map[i] = row;
    }

    return map;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(40, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(315, ans);
}
