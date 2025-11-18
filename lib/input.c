#include "input.h"

uint8_t llic_input_get_mouse_position(uint16_t *x, uint16_t *y) {
  const CGEventRef event = CGEventCreate(NULL);
  if (!event)
    return 0;

  const CGPoint cursor = CGEventGetLocation(event);
  CFRelease(event);

  *x = (uint16_t)cursor.x;
  *y = (uint16_t)cursor.y;

  return 1;
}

uint8_t llic_input_set_mouse_position(const uint16_t x, const uint16_t y) {
  const CGPoint point = CGPointMake(x, y);
  CGWarpMouseCursorPosition(point);
  CGAssociateMouseAndMouseCursorPosition(true);

  return 1;
}

uint8_t llic_input_apply_mouse_event(const llic_input_mouse_event_t type) {
  CGEventType event_type;

  switch (type) {
  case MOUSE_LEFT_CLICK_DOWN:
    event_type = kCGEventLeftMouseDown;
    break;
  case MOUSE_LEFT_CLICK_UP:
    event_type = kCGEventLeftMouseUp;
    break;
  case MOUSE_RIGHT_CLICK_DOWN:
    event_type = kCGEventRightMouseDown;
    break;
  case MOUSE_RIGHT_CLICK_UP:
    event_type = kCGEventRightMouseUp;
    break;
  default:
    return 0;
  }

  uint16_t x, y;
  if (!llic_input_get_mouse_position(&x, &y))
    return 0;

  const CGPoint point = CGPointMake(x, y);
  const CGEventRef event = CGEventCreateMouseEvent(NULL, event_type, point, 0);

  CGEventPost(kCGHIDEventTap, event);
  CFRelease(event);

  return 1;
}

uint8_t llic_input_scroll_mouse(const uint16_t power,
                                const llic_input_scroll_event_t type) {

  int32_t delta_v = 0;
  int32_t delta_h = 0;

  switch (type) {
  case MOUSE_SCROLL_DOWN: {
    delta_v = -power;
    delta_h = 0;
    break;
  }
  case MOUSE_SCROLL_UP: {
    delta_v = power;
    delta_h = 0;
    break;
  }
  case MOUSE_SCROLL_LEFT: {
    delta_v = 0;
    delta_h = power;
    break;
  }
  case MOUSE_SCROLL_RIGHT: {
    delta_v = 0;
    delta_h = -power;
    break;
  }
  default:
    return 0;
  }

  const CGEventRef event = CGEventCreateScrollWheelEvent(
      NULL, kCGScrollEventUnitPixel, 2, delta_v, delta_h);

  if (!event)
    return 0;

  CGEventPost(kCGHIDEventTap, event);
  CFRelease(event);

  return 1;
}