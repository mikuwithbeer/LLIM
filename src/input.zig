const C = @cImport({
    @cInclude("CoreGraphics/CoreGraphics.h");
});

pub const InputError = error{
    FailedToSetMousePosition,
};

pub const Input = struct {
    pub fn getMousePosition() ?[2]u16 {
        const event = C.CGEventCreate(null);
        if (event != null) {
            defer C.CFRelease(event);

            const cursor = C.CGEventGetLocation(event.?);
            return [_]u16{
                @as(u16, @intFromFloat(cursor.x)),
                @as(u16, @intFromFloat(cursor.y)),
            };
        }

        return null;
    }

    pub fn setMousePosition(x: u16, y: u16) InputError!void {
        const point = C.CGPointMake(@floatFromInt(x), @floatFromInt(y));
        if (C.CGWarpMouseCursorPosition(point) != C.kCGErrorSuccess) {
            return InputError.FailedToSetMousePosition;
        }

        if (C.CGAssociateMouseAndMouseCursorPosition(C.TRUE) != C.kCGErrorSuccess) {
            return InputError.FailedToSetMousePosition;
        }
    }
};
