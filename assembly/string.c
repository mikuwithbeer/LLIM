#include "string.h"

llic_string_t *llic_string_new(void) {
  llic_string_t *string = malloc(sizeof(llic_string_t));
  if (string == NULL) {
    return NULL;
  }

  string->capacity = 32;
  string->length = 0;

  char *data = malloc(string->capacity);
  if (data == NULL) {
    free(string);
    return NULL;
  }

  string->data = data;
  return string;
}

uint8_t llic_string_append(llic_string_t *string, const char character) {
  if (string->length >= string->capacity) {
    string->capacity *= 2;

    char *data = realloc(string->data, string->capacity);
    if (data == NULL) {
      string->capacity /= 2;
      return 0;
    }

    string->data = data;
  }

  string->data[string->length++] = character;
  return 1;
}

uint8_t llic_string_extend(llic_string_t *string, const char *data,
                           const size_t length) {
  for (size_t index = 0; index < length; index++)
    if (!llic_string_append(string, data[index]))
      return 0;

  return 1;
}

uint8_t llic_string_get(const llic_string_t *string, const size_t index,
                        char *out) {
  if (index >= string->length)
    return 0;

  *out = string->data[index];
  return 1;
}

uint8_t llic_string_length(const llic_string_t *string) {
  return string->length;
}

void llic_string_free(llic_string_t *string) {
  free(string->data);
  free(string);
}
