const C = @cImport({
    @cInclude("CoreGraphics/CoreGraphics.h");
});

pub const MouseClick = enum {
    LeftDown,
    LeftUp,
    RightDown,
    RightUp,

    pub fn fromId(self: u8) ?MouseClick {
        return switch (self) {
            0 => .LeftDown,
            1 => .LeftUp,
            2 => .RightDown,
            3 => .RightUp,
            else => null,
        };
    }

    pub fn toCGEventType(self: MouseClick) C.CGEventType {
        return switch (self) {
            .LeftDown => C.kCGEventLeftMouseDown,
            .LeftUp => C.kCGEventLeftMouseUp,
            .RightDown => C.kCGEventRightMouseDown,
            .RightUp => C.kCGEventRightMouseUp,
        };
    }
};

pub const InputError = error{
    FailedToGetMousePosition,
    FailedToSetMousePosition,
    FailedToClickMouse,
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

    pub fn clickMouse(button: MouseClick) InputError!void {
        const positions = getMousePosition() orelse {
            return InputError.FailedToGetMousePosition;
        };

        const point = C.CGPointMake(@floatFromInt(positions[0]), @floatFromInt(positions[1]));
        const event = C.CGEventCreateMouseEvent(
            null,
            button.toCGEventType(),
            point,
            0,
        );

        if (event) |mouse_event| {
            C.CGEventPost(C.kCGHIDEventTap, mouse_event);
            C.CFRelease(mouse_event);
        } else {
            return InputError.FailedToClickMouse;
        }
    }
};
