# Programming Project Guidelines

## Development Process

1. **Plan First**: Always start with discussing the approach
2. **Identify Decisions**: Surface all implementation choices that need to be made
3. **Consult on Options**: When multiple approaches exist, present them with trade-offs
4. **Confirm Alignment**: Ensure we agree on the approach before writing code
5. **Then Implement**: Only write code after we've aligned on the plan

## Core Behaviors

- Break down features into clear tasks before implementing
- When facing implementation complexity: ask for guidance, don't simplify arbitrarily
- When discovering architectural flaws: stop and discuss, don't work around them

## When Planning

- Present multiple options with pros/cons when they exist
- Call out edge cases and how we should handle them
- Ask clarifying questions rather than making assumptions
- Question design decisions that seem suboptimal
- Share opinions on best practices, but acknowledge when something is opinion vs fact

## When Implementing (after alignment)

- Follow the agreed-upon plan precisely
- If you discover an unforeseen issue, stop and discuss
- Note concerns inline if you see them during implementation
- Never mark incomplete work as finished — be transparent about progress

## What NOT to do

- Don't make architectural decisions unilaterally
- Don't co-author yourself in commit messages

## Technical Discussion Guidelines

- Assume I understand common programming concepts without over-explaining
- Point out potential bugs, performance issues, or maintainability concerns
- Be direct with feedback rather than couching it in niceties

## Context About Me

- Prefer thorough planning to minimize code revisions
- Want to be consulted on implementation decisions

---

# Coding Styles and Conventions

## Conventions

- Use snake_case, unless language-specific conventions dictate otherwise (see language sections below)
- Lines have a width of 120 characters
- Indentation is 8 units. Use tabs or spaces depending on what the project uses—never mix. Language-specific sections
  may override this (e.g., 2 or 4 for JS).
- Use `NOTE:` or `XXX:` comments for important notes
- Use `TODO:` for tasks to be implemented
- Use `FIXME:` for code that needs fixing
- By default use GPLv2 license. Use SPDX identifier on each file (`// SPDX-License-Identifier: GPL-2.0`), place full
  license text in a LICENSE file in the repo
- Write small functions that do one thing

## Styles

First check if the project has a file like .clang-format or similar. If so, take the guidelines from there, if not
follow the next ones

- After an if, switch or loop statement, leave an empty line. This rule applies to all languages. Exceptions where no
  empty line is needed: if the statement is the last one in a block; if the statement is the last one in the function;
  if the statement is just before the return value or has 2 or less lines before the return statement. Example:

  ```c
      for (i = 0; i < 100; ++i) {
          if (cond1)
              nCoindicendes++;
           else
              nCoindicendes = 0; // Here we leave an empty line as it is not the last in the inner block

          if (cond2)
              nCoindicendes++; // No empty line as is the last one in the inner block
      } // Here we leave an empty line as it's the end of a block

      if (nCoindicendes >= (gadget->length / 2)) {
          free(gadget);
          return NULL;
      } // No empty line here as is just before the return statement
      return gadget;
  }
  ```

- Regarding if and loop statements, if a block has more than one line, use braces. Each branch is evaluated
  independently—if one branch needs braces, others with single lines can still omit them. Example:

  ```c
  if (cond1) // For statements like this one where the body has one line, do not use braces
     nCoindicendes++;
  else
     nCoindicendes = 0; // Even for else clauses

  if (cond2) {
     nCoindicendes++;
     foo();
     bar();
  } // As this statement's body is larger than one line, use braces

  if (cond3) {
     nCoindicendes++;
     foo();
     bar();
  } else
     foo(); // Here use braces for the if clause as the statement's body is larger than one line. But then use no braces for else clause as it uses one line

   for (i = 0; i < 100; ++i) {
     foo();
     bar();
   } // Here we use braces as it has more than one line

   for (i = 0; i < 100; ++i)
        nCoindicendes++; // Here we do not use braces as it has one line
  ```

- Place braces as described here. Use Allman style for function definitions, K&R style for control statements (if,
  switch, loops), structs, classes, enums and lambdas:

  ```c
  // Function definition - Allman style
  void foo(int bar)
  {
      // ...
  }

  // Control statements - K&R style
  for (i = 0; i < 100; ++i) {
      foo();
      bar();
  }

  if (cond) {
      foo();
  } else {
      bar();
  }

  switch (value) {
  case 1:
      foo();
      break;
  case 2:
      bar();
      break;
  }

  // Structs and classes - K&R style
  struct point_t {
      int x;
      int y;
  };

  class Foo {
  public:
      void bar();
  };

  enum color_t {
      RED,
      GREEN,
      BLUE
  };

  // Lambdas - K&R style
  auto add = [](int a, int b) {
      return a + b;
  };

  // Short lambdas and enums can be single line
  auto add = [](int a, int b) { return a + b; };
  enum status_t { OK, ERROR };
  ```

- Do not use braces for case blocks in switch statements

## C/C++ guidelines

- When using `#include` use first system includes: `#include <stdio.h>`, `#include <cstdio>`. Place an empty line and then use user includes: `#include "foo.h"`, `#include foo.hpp"`. Sort both of them alphabetically.
- After includes declare whatever macro is needed in the current translation unit (TU). If you are in a header file this rule
  also applies with the difference that the macro could be used by whoever includes the header file.
- Then declare extern variables
- Then declare global variables (`int x;`)
- Then declare TU-local global variables (`static int x;`)
- Finally declare structs or unions that are going to be used in the current TU
- Always use `static` for functions intended to be used in the current TU
- Place function attributes before the return value type and after function qualifier (`static`, `inline`, ...)
- Ask to the user which build system has to be used: Make or Cmake
- Leave an empty space before a single line comment (`// foo`)
- Leave an empty line between functions
- Always include `<stdint.h>` (C) or `<cstdint>` (C++) and use fixed-width types (`uint8_t`, `int32_t`, etc.). Avoid
  plain `int`, `long`, etc. except where an API requires them. Use `size_t` for array indices and sizes. Use
  `uint32_t`/`int32_t` for counters where you control the range
- For new/standalone projects, place source code under `src/` folder and header files under `include/`. Subfolders are
  allowed. When working on existing projects, follow the existing structure
- In loops use pre-increment `++var` for the update variable: `for (int32_t i = 0; i < 50; ++i)`
- Use Yoda style for equality checks with literals or function calls. E.g.:

  ```c
  if (0 == x)
  if (NULL == ptr)
  if (0 == strcmp(a, b))
  ```

## C specific guidelines

- Declare variables at the beginning of functions. First place declared but uninitialized variables, then declared and
  initialized. Example:

  ```c
  static struct gadget_t *jopFilter(struct gadget_t *gadget)
  {
      int8_t i;
      char *refRegister;
      uint8_t nCoindicendes = 0;
      refRegister = gadget->instructions[0]->regDest;

      for (i = gadget->length - 1; i >= 1; i--) {
          if (0 == strcmp(refRegister, gadget->instructions[i]->regDest))
              nCoindicendes++;
      }

      if (nCoindicendes >= (gadget->length / 2)) {
          free(gadget);
          return NULL;
      }
      return gadget;
  }
  ```

- Document each function using kerneldoc style:

  ```c
  /**
   * function_name - Short description
   * @param1: description
   * @param2: description
   *
   * Longer description if needed.
   *
   * Return: description of return value
   */
  ```
- When creating header files remember to add header guards. Use only the filename (not the full path) for the guard
  name. E.g., `include/foo/bar.h` uses `BAR_H_`:

  ```c
  #ifndef BAR_H_
  #define BAR_H_
  #endif // BAR_H_
  ```

- Pointer declarations attach the asterisk to the variable name: `char *ptr`, not `char* ptr`
- Use `const` for pointer parameters and return types when the data is not modified. Do not use `const` on local
  variables:

  ```c
  const char *get_name(void);
  void print(const char *str);
  ```

- Avoid `typedef` on structs and enums unless deliberately hiding implementation details. Use the full `struct foo` /
  `enum foo` at point of use
- Enums use `snake_case` for the type name and prefixed `ALL_CAPS` for enumerators. No typedef:

  ```c
  enum hrtimer_mode {
      HRTIMER_MODE_ABS = 0x00,
      HRTIMER_MODE_REL = 0x01,
  };
  ```

- Avoid function-like macros except for utility patterns like `LOG` and `ASSERT`. Prefer `static inline` otherwise
- Error handling via return value. Convention:
  - Return `int` (0 = success, `< 0` = error) when the function does work with no meaningful return value
  - Return pointer (`NULL` = error) when the function's primary job is to produce a pointer
  - Return `int` error code + output via pointer param when the function both produces a value and can fail

  ```c
  int do_work(void);                        // 0 or < 0
  struct foo *alloc_foo(void);              // NULL on error
  int get_value(uint32_t *out);             // 0 or < 0, result in out
  ```

## C++ specific guidelines

- Declare variables at point of use and initialize immediately
- Document each function using doxygen-javadoc style:

  ```cpp
  /**
   * @brief Short description
   *
   * Longer description if needed.
   *
   * @param param1 description
   * @param param2 description
   * @return description of return value
   */
  ```

- Use PascalCase for class names. Use snake_case for the rest
- Structs for data transport use snake_case. Structs with explicit constructors use PascalCase:

  ```cpp
  // Data-only struct - snake_case
  struct point_t {
      int x;
      int y;
  };

  // Struct with constructor - PascalCase
  struct Connection {
      Connection(int fd) : fd_(fd) {}
      int fd_;
  };
  ```

- Pointer declarations attach the asterisk to the variable name: `char *ptr`, not `char* ptr`
- Prefer `enum class` over unscoped enums. For `enum class`, use PascalCase for both the type and enumerators:

  ```cpp
  enum class Color { Red, Green, Blue };
  enum class Permission { Read = 1 << 0, Write = 1 << 1 };
  ```

- Unscoped enums are allowed only for bitmask/flags use cases where implicit integer conversion is needed. In that
  case, prefix enumerators with the type name:

  ```cpp
  enum Permission { Permission_Read = 1 << 0, Permission_Write = 1 << 1 };
  Permission p = Permission_Read | Permission_Write;
  ```

- Header files must use `.hpp` extension unless this header is intended to also be used in C. If that's the case and you
  create the file, then add appropriate guards (`#ifdef __cplusplus`).
- Do not use ifdef guards for `.hpp` files, instead use `#pragma once`
- Classes with private members, should have a final underscore in the field name
- At the end of each namespace place a comment signaling the end with the form: `//namespace name_of_namespace`. If it
  is an anonymous namespace then simply use `// namespace`
- Use `const` qualifier to match const correctness
- When using std c++ attributes, use `[[attribute]]` where attribute is the attribute to be used
- When using non std c++ attributes, first try to use `[[namespace::attribute]]`: e.g. `[[clang::cf_consumed]]`. If it
  is not available that way then fallback to `__attribute__((attribute))`
- Do not use namespaces like: `using namespace std;`. Instead import whatever is needed and then use it like this:

  ```cpp
     void print(std::string_view view) {
        std::cout << view << std::endl;
     }
  ```

- For nested namespaces is allowed to import the root one and then use it like the previous rule
- Avoid the use of auto at all. Or use it for small trivial functions, or in places you think is coherent
- Use C++ casts instead of C-style casts. For example:

  ```cpp
  // OK
  auto *ptr = reinterpret_cast<char *>(get_buffer());
  int num = static_cast<int>(float_value);

  // BAD
  char *ptr = (char *)get_buffer();
  int num = (int)float_value;
  ```

- Prefer RAII—tie resource lifetime (memory, files, locks) to object lifetime
- Prefer smart pointers (`std::unique_ptr`, `std::shared_ptr`) over raw pointers. Default to `std::unique_ptr`;
  use `std::shared_ptr` only when shared ownership is genuinely needed
- Prefer references over pointers when null is not a valid value
- Always use `nullptr` instead of `NULL` or `0`
- Prefer `constexpr` over `const` or `#define` for compile-time constants
- Prefer range-based for loops: `for (const auto& item : container)`
- Prefer brace initialization `{}`
- Prefer `using` over `typedef`:

  ```cpp
  // OK
  using callback_t = void (*)(int);

  // BAD
  typedef void (*callback_t)(int);
  ```

- Any class with virtual methods must have a virtual destructor
- Mark overriding methods with `override`. Do not use abstract classes unless genuinely needed - a class can provide
  a default implementation and still mark methods as `virtual`
- Implementation always goes in `.cpp` files. The only exception is small free helper functions that are genuinely
  shared and belong logically in the header. Class member definitions must never be defined inside the header
- Error handling:
  - Throw exceptions for unexpected failures (including constructors that cannot complete initialization)
  - Use `std::optional<T>` for functions where "not found" / "not present" is an expected outcome
  - Use return codes (consistent with C conventions) for operations where failure is a normal expected path
  - Use `assert` for programming errors and invariant violations that are unrecoverable

  ```cpp
  File open(const std::string &path);       // throws on unexpected failure
  std::optional<User> find_user(int32_t id); // not found is normal, not exceptional
  int32_t connect(const std::string &addr);  // < 0 on expected failure
  ```

- When using C libraries, wrap them in RAII classes. Raw pointers are OK internally for C interop, but expose a C++
  friendly interface (references, smart pointers) externally:

  ```cpp
  class Database {
  public:
      Database(const std::string& path) { db_ = sqlite3_open(path.c_str()); }
      ~Database() { if (db_) sqlite3_close(db_); }
      void execute(const std::string& query);
  private:
      sqlite3 *db_;  // raw pointer OK for C interop
  };
  ```

## Build systems

### CMake

- Minimum version: 3.21
- Use modern CMake (target-based): `target_include_directories`, `target_link_libraries`, `target_compile_options`.
  Never use global `include_directories`, `link_libraries`, etc.
- Build output always goes under `build/`. Never build in the source tree
- Pass build type manually: `cmake -DCMAKE_BUILD_TYPE=Debug ..`
- Three build types:
  - `Debug`: `-Wall -Wextra`, no optimization
  - `Release`: `-O2`, full LTO (`-flto`), strip symbols
  - `Asan`: AddressSanitizer + UBSan (`-fsanitize=address,undefined`), no optimization

  ```cmake
  cmake_minimum_required(VERSION 3.21)
  project(my_project)

  add_executable(my_target src/main.cpp)

  target_compile_options(my_target PRIVATE
      $<$<CONFIG:Debug>:-Wall -Wextra>
      $<$<CONFIG:Release>:-O2 -flto>
      $<$<CONFIG:Asan>:-fsanitize=address,undefined -fno-omit-frame-pointer>
  )
  target_link_options(my_target PRIVATE
      $<$<CONFIG:Release>:-flto -s>
      $<$<CONFIG:Asan>:-fsanitize=address,undefined>
  )
  ```

### Makefiles

- Write by hand unless using CMake
- Always define `all` as the default target and `clean` as a phony target
- Add `install` only when the project warrants it
- Follow standard variable conventions: `CC`, `CXX`, `CFLAGS`, `CXXFLAGS`, `LDFLAGS`, `LDLIBS`

  ```makefile
  CC      = gcc
  CFLAGS  = -Wall -Wextra

  .PHONY: all clean

  all: my_target

  my_target: src/main.c
  	$(CC) $(CFLAGS) -o $@ $^

  clean:
  	rm -f my_target
  ```

## Python guidelines

- Document each function using sphinx style:

  ```python
  def function_name(param1: int, param2: str) -> bool:
      """Short description.

      Longer description if needed.

      :param param1: description
      :param param2: description
      :return: description of return value
      """
  ```

- Use PascalCase for class names. Use snake_case for the rest
- Variables should not be declared at the top of the function, just whenever they are used
- Type each function. Type the arguments and the return value. For example:

  ```python
  def sum(a: int, b: int) -> int:
      return a + b
  ```

- Whenever it's possible do not use imports for typing, like `tuple` vs `Tuple`
- Sort imports with this order: STDLIB, THIRDPARTY, FIRSTPARTY, LOCALFOLDER. Each group with a newline as separator.
  Look at the following snippet:

  ```python
  import os
  import sys

  import requests

  import my_app.utils

  from . import models
  ```

- Sort imports in alphabetical order
- Use t-strings always. If python version doesn't have support for t-strings use f-strings
- Use the `logging` module, never `print` for diagnostic output. Use a per-module logger:

  ```python
  import logging
  logger = logging.getLogger(__name__)
  ```

  Set up a colored formatter in `main()` using a custom formatter (see logging snippet). Log levels:
  - `DEBUG`: detailed diagnostic info
  - `INFO`: normal operation
  - `WARNING`: orange - unexpected but recoverable
  - `ERROR`: red - operation failed
  - `CRITICAL`: bold red - fatal, program cannot continue

- Error handling: prefer built-in exceptions (`ValueError`, `TypeError`, `RuntimeError`, `OSError`, etc.) when they
  semantically match. Define custom exception classes when the error is domain-specific or callers need to
  distinguish it:

  ```python
  class ParseError(Exception):
      """Raised when input cannot be parsed."""
      pass
  ```

- Project structure: place source code directly under `my_package/`. Use `pyproject.toml` for projects that need
  packaging

## Rust guidelines

- Declare variables at point of use
- Use PascalCase for types/traits, snake_case for functions/variables, SCREAMING_CASE for constants
- Document functions using `///` doc comments with markdown:

  ```rust
  /// Short description.
  ///
  /// Longer description if needed.
  ///
  /// # Arguments
  ///
  /// * `param1` - description
  /// * `param2` - description
  ///
  /// # Returns
  ///
  /// Description of return value.
  fn function_name(param1: i32, param2: &str) -> bool {
      // ...
  }
  ```

- Use `mod.rs` with `pub mod name;` for module structure
- Prefer borrowing (`&`) over cloning
- Avoid `unsafe` unless necessary (FFI, low-level operations). For `unsafe fn`, document safety requirements in the
  function documentation. Do not add `// SAFETY:` comments inside safe functions:

  ```rust
  /// Does something unsafe.
  ///
  /// # Safety
  ///
  /// - `ptr` must be valid and aligned
  /// - `ptr` must point to initialized memory
  unsafe fn write_value(ptr: *mut u32, value: u32) {
      *ptr = value;
  }
  ```
