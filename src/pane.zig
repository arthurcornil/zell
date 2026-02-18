const std = @import("std");
const ArrayList = std.ArrayList;
const Io = std.Io;
const Rect = @import("primitive.zig").Rect;
const Ansi = @import("ansi.zig");

const SelectionError = error{
    indexTooLow,
    indexTooHigh
};

pub const Content = union(enum){
    list: ArrayList([]const u8),
    raw: []const u8
};

pub const PaneList = struct {
    index: u8 = 0,

    pub fn down(self: *PaneList) SelectionError!void {
        const pane: *Pane = @alignCast(@fieldParentPtr("select", self));
        if (self.index >= pane.content.?.list.items.len - 1)
            return SelectionError.indexTooHigh;
        self.index += 1;
    }

    pub fn up(self: *PaneList) SelectionError!void {
        if (self.index <= 0)
            return SelectionError.indexTooLow;
        self.index -= 1;
    }
};

pub const PaneOptions = struct {
    boxed: bool = true,
    rounded: bool = true,
    selectable: bool = false,
    paddingVertical: u8 = 0,
    paddingHorizontal: u8 = 0,
    selectableLine: bool = false,
    centerContent: bool = false
};

pub const Pane = struct {
    height: u8 = 100,
    title: []const u8 = "",
    options: PaneOptions = .{},
    rect: ?Rect = null,
    content: ?Content = null,
    select: PaneList = .{},

    pub fn render(pane: Pane, stdout: anytype) !void {
        const rect = pane.rect.?;
        if (pane.options.boxed) try drawBox(rect, stdout);
        
        if (pane.title.len > 0) {
            const safeTitleLen = @min(pane.title.len, rect.width - 2);
            try moveCursor(rect.y, rect.x + 1, stdout);
            try stdout.print("{s}", .{ pane.title[0..safeTitleLen] });
        }
        if (pane.content == null) return;

        const content = pane.content.?;
        const paddingH = pane.options.paddingHorizontal;
        const paddingV = pane.options.paddingVertical;
        if (rect.width <= 2 + (paddingH * 2) or rect.height <= 2 + (paddingV * 2)) return;
        const availableWidth = rect.width - 2 - (paddingH * 2);
        const availableHeight = rect.height - 2 - (paddingV * 2);

        switch(content) {
            .raw => |text| {
                var currRow: usize = 0;
                var lines = std.mem.splitScalar(u8, text, '\n');
                while (lines.next()) |line| {
                    if (currRow >= availableHeight)
                        break ;
                    if (line.len == 0) {
                        currRow += 1;
                        continue ;
                    }

                    var i: usize = 0;
                    while (i < line.len) : (currRow += 1) {
                        if (currRow >= availableHeight)
                            break ;

                        const startY: usize = rect.y + 1 + paddingV + currRow;
                        var startX: usize = rect.x + 1 + paddingH;

                        const remaining = line.len - i;
                        const chunkLen = @min(remaining, availableWidth);
                        const chunk = line[i..i + chunkLen];

                        if (pane.options.centerContent and chunkLen < availableWidth)
                            startX += (availableWidth - chunkLen) / 2;

                        try moveCursor(startY, startX, stdout);
                        try stdout.print("{s}", .{ chunk });
                        i += chunkLen;
                    }
                }
            },
            .list => |list| {
                var currRow: usize = 0;
                for (list.items, 0..) |str, i| {
                    if (currRow >= availableHeight) break;

                    try moveCursor(
                        rect.y + 1 + paddingV + currRow,
                        rect.x + 1 + paddingH,
                        stdout
                    );
                    const printLen = @min(str.len, availableWidth);
                    const displayStr = str[0..printLen];
                    if (i == pane.select.index and pane.options.selectableLine) 
                        try stdout.print("{s}", .{ Ansi.InvertColors });
                    try stdout.print("{s}{s}", .{ displayStr, Ansi.ResetAll });
                    currRow += 1;
                }
            }
        }
    }
};

fn moveCursor(row: usize, col: usize, stdout: *Io.Writer) !void {
    try stdout.print("\x1b[{d};{d}H", .{row + 1, col + 1});
}

fn drawBox(rect: Rect, stdout: *Io.Writer) !void {
    const box: Ansi.Box = .{};

    try moveCursor(rect.y, rect.x, stdout);
    try stdout.print("{s}", .{ box.tl });
    for (0..rect.width - 2) |_| try stdout.print("{s}", .{ box.h });
    try stdout.print("{s}", .{ box.tr });
    for (1..rect.height - 1) |i| {
        try moveCursor(rect.y + i, rect.x, stdout);
        try stdout.print("{s}", .{ box.v });
        try moveCursor(rect.y + i, rect.x + rect.width - 1, stdout);
        try stdout.print("{s}", .{ box.v });
    }
    try moveCursor(rect.y + rect.height - 1, rect.x, stdout);
    try stdout.print("{s}", .{ box.bl });
    for (0..rect.width - 2) |_| try stdout.print("{s}", .{ box.h });
    try stdout.print("{s}", .{ box.br });
}
