const std = @import("std");

const data = @embedFile("data/day07.txt");
const data_test = @embedFile("data/day07.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const crab_positions = try parseInput(allocator, input);
    defer allocator.free(crab_positions);

    std.sort.pdq(i16, crab_positions, {}, std.sort.asc(i16));
    const median = crab_positions[@divTrunc(crab_positions.len, 2)];
    return calcFuel(crab_positions, median, false);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const crab_positions = try parseInput(allocator, input);
    defer allocator.free(crab_positions);

    const optimal_pos = binarySearch(crab_positions);
    return calcFuel(crab_positions, optimal_pos, true);
}

fn binarySearch(positions: []const i16) i16 {
    var lo, var hi = std.mem.minMax(i16, positions);
    while (lo < hi) {
        const mid = @divTrunc(lo + hi, 2);
        const fuel_mid = calcFuel(positions, mid, true);
        const fuel_left = calcFuel(positions, mid - 1, true);
        const fuel_right = calcFuel(positions, mid + 1, true);
        if (fuel_left < fuel_mid and fuel_mid < fuel_right) {
            hi = mid - 1;
        } else if (fuel_left > fuel_mid and fuel_mid > fuel_right) {
            lo = mid + 1;
        } else {
            return mid;
        }
    }
    return lo;
}

fn calcFuel(positions: []const i16, horizontal: i16, p2: bool) u32 {
    var fuel: u32 = 0;
    for (positions) |pos| {
        const dist: u32 = @abs(horizontal - pos);
        fuel += if (!p2) dist else @divTrunc(dist * (dist + 1), 2);
    }
    return fuel;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]i16 {
    const size = std.mem.count(u8, input, ",") + 1;
    const crab_positions = try allocator.alloc(i16, size);
    errdefer allocator.free(crab_positions);

    var pos_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], ',');
    var i: usize = 0;
    while (pos_it.next()) |pos_str| : (i += 1) {
        const position = try std.fmt.parseInt(i16, pos_str, 10);
        crab_positions[i] = position;
    }
    return crab_positions;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(37, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(168, ans);
}
