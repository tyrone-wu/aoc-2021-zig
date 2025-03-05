const std = @import("std");

const data = @embedFile("data/day08.txt");
const data_test = @embedFile("data/day08.test.txt");

const Entry = struct {
    signal_pattern: [10][]const u8,
    output: [4][]const u8,

    fn new(input: []const u8) Entry {
        var entry = Entry{ .signal_pattern = undefined, .output = undefined };
        var split_it = std.mem.splitSequence(u8, input, " | ");

        var sig_it = std.mem.splitScalar(u8, split_it.next().?, ' ');
        var i: usize = 0;
        while (sig_it.next()) |signal| : (i += 1) {
            entry.signal_pattern[i] = signal;
        }

        var output_it = std.mem.splitScalar(u8, split_it.next().?, ' ');
        i = 0;
        while (output_it.next()) |val| : (i += 1) {
            entry.output[i] = val;
        }

        return entry;
    }
};

const Segment = struct {
    wires: u7,

    fn new() Segment {
        return Segment{ .wires = 0 };
    }

    fn newWithSignal(signal: []const u8) !Segment {
        var seg = Segment.new();
        try seg.fromSignal(signal);
        return seg;
    }

    fn fromSignal(self: *Segment, signal: []const u8) !void {
        for (signal) |c| {
            if (c > 'g')
                return error.InvalidSegment;

            self.wires |= @as(u7, 1) << @intCast(c - 'a');
        }
    }

    fn len(self: Segment) u7 {
        return @popCount(self.wires);
    }

    fn decode(self: Segment, one: Segment, four: Segment) !u8 {
        return switch (self.len()) {
            2 => 1,
            4 => 4,
            3 => 7,
            7 => 8,
            6 => if (self.wires & four.wires == four.wires)
                9
            else if (self.wires & one.wires == one.wires)
                0
            else
                6,
            5 => if (self.wires & one.wires == one.wires)
                3
            else if (@popCount(self.wires & four.wires) == 2)
                2
            else
                5,
            else => return error.NumNotFound,
        };
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

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u16 {
    const entries = try parseInput(allocator, input);
    defer allocator.free(entries);

    var count: u16 = 0;
    for (entries) |entry| {
        for (entry.output) |signal| {
            if (signal.len == 2 or signal.len == 4 or signal.len == 3 or signal.len == 7)
                count += 1;
        }
    }
    return count;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const entries = try parseInput(allocator, input);
    defer allocator.free(entries);

    var sum: u32 = 0;
    for (entries) |entry| {
        var one = Segment.new();
        var four = Segment.new();
        // var seven: Segment = undefined;
        for (entry.signal_pattern) |signal| {
            switch (signal.len) {
                2 => try one.fromSignal(signal),
                4 => try four.fromSignal(signal),
                // 3 => try seven.fromSignal(signal),
                else => {},
            }
        }

        var num: u32 = 0;
        for (entry.output) |val| {
            const seg = try Segment.newWithSignal(val);
            num = num * 10 + try seg.decode(one, four);
        }
        sum += num;
    }
    return sum;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const Entry {
    const size = std.mem.count(u8, input, "\n");
    const entries = try allocator.alloc(Entry, size);
    errdefer allocator.free(entries);

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    var i: usize = 0;
    while (line_it.next()) |line| : (i += 1) {
        entries[i] = Entry.new(line);
    }
    return entries;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(26, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(61229, ans);
}
