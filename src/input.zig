//! This module provides functions for controlling input on macOS.
//! It uses the CoreGraphics framework for these operations.

const std = @import("std");

const C = @cImport({
    @cInclude("CoreGraphics/CoreGraphics.h");
});

/// Represents errors that can occur during input operations.
pub const InputError = error{
    FailedToGetMousePosition,
    FailedToSetMousePosition,
    FailedToClickMouse,
    FailedToUseKeyboard,
};

/// Represents keyboard event types.
pub const KeyboardEvent = enum(u16) {
    KeyboardDown = 0,
    KeyboardUp = 1,

    /// Converts a ID to a `KeyboardEvent` enum variant.
    /// Returns `null` if the ID is invalid.
    pub fn fromId(id: u16) ?KeyboardEvent {
        return std.enums.fromInt(KeyboardEvent, id);
    }
};

/// Represents mouse button click types.
pub const MouseEvent = enum(u16) {
    LeftDown = 0,
    LeftUp = 1,
    RightDown = 2,
    RightUp = 3,

    /// Converts a ID to a `MouseEvent` enum variant.
    /// Returns `null` if the ID is invalid.
    pub fn fromId(id: u16) ?MouseEvent {
        return std.enums.fromInt(MouseEvent, id);
    }

    /// Converts the `MouseEvent` variant to the corresponding `CGEventType`.
    /// Used for creating mouse events in CoreGraphics.
    pub fn toCGEventType(self: MouseEvent) C.CGEventType {
        return switch (self) {
            .LeftDown => C.kCGEventLeftMouseDown,
            .LeftUp => C.kCGEventLeftMouseUp,
            .RightDown => C.kCGEventRightMouseDown,
            .RightUp => C.kCGEventRightMouseUp,
        };
    }
};

/// Provides functions for input operations.
pub const Input = struct {
    /// Gets the current mouse position.
    /// Returns an array with x and y coordinates, or `null` on failure.
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

    /// Sets the mouse position to the specified x and y coordinates.
    pub fn setMousePosition(x: u16, y: u16) InputError!void {
        const point = C.CGPointMake(@floatFromInt(x), @floatFromInt(y));
        if (C.CGWarpMouseCursorPosition(point) != C.kCGErrorSuccess) {
            return InputError.FailedToSetMousePosition;
        }

        if (C.CGAssociateMouseAndMouseCursorPosition(C.TRUE) != C.kCGErrorSuccess) {
            return InputError.FailedToSetMousePosition;
        }
    }

    /// Simulates a mouse click of the specified button type.
    pub fn clickMouse(button: MouseEvent) InputError!void {
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

    /// Simulates a keyboard event of the specified type and key code.
    /// See https://gist.github.com/eegrok/949034 for key code reference.
    pub fn useKeyboardEvent(event: KeyboardEvent, keyCode: u16) InputError!void {
        const cg_event = C.CGEventCreateKeyboardEvent(
            null,
            @as(C.CGKeyCode, keyCode),
            event == .KeyboardDown,
        );

        if (cg_event) |keyboard_event| {
            C.CGEventPost(C.kCGHIDEventTap, keyboard_event);
            C.CFRelease(keyboard_event);
        } else {
            return InputError.FailedToUseKeyboard;
        }
    }
};
