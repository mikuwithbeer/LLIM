#include "token.h"

llic_token_t llic_token_new(const llic_token_type_t type,
                            llic_string_t *string) {
  return (llic_token_t){type, string};
}

llic_token_list_t *llic_token_list_new(void) {
  llic_token_list_t *list = malloc(sizeof(llic_token_list_t));
  if (list == NULL)
    return NULL;

  list->capacity = 32;
  list->length = 0;

  llic_token_t *tokens = malloc(sizeof(llic_token_t) * list->capacity);
  if (tokens == NULL) {
    free(list);
    return NULL;
  }

  list->tokens = tokens;
  return list;
}

uint8_t llic_token_list_append(llic_token_list_t *list,
                               const llic_token_t token) {
  if (list->length >= list->capacity) {
    list->capacity *= 2;

    llic_token_t *tokens =
        realloc(list->tokens, sizeof(llic_token_t) * list->capacity);

    if (tokens == NULL) {
      list->capacity /= 2;
      return 0;
    }

    list->tokens = tokens;
  }

  list->tokens[list->length++] = token;
  return 1;
}

uint8_t llic_token_list_get(const llic_token_list_t *list, const size_t index,
                            llic_token_t *out) {
  if (index >= list->length)
    return 0;

  *out = list->tokens[index];
  return 1;
}

void llic_token_list_free(llic_token_list_t *list) {
  for (size_t index = 0; index < list->length; index++)
    llic_string_free(list->tokens[index].string);

  free(list->tokens);
  free(list);
}
