#include "lib/vm.h"

#include <stdio.h>

int main(void) {
  llic_bytecode_t *bytecode = llic_bytecode_new(32);

  /*
    llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 6);

    llic_bytecode_append(bytecode, COMMAND_JUMP_FORWARD);
    llic_bytecode_append(bytecode, 0);

    llic_bytecode_append(bytecode, COMMAND_NOP);
    llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 0);
    llic_bytecode_append(bytecode, 6);
    llic_bytecode_append(bytecode, COMMAND_JUMP_BACK);
    llic_bytecode_append(bytecode, 0);*/
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

  llic_bytecode_append(bytecode, COMMAND_GET_MOUSE_POSITION);

  llic_bytecode_append(bytecode, COMMAND_SET_REGISTER);
  llic_bytecode_append(bytecode, 2);
  llic_bytecode_append(bytecode, 0);
  llic_bytecode_append(bytecode, 255);

  llic_bytecode_append(bytecode, COMMAND_ADD_REGISTER);
  llic_bytecode_append(bytecode, 0);
  llic_bytecode_append(bytecode, 2);

  llic_bytecode_append(bytecode, COMMAND_SET_MOUSE_POSITION);

  llic_config_t config = llic_config_default();
  config.permission = PERM_MOUSE;

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

  return 0;
}