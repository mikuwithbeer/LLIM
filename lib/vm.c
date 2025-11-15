#include "vm.h"

#include <stdio.h>

llic_vm_t *llic_vm_new(llic_bytecode_t *bytecode, const llic_config_t config) {
  if (bytecode == NULL)
    return NULL;

  llic_vm_t *vm = malloc(sizeof(llic_vm_t));
  if (vm == NULL)
    return NULL;

  vm->cursor = 0;
  vm->state = STATE_IDLE;

  vm->bytecode = bytecode;
  vm->command = (llic_command_t){0};
  vm->config = config;

  vm->stack = llic_stack_new(config.stack_capacity);
  if (vm->stack == NULL) {
    free(vm);
    return NULL;
  }

  return vm;
}

uint8_t llic_vm_run(llic_vm_t *vm) {
  uint8_t argi = 0, argc = 0;
  llic_bytecode_append(vm->bytecode, COMMAND_NOP); // bug

  while (vm->cursor < vm->bytecode->length) {
    if (vm->state == STATE_RUNNING) {
      printf("cmd %d\n", vm->command.id);
      printf("args %d %d %d %d\n", vm->command.args[0], vm->command.args[1],
             vm->command.args[2], vm->command.args[3]);

      vm->state = STATE_IDLE;
    } else {
      uint8_t byte;
      llic_bytecode_get(vm->bytecode, vm->cursor++, &byte);

      switch (vm->state) {
      case STATE_IDLE: {
        const llic_command_id_t cid = (llic_command_id_t)byte;
        vm->command.id = cid;

        argi = 0, argc = llic_command_to_argc(cid);
        if (argc == 0) {
          vm->state = STATE_RUNNING;
        } else {
          vm->state = STATE_COLLECTING;
        }

        break;
      }

      case STATE_COLLECTING: {
        vm->command.args[argi++] = byte;
        if (argi == argc) {
          vm->state = STATE_RUNNING;
        }

        break;
      }
      }
    }
  }

  return 1;
}

void llic_vm_free(llic_vm_t *vm) {
  llic_stack_free(vm->stack);
  llic_bytecode_free(vm->bytecode);
  free(vm);
}
