const std = @import("std");

const data = @embedFile("data/day04.txt");
const data_test = @embedFile("data/day04.test.txt");

const BingoBoard = struct {
    board: [5][5]u8,
    marked: [5][5]bool,
    unmarked_sum: u32,
    won: bool,

    fn new(input: []const u8) !BingoBoard {
        var board_sum: u32 = 0;
        var board: [5][5]u8 = undefined;

        var row_it = std.mem.splitScalar(u8, input, '\n');
        var i: u8 = 0;
        while (row_it.next()) |row_str| : (i += 1) {
            var num_it = std.mem.tokenizeScalar(u8, row_str, ' ');
            var j: u8 = 0;
            while (num_it.next()) |num_str| : (j += 1) {
                const num = try std.fmt.parseInt(u8, num_str, 10);
                board[i][j] = num;
                board_sum += num;
            }
        }

        var marked: [5][5]bool = undefined;
        for (&marked) |*row| {
            for (row) |*m| {
                m.* = false;
            }
        }

        return BingoBoard{
            .board = board,
            .marked = marked,
            .unmarked_sum = board_sum,
            .won = false,
        };
    }

    fn mark(self: *BingoBoard, draw: u8) void {
        for (self.board, 0..) |row, i| {
            for (row, 0..) |num, j| {
                if (!self.marked[i][j] and num == draw) {
                    self.marked[i][j] = true;
                    self.unmarked_sum -= num;
                }
            }
        }
    }

    fn isComplete(self: BingoBoard) bool {
        for (0..5) |i| {
            var row_marked: u8 = 0;
            var col_marked: u8 = 0;
            for (0..5) |j| {
                if (self.marked[i][j]) {
                    row_marked += 1;
                }
                if (self.marked[j][i])
                    col_marked += 1;
            }

            if (row_marked == 5 or col_marked == 5)
                return true;
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

fn partOne(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const draws, const boards = try parseInput(allocator, input);
    defer {
        allocator.free(draws);
        allocator.free(boards);
    }

    for (draws) |draw| {
        for (boards) |*board| {
            board.mark(draw);
            if (board.isComplete())
                return board.unmarked_sum * draw;
        }
    }
    return error.NoSolution;
}

fn partTwo(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const draws, const boards = try parseInput(allocator, input);
    defer {
        allocator.free(draws);
        allocator.free(boards);
    }

    var last_win_sum: u32 = 0;
    for (draws) |draw| {
        for (boards) |*board| {
            if (board.won)
                continue;

            board.mark(draw);
            if (board.isComplete()) {
                board.won = true;
                last_win_sum = board.unmarked_sum * draw;
            }
        }
    }
    return last_win_sum;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct { []const u8, []BingoBoard } {
    var split_it = std.mem.tokenizeSequence(u8, input, "\n\n");

    const draws_str = split_it.next().?;
    const size_draws = std.mem.count(u8, draws_str, ",") + 1;
    const draws = try allocator.alloc(u8, size_draws);
    errdefer allocator.free(draws);

    var draws_it = std.mem.splitScalar(u8, draws_str, ',');
    var i: usize = 0;
    while (draws_it.next()) |draw_str| : (i += 1) {
        const draw = try std.fmt.parseInt(u8, draw_str, 10);
        draws[i] = draw;
    }

    const size_boards = std.mem.count(u8, input, "\n\n");
    const boards = try allocator.alloc(BingoBoard, size_boards);
    errdefer allocator.free(boards);

    i = 0;
    while (split_it.next()) |board_str| : (i += 1) {
        const board = try BingoBoard.new(board_str);
        boards[i] = board;
    }

    return .{ draws, boards };
}

test "p1" {
    const allocator = std.testing.allocator;
    const ans = try partOne(allocator, data_test);
    try std.testing.expectEqual(4512, ans);
}

test "p2" {
    const allocator = std.testing.allocator;
    const ans = try partTwo(allocator, data_test);
    try std.testing.expectEqual(1924, ans);
}
