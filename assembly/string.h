#ifndef LLIC_STRING_H
#define LLIC_STRING_H

#include <stdint.h>
#include <stdlib.h>

typedef struct {
  char *data;
  size_t length;
  size_t capacity;
} llic_string_t;

llic_string_t *llic_string_new(void);

uint8_t llic_string_append(llic_string_t *string, char character);

uint8_t llic_string_extend(llic_string_t *string, const char *data,
                           size_t length);

uint8_t llic_string_get(const llic_string_t *string, size_t index, char *out);

uint8_t llic_string_length(const llic_string_t *string);

void llic_string_free(llic_string_t *string);

#endif // LLIC_STRING_H
