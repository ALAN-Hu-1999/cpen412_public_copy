/* MALLOC.H for CC68K */

#ifndef __MALLOC_DEF_
#define __MALLOC_DEF_

#include <stddef.h>

typedef struct header {
    size_t size;
    struct header *next;
} HEADER;

extern char *_heap;
extern char *_stack;
extern HEADER *_allocp;

void *sbrk(size_t);
void *calloc(size_t, size_t);
void *malloc(size_t);
void *realloc(void *, size_t);
void free(void *);
unsigned long coreleft(void);

#endif