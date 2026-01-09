# Preferences

You must follow the following coding styles and conventions

## Conventions

- Use snake_case, unless is a common practice to use other case style for that particular language (e.g. camelCase for
  Java)
- Lines have a width of 120 characters
- Tabs have a length of 8. If the project uses space as tab, then 8 spaces must be used. Here is important to follow
  what the project uses, you are not allowed to mix styles.
- Use `NOTE:` or `XXX:` comments for important notes.
- Use `TODO:` for tasks to be implemented
- By default use GPLv2 license. Place the license on each file
- Write always small functions

## Styles

First check if the project has a file like .clang-format or similar. If so, take the guidelines from there, if not
follow the next ones

- Variables must be declared at the beginning of the functions. First place declared but uninitialized variables, then
  declared and initialized. Take as an example this snippet:

  ```c
  static struct gadget_t *jopFilter(struct gadget_t *gadget)
  {
      int8_t i;
      char *refRegister;
      uint8_t nCoindicendes = 0;
      refRegister = gadget->instructions[0]->regDest;

      for (i = gadget->length - 1; i >= 1; i--)
      {
          if (0 == strcmp(refRegister, gadget->instructions[i]->regDest))
              nCoindicendes++;
      }

      if (nCoindicendes >= (gadget->length / 2))
      {
          free(gadget);
          return NULL;
      }
      return gadget;
  }
  ```

- After an if, switch or loop statement, leave an empty line. There are some cases where no empty line must be written: if the statement is the last one in a block; If the statement is the last one in the function; If the statement is just before the return value or has 2 or less lines before the return statement. As an example look at the following snippet:

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

- Regarding if and loop statements, if the statement's block has more than one line, then use braces. As an example look at the following snippet:

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

- Place braces as described here:

  ```c
  // OK
  for (i = 0; i < 100; ++i) {
    foo();
    bar();
  }

  // BAD
  for (i = 0; i < 100; ++i)
  {
    foo();
    bar();
  }
  ```

### C/C++ guidelines

- When using `#include` use first system includes: `#include <stdio.h>`, `#include <cstdio>`. Place an empty line and then use user includes: `#include "foo.h"`, `#include foo.hpp"`. Sort both of them alphabetically.
- After includes declare whatever macro is needed in the current translation unit (TU). If you are in a header file this rule
  also applies with the difference that the macro could be used by whoever includes the header file.
- Then is time for global variables declarations.
- After global variables declare global variables to the current TU
- Finally declare structs or unions that are going to be used in the current TU
- Always use `static` for functions intended to be used in the current TU
- Place function attributes before the return value type and after function qualifier (`static`, `inline`, ...)
- Ask to the user which build system has to be used: Make or Cmake
- Leave an empty space before a single line comment (`// foo`)
- Leave an empty line between functions
- Use standard types: `uint8_t`, `int8_t`, `uint32_t` and so on
- Place source code under `src` folder. Here you can create subfolders
- Place header files under `include` folder. Here you can create subfolders
- In loops use pre increment `++var` for the update variable: `for (int i = 0; i < 50; ++i)`
- In if statements place the result first. E.g.:

  ```c
  if (0 == strcmp(a, b))
  ```

### C specific guidelines

- Document each function using kerneldoc style
- When creating header files remember to add header guards. Header guards must follow this style:

  ```c
  #ifndef FILENAME_H_
  #define FILENAME_H_
  #endif // FILENAME_H_
  ```

### C++ specific guidelines

- Document each function using doxygen-javadoc style
- use camelCase for class names. Use snake_case for the rest
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
- Use C++ casts instead of c-style casts. For example:

  ```cpp
     // OK
     char *foo = reinterpret_cast<char *>(malloc(sizeof(500 * char)));
     // BAD
     char *foo = (char *)malloc(sizeof(500 * char));
  ```

### Python guidelines

- Document each function using sphinx style
- use camelCase for class names. Use snake_case for the rest
- Variables should not be declared at the top of the function, just whenever they are used
- Type each function. Type the arguments and the return value. For example:

  ```python
     def sum(a: int, b: int) -> int;
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

     import .models
  ```

- Sort imports in alphabetical order
- Use t-strings always. If python version doesn't have support for t-strings use f-strings
