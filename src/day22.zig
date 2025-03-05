const std = @import("std");

const data = @embedFile("data/day22.txt");
const data_test_p1 = @embedFile("data/day22.test.p1.txt");
const data_test_p2 = @embedFile("data/day22.test.p2.txt");

const Range = struct {
    min: i32,
    max: i32,

    fn fromStr(min_str: []const u8, max_str: []const u8) !Range {
        return Range{
            .min = try std.fmt.parseInt(i32, min_str, 10),
            .max = try std.fmt.parseInt(i32, max_str, 10),
        };
    }

    fn within(self: Range, bound: i32) bool {
        return -bound <= self.min and self.max <= bound;
    }

    fn contains(self: Range, pos: i32) bool {
        return self.min <= pos and pos <= self.max;
    }

    fn intersects(self: Range, other: Range) bool {
        return self.contains(other.min) or self.contains(other.max) or other.contains(self.min) or other.contains(self.max);
    }

    fn getIntersectRange(self: Range, other: Range) Range {
        std.debug.assert(self.intersects(other));

        const min = @max(self.min, other.min);
        const max = @min(self.max, other.max);
        return Range{ .min = min, .max = max };
    }

    fn length(self: Range) u64 {
        return @abs(self.max - self.min) + 1;
    }
};

const Cuboid = struct {
    x_range: Range,
    y_range: Range,
    z_range: Range,

    fn fromInput(input: []const u8) !Cuboid {
        var it = std.mem.tokenizeAny(u8, input, "onoff xyz=.,");
        const x_range = try Range.fromStr(it.next().?, it.next().?);
        const y_range = try Range.fromStr(it.next().?, it.next().?);
        const z_range = try Range.fromStr(it.next().?, it.next().?);

        return Cuboid{
            .x_range = x_range,
            .y_range = y_range,
            .z_range = z_range,
        };
    }

    fn within(self: Cuboid, bound: i32) bool {
        return self.x_range.within(bound) and self.y_range.within(bound) and self.z_range.within(bound);
    }

    fn intersects(self: Cuboid, other: Cuboid) bool {
        return self.x_range.intersects(other.x_range) and self.y_range.intersects(other.y_range) and self.z_range.intersects(other.z_range);
    }

    fn getIntersectCuboid(self: Cuboid, other: Cuboid) ?Cuboid {
        if (!self.intersects(other))
            return null;

        const x_range = self.x_range.getIntersectRange(other.x_range);
        const y_range = self.y_range.getIntersectRange(other.y_range);
        const z_range = self.z_range.getIntersectRange(other.z_range);
        return Cuboid{
            .x_range = x_range,
            .y_range = y_range,
            .z_range = z_range,
        };
    }

    fn volume(self: Cuboid) u64 {
        return self.x_range.length() * self.y_range.length() * self.z_range.length();
    }
};

const RebootStep = struct {
    on: bool,
    cuboid: Cuboid,

    fn new(on: bool, cuboid: Cuboid) RebootStep {
        return RebootStep{ .on = on, .cuboid = cuboid };
    }

    fn fromInput(input: []const u8) !RebootStep {
        return RebootStep.new(
            input[1] == 'n',
            try Cuboid.fromInput(input),
        );
    }

    fn apply(self: RebootStep, cubes: *std.AutoHashMap([3]i32, void)) !void {
        const x_range = self.cuboid.x_range;
        const y_range = self.cuboid.y_range;
        const z_range = self.cuboid.z_range;

        var z = z_range.min;
        while (z <= z_range.max) : (z += 1) {
            var y = y_range.min;
            while (y <= y_range.max) : (y += 1) {
                var x = x_range.min;
                while (x <= x_range.max) : (x += 1) {
                    if (self.on) {
                        try cubes.put(.{ x, y, z }, {});
                    } else {
                        _ = cubes.remove(.{ x, y, z });
                    }
                }
            }
        }
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
    const reboot_steps = try parseInput(allocator, input);
    defer allocator.free(reboot_steps);

    var cubes = std.AutoHashMap([3]i32, void).init(allocator);
    defer cubes.deinit();

    for (reboot_steps) |step| {
        if (step.cuboid.within(50))
            try step.apply(&cubes);
    }
    return cubes.count();
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const reboot_steps = try parseInput(allocator, input);
    defer allocator.free(reboot_steps);

    var steps = std.ArrayList(RebootStep).init(allocator);
    defer steps.deinit();

    for (reboot_steps) |current| {
        const size = steps.items.len;
        // does not work since memory of the slice won't exist if ArrayList is resized
        // for (steps.items[0..size]) |prev| {
        for (0..size) |i| {
            const prev = steps.items[i];
            if (current.cuboid.getIntersectCuboid(prev.cuboid)) |x_cuboid| {
                const on = !prev.on;
                const add_step = RebootStep.new(on, x_cuboid);
                try steps.append(add_step);
            }
        }
        if (current.on)
            try steps.append(current);
    }

    var on_volume: u64 = 0;
    var off_volume: u64 = 0;
    for (steps.items) |step| {
        if (step.on) {
            on_volume += step.cuboid.volume();
        } else {
            off_volume += step.cuboid.volume();
        }
    }
    return on_volume - off_volume;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const RebootStep {
    const size = std.mem.count(u8, input, "\n");
    var reboot_steps = try allocator.alloc(RebootStep, size);
    errdefer allocator.free(reboot_steps);

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    var i: usize = 0;
    while (line_it.next()) |line| : (i += 1) {
        reboot_steps[i] = try RebootStep.fromInput(line);
    }
    return reboot_steps;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test_p1);
    try std.testing.expectEqual(590784, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test_p2);
    try std.testing.expectEqual(2758514936282235, ans);
}
