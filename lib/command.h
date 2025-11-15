#ifndef LLIC_COMMAND_H
#define LLIC_COMMAND_H

#include <stdlib.h>

typedef enum { COMMAND_NOP } llic_command_id_t;

typedef struct {
  llic_command_id_t id;
  uint8_t args[4];
} llic_command_t;

uint8_t llic_command_to_argc(llic_command_id_t id);

#endif // LLIC_COMMAND_H
