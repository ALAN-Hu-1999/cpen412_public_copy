/* STDDEF.H for CC68K */

#ifndef __STDDEF_DEF_
#define __STDDEF_DEF_

typedef int ptrdiff_t;
typedef unsigned size_t;

#define offsetof(s_name, m_name)  (size_t)&(((s_name *)0)->m_name)
#define NULL  (void *)0


#endif