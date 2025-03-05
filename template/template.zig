const std = @import("std");

// const List = std.ArrayList;
// const Map = std.AutoHashMap;
// const StrMap = std.StringHashMap;
// const BitSet = std.DynamicBitSet;

// const tokenizeAny = std.mem.tokenizeAny;
// const tokenizeSeq = std.mem.tokenizeSequence;
// const tokenizeSca = std.mem.tokenizeScalar;
// const splitAny = std.mem.splitAny;
// const splitSeq = std.mem.splitSequence;
// const splitSca = std.mem.splitScalar;
// const indexOf = std.mem.indexOfScalar;
// const indexOfAny = std.mem.indexOfAny;
// const indexOfStr = std.mem.indexOfPosLinear;
// const lastIndexOf = std.mem.lastIndexOfScalar;
// const lastIndexOfAny = std.mem.lastIndexOfAny;
// const lastIndexOfStr = std.mem.lastIndexOfLinear;
// const trim = std.mem.trim;
// const sliceMin = std.mem.min;
// const sliceMax = std.mem.max;

// const parseInt = std.fmt.parseInt;
// const parseFloat = std.fmt.parseFloat;

// const print = std.debug.print;
// const assert = std.debug.assert;

// const sort = std.sort.block;
// const asc = std.sort.asc;
// const desc = std.sort.desc;

const data = @embedFile("data/day$.txt");
const data_test = @embedFile("data/day$.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    _ = allocator;
    _ = input;
    return 0;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    _ = allocator;
    _ = input;
    return 0;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(0, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(0, ans);
}
