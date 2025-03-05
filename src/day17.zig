const std = @import("std");

const data = @embedFile("data/day17.txt");
const data_test = @embedFile("data/day17.test.txt");

const Status = enum {
    maybe,
    success,
    miss,
};

const TargetArea = struct {
    x_min: i32,
    x_max: i32,
    y_min: i32,
    y_max: i32,

    fn fromInput(input: []const u8) !TargetArea {
        var area = TargetArea{ .x_min = 0, .x_max = 0, .y_min = 0, .y_max = 0 };
        var tokens_it = std.mem.tokenizeAny(u8, input, "target area: x=.,y\n");
        area.x_min = try std.fmt.parseInt(i32, tokens_it.next().?, 10);
        area.x_max = try std.fmt.parseInt(i32, tokens_it.next().?, 10);
        area.y_min = try std.fmt.parseInt(i32, tokens_it.next().?, 10);
        area.y_max = try std.fmt.parseInt(i32, tokens_it.next().?, 10);
        return area;
    }

    fn status(self: TargetArea, probe: Vector) Status {
        if (probe.x > self.x_max or probe.y < self.y_min) {
            return Status.miss;
        } else if ((self.x_min <= probe.x and probe.x <= self.x_max) and (self.y_min <= probe.y and probe.y <= self.y_max)) {
            return Status.success;
        } else {
            return Status.maybe;
        }
    }
};

const Vector = struct {
    x: i32,
    y: i32,

    fn new(x: i32, y: i32) Vector {
        return Vector{ .x = x, .y = y };
    }

    fn step(self: *Vector, velocity: *Vector) void {
        self.x += velocity.x;
        self.y += velocity.y;
        velocity.*.x += if (velocity.x > 0) -1 else if (velocity.x < 0) 1 else 0;
        velocity.*.y -= 1;
    }
};

pub fn main() !void {
    const p1 = try partOne(data);
    const p2 = try partTwo(data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !i32 {
    const target_area = try TargetArea.fromInput(input);
    // x independent from y
    // probe will eventually hit y = 0
    // the step after it hits y = 0 will maximize y dist
    // so initial velocity is dist from (0 - edge of target area) - 1
    // calc dist from summation sequence
    const y_velocity = @abs(target_area.y_min) - 1;
    return summationI(@intCast(y_velocity));
}

fn partTwo(input: []const u8) !u32 {
    const target_area = try TargetArea.fromInput(input);

    var x_min: i32 = 0;
    while (summationI(x_min + 1) < target_area.x_min) : (x_min += 1) {}
    const x_max = target_area.x_max + 1;
    const y_min = target_area.y_min - 1;
    const y_max = @abs(target_area.y_min) + 1;

    var in_ta: u32 = 0;
    var y_velocity: i32 = y_min;
    while (y_velocity <= y_max) : (y_velocity += 1) {
        var x_velocity: i32 = x_min - 1;
        while (x_velocity <= x_max) : (x_velocity += 1) {
            var probe = Vector.new(0, 0);
            var velocity = Vector.new(x_velocity, y_velocity);

            var status = target_area.status(probe);
            while (status == .maybe) : (status = target_area.status(probe)) {
                probe.step(&velocity);
            }

            if (status == .success)
                in_ta += 1;
        }
    }
    return in_ta;
}

fn summationI(num: i32) i32 {
    return @divTrunc(num * (num + 1), 2);
}

test "p1" {
    const ans = try partOne(data_test);
    try std.testing.expectEqual(45, ans);
}

test "p2" {
    const ans = try partTwo(data_test);
    try std.testing.expectEqual(112, ans);
}
