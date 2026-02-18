const std = @import("std");
const posix = std.posix;

/// Control Sequence Introducer: ESC key, followed by '[' character
pub const CSI = "\x1b[";

/// The ESC character
pub const ESC = '\x1b';

// Sets the number of column and rows to very high numbers, trying to maximize
// the window.
pub const WinMaximize = CSI ++ "999C" ++ CSI ++ "999B";

// Reports the cursor position (CPR) by transmitting ESC[n;mR, where n is the
// row and m is the column
pub const ReadCursorPos = CSI ++ "6n";

// CSI sequence to clear the screen.
pub const ClearScreen = CSI ++ "2J" ++ CSI ++ "H";

pub const InvertColors = CSI ++ "7m";
pub const ResetAll = CSI ++ "0m";
pub const HideCursor = "\x1b[?25l";
pub const ShowCursor = "\x1b[?25h";

pub const Box = struct {
    tl: []const u8 = "╭",
    tr: []const u8 = "╮",
    bl: []const u8 = "╰",
    br: []const u8 = "╯",
    h:  []const u8 = "─", 
    v:  []const u8 = "│", 
};

pub const Screen = struct {
    rows: usize = 0,
    cols: usize = 0,
};

pub fn winsize(wsz: *posix.winsize) c_int {
    return std.posix.system.ioctl(posix.STDOUT_FILENO, std.posix.system.T.IOCGWINSZ, @intFromPtr(wsz));
}

pub fn getWindowSize() !Screen {
    var screen: Screen = undefined;
    var ws: posix.winsize = undefined;

    if (winsize(&ws) == -1 or winsize.col == 0) {
    } else {
        std.debug.print("here: {}\r\n", .{ ws.row });
        screen = Screen{
            .rows = ws.row,
            .cols = ws.col,
        };
    }
    return screen;
}
