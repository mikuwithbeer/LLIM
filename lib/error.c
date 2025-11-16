#include "error.h"

llic_error_t llic_error_new(const llic_error_id_t id) {
  llic_error_t error = {0};
  error.id = id;

  switch (id) {
  case ERROR_NONE:
    break;
  case ERROR_UNKNOWN_COMMAND:
    strcpy(error.message, "unknown command");
    break;
  case ERROR_STACK_OVERFLOW:
    strcpy(error.message, "stack overflow");
    break;
  case ERROR_STACK_UNDERFLOW:
    strcpy(error.message, "stack underflow");
    break;
  case ERROR_UNKNOWN_REGISTER:
    strcpy(error.message, "unknown register");
    break;
  case ERROR_PERMISSION_DENIED:
    strcpy(error.message, "permission denied");
    break;
  case ERROR_MACOS_API:
    strcpy(error.message, "macos api error");
    break;
  case ERROR_DIVIDE_BY_ZERO:
    strcpy(error.message, "divide by zero");
    break;
  }

  return error;
}
