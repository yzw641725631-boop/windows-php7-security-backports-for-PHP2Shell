#include "config.w32.h"
#include <php_stdint.h>
#define TIMELIB_OMIT_STDINT 1
#define HAVE_GETTIMEOFDAY 1
#include "zend.h"
#define timelib_malloc  emalloc
#define timelib_realloc erealloc
#define timelib_calloc  ecalloc
#define timelib_strdup  estrdup
#define timelib_free    efree
