#include "lexer.h"

#include <stdio.h>

llic_lexer_t *llic_lexer_new(llic_string_t *source) {
  llic_lexer_t *lexer = malloc(sizeof(llic_lexer_t));
  if (lexer == NULL)
    return NULL;

  llic_token_list_t *tokens = llic_token_list_new();
  if (tokens == NULL) {
    free(lexer);
    return NULL;
  }

  lexer->tokens = tokens;
  lexer->source = source;

  lexer->cursor = 0;
  lexer->line = 1;

  lexer->state = LEXER_STATE_IDLE;

  return lexer;
}

uint8_t llic_lexer_next(llic_lexer_t *lexer) {
  char character;

  if (!llic_string_get(lexer->source, lexer->cursor, &character))
    return 0; // end of line

  if (character == '\n') {
    lexer->line++;
    lexer->cursor++;

    return 1;
  }

  if (character == '.') {
    lexer->state = LEXER_STATE_COMMAND;
    lexer->cursor++; // consume the dot
  } else if (character == '#') {
    lexer->state = LEXER_STATE_COMMENT;
    lexer->cursor++; // consume the hashtag
  } else if (character >= '0' && character <= '9') {
    lexer->state = LEXER_STATE_NUMBER;
  } else if (character >= 'A' && character <= 'F') {
    llic_string_t *register_name = llic_string_new();
    llic_string_append(register_name, character);

    const llic_token_t token = llic_token_new(TOKEN_REGISTER, register_name);
    llic_token_list_append(lexer->tokens, token);

    lexer->cursor++; // consume the register
  } else {
    lexer->cursor++; // ignore character
  }

  return 1;
}

uint8_t llic_lexer_collect(llic_lexer_t *lexer) {
  uint8_t result = 1;

  switch (lexer->state) {
  case LEXER_STATE_COMMAND:
    result = llic_lexer_collect_command(lexer);
    break;
  case LEXER_STATE_COMMENT:
    result = llic_lexer_collect_comment(lexer);
    break;
  case LEXER_STATE_NUMBER:
    result = llic_lexer_collect_number(lexer);
    break;
  default:
    break;
  }

  lexer->state = LEXER_STATE_IDLE;
  return result;
}

uint8_t llic_lexer_collect_command(llic_lexer_t *lexer) {
  llic_string_t *command = llic_string_new();
  char character;

  while (llic_string_get(lexer->source, lexer->cursor, &character)) {
    if (character >= 'A' && character <= 'Z') {
      llic_string_append(command, character);
      lexer->cursor++;
    } else {
      break;
    }
  }

  if (command->length == 0) {
    llic_string_free(command);
    return 0;
  }

  llic_token_list_append(lexer->tokens, llic_token_new(TOKEN_COMMAND, command));
  return 1;
}

uint8_t llic_lexer_collect_comment(llic_lexer_t *lexer) {
  char character;

  while (llic_string_get(lexer->source, lexer->cursor++, &character)) {
    if (character == '\n') {
      lexer->line++;
      break;
    }
  }

  return 1;
}

uint8_t llic_lexer_collect_number(llic_lexer_t *lexer) {
  llic_string_t *number = llic_string_new();
  char character;

  while (llic_string_get(lexer->source, lexer->cursor, &character)) {
    if (character >= '0' && character <= '9') {
      llic_string_append(number, character);
      lexer->cursor++;
    } else {
      break;
    }
  }

  if (number->length == 0) {
    llic_string_free(number);
    return 0;
  }

  llic_token_list_append(lexer->tokens, llic_token_new(TOKEN_NUMBER, number));
  return 1;
}

void llic_lexer_free(llic_lexer_t *lexer) {
  llic_token_list_free(lexer->tokens);
  llic_string_free(lexer->source);
  free(lexer);
}
