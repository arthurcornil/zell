const std = @import("std");
const Pane = @import("pane.zig").Pane;
const Rect = @import("primitive.zig").Rect;
const Ansi = @import("ansi.zig");

const LayoutError = error{
    PanePositionNotDefined,
    UnableToGetTermSize
};

pub const Col = struct {
    panes: []Pane,
    width: u8
};

const IoctlReturn = union(enum) {
    unsigned: usize,
    signed: isize,
};

pub const LayoutOptions = struct{
    paddingHorizontal: u8 = 0,
    paddingVertical: u8 = 0,
};

pub const Layout = struct {
    cols: []Col,
    options: LayoutOptions = .{},

    pub fn positionPanes(self: *Layout) !void {
        const screen = try getScreenRect(self);
        var currentX: usize = screen.x;
        for (self.cols) |col| {
            const colWidth = (screen.width * col.width) / 100;
            var currentY: usize = screen.y;
            for (col.panes) |*pane| {
                const paneHeight = (screen.height * pane.height) / 100;
                pane.rect = Rect{
                    .x = currentX,
                    .y = currentY,
                    .width = colWidth,
                    .height = paneHeight
                };
                currentY += paneHeight;
            }
            currentX += colWidth;
        }
    }
    pub fn deinit(self: Layout) void {
        self.rects.deinit();
    }

    pub fn render(self: *Layout, io: std.Io) !void {
        var buffer: [4096]u8 = undefined;
        var writer = std.Io.File.stdout().writer(io, &buffer);
        const stdout = &writer.interface;

        try stdout.print("{s}{s}", .{ Ansi.ClearScreen, Ansi.HideCursor });
        try stdout.print("\x1b[H", .{});

        var rectId: usize = 0;
        for (self.cols) |col| {
            for (col.panes) |pane| {
                if (pane.rect == null)
                    return LayoutError.PanePositionNotDefined;
                try pane.render(stdout);
                rectId += 1;
            }
        }
        try stdout.flush();
    }
};

pub fn winsize(wsz: *std.posix.winsize) IoctlReturn {
    const returnIoctl = std.posix.system.ioctl(std.posix.STDOUT_FILENO, std.posix.system.T.IOCGWINSZ, @intFromPtr(wsz));
    const ioctlReturn = if (@TypeOf(returnIoctl) == usize) IoctlReturn{ .unsigned = returnIoctl } else IoctlReturn{ .signed = returnIoctl };
    return ioctlReturn;
}

pub fn getScreenRect(layout: *const Layout) !Rect {
    var screen: Rect = undefined;
    var ws: std.posix.winsize = undefined;
    const winsizeReturn = winsize(&ws);

    switch(winsizeReturn) {
        .signed => if (winsizeReturn.signed == -1) return LayoutError.UnableToGetTermSize,
        else => {}
    }
    if (ws.col == 0)
        return LayoutError.UnableToGetTermSize;
    screen = Rect{
        .x = layout.options.paddingHorizontal,
        .y = layout.options.paddingVertical,
        .height = ws.row - (layout.options.paddingVertical * 2),
        .width = ws.col - (layout.options.paddingHorizontal * 2),
    };
    return screen;
}
