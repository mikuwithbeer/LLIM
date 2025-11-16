#ifndef LLIC_ERROR_H
#define LLIC_ERROR_H

#include <string.h>

typedef enum {
  ERROR_NONE = 0,
  ERROR_UNKNOWN_COMMAND,
  ERROR_STACK_OVERFLOW,
  ERROR_STACK_UNDERFLOW,
  ERROR_UNKNOWN_REGISTER,
  ERROR_PERMISSION_DENIED,
  ERROR_MACOS_API,
  ERROR_DIVIDE_BY_ZERO
} llic_error_id_t;

typedef struct {
  llic_error_id_t id;
  char message[128];
} llic_error_t;

llic_error_t llic_error_new(llic_error_id_t id);

#endif // LLIC_ERROR_H
