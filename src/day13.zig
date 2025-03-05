const std = @import("std");

const data = @embedFile("data/day13.txt");
const data_test = @embedFile("data/day13.test.txt");

const Paper = struct {
    allocator: std.mem.Allocator,
    dots: std.AutoHashMap([2]u16, void),
    insns: []const Instruction,

    const Instruction = struct {
        x_axis: bool,
        pos: u16,

        fn new(input: []const u8) !Instruction {
            const x_axis = input[11] == 'x';
            const pos = try std.fmt.parseInt(u16, input[13..], 10);
            return Instruction{ .x_axis = x_axis, .pos = pos };
        }
    };

    fn new(allocator: std.mem.Allocator, input: []const u8) !Paper {
        var split = std.mem.splitSequence(u8, input[0 .. input.len - 1], "\n\n");

        var dots = std.AutoHashMap([2]u16, void).init(allocator);
        errdefer dots.deinit();

        var dots_it = std.mem.splitScalar(u8, split.next().?, '\n');
        while (dots_it.next()) |dot_str| {
            var point_split = std.mem.splitScalar(u8, dot_str, ',');
            const x = try std.fmt.parseInt(u16, point_split.next().?, 10);
            const y = try std.fmt.parseInt(u16, point_split.next().?, 10);
            try dots.put(.{ x, y }, {});
        }

        const insns_section = split.next().?;
        const size = std.mem.count(u8, insns_section, "\n") + 1;
        var insns = try allocator.alloc(Instruction, size);
        errdefer allocator.free(insns);

        var insns_it = std.mem.splitScalar(u8, insns_section, '\n');
        var i: usize = 0;
        while (insns_it.next()) |insn_str| : (i += 1) {
            insns[i] = try Instruction.new(insn_str);
        }

        return Paper{ .allocator = allocator, .dots = dots, .insns = insns };
    }

    fn deinit(self: *Paper) void {
        self.allocator.free(self.insns);
        self.dots.deinit();
    }

    fn debug(self: Paper) void {
        var x_max: u16 = 0;
        var y_max: u16 = 0;
        var dot_it = self.dots.keyIterator();
        while (dot_it.next()) |dot| {
            const x, const y = dot.*;
            x_max = @max(x_max, x);
            y_max = @max(y_max, y);
        }

        var y: u16 = 0;
        while (y <= y_max) : (y += 1) {
            var x: u16 = 0;
            while (x <= x_max) : (x += 1) {
                const c: u8 = if (self.dots.contains(.{ x, y })) '#' else '.';
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }

    fn applyFolds(self: *Paper, fold_once: bool) !void {
        for (self.insns) |insn| {
            var dot_it = self.dots.keyIterator();
            while (dot_it.next()) |dot| {
                const x, const y = dot.*;
                if (insn.x_axis and x > insn.pos) {
                    _ = self.dots.remove(dot.*);
                    const x_n = 2 * insn.pos - x;
                    try self.dots.put(.{ x_n, y }, {});
                } else if (!insn.x_axis and y > insn.pos) {
                    _ = self.dots.remove(dot.*);
                    const y_n = 2 * insn.pos - y;
                    try self.dots.put(.{ x, y_n }, {});
                }
            }

            if (fold_once)
                break;
        }
    }

    fn totalDots(self: Paper) u32 {
        return self.dots.count();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2:\n", .{p1});
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var paper = try Paper.new(allocator, input);
    defer paper.deinit();

    try paper.applyFolds(true);
    // paper.debug();
    return paper.totalDots();
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !void {
    var paper = try Paper.new(allocator, input);
    defer paper.deinit();

    try paper.applyFolds(false);
    paper.debug();
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(17, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    try partTwo(allocator, data_test);
}
