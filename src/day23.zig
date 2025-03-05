const std = @import("std");

const data_p1 = @embedFile("data/day23.p1.txt");
const data_test_p1 = @embedFile("data/day23.test.p1.txt");

const data_p2 = @embedFile("data/day23.p2.txt");
const data_test_p2 = @embedFile("data/day23.test.p2.txt");

const AmphipodType = enum(u8) {
    amber = 0,
    bronze = 1,
    copper = 2,
    desert = 3,

    fn fromInput(input: u8) !AmphipodType {
        return switch (input) {
            'A' => .amber,
            'B' => .bronze,
            'C' => .copper,
            'D' => .desert,
            else => return error.InvalidType,
        };
    }

    fn getRoomX(self: AmphipodType) u8 {
        return switch (self) {
            .amber => 3,
            .bronze => 5,
            .copper => 7,
            .desert => 9,
        };
    }

    fn getEnergy(self: AmphipodType) u32 {
        return switch (self) {
            .amber => 1,
            .bronze => 10,
            .copper => 100,
            .desert => 1000,
        };
    }

    fn toIdx(i: usize) usize {
        return @divTrunc(i - 3, 2);
    }
};

const Amphipod = struct {
    type: AmphipodType,
    x: u8,
    moves: u8,

    fn new(pod_type: AmphipodType, x: u8, y: u8) Amphipod {
        return Amphipod{
            .type = pod_type,
            .x = x,
            .moves = if (y == 1) 1 else 2,
        };
    }
};

const Room = struct {
    data: std.BoundedArray(Amphipod, 4),

    fn new() Room {
        return Room{ .data = std.BoundedArray(Amphipod, 4){} };
    }

    fn push(self: *Room, pod: Amphipod) !void {
        try self.data.append(pod);
    }

    fn pop(self: *Room) ?Amphipod {
        return self.data.pop();
    }

    fn peek(self: Room) ?Amphipod {
        return if (self.len() > 0) self.data.get(self.len() - 1) else null;
    }

    fn len(self: Room) usize {
        return self.data.len;
    }

    fn isStable(self: Room, type_id: u8) bool {
        for (self.data.constSlice()) |pod| {
            if (@intFromEnum(pod.type) != type_id)
                return false;
        }
        return true;
    }
};

const Burrow = struct {
    hallway: [11]?Amphipod,
    rooms: [4]Room,

    fn new() Burrow {
        var burrow = Burrow{ .hallway = undefined, .rooms = undefined };
        for (&burrow.hallway) |*opt| {
            opt.* = null;
        }
        for (&burrow.rooms) |*room| {
            room.* = Room.new();
        }
        return burrow;
    }

    fn areHome(self: Burrow, total_size: u8) bool {
        var count: u8 = 0;
        for (self.rooms, 0..) |room, id| {
            if (!room.isStable(@intCast(id)))
                return false;
            count += @intCast(room.len());
        }
        return count == total_size;
    }

    fn isBlocked(self: Burrow, x_src: u8, x_dst: u8) bool {
        const s = if (x_src < x_dst) x_src else x_dst - 1;
        const e = if (x_src < x_dst) x_dst else x_src - 1;
        for (self.hallway[s..e]) |pod_opt| {
            if (pod_opt != null)
                return true;
        }
        return false;
    }

    fn totalPods(self: Burrow) usize {
        var total_pods: usize = 0;
        for (self.rooms) |room| {
            total_pods += room.len();
        }
        for (self.hallway) |pod_opt| {
            if (pod_opt != null)
                total_pods += 1;
        }
        return total_pods;
    }
};

const x_hallway = [_]u8{ 1, 2, 4, 6, 8, 10, 11 };

const State = struct {
    burrow: Burrow,
    total_energy: u32,

    fn new(burrow: Burrow, total_energy: u32) State {
        return State{ .burrow = burrow, .total_energy = total_energy };
    }

    fn compare(context: void, a: State, b: State) std.math.Order {
        _ = context;
        return std.math.order(a.total_energy, b.total_energy);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data_p1);
    const p2 = try partTwo(allocator, data_p2);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

// 0m23.175s both parts

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const start = try parseInput(input);
    return try solve(allocator, start);
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const start = try parseInput(input);
    return try solve(allocator, start);
}

fn solve(allocator: std.mem.Allocator, start: Burrow) !u32 {
    const total_pods: u8 = @intCast(start.totalPods());
    const room_capacity = @divTrunc(total_pods, 4);

    var visited = std.AutoHashMap(Burrow, void).init(allocator);
    defer visited.deinit();

    var queue = std.PriorityQueue(State, void, State.compare).init(allocator, {});
    defer queue.deinit();
    try queue.add(State.new(start, 0));

    while (queue.removeOrNull()) |current| {
        const burrow = current.burrow;
        const total_energy = current.total_energy;
        if (burrow.areHome(total_pods))
            return total_energy;

        if (visited.contains(burrow))
            continue;
        try visited.put(burrow, {});

        // hallway to room
        for (burrow.hallway, 0..) |opt, i| {
            if (opt) |pod| {
                if (pod.moves == 0)
                    continue;

                const x_dst = pod.type.getRoomX();
                if (burrow.isBlocked(pod.x, x_dst))
                    continue;

                const i_room = AmphipodType.toIdx(x_dst);
                const len = burrow.rooms[i_room].len();
                if (len == room_capacity)
                    continue;

                var burrow_clone = burrow;
                burrow_clone.hallway[i] = null;
                var pod_clone = pod;
                pod_clone.x = x_dst;
                pod_clone.moves -= 1;
                try burrow_clone.rooms[i_room].push(pod_clone);

                const energy_expended: u32 = pod.type.getEnergy() * @as(u32, @intCast(@max(pod.x, x_dst) - @min(pod.x, x_dst) + room_capacity - len));
                try queue.add(State.new(burrow_clone, total_energy + energy_expended));
            }
        }

        // room to hallway
        for (burrow.rooms, 0..) |room, type_id| {
            if (room.isStable(@intCast(type_id)))
                continue;

            if (room.peek()) |pod| {
                if (pod.moves == 0)
                    continue;

                const len = room.len();
                for (x_hallway) |x_dst| {
                    if (burrow.isBlocked(pod.x, x_dst))
                        continue;

                    var burrow_clone = burrow;
                    var pod_clone = burrow_clone.rooms[type_id].pop().?;
                    pod_clone.x = x_dst;
                    pod_clone.moves -= 1;
                    burrow_clone.hallway[x_dst - 1] = pod_clone;

                    const energy_expended: u32 = pod.type.getEnergy() * @as(u32, @intCast(@max(pod.x, x_dst) - @min(pod.x, x_dst) + room_capacity - (len - 1)));
                    try queue.add(State.new(burrow_clone, total_energy + energy_expended));
                }
            }
        }
    }
    return error.NoSolution;
}

fn parseInput(input: []const u8) !Burrow {
    var burrow = Burrow.new();

    var line_it = std.mem.splitScalar(u8, input, '\n');
    var y: u8 = 0;
    while (line_it.next()) |line| : (y += 1) {
        var x: u8 = 0;
        while (x < line.len) : (x += 1) {
            switch (line[@intCast(x)]) {
                '#', '.', ' ' => {},
                'A'...'D' + 1 => {
                    const pod_type = try AmphipodType.fromInput(line[@intCast(x)]);
                    const pod = Amphipod.new(pod_type, x, y);
                    if (y == 1) {
                        burrow.hallway[x - 1] = pod;
                    } else {
                        try burrow.rooms[AmphipodType.toIdx(x)].data.insert(0, pod);
                    }
                },
                else => return error.InvalidChar,
            }
        }
    }
    return burrow;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test_p1);
    try std.testing.expectEqual(12521, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test_p2);
    try std.testing.expectEqual(44169, ans);
}
