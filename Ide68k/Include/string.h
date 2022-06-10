/* STRING.H for CC68K */

#ifndef __STRING_DEF_
#define __STRING_DEF_

#include <stddef.h>

void *memset(void *, int, size_t);
void *memcpy(void *, const void *, size_t);
char *strcat(char *, const char *);
char *strchr(const char *, int);
int strcmp(const char *, const char *);
char *strcpy(char *, const char *);
int strcspn(const char *, const char *);
int strlen(const char *);
char *strupr(char *);
char *strlwr(char *);
char *strncat(char *, const char *, size_t);
int strncmp(const char *, const char *, size_t);
int strncmpi(const char *, const char *, size_t);
char *strncpy(char *, const char *, size_t);
int strnicmp(const char *, const char *, size_t);
char *strpbrk(char *, char *);
char *strrchr(char *, int);
char *strnset(char *, unt, size_t);
char *strpbrk(const char *, const char *);
char *strrchr(const char *, int);
char *strrev(char *);
char *strset(char *, int);
size_t strspn(const char *, const char *);
char *strstr(const char *, const char *);
double strtod(const char *, char **);
char *strtok(char *, const char *);
long strtol(const char *, char **, int);
unsigned long strtoul(const char *, char **, int);

#endif