#include "config.h"

llic_config_t llic_config_default(void) {
  llic_config_t config = {0};
  config.stack_capacity = 256;
  config.permission = PERM_NONE;

  return config;
}

uint8_t llic_config_check(const llic_config_t config,
                          const llic_permission_t permission) {
  return (config.permission & permission) == permission;
}
