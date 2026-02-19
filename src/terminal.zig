const std = @import("std");
const posix = std.posix;

pub const Terminal = struct {
    origTermios: posix.termios,

    pub fn init(io: std.Io) !Terminal {
        const tty = std.Io.File.stdin().handle;
        const origTermios = try posix.tcgetattr(tty);
        var termios = origTermios;

        termios.lflag.ECHO = false;
        termios.lflag.ICANON = false;
        termios.lflag.ISIG = false;
        termios.iflag.IXON = false;
        termios.lflag.IEXTEN = false;
        termios.iflag.ICRNL = false;
        termios.oflag.OPOST = false;
        termios.iflag.BRKINT = false;
        termios.iflag.INPCK = false;
        termios.iflag.ISTRIP = false;
        termios.cflag.CSIZE = .CS8;
        termios.cc[@intFromEnum(posix.V.MIN)] = 1;
        termios.cc[@intFromEnum(posix.V.TIME)] = 0;
        try posix.tcsetattr(tty, .FLUSH, termios);

        const stdout = std.Io.File.stdout();
        //hide cursor
        try stdout.writeStreamingAll(io, "\x1b[?25l");
        //move to alternative buffer
        try stdout.writeStreamingAll(io, "\x1b[?1049h");

        return .{ .origTermios =  origTermios };
    }

    pub fn deinit(self: Terminal, io: std.Io) void {
        const tty = std.Io.File.stdin().handle;
        std.posix.tcsetattr(tty, .FLUSH, self.original_termios) catch {};

        const stdout = std.Io.File.stdout();
        stdout.writeStreamingAll(io, "\x1b[?25h") catch {};
        stdout.writeStreamingAll(io, "\x1b[?1049l") catch {};
    }
};
