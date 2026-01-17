#ifndef LLIC_COMMAND_H
#define LLIC_COMMAND_H

#include "config.h"

/// Sentinel value for commands that should be unreachable
#define UNREACHABLE_ARGC 67

/// Represents all possible command opcodes for the VM.
typedef enum {
  // vm ops
  COMMAND_NOP = 1,
  COMMAND_JUMP_BACK,
  COMMAND_JUMP_FORWARD,
  COMMAND_HALT,
  // stack ops
  COMMAND_PUSH_STACK,
  COMMAND_POP_STACK,
  COMMAND_SWAP_STACK,
  COMMAND_REVERSE_STACK,
  // register ops
  COMMAND_SET_REGISTER,
  COMMAND_GET_REGISTER,
  COMMAND_COPY_REGISTER,
  COMMAND_ADD_REGISTER,
  COMMAND_SUB_REGISTER,
  COMMAND_MUL_REGISTER,
  COMMAND_DIV_REGISTER,
  COMMAND_MOD_REGISTER,
  COMMAND_BIGGER_REGISTER,
  COMMAND_SMALLER_REGISTER,
  COMMAND_EQUAL_REGISTER,
  // mouse ops
  COMMAND_GET_MOUSE_POSITION,
  COMMAND_SET_MOUSE_POSITION,
  COMMAND_EXECUTE_MOUSE,
  COMMAND_SCROLL_MOUSE,
  // keyboard ops
  COMMAND_EXECUTE_KEYBOARD,
  // os ops
  COMMAND_SLEEP,

} llic_command_id_t;

/// Represents a single command with its ID and arguments.
typedef struct {
  llic_command_id_t id;
  /// A fixed-size array holding the arguments for this command.
  uint8_t args[4];
} llic_command_t;

/**
 * @brief Gets the number of arguments required for a specific command ID.
 *
 * @param id The command ID to query.
 *
 * @return The number of arguments the command uses.
 */
uint8_t llic_command_to_argc(llic_command_id_t id);

/**
 * @brief Gets the permission level required to execute a command.
 *
 * @param id The command ID to check.
 *
 * @return The minimum permission requirement for the command.
 */
llic_permission_t llic_permission_from_command(llic_command_id_t id);

#endif // LLIC_COMMAND_H
