const std = @import("std");

const data = @embedFile("data/day20.txt");
const data_test = @embedFile("data/day20.test.txt");

const Image = struct {
    pixels: std.AutoHashMap([2]i32, void),

    fn fromInput(allocator: std.mem.Allocator, input: []const u8) !Image {
        var pixels = std.AutoHashMap([2]i32, void).init(allocator);
        errdefer pixels.deinit();

        var line_it = std.mem.splitScalar(u8, input, '\n');
        var y: i32 = 0;
        while (line_it.next()) |line| : (y += 1) {
            var x: i32 = 0;
            while (x < line.len) : (x += 1) {
                if (line[@intCast(x)] == '#')
                    try pixels.put(.{ x, y }, {});
            }
        }
        return Image{ .pixels = pixels };
    }

    fn deinit(self: *Image) void {
        self.pixels.deinit();
    }

    fn debug(self: Image) void {
        const x_min, const x_max, var y, const y_max = getBounds(self.pixels);
        while (y <= y_max) : (y += 1) {
            var x = x_min;
            while (x <= x_max) : (x += 1) {
                const c: u8 = if (self.pixels.contains(.{ x, y })) '#' else '.';
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }

    fn getBounds(pixels: std.AutoHashMap([2]i32, void)) [4]i32 {
        var x_min: i32 = std.math.maxInt(i32);
        var x_max: i32 = std.math.minInt(i32);
        var y_min: i32 = x_min;
        var y_max: i32 = x_max;
        var it = pixels.keyIterator();
        while (it.next()) |pos| {
            const x_pos, const y_pos = pos.*;
            x_min = @min(x_min, x_pos);
            x_max = @max(x_max, x_pos);
            y_min = @min(y_min, y_pos);
            y_max = @max(y_max, y_pos);
        }
        return [_]i32{ x_min, x_max, y_min, y_max };
    }

    fn enhance(self: *Image, algo: []const u8, light_mode: bool) !void {
        var buffer = try self.pixels.clone();
        defer buffer.deinit();
        self.pixels.clearRetainingCapacity();

        const x_min, const x_max, const y_min, const y_max = getBounds(buffer);
        var y_center = y_min - 1;
        while (y_center <= y_max + 1) : (y_center += 1) {
            var x_center = x_min - 1;
            while (x_center <= x_max + 1) : (x_center += 1) {
                var num: usize = 0;

                var y = y_center - 1;
                while (y <= y_center + 1) : (y += 1) {
                    var x = x_center - 1;
                    while (x <= x_center + 1) : (x += 1) {
                        const light = switch (x < x_min or x > x_max or y < y_min or y > y_max) {
                            false => buffer.contains(.{ x, y }),
                            true => light_mode,
                        };
                        num = (num << 1) | @intFromBool(light);
                    }
                }

                if (algo[num] == '#')
                    try self.pixels.put(.{ x_center, y_center }, {});
            }
        }
    }

    fn pixelsLit(self: Image) u32 {
        return self.pixels.count();
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
    return try solve(allocator, input, 2, false);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    return try solve(allocator, input, 50, false);
}

fn solve(allocator: std.mem.Allocator, input: []const u8, num_enhance: u8, verbose: bool) !u32 {
    const enhance_algo, var input_image = try parseInput(allocator, input);
    defer input_image.deinit();

    for (0..num_enhance) |i| {
        const light_mode = switch (enhance_algo[0] == '#') {
            false => false,
            true => @rem(i, 2) == 1,
        };
        try input_image.enhance(enhance_algo, light_mode);
        if (verbose)
            input_image.debug();
    }
    return input_image.pixelsLit();
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct { []const u8, Image } {
    var split = std.mem.splitSequence(u8, input, "\n\n");
    const enhance_algo = split.next().?;
    const input_image = try Image.fromInput(allocator, split.next().?);
    return .{ enhance_algo, input_image };
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(35, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(3351, ans);
}
