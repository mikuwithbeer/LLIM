#include "assembly/lexer.h"
#include "machine/vm.h"

#include <stdio.h>

int main(void) {
  const char *lol = ".LOLA AAA 5314 A B 45 234 .LMAO #lmao\n .GET 31 69 .LOL # lmao .LOL";
  llic_string_t *str = llic_string_new();
  llic_string_extend(str, lol, strlen(lol));

  llic_lexer_t *lexer = llic_lexer_new(str);

  while (1) {
    if (!llic_lexer_next(lexer))
      break;

    if (!llic_lexer_collect(lexer))
      break;
  }

  for (size_t index = 0; index < lexer->tokens->length; index++) {
    llic_token_t token = lexer->tokens->tokens[index];
    printf("%s %d\n", token.string->data, token.type);
  }

  llic_lexer_free(lexer);

  /*
    llic_bytecode_append(bytecode, COMMAND_PUSH);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 99);
    llic_bytecode_append(bytecode, COMMAND_PUSH);
    llic_bytecode_append(bytecode, 10);
    llic_bytecode_append(bytecode, 2);
    llic_bytecode_append(bytecode, COMMAND_SWAP);
    llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 40);
    llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
    llic_bytecode_append(bytecode, 1);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, COMMAND_DIV_REGISTER);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 1);*/

  /* llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 1);
   llic_bytecode_append(bytecode, 255);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 1);
   llic_bytecode_append(bytecode, 1);
   llic_bytecode_append(bytecode, 255);

   llic_bytecode_append(bytecode, COMMAND_SET_MOUSE_POSITION);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);

   llic_bytecode_append(bytecode, COMMAND_EXECUTE_MOUSE);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 1);

   llic_bytecode_append(bytecode, COMMAND_EXECUTE_MOUSE);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 4);
   llic_bytecode_append(bytecode, 255);

   llic_bytecode_append(bytecode, COMMAND_SLEEP);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 1);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0x38);

   llic_bytecode_append(bytecode, COMMAND_EXECUTE_KEYBOARD);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 2);
   llic_bytecode_append(bytecode, 255);

   llic_bytecode_append(bytecode, COMMAND_SLEEP);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 2);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 1);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);

   llic_bytecode_append(bytecode, COMMAND_EXECUTE_KEYBOARD);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 1);

   llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
   llic_bytecode_append(bytecode, 1);
   llic_bytecode_append(bytecode, 0);
   llic_bytecode_append(bytecode, 0x38);

   llic_bytecode_append(bytecode, COMMAND_EXECUTE_KEYBOARD);

   /*
     llic_bytecode_append(bytecode, COMMAND_SCROLL_MOUSE);
     llic_bytecode_append(bytecode, COMMAND_HALT);*/
  /*
    llic_config_t config = llic_config_default();
    config.permission = PERM_ALL;

    llic_vm_t *vm = llic_vm_new(bytecode, config);
    uint8_t res = llic_vm_loop(vm);

    if (res == 0) {
      printf("vm error: %s\n", vm->error.message);
      return 1;
    }

    printf("(a..f): %d %d %d %d %d %d\n", vm->registers.a, vm->registers.b,
           vm->registers.c, vm->registers.d, vm->registers.e, vm->registers.f);

    printf("stack: %d %d %d\n", vm->stack->data[0], vm->stack->data[1],
           vm->stack->data[2]);

    llic_vm_free(vm);
    */

  return 0;
}