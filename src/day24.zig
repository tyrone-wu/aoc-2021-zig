const std = @import("std");

const data = @embedFile("data/day24.txt");

const TypeFormat = enum { reg, int };

const Instruction = struct {
    const Opcode = enum { inp, add, mul, div, mod, eql };

    opcode: Opcode,
    a: u8,
    b: ?union(TypeFormat) {
        reg: u8,
        int: i64,
    },

    fn fromInput(input: []const u8) !Instruction {
        var insn = Instruction{ .opcode = undefined, .a = undefined, .b = null };
        var split_it = std.mem.splitScalar(u8, input, ' ');

        insn.opcode = switch (split_it.next().?[1]) {
            'n' => .inp,
            'd' => .add,
            'u' => .mul,
            'i' => .div,
            'o' => .mod,
            'q' => .eql,
            else => return error.InvalidInsn,
        };

        const a_str = split_it.next().?;
        insn.a = a_str[0] - 'w';

        if (split_it.next()) |b_str| {
            insn.b = switch (b_str[0]) {
                'w'...'z' + 1 => .{ .reg = b_str[0] - 'w' },
                else => .{ .int = try std.fmt.parseInt(i64, b_str, 10) },
            };
        }

        return insn;
    }
};

const Monad = struct {
    allocator: std.mem.Allocator,
    insns: []Instruction,
    sections: [14]usize,

    fn fromInput(allocator: std.mem.Allocator, input: []const u8) !Monad {
        const size = std.mem.count(u8, input, "\n");
        var monad = Monad{
            .allocator = allocator,
            .insns = try allocator.alloc(Instruction, size),
            .sections = undefined,
        };
        errdefer allocator.free(monad.insns);

        var line_it = std.mem.splitScalar(u8, input[0 .. input.len - 1], '\n');
        var i_insn: usize = 0;
        var i_sec: usize = 0;
        while (line_it.next()) |line| : (i_insn += 1) {
            monad.insns[i_insn] = try Instruction.fromInput(line);
            if (monad.insns[i_insn].opcode == .inp) {
                monad.sections[i_sec] = i_insn;
                i_sec += 1;
            }
        }
        return monad;
    }

    fn deinit(self: *Monad) void {
        self.allocator.free(self.insns);
    }
};

const Alu = struct {
    vars: [4]i64,

    fn new() Alu {
        return Alu{ .vars = [_]i64{ 0, 0, 0, 0 } };
    }

    fn runSection(self: *Alu, insns_section: []const Instruction, digit: i64) !void {
        for (insns_section) |insn| {
            const i = insn.a;
            const a = self.vars[i];
            const b: ?i64 = if (insn.b) |b| switch (b) {
                .reg => |idx| self.vars[idx],
                .int => |int| int,
            } else null;

            switch (insn.opcode) {
                .inp => self.vars[i] = digit,
                .add => self.vars[i] = a + b.?,
                .mul => self.vars[i] = a * b.?,
                .div => {
                    if (b.? == 0)
                        return error.DivideByZero;

                    self.vars[i] = @divTrunc(a, b.?);
                },
                .mod => {
                    if (a < 0 or b.? <= 0)
                        return error.ModNegativeOrZero;

                    self.vars[i] = @rem(a, b.?);
                },
                .eql => self.vars[i] = @intFromBool(a == b.?),
            }
        }
    }

    fn getZ(self: Alu) i64 {
        return self.vars[3];
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

fn partOne(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var monad = try Monad.fromInput(allocator, input);
    defer monad.deinit();

    // var alu = Alu.new();
    // var model_number: i64 = 99999999999999;
    // while (!try alu.runMonad(monad, model_number)) : (model_number -= 1) {
    //     alu.reset();
    //     if (@rem(model_number, 1000000) == 0)
    //         std.debug.print("{d}\n", .{model_number});
    // }
    return (try dfs(Alu.new(), monad, 0, &[_]i64{ 9, 8, 7, 6, 5, 4, 3, 2, 1 }, 14)).?;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var monad = try Monad.fromInput(allocator, input);
    defer monad.deinit();

    return (try dfs(Alu.new(), monad, 0, &[_]i64{ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, 14)).?;
}

fn dfs(alu: Alu, monad: Monad, i_section: u8, digits: []const i64, depth: i64) !?i64 {
    if (depth == 0)
        return 0;

    const start = monad.sections[i_section];
    const end = if (i_section < 13) monad.sections[i_section + 1] else monad.insns.len;
    const prev_z = alu.getZ();

    for (digits) |digit| {
        var alu_clone = alu;
        try alu_clone.runSection(monad.insns[start..end], digit);
        const z = alu_clone.getZ();
        if ((prev_z < z and prev_z * 20 <= z) or (prev_z > z and @divTrunc(prev_z, 20) >= z)) {
            if (try dfs(alu_clone, monad, i_section + 1, digits, depth - 1)) |number| {
                return digit * std.math.pow(i64, 10, depth - 1) + number;
            }
        }
    }
    return null;
}
