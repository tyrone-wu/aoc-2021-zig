const std = @import("std");

const data = @embedFile("data/day21.txt");
const data_test = @embedFile("data/day21.test.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p1 = try partOne(data);
    const p2 = try partTwo(allocator, data);
    std.debug.print("part 1: {d}\npart 2: {d}\n", .{ p1, p2 });
}

fn partOne(input: []const u8) !u32 {
    const board_size: u8 = 10;
    const score_threshold: u32 = 1000;
    var p1_pos, var p2_pos = try parseInput(input);
    var p1_score: u32 = 0;
    var p2_score: u32 = 0;
    var p1_turn = true;

    const dice_size: u8 = 100;
    var dice: u8 = 0;
    var total_rolls: u32 = 0;

    while (p1_score < score_threshold and p2_score < score_threshold) {
        var roll: u16 = 0;
        for (0..3) |_| {
            roll += dice + 1;
            dice = @rem(dice + 1, dice_size);
        }
        total_rolls += 3;

        if (p1_turn) {
            p1_pos = @rem(roll + p1_pos, board_size);
            p1_score += p1_pos + 1;
        } else {
            p2_pos = @rem(p2_pos + roll, board_size);
            p2_score += p2_pos + 1;
        }
        p1_turn = !p1_turn;
    }
    return (if (p1_score >= score_threshold) p2_score else p1_score) * total_rolls;
}

const GameState = struct {
    p1_pos: u8,
    p2_pos: u8,
    p1_score: u8,
    p2_score: u8,
    p1_turn: bool,
    dice: u8,

    fn new(p1_pos: u8, p2_pos: u8, p1_score: u8, p2_score: u8, p1_turn: bool, dice: u8) GameState {
        return GameState{
            .p1_pos = p1_pos,
            .p2_pos = p2_pos,
            .p1_score = p1_score,
            .p2_score = p2_score,
            .p1_turn = p1_turn,
            .dice = dice,
        };
    }

    fn nextState(self: GameState, roll: u8) GameState {
        var next = self;
        if (next.p1_turn) {
            next.p1_pos = @rem(roll + next.p1_pos, 10);
            next.p1_score += next.p1_pos + 1;
        } else {
            next.p2_pos = @rem(roll + next.p2_pos, 10);
            next.p2_score += next.p2_pos + 1;
        }
        next.p1_turn = !next.p1_turn;
        return next;
    }
};

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const p1_pos, const p2_pos = try parseInput(input);
    const start = GameState.new(@intCast(p1_pos), @intCast(p2_pos), 0, 0, true, 0);

    var cache = std.AutoHashMap(GameState, [2]u64).init(allocator);
    defer cache.deinit();

    const p1_wins, const p2_wins = try turn(&cache, start);
    return @max(p1_wins, p2_wins);
}

const p2_dice = [_]u8{ 1, 2, 3 };

fn turn(cache: *std.AutoHashMap(GameState, [2]u64), game: GameState) ![2]u64 {
    if (game.p1_score >= 21) {
        return .{ 1, 0 };
    } else if (game.p2_score >= 21) {
        return .{ 0, 1 };
    }

    if (cache.get(game)) |wins|
        return wins;

    var wins = [_]u64{ 0, 0 };
    for (p2_dice) |r1| {
        for (p2_dice) |r2| {
            for (p2_dice) |r3| {
                const roll = r1 + r2 + r3;
                const next = game.nextState(roll);
                const next_wins = try turn(cache, next);
                wins[0] += next_wins[0];
                wins[1] += next_wins[1];
            }
        }
    }

    try cache.put(game, wins);
    return wins;
}

fn parseInput(input: []const u8) ![2]u16 {
    const nl = std.mem.indexOfScalar(u8, input, '\n').?;
    const p1_start = try std.fmt.parseInt(u16, input[28..nl], 10);
    const p2_start = try std.fmt.parseInt(u16, input[nl + 29 .. input.len - 1], 10);
    return .{ p1_start - 1, p2_start - 1 };
}

test "p1" {
    const ans = try partOne(data_test);
    try std.testing.expectEqual(739785, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(444356092776315, ans);
}
