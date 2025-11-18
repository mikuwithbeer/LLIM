#ifndef LLIC_INPUT_H
#define LLIC_INPUT_H

#include <ApplicationServices/ApplicationServices.h>

/// Represents all possible mouse events (excluding movement).
typedef enum {
  MOUSE_LEFT_CLICK_DOWN,
  MOUSE_LEFT_CLICK_UP,
  MOUSE_RIGHT_CLICK_DOWN,
  MOUSE_RIGHT_CLICK_UP,
  MOUSE_MIDDLE_CLICK_DOWN,
  MOUSE_MIDDLE_CLICK_UP
} llic_input_mouse_event_t;

typedef enum {
  MOUSE_SCROLL_DOWN,
  MOUSE_SCROLL_UP,
  MOUSE_SCROLL_LEFT,
  MOUSE_SCROLL_RIGHT
} llic_input_scroll_event_t;

/**
 * @brief Gets the current global mouse cursor position.
 *
 * @param x A pointer to store X coordinate.
 * @param y A pointer to store Y coordinate.
 *
 * @return Returns 1 on success, or 0 if the position could not be retrieved.
 */
uint8_t llic_input_get_mouse_position(uint16_t *x, uint16_t *y);

/**
 * @brief Sets the global mouse cursor position.
 *
 * @param x The X coordinate to move the mouse to.
 * @param y The Y coordinate to move the mouse to.
 *
 * @return Returns 1 on success, or 0 if the position could not be set.
 */
uint8_t llic_input_set_mouse_position(uint16_t x, uint16_t y);

/**
 * @brief Simulates a specific mouse event at the given coordinates.
 *
 * @param type The type of mouse event to apply (e.g., click, press, release).
 *
 * @return Returns 1 on success, or 0 if the event could not be applied.
 */
uint8_t llic_input_apply_mouse_event(llic_input_mouse_event_t type);

/**
 * @brief Simulates a mouse scroll event.
 *
 * @param power The intensity of the scroll.
 * @param type The type of scroll (vertical or horizontal).
 *
 * @return Returns 1 on success, or 0 if the event simulation fails.
 */
uint8_t llic_input_scroll_mouse(uint16_t power, llic_input_scroll_event_t type);

#endif // LLIC_INPUT_H
