#include "bytecode.h"

llic_bytecode_t *llic_bytecode_new(const size_t capacity) {
  llic_bytecode_t *bytecode = malloc(sizeof(llic_bytecode_t));
  if (bytecode) {
    bytecode->capacity = capacity;
    bytecode->length = 0;

    uint8_t *data = malloc(capacity);
    if (data == NULL) {
      free(bytecode); // also free bytecode before failing
      return NULL;
    }

    bytecode->data = data;
    return bytecode;
  }

  return NULL;
}

uint8_t llic_bytecode_get(const llic_bytecode_t *bytecode, const size_t index,
                          uint8_t *out) {
  if (bytecode->length <= index)
    return 0;

  *out = bytecode->data[index];
  return 1;
}

uint8_t llic_bytecode_append(llic_bytecode_t *bytecode, const uint8_t value) {
  if (bytecode->length >= bytecode->capacity) {
    bytecode->capacity *= 2;

    uint8_t *data = realloc(bytecode->data, bytecode->capacity);
    if (data == NULL)
      return 0;

    bytecode->data = data;
  }

  bytecode->data[bytecode->length++] = value;
  return 1;
}

uint8_t llic_bytecode_load(llic_bytecode_t *bytecode, const uint8_t *data,
                           const size_t length) {
  for (size_t index = 0; index <= length; index++)
    if (!llic_bytecode_append(bytecode, data[index]))
      return 0;

  return 1;
}

void llic_bytecode_free(llic_bytecode_t *bytecode) {
  free(bytecode->data);
  free(bytecode);
}
