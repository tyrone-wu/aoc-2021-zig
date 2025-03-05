const std = @import("std");

const data = @embedFile("data/day09.txt");
const data_test = @embedFile("data/day09.test.txt");

const deltas: [4][2]i8 = .{
    .{ 1, 0 },
    .{ -1, 0 },
    .{ 0, 1 },
    .{ 0, -1 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u16 {
    const heightmap = try parseInput(allocator, input);
    defer {
        var i: usize = 0;
        while (i < heightmap.len - 1) : (i += 1) {
            allocator.free(heightmap[i]);
        }
        allocator.free(heightmap);
    }

    const low_points = try getLowPoints(allocator, heightmap);
    defer low_points.deinit();

    var risk_level: u16 = 0;
    for (low_points.items) |point| {
        const x, const y = point;
        risk_level += 1 + heightmap[y][x];
    }
    return risk_level;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const heightmap = try parseInput(allocator, input);
    defer {
        var i: usize = 0;
        while (i < heightmap.len - 1) : (i += 1) {
            allocator.free(heightmap[i]);
        }
        allocator.free(heightmap);
    }

    const low_points = try getLowPoints(allocator, heightmap);
    defer low_points.deinit();

    var visited = std.AutoHashMap([2]usize, void).init(allocator);
    defer visited.deinit();

    var queue_buffer: std.fifo.LinearFifo([2]usize, .Dynamic) = std.fifo.LinearFifo([2]usize, .Dynamic).init(allocator);
    defer queue_buffer.deinit();

    var largets_basins: [3]u32 = .{ 0, 0, 0 };
    for (low_points.items) |low| {
        var basin_size: u32 = 0;
        try visited.put(low, {});
        try queue_buffer.writeItem(low);

        while (queue_buffer.readItem()) |point| {
            basin_size += 1;

            const x, const y = point;
            const height_current = heightmap[y][x];
            for (deltas) |delta| {
                const x_n: usize = @intCast(@as(i8, @intCast(x)) + delta[0]);
                const y_n: usize = @intCast(@as(i8, @intCast(y)) + delta[1]);
                const height_adj = heightmap[y_n][x_n];

                const adj_point: [2]usize = .{ x_n, y_n };
                if (height_adj >= 9 or visited.contains(adj_point))
                    continue;

                if (height_adj > height_current) {
                    try queue_buffer.writeItem(adj_point);
                    try visited.put(adj_point, {});
                }
            }
        }

        const i = std.mem.indexOfMin(u32, &largets_basins);
        if (largets_basins[i] < basin_size)
            largets_basins[i] = basin_size;
    }
    return largets_basins[0] * largets_basins[1] * largets_basins[2];
}

fn getLowPoints(allocator: std.mem.Allocator, heightmap: []const []const u8) !std.ArrayList([2]usize) {
    var low_points = std.ArrayList([2]usize).init(allocator);
    errdefer low_points.deinit();

    for (1..heightmap.len - 1) |y| {
        for (1..heightmap[0].len - 1) |x| {
            const height = heightmap[y][x];

            var high: u8 = 0;
            for (deltas) |delta| {
                const x_n: usize = @intCast(@as(i8, @intCast(x)) + delta[0]);
                const y_n: usize = @intCast(@as(i8, @intCast(y)) + delta[1]);
                if (heightmap[y_n][x_n] > height)
                    high += 1;
            }

            if (high == 4)
                try low_points.append(.{ x, y });
        }
    }
    return low_points;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    const row_size = std.mem.count(u8, input, "\n") + 2;
    const heightmap = try allocator.alloc([]const u8, row_size);
    errdefer allocator.free(heightmap);

    const col_size = std.mem.indexOfScalar(u8, input, '\n').? + 2;

    const row_pad = try allocator.alloc(u8, col_size);
    errdefer allocator.free(row_pad);

    for (row_pad) |*p| {
        p.* = 10;
    }
    heightmap[0] = row_pad;

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    var i: usize = 1;
    while (line_it.next()) |line| : (i += 1) {
        const row = try allocator.alloc(u8, col_size);
        errdefer allocator.free(row);

        row[0] = 10;
        for (line, 1..) |c, j| {
            row[j] = c - '0';
        }
        row[col_size - 1] = 10;

        heightmap[i] = row;
    }
    heightmap[i] = row_pad;

    return heightmap;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(15, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(1134, ans);
}
