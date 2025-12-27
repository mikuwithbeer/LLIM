#ifndef LLIC_TOKEN_H
#define LLIC_TOKEN_H

#include "string.h"

typedef enum { TOKEN_COMMAND, TOKEN_REGISTER, TOKEN_NUMBER } llic_token_type_t;

typedef struct {
  llic_token_type_t type;
  llic_string_t *string;
} llic_token_t;

typedef struct {
  llic_token_t *tokens;
  size_t length;
  size_t capacity;
} llic_token_list_t;

llic_token_t llic_token_new(llic_token_type_t type, llic_string_t *string);

void llic_token_free(llic_token_t token);

llic_token_list_t *llic_token_list_new(void);

uint8_t llic_token_list_append(llic_token_list_t *list, llic_token_t token);

uint8_t llic_token_list_get(const llic_token_list_t *list, size_t index,
                            llic_token_t *out);

void llic_token_list_free(llic_token_list_t *list);

#endif // LLIC_TOKEN_H
