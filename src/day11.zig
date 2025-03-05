const std = @import("std");

const data = @embedFile("data/day11.txt");
const data_test = @embedFile("data/day11.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var octopuses = parseInput(input);

    var total_flashes: u32 = 0;
    const total_steps = 100;
    for (0..total_steps) |_| {
        const flashes, _ = try step(allocator, &octopuses);
        total_flashes += flashes;
    }
    return total_flashes;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var octopuses = parseInput(input);

    var current_steps: u32 = 0;
    var all_flash = false;
    while (!all_flash) : (current_steps += 1) {
        _, all_flash = try step(allocator, &octopuses);
    }
    return current_steps;
}

fn step(allocator: std.mem.Allocator, octopuses: *[12][12]i8) !struct { u32, bool } {
    var flashes_seen = std.AutoHashMap([2]i8, void).init(allocator);
    defer flashes_seen.deinit();

    var queue: std.fifo.LinearFifo([2]i8, .Dynamic) = std.fifo.LinearFifo([2]i8, .Dynamic).init(allocator);
    defer queue.deinit();

    for (1..11) |y| {
        for (1..11) |x| {
            octopuses[y][x] += 1;
            if (octopuses[y][x] > 9) {
                const coord: [2]i8 = .{ @intCast(x), @intCast(y) };
                try queue.writeItem(coord);
                try flashes_seen.put(coord, {});
            }
        }
    }

    while (queue.readItem()) |coord| {
        octopuses[@intCast(coord[1])][@intCast(coord[0])] = 0;
        for ([3]i8{ -1, 0, 1 }) |dy| {
            for ([3]i8{ -1, 0, 1 }) |dx| {
                const adj_coord: [2]i8 = .{ dx + coord[0], dy + coord[1] };
                const x: usize = @intCast(adj_coord[0]);
                const y: usize = @intCast(adj_coord[1]);
                if (octopuses[y][x] < 0 or (dy == 0 and dx == 0) or flashes_seen.contains(adj_coord))
                    continue;

                octopuses[y][x] += 1;
                if (octopuses[y][x] > 9) {
                    try queue.writeItem(adj_coord);
                    try flashes_seen.put(adj_coord, {});
                }
            }
        }
    }

    const flashes = flashes_seen.count();
    return .{ flashes, flashes == 100 };
}

fn parseInput(input: []const u8) [12][12]i8 {
    var octopuses: [12][12]i8 = undefined;
    for (0..12) |i| {
        octopuses[i][0] = -1;
        octopuses[i][11] = -1;
        octopuses[0][i] = -1;
        octopuses[11][i] = -1;
    }

    var i: usize = 0;
    for (input) |c| {
        if (c == '\n')
            continue;

        octopuses[@divTrunc(i, 10) + 1][@mod(i, 10) + 1] = @intCast(c - '0');
        i += 1;
    }
    return octopuses;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(1656, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(195, ans);
}
