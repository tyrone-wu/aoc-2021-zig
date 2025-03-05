const std = @import("std");

const data = @embedFile("data/day18.txt");
const data_test = @embedFile("data/day18.test.txt");

const SnailfishType = enum { number, pair };

const SnailfishNumber = struct {
    allocator: std.mem.Allocator,
    parent: ?*SnailfishNumber,
    data: union(SnailfishType) {
        number: u8,
        pair: [2]*SnailfishNumber,
    },

    fn newNumber(allocator: std.mem.Allocator, parent: ?*SnailfishNumber, number: u8) !*SnailfishNumber {
        const sn = try init(allocator);
        errdefer sn.deinit();

        sn.allocator = allocator;
        sn.parent = parent;
        sn.data = .{ .number = number };
        return sn;
    }

    fn newPair(allocator: std.mem.Allocator, parent: ?*SnailfishNumber, left_number: u8, right_number: u8) !*SnailfishNumber {
        const sn = try init(allocator);
        errdefer allocator.destroy(sn);
        const left = try newNumber(allocator, sn, left_number);
        errdefer left.deinit();
        const right = try newNumber(allocator, sn, right_number);
        errdefer right.deinit();

        sn.allocator = allocator;
        sn.parent = parent;
        sn.data = .{
            .pair = .{ left, right },
        };
        return sn;
    }

    fn fillPair(sn: *SnailfishNumber, parent: ?*SnailfishNumber, left: *SnailfishNumber, right: *SnailfishNumber) *SnailfishNumber {
        sn.parent = parent;
        sn.data = .{ .pair = .{ left, right } };
        return sn;
    }

    fn init(allocator: std.mem.Allocator) !*SnailfishNumber {
        const sn = try allocator.create(SnailfishNumber);
        errdefer allocator.destroy(sn);

        sn.allocator = allocator;
        return sn;
    }

    fn fromInput(allocator: std.mem.Allocator, input: []const u8, i: *usize, parent: ?*SnailfishNumber) !*SnailfishNumber {
        switch (input[i.*]) {
            '0'...'9' + 1 => {
                const num = input[i.*] - '0';
                i.* += 1;
                return try newNumber(allocator, parent, num);
            },
            '[' => {
                const pair = try init(allocator);
                errdefer allocator.destroy(pair);

                i.* += 1;
                const left = try fromInput(allocator, input, i, pair);
                while (input[i.*] != ',') : (i.* += 1) {}
                i.* += 1;
                const right = try fromInput(allocator, input, i, pair);

                return fillPair(pair, parent, left, right);
            },
            else => return error.InvalidChar,
        }
    }

    fn deinit(self: *SnailfishNumber) void {
        switch (self.data) {
            .number => {},
            .pair => {
                self.data.pair[0].deinit();
                self.data.pair[1].deinit();
            },
        }
        self.allocator.destroy(self);
    }

    fn debug(self: SnailfishNumber) void {
        switch (self.data) {
            .number => |number| std.debug.print("{d}", .{number}),
            .pair => |pair| {
                std.debug.print("[", .{});
                pair[0].debug();
                std.debug.print(",", .{});
                pair[1].debug();
                std.debug.print("]", .{});
            },
        }
    }

    fn reduce(self: *SnailfishNumber) !void {
        while (true) {
            if (!try self.explode(0)) {
                if (!try self.split())
                    break;
            }
        }
    }

    fn explode(self: *SnailfishNumber, depth: u8) !bool {
        switch (self.data) {
            .number => return false,
            .pair => |pair| {
                if (depth >= 4) {
                    const left_number = pair[0].data.number;
                    const right_number = pair[1].data.number;

                    var prev = self;
                    var cursor: ?*SnailfishNumber = self.parent;
                    while (cursor != null and cursor.?.data.pair[0].isPair() and cursor.?.data.pair[1] != prev) : (cursor = cursor.?.parent) {
                        prev = cursor.?;
                    }
                    if (cursor) |sn| {
                        if (sn.data.pair[0].isPair()) {
                            cursor = sn.data.pair[0];
                            while (cursor.?.isPair()) : (cursor = cursor.?.data.pair[1]) {}
                            cursor.?.data.number += left_number;
                        } else {
                            sn.data.pair[0].data.number += left_number;
                        }
                    }

                    prev = self;
                    cursor = self.parent;
                    while (cursor != null and cursor.?.data.pair[1].isPair() and cursor.?.data.pair[0] != prev) : (cursor = cursor.?.parent) {
                        prev = cursor.?;
                    }
                    if (cursor) |sn| {
                        if (sn.data.pair[1].isPair()) {
                            cursor = sn.data.pair[1];
                            while (cursor.?.isPair()) : (cursor = cursor.?.data.pair[0]) {}
                            cursor.?.data.number += right_number;
                        } else {
                            sn.data.pair[1].data.number += right_number;
                        }
                    }

                    pair[0].deinit();
                    pair[1].deinit();
                    self.data = .{ .number = 0 };
                    return true;
                } else {
                    return try pair[0].explode(depth + 1) or try pair[1].explode(depth + 1);
                }
            },
        }
    }

    fn split(self: *SnailfishNumber) !bool {
        switch (self.data) {
            .number => |number| {
                if (number >= 10) {
                    const left_num = @divTrunc(number, 2);
                    const left = try newNumber(self.allocator, self, left_num);
                    errdefer left.deinit();

                    const right_num = left_num + @as(u8, if (@rem(number, 2) == 1) 1 else 0);
                    const right = try newNumber(self.allocator, self, right_num);
                    errdefer right.deinit();

                    self.data = .{
                        .pair = .{ left, right },
                    };
                    return true;
                } else {
                    return false;
                }
            },
            .pair => |pair| return try pair[0].split() or try pair[1].split(),
        }
    }

    fn isPair(self: SnailfishNumber) bool {
        return switch (self.data) {
            .number => false,
            .pair => true,
        };
    }

    fn add(left: *SnailfishNumber, right: *SnailfishNumber) !*SnailfishNumber {
        const sn = try left.allocator.create(SnailfishNumber);
        errdefer left.allocator.destroy(sn);

        left.parent = sn;
        right.parent = sn;

        sn.allocator = left.allocator;
        sn.parent = null;
        sn.data = .{
            .pair = .{ left, right },
        };
        return sn;
    }

    fn magnitude(self: SnailfishNumber) u32 {
        return switch (self.data) {
            .number => |number| number,
            .pair => |pair| 3 * pair[0].magnitude() + 2 * pair[1].magnitude(),
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

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const numbers = try parseInput(allocator, &arena, input);
    defer {
        for (numbers) |sn| {
            sn.deinit();
        }
        allocator.free(numbers);
    }

    var sn = numbers[0];
    for (1..numbers.len) |i| {
        // std.debug.print("before: ", .{});
        // sn.debug();
        // std.debug.print("\n", .{});

        // std.debug.print("+: ", .{});
        // numbers[i].debug();
        // std.debug.print("\n", .{});

        sn = try SnailfishNumber.add(sn, numbers[i]);
        try sn.reduce();

        // std.debug.print("after: ", .{});
        // sn.debug();
        // std.debug.print("\n", .{});
    }

    return sn.magnitude();
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // too lazy to implement clone, so re-parse input
    const size = std.mem.count(u8, input, "\n");
    var max_magnitude: u32 = 0;
    for (0..size) |i| {
        for (i + 1..size) |j| {
            {
                const numbers = try parseInput(allocator, &arena, input);
                defer allocator.free(numbers);

                var sn = try SnailfishNumber.add(numbers[i], numbers[j]);
                try sn.reduce();
                max_magnitude = @max(max_magnitude, sn.magnitude());
            }
            {
                const numbers = try parseInput(allocator, &arena, input);
                defer allocator.free(numbers);

                const sn = try SnailfishNumber.add(numbers[j], numbers[i]);
                try sn.reduce();
                max_magnitude = @max(max_magnitude, sn.magnitude());
            }
        }
    }
    return max_magnitude;
}

fn parseInput(general_allocator: std.mem.Allocator, arena: *std.heap.ArenaAllocator, input: []const u8) ![]*SnailfishNumber {
    const size = std.mem.count(u8, input, "\n");
    var numbers = try general_allocator.alloc(*SnailfishNumber, size);
    errdefer general_allocator.free(numbers);

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    var i: usize = 0;
    while (line_it.next()) |line| : (i += 1) {
        var j: usize = 0;
        const arena_allocator = arena.allocator();
        numbers[i] = try SnailfishNumber.fromInput(arena_allocator, line, &j, null);
        errdefer numbers[i].deinit();
    }
    return numbers;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(4140, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(3993, ans);
}
