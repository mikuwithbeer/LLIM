cmake_minimum_required(VERSION 4.0)
project(llic C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(llic main.c
        assembly/token.c
        assembly/token.h
        assembly/string.c
        assembly/string.h
        assembly/lexer.c
        assembly/lexer.h
)

target_sources(llic PRIVATE
        machine/bytecode.c machine/bytecode.h
        machine/vm.c machine/vm.h
        machine/config.c machine/config.h
        machine/stack.c machine/stack.h
        machine/register.c machine/register.h
        machine/command.c machine/command.h
        machine/error.c machine/error.h
        machine/input.c machine/input.h
)

target_compile_options(llic PRIVATE -Wall -Wextra -Wpedantic)

find_library(APP_SERVICES_LIB ApplicationServices REQUIRED)
target_link_libraries(llic PRIVATE ${APP_SERVICES_LIB})
