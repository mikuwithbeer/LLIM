#ifndef LLIC_VM_H
#define LLIC_VM_H

#include "bytecode.h"
#include "command.h"
#include "config.h"
#include "stack.h"

typedef enum { STATE_IDLE, STATE_COLLECTING, STATE_RUNNING } llic_vm_state_t;

typedef struct {
  size_t cursor;
  llic_vm_state_t state;

  llic_bytecode_t *bytecode;
  llic_command_t command;
  llic_config_t config;
  llic_stack_t *stack;
} llic_vm_t;

llic_vm_t *llic_vm_new(llic_bytecode_t *bytecode, llic_config_t config);

uint8_t llic_vm_run(llic_vm_t *vm);

void llic_vm_free(llic_vm_t *vm);

#endif // LLIC_VM_H
