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
  char determiner;
  if (!llic_string_get(lexer->source, lexer->cursor, &determiner))
    return 0;

  lexer->cursor++;

  switch (determiner) {
  case '.':
    lexer->state = LEXER_STATE_COMMAND;
    break;
  case '#':
    lexer->state = LEXER_STATE_COMMENT;
    break;
  case '0':
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
    lexer->state = LEXER_STATE_NUMBER;
    lexer->cursor--;
    break;
  case 'A':
  case 'B':
  case 'C':
  case 'D':
  case 'E':
  case 'F': {
    llic_string_t *register_name = llic_string_new();
    llic_string_append(register_name, determiner);

    const llic_token_t token = llic_token_new(TOKEN_REGISTER, register_name);
    llic_token_list_append(lexer->tokens, token);

    break;
  }
  default:
    break;
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
  while (llic_string_get(lexer->source, lexer->cursor++, &character)) {
    if (character > 64 && character < 91) {
      llic_string_append(command, character);
    } else if (character == '\n') {
      lexer->line++;
      break;
    } else if (character == ' ' || character == '\r') {
      break;
    } else {
      llic_string_free(command);
      return 0;
    }
  }

  if (command->length == 0) {
    llic_string_free(command);
    return 0;
  }

  const llic_token_t token = llic_token_new(TOKEN_COMMAND, command);
  llic_token_list_append(lexer->tokens, token);

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
  llic_string_t *command = llic_string_new();
  char character;
  while (llic_string_get(lexer->source, lexer->cursor++, &character)) {
    if (character > 47 && character < 58) {
      llic_string_append(command, character);
    } else if (character == '\n') {
      lexer->line++;
      break;
    } else if (character == ' ' || character == '\r') {
      break;
    } else {
      llic_string_free(command);
      return 0;
    }
  }

  if (command->length == 0) {
    llic_string_free(command);
    return 0;
  }

  const llic_token_t token = llic_token_new(TOKEN_NUMBER, command);
  llic_token_list_append(lexer->tokens, token);

  return 1;
}

void llic_lexer_free(llic_lexer_t *lexer) {
  llic_token_list_free(lexer->tokens);
  llic_string_free(lexer->source);
  free(lexer);
}
