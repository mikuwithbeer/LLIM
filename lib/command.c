#include "command.h"

uint8_t llic_command_to_argc(const llic_command_id_t id) {
  switch (id) {
  case COMMAND_NOP:
  case COMMAND_SWAP:
  case COMMAND_GET_MOUSE_POSITION:
  case COMMAND_SET_MOUSE_POSITION:
    return 0;
  case COMMAND_POP:
  case COMMAND_GET_REGISTER:
  case COMMAND_JUMP_BACK:
  case COMMAND_JUMP_FORWARD:
    return 1;
  case COMMAND_PUSH:
  case COMMAND_COPY_REGISTER:
  case COMMAND_ADD_REGISTER:
  case COMMAND_SUB_REGISTER:
  case COMMAND_MUL_REGISTER:
  case COMMAND_DIV_REGISTER:
  case COMMAND_MOD_REGISTER:
    return 2;
  case COMMAND_SET_REGISTER:
    return 3;
  default:
    return UNREACHABLE_ARGC;
  }
}

llic_permission_t llic_permission_from_command(llic_command_id_t id) {
  switch (id) {
  case COMMAND_GET_MOUSE_POSITION:
  case COMMAND_SET_MOUSE_POSITION:
    return PERM_MOUSE;
  default:
    return PERM_NONE;
  }
}
