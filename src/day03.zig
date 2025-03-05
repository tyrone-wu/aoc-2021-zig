const std = @import("std");

const data = @embedFile("data/day03.txt");
const data_test = @embedFile("data/day03.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const diagnostic_report = try parseInput(allocator, input);
    defer allocator.free(diagnostic_report);

    const num_bits = std.mem.indexOfScalar(u8, input, '\n').?;
    var bit_freqs = try allocator.alloc(i16, num_bits);
    defer allocator.free(bit_freqs);
    try getBitFrequencies(diagnostic_report, &bit_freqs);

    var gamma_rate: u32 = 0;
    for (bit_freqs) |freq| {
        gamma_rate <<= 1;
        if (freq > 0) {
            gamma_rate |= 1;
        }
    }
    const epsilon_rate = gamma_rate ^ ((@as(u32, 1) << @intCast(num_bits)) - 1);
    return gamma_rate * epsilon_rate;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const diagnostic_report = try parseInput(allocator, input);
    defer allocator.free(diagnostic_report);

    const num_bits = std.mem.indexOfScalar(u8, input, '\n').?;
    const o2_generator = try getO2Co2(allocator, diagnostic_report, num_bits, .{ '1', '0' });
    const co2_scrubber = try getO2Co2(allocator, diagnostic_report, num_bits, .{ '0', '1' });
    return o2_generator * co2_scrubber;
}

fn getO2Co2(allocator: std.mem.Allocator, diag_report: []const []const u8, num_bits: usize, targets: [2]u8) !u32 {
    const most, const least = targets;

    var clone = try std.ArrayList([]const u8).initCapacity(allocator, diag_report.len);
    defer clone.deinit();
    try clone.appendSlice(diag_report);

    var bit_freqs = try allocator.alloc(i16, num_bits);
    defer allocator.free(bit_freqs);

    var i_bit: usize = 0;
    while (clone.items.len > 1) : (i_bit += 1) {
        try getBitFrequencies(clone.items, &bit_freqs);

        var i: usize = 0;
        while (clone.items.len > 1 and i < clone.items.len) {
            const bit_str = clone.items[i][i_bit];
            if ((bit_str == most and bit_freqs[i_bit] >= 0) or (bit_str == least and bit_freqs[i_bit] < 0)) {
                i += 1;
            } else {
                _ = clone.swapRemove(i);
            }
        }
    }

    var num: u32 = 0;
    for (clone.items[0]) |bit_str| {
        num <<= 1;
        if (bit_str == '1')
            num |= 1;
    }
    return num;
}

fn getBitFrequencies(diag_report: []const []const u8, bit_freqs: *[]i16) !void {
    for (bit_freqs.*) |*freq| {
        freq.* = 0;
    }
    for (diag_report) |binary_str| {
        for (binary_str, 0..) |bit_str, i| {
            switch (bit_str) {
                '0' => bit_freqs.*[i] -= 1,
                '1' => bit_freqs.*[i] += 1,
                else => return error.InvalidBit,
            }
        }
    }
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    const size = std.mem.count(u8, input, "\n");
    var diagnostic_report = try allocator.alloc([]const u8, size);
    errdefer allocator.free(diagnostic_report);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |binary_str| : (i += 1) {
        diagnostic_report[i] = binary_str;
    }
    return diagnostic_report;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(198, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(230, ans);
}
