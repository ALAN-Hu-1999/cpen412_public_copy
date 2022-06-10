/* STDLIB.H for CC68K */

#ifndef __STDLIB_DEF_
#define __STDLIB_DEF_

#include <stddef.h>

#define max(a,b) (((a) > (b)) ? (a) : (b))
#define min(a,b) (((a) < (b)) ? (a) : (b))
#define abs(a)   (((a) < 0) ? -(a) : (a))

char *ltoa(long, char *, int);
char *ultoa(unsigned long, char *, int);
char *itoa(int, char *, int);
long strtol(char *, char **, int);
double strtod(char *, char **);
int atoi(char *);
long atol(char *);
int rand(void);
void srand(unsigned int);
void exit(int);

#endif