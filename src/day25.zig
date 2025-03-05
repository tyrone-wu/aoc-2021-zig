const std = @import("std");

const data = @embedFile("data/day25.txt");
const data_test = @embedFile("data/day25.test.txt");

const Space = enum { open, east, south };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    std.debug.print("part 1: {d}\n", .{p1});
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var map = try parseInput(allocator, input);
    defer {
        for (map) |*row| {
            allocator.free(row.*);
        }
        allocator.free(map);
    }

    var map_buffer = try allocator.alloc([]Space, map.len);
    defer {
        for (map_buffer) |*row| {
            allocator.free(row.*);
        }
        allocator.free(map_buffer);
    }
    for (map_buffer) |*row| {
        row.* = try allocator.alloc(Space, map[0].len);
        errdefer allocator.free(row.*);
    }

    var steps: u32 = 0;
    var moved = true;
    while (moved) : (steps += 1) {
        moved = false;

        for (map, 0..) |row, y| {
            for (row, 0..) |space, x| {
                map_buffer[y][x] = space;
            }
        }

        for (map_buffer, 0..) |row, y| {
            for (row, 0..) |space, x| {
                if (space == .east) {
                    const x_next = @rem(x + 1, row.len);
                    if (map_buffer[y][x_next] == .open) {
                        map[y][x] = .open;
                        map[y][x_next] = .east;
                        moved = true;
                    }
                }
            }
            for (map[y], 0..) |space, x| {
                map_buffer[y][x] = space;
            }
        }

        for (map_buffer, 0..) |row, y| {
            for (row, 0..) |space, x| {
                if (space == .south) {
                    const y_next = @rem(y + 1, map_buffer.len);
                    if (map_buffer[y_next][x] == .open) {
                        map[y][x] = .open;
                        map[y_next][x] = .south;
                        moved = true;
                    }
                }
            }
        }
    }
    return steps;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const []Space {
    const rows = std.mem.count(u8, input, "\n");
    const cols = std.mem.indexOfScalar(u8, input, '\n').?;

    var map = try allocator.alloc([]Space, rows);
    errdefer {
        for (map) |*row| {
            allocator.free(row.*);
        }
        allocator.free(map);
    }

    var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
    var y: usize = 0;
    while (line_it.next()) |line| : (y += 1) {
        var row = try allocator.alloc(Space, cols);
        errdefer allocator.free(row);

        for (line, 0..) |c, x| {
            row[x] = switch (c) {
                '.' => .open,
                '>' => .east,
                'v' => .south,
                else => return error.InvalidSpace,
            };
        }
        map[y] = row;
    }
    return map;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(58, ans);
}
