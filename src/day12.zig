const std = @import("std");

const data = @embedFile("data/day12.txt");
const data_test = @embedFile("data/day12.test.txt");

const Cave = struct {
    id: u64,
    is_small: bool,

    fn new(input: []const u8) Cave {
        var id: u64 = 0;
        if (std.mem.eql(u8, input, "start")) {
            // start is 0
        } else if (std.mem.eql(u8, input, "end")) {
            id = std.math.maxInt(u64);
        } else {
            for (input) |c| {
                id |= @as(u64, 1) << @intCast(std.ascii.toLower(c) - 'a');
            }
        }

        const is_small = std.ascii.isLower(input[0]);

        return Cave{ .id = id, .is_small = is_small };
    }

    fn isEnd(self: Cave) bool {
        return self.id == std.math.maxInt(u64);
    }

    fn isStart(self: Cave) bool {
        return self.id == 0;
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
    var graph = try parseInput(allocator, input);
    defer {
        var val_it = graph.valueIterator();
        while (val_it.next()) |val| {
            val.deinit();
        }
        graph.deinit();
    }

    var visited_caves = std.AutoHashMap(Cave, u8).init(allocator);
    defer visited_caves.deinit();
    const start = Cave.new("start");
    try visited_caves.put(start, 1);

    return if (!p2)
        try dfs(graph, &visited_caves, start)
    else
        try dfsP2(graph, &visited_caves, start, false);
}

fn dfs(graph: std.AutoHashMap(Cave, std.ArrayList(Cave)), visited_caves: *std.AutoHashMap(Cave, u8), current: Cave) !u32 {
    if (current.isEnd())
        return 1;

    var distinct_paths: u32 = 0;
    for (graph.get(current).?.items) |to| {
        if (to.is_small and visited_caves.contains(to))
            continue;

        try visited_caves.put(to, 0);
        distinct_paths += try dfs(graph, visited_caves, to);
        _ = visited_caves.remove(to);
    }
    return distinct_paths;
}

fn dfsP2(graph: std.AutoHashMap(Cave, std.ArrayList(Cave)), visited_caves: *std.AutoHashMap(Cave, u8), current: Cave, twice: bool) !u32 {
    if (current.isEnd())
        return 1;

    var distinct_paths: u32 = 0;
    for (graph.get(current).?.items) |to| {
        if (to.isStart())
            continue;

        const num_visited = visited_caves.get(to) orelse 0;
        var twice_tmp = twice;
        if (to.is_small) {
            switch (num_visited) {
                0 => {},
                1 => {
                    if (twice)
                        continue;
                    twice_tmp = true;
                },
                else => continue,
            }
        }

        try visited_caves.put(to, 1 + num_visited);
        distinct_paths += try dfsP2(graph, visited_caves, to, twice_tmp);
        try visited_caves.put(to, num_visited);
    }
    return distinct_paths;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.AutoHashMap(Cave, std.ArrayList(Cave)) {
    var graph = std.AutoHashMap(Cave, std.ArrayList(Cave)).init(allocator);
    errdefer {
        var val_it = graph.valueIterator();
        while (val_it.next()) |val| {
            val.deinit();
        }
        graph.deinit();
    }

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    while (line_it.next()) |line| {
        var split = std.mem.splitScalar(u8, line, '-');
        const from = Cave.new(split.next().?);
        const to = Cave.new(split.next().?);

        if (!graph.contains(from))
            try graph.put(from, std.ArrayList(Cave).init(allocator));
        try graph.getPtr(from).?.append(to);

        if (!graph.contains(to))
            try graph.put(to, std.ArrayList(Cave).init(allocator));
        try graph.getPtr(to).?.append(from);
    }

    return graph;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(226, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(3509, ans);
}
