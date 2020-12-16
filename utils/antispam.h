
#ifndef IN_MEMORY_FILE_H
#define IN_MEMORY_FILE_H

#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

void getDomainBuffer(char* buf);

bool checkDomainCorrect(char *input_domain);

#endif // IN_MEMORY_FILE_H
