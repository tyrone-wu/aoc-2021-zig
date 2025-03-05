const std = @import("std");

const data = @embedFile("data/day19.txt");
const data_test = @embedFile("data/day19.test.txt");

const ScannerReport = struct {
    allocator: std.mem.Allocator,
    beacons: []const [24][3]i32,
    orientation: ?u8,
    offset: ?[3]i32,

    fn fromInput(allocator: std.mem.Allocator, input: []const u8) !ScannerReport {
        const size = std.mem.count(u8, input[0 .. input.len - 1], "\n");
        var beacons = try allocator.alloc([24][3]i32, size);
        errdefer allocator.free(beacons);

        var line_it = std.mem.tokenizeScalar(u8, input, '\n');
        _ = line_it.next().?;

        var i: usize = 0;
        while (line_it.next()) |line| : (i += 1) {
            var pos: [3]i32 = undefined;
            var pos_it = std.mem.splitScalar(u8, line, ',');
            var j: usize = 0;
            while (pos_it.next()) |pos_str| : (j += 1) {
                pos[j] = try std.fmt.parseInt(i32, pos_str, 10);
            }
            beacons[i] = getOrientations(pos);
        }

        return ScannerReport{
            .allocator = allocator,
            .beacons = beacons,
            .orientation = null,
            .offset = null,
        };
    }

    fn deinit(self: *ScannerReport) void {
        self.allocator.free(self.beacons);
    }

    fn tryFit(allocator: std.mem.Allocator, base: *ScannerReport, piece: *ScannerReport) !bool {
        var buffer = std.AutoHashMap([3]i32, void).init(allocator);
        defer buffer.deinit();

        for (base.beacons) |base_beacon| {
            const base_pos = add(base_beacon[base.orientation.?], base.offset.?);

            for (0..24) |orientation| {
                for (piece.beacons) |piece_beacon| {
                    const pivot = piece_beacon[orientation];
                    const offset = sub(base_pos, pivot);

                    buffer.clearRetainingCapacity();
                    for (piece.beacons) |piece_pos| {
                        const new_pos = add(piece_pos[orientation], offset);
                        try buffer.put(new_pos, {});
                    }

                    var matches: u8 = 0;
                    for (base.beacons) |bb| {
                        const b = add(bb[base.orientation.?], base.offset.?);
                        if (buffer.contains(b))
                            matches += 1;
                    }
                    if (matches >= 12) {
                        piece.orientation = @intCast(orientation);
                        piece.offset = offset;
                        return true;
                    }
                }
            }
        }
        return false;
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

// 1m7.578s to finish
fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const scan_reports = try parseInput(allocator, input);
    defer {
        for (scan_reports) |*report| {
            report.deinit();
        }
        allocator.free(scan_reports);
    }

    try findOffsets(allocator, scan_reports);

    var beacon_positions = std.AutoHashMap([3]i32, void).init(allocator);
    defer beacon_positions.deinit();

    for (scan_reports) |report| {
        for (report.beacons) |beacons| {
            const pos = add(beacons[report.orientation.?], report.offset.?);
            try beacon_positions.put(pos, {});
        }
    }
    return beacon_positions.count();
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const scan_reports = try parseInput(allocator, input);
    defer {
        for (scan_reports) |*report| {
            report.deinit();
        }
        allocator.free(scan_reports);
    }

    try findOffsets(allocator, scan_reports);

    var max_dist: u32 = 0;
    for (scan_reports, 0..) |a, i| {
        for (scan_reports[i + 1 ..]) |b| {
            const man_dist = manDist(a.offset.?, b.offset.?);
            max_dist = @max(max_dist, man_dist);
        }
    }
    return max_dist;
}

fn manDist(a: [3]i32, b: [3]i32) u32 {
    return @abs(a[0] - b[0]) + @abs(a[1] - b[1]) + @abs(a[2] - b[2]);
}

fn findOffsets(allocator: std.mem.Allocator, scan_reports: []ScannerReport) !void {
    scan_reports[0].orientation = 0;
    scan_reports[0].offset = .{ 0, 0, 0 };

    while (!isFinished(scan_reports)) {
        for (scan_reports) |*base| {
            if (base.orientation == null)
                continue;

            for (scan_reports) |*piece| {
                if (piece.orientation != null or base == piece)
                    continue;

                const success = try ScannerReport.tryFit(allocator, base, piece);
                _ = success;
                // if (success) {
                //     std.debug.print("fit {d} with {d}\n", .{ i, j });
                //     std.debug.print("scanner center {d}: {any}\n", .{ j, piece.offset.? });
                // }
            }
        }
    }
}

fn isFinished(scan_reports: []const ScannerReport) bool {
    for (scan_reports) |report| {
        if (report.orientation == null)
            return false;
    }
    return true;
}

fn add(a: [3]i32, b: [3]i32) [3]i32 {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}

fn sub(a: [3]i32, b: [3]i32) [3]i32 {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
}

fn getOrientations(pos: [3]i32) [24][3]i32 {
    const x, const y, const z = pos;
    // screw it
    return .{
        .{ x, y, z },
        .{ x, -y, -z },
        .{ -x, y, -z },
        .{ -x, -y, z },
        .{ x, z, -y },
        .{ x, -z, y },
        .{ -x, z, y },
        .{ -x, -z, -y },
        .{ y, z, x },
        .{ y, -z, -x },
        .{ -y, z, -x },
        .{ -y, -z, x },
        .{ y, x, -z },
        .{ y, -x, z },
        .{ -y, x, z },
        .{ -y, -x, -z },
        .{ z, x, y },
        .{ z, -x, -y },
        .{ -z, x, -y },
        .{ -z, -x, y },
        .{ z, y, -x },
        .{ z, -y, x },
        .{ -z, y, x },
        .{ -z, -y, -x },
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]ScannerReport {
    const size = std.mem.count(u8, input, "\n\n") + 1;
    const scan_reports = try allocator.alloc(ScannerReport, size);
    errdefer {
        for (scan_reports) |*report| {
            report.deinit();
        }
        allocator.free(scan_reports);
    }

    var section_it = std.mem.splitSequence(u8, input, "\n\n");
    var i: usize = 0;
    while (section_it.next()) |section_str| : (i += 1) {
        scan_reports[i] = try ScannerReport.fromInput(allocator, section_str);
    }
    return scan_reports;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(79, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(3621, ans);
}
