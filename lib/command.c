#include "command.h"

uint8_t llic_command_to_argc(const llic_command_id_t id) {
  switch (id) {
  case COMMAND_NOP:
    return 0;
  default:
    return 69;
  }
}
