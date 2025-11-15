#ifndef LLIC_CONFIG_H
#define LLIC_CONFIG_H

#include <stdlib.h>

typedef enum {
  PERM_NONE,
  PERM_MOUSE = 1,
  PERM_KEYBOARD = 2,
  PERM_SCREEN = 4,
  PERM_ALL = PERM_MOUSE | PERM_KEYBOARD | PERM_SCREEN
} llic_permission_t;

typedef struct {
  uint8_t debug;
  size_t stack_capacity;
  llic_permission_t permission;
} llic_config_t;

llic_config_t llic_config_default(void);

uint8_t llic_config_check(llic_config_t config, llic_permission_t permission);

#endif // LLIC_CONFIG_H
