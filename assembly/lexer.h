#ifndef LLIC_LEXER_H
#define LLIC_LEXER_H

#include "string.h"
#include "token.h"

typedef enum {
  LEXER_STATE_IDLE,
  LEXER_STATE_COMMAND,
  LEXER_STATE_COMMENT,
  LEXER_STATE_NUMBER,
} llic_lexer_state_t;

typedef struct {
  llic_token_list_t *tokens;
  llic_string_t *source;

  size_t cursor;
  size_t line;

  llic_lexer_state_t state;
} llic_lexer_t;

llic_lexer_t *llic_lexer_new(llic_string_t *source);

uint8_t llic_lexer_next(llic_lexer_t *lexer);

uint8_t llic_lexer_collect(llic_lexer_t *lexer);

uint8_t llic_lexer_collect_command(llic_lexer_t *lexer);

uint8_t llic_lexer_collect_comment(llic_lexer_t *lexer);

uint8_t llic_lexer_collect_number(llic_lexer_t *lexer);

void llic_lexer_free(llic_lexer_t *lexer);

#endif // LLIC_LEXER_H
