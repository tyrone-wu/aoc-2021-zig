const std = @import("std");

const data = @embedFile("data/day14.txt");
const data_test = @embedFile("data/day14.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const steps: usize = 10; // 40
    var polymer_template, var rules = try parseInput(allocator, input, steps);
    defer {
        polymer_template.deinit();
        rules.deinit();
    }

    var buffer = try std.ArrayList(u8).initCapacity(allocator, polymer_template.capacity);
    defer buffer.deinit();

    for (0..steps) |_| {
        buffer.clearRetainingCapacity();
        try buffer.appendSlice(polymer_template.items);
        polymer_template.clearRetainingCapacity();

        for (0..buffer.items.len - 1) |i| {
            const pair = buffer.items[i .. i + 2];
            const insert = rules.get(pair).?;
            try polymer_template.append(pair[0]);
            try polymer_template.append(insert);
        }
        try polymer_template.append(buffer.getLast());
    }

    var elements_freq: [26]u64 = undefined;
    for (&elements_freq) |*freq| {
        freq.* = 0;
    }
    for (polymer_template.items) |element| {
        elements_freq[element - 'A'] += 1;
    }

    return getChecksum(&elements_freq);
}

const State = struct {
    pair_id: u64,
    depth: u8,

    fn new(pair: []const u8, depth: u8) State {
        const pair_id: u64 = (@as(u64, pair[0] - 'A') << 26) | (pair[1] - 'A');
        return State{ .pair_id = pair_id, .depth = depth };
    }
};

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var polymer_template, var rules = try parseInput(allocator, input, null);
    defer {
        polymer_template.deinit();
        rules.deinit();
    }

    var elements_freq: [26]u64 = undefined;
    for (&elements_freq) |*freq| {
        freq.* = 0;
    }

    var cache = std.AutoHashMap(State, [26]u64).init(allocator);
    defer cache.deinit();

    const steps: u8 = 40;
    for (0..polymer_template.items.len - 1) |i| {
        const pair: [2]u8 = .{ polymer_template.items[i], polymer_template.items[i + 1] };
        elements_freq[pair[0] - 'A'] += 1;

        const freqs = try dfs(steps, rules, &cache, pair, 0);
        accumulateFreqs(&elements_freq, freqs);
    }
    elements_freq[polymer_template.getLast() - 'A'] += 1;

    return getChecksum(&elements_freq);
}

fn dfs(steps: u8, rules: std.StringHashMap(u8), cache: *std.AutoHashMap(State, [26]u64), pair: [2]u8, depth: u8) ![26]u64 {
    var elements_freq: [26]u64 = undefined;
    for (&elements_freq) |*freq| {
        freq.* = 0;
    }

    if (depth == steps)
        return elements_freq;

    const state = State.new(&pair, depth);
    if (cache.get(state)) |recorded|
        return recorded;

    const insert = rules.get(&pair).?;
    elements_freq[insert - 'A'] += 1;

    const left, const right = pair;

    const left_pair: [2]u8 = .{ left, insert };
    var freqs = try dfs(steps, rules, cache, left_pair, depth + 1);
    accumulateFreqs(&elements_freq, freqs);

    const right_pair: [2]u8 = .{ insert, right };
    freqs = try dfs(steps, rules, cache, right_pair, depth + 1);
    accumulateFreqs(&elements_freq, freqs);

    try cache.put(state, elements_freq);
    return elements_freq;
}

fn accumulateFreqs(acc: *[26]u64, add: [26]u64) void {
    for (add, 0..) |freq, i| {
        acc[i] += freq;
    }
}

fn getChecksum(elements_freq: []const u64) u64 {
    var min: u64 = std.math.maxInt(u64);
    var max: u64 = 0;
    for (elements_freq) |freq| {
        if (freq == 0)
            continue;
        min = @min(min, freq);
        max = @max(max, freq);
    }
    return max - min;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8, steps: ?usize) !struct { std.ArrayList(u8), std.StringHashMap(u8) } {
    var split = std.mem.splitSequence(u8, input[0 .. input.len - 1], "\n\n");

    const polymer_str = split.next().?;
    // var capacity = polymer_str.len;
    // for (0..steps) |_| {
    //     capacity += capacity - 1;
    // }
    const capacity = if (steps) |n| (polymer_str.len - 1) * std.math.pow(usize, 2, n) + 1 else polymer_str.len;

    var polymer_template = try std.ArrayList(u8).initCapacity(allocator, capacity);
    errdefer polymer_template.deinit();

    try polymer_template.appendSlice(polymer_str);

    var rules = std.StringHashMap(u8).init(allocator);
    errdefer rules.deinit();

    var line_it = std.mem.splitScalar(u8, split.next().?, '\n');
    while (line_it.next()) |line_str| {
        try rules.put(line_str[0..2], line_str[line_str.len - 1]);
    }

    return .{ polymer_template, rules };
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(1588, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(2188189693529, ans);
}
