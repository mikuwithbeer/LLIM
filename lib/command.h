#ifndef LLIC_COMMAND_H
#define LLIC_COMMAND_H

#include "config.h"

#define UNREACHABLE_ARGC 69

typedef enum {
  COMMAND_NOP = 0,
  COMMAND_JUMP_BACK,
  COMMAND_JUMP_FORWARD,
  COMMAND_PUSH,
  COMMAND_POP,
  COMMAND_SWAP,
  COMMAND_SET_REGISTER,
  COMMAND_GET_REGISTER,
  COMMAND_COPY_REGISTER,
  COMMAND_ADD_REGISTER,
  COMMAND_SUB_REGISTER,
  COMMAND_MUL_REGISTER,
  COMMAND_DIV_REGISTER,
  COMMAND_MOD_REGISTER,
  COMMAND_GET_MOUSE_POSITION,
  COMMAND_SET_MOUSE_POSITION
} llic_command_id_t;

typedef struct {
  llic_command_id_t id;
  uint8_t args[4];
} llic_command_t;

uint8_t llic_command_to_argc(llic_command_id_t id);
llic_permission_t llic_permission_from_command(llic_command_id_t id);

#endif // LLIC_COMMAND_H
