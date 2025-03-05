const std = @import("std");

const data = @embedFile("data/day16.txt");
const data_test_p1 = @embedFile("data/day16.test.p1.txt");
const data_test_p2 = @embedFile("data/day16.test.p2.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(allocator, data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const bits = try parseInput(allocator, input);
    defer allocator.free(bits);

    var i: usize = 0;
    const version_sum, _ = try parsePacket(bits, &i, 4);
    return version_sum;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const bits = try parseInput(allocator, input);
    defer allocator.free(bits);

    var i: usize = 0;
    _, const decoded = try parsePacket(bits, &i, 4);
    return decoded.?;
}

fn parsePacket(bits: []const bool, i: *usize, parent_type_id: u64) !struct { u64, ?u64 } {
    var version_sum: u64 = 0;
    var decoded: ?u64 = null;

    if (i.* + 6 > bits.len)
        return .{ version_sum, decoded };

    const version = binToDec(bits[i.* .. i.* + 3]);
    i.* += 3;
    version_sum += version;

    const type_id = binToDec(bits[i.* .. i.* + 3]);
    i.* += 3;

    switch (type_id) {
        4 => {
            var literal: u64 = 0;
            while (bits[i.*]) {
                i.* += 1;
                literal = (literal << 4) | binToDec(bits[i.* .. i.* + 4]);
                i.* += 4;
            }
            i.* += 1;
            literal = (literal << 4) | binToDec(bits[i.* .. i.* + 4]);
            i.* += 4;

            try decode(parent_type_id, &decoded, literal);
        },
        else => {
            const length_type_id = bits[i.*];
            i.* += 1;

            if (length_type_id and i.* + 11 <= bits.len) {
                const num_subpackets = binToDec(bits[i.* .. i.* + 11]);
                i.* += 11;

                for (0..num_subpackets) |_| {
                    const ret_vsum, const ret_decoded = try parsePacket(bits, i, type_id);
                    version_sum += ret_vsum;
                    try decode(type_id, &decoded, ret_decoded);
                }
            } else if (!length_type_id and i.* + 15 <= bits.len) {
                const total_length = binToDec(bits[i.* .. i.* + 15]) + i.* + 15;
                i.* += 15;

                while (i.* < total_length) {
                    const ret_vsum, const ret_decoded = try parsePacket(bits, i, type_id);
                    version_sum += ret_vsum;
                    try decode(type_id, &decoded, ret_decoded);
                }
            }
        },
    }

    return .{ version_sum, decoded };
}

fn decode(parent_type_id: u64, decoded: *?u64, ret_decode_opt: ?u64) !void {
    if (ret_decode_opt == null)
        return;

    const ret_decode = ret_decode_opt.?;
    if (decoded.*) |decoded_val| {
        decoded.*.? = switch (parent_type_id) {
            0 => decoded_val + ret_decode,
            1 => decoded_val * ret_decode,
            2 => @min(decoded_val, ret_decode),
            3 => @max(decoded_val, ret_decode),
            4 => ret_decode,
            5...8 => @intFromBool(switch (parent_type_id) {
                5 => decoded_val > ret_decode,
                6 => decoded_val < ret_decode,
                7 => decoded_val == ret_decode,
                else => unreachable,
            }),
            else => return error.InvalidTypeId,
        };
    } else {
        decoded.* = ret_decode;
    }
}

fn binToDec(binary: []const bool) u64 {
    var decimal: u64 = 0;
    for (binary) |b| {
        decimal = (decimal << 1) | @intFromBool(b);
    }
    return decimal;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]const bool {
    const size = (input.len - 1) * 4;
    const bits = try allocator.alloc(bool, size);
    errdefer allocator.free(bits);

    for (input[0 .. input.len - 1], 0..) |hex, i| {
        var offset = i * 4;
        for (try hexToBin(hex)) |dec| {
            bits[offset] = dec;
            offset += 1;
        }
    }
    return bits;
}

fn hexToBin(hex: u8) ![4]bool {
    const dec: u8 = switch (hex) {
        '0'...'9' + 1 => hex - '0',
        'A'...'F' + 1 => 0b1010 + hex - 'A',
        else => return error.InvalidHex,
    };

    var binary: [4]bool = undefined;
    for (0..4) |i| {
        binary[i] = (dec >> @intCast(3 - i)) & 1 == 1;
    }
    return binary;
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test_p1);
    try std.testing.expectEqual(31, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test_p2);
    try std.testing.expectEqual(1, ans);
}
