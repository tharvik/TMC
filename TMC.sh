#!/bin/bash

## TMC: Test Malloc in C

f=vm.c
CFLAGS="-std=c99"
VFLAGS=""

# patching
mv "$f" "$f".old

cat > "$f" <<-EOF
#include <stdlib.h>
#ifdef DEBUG
#ifndef MAX_ALLOC
	#error You have to define MAX_ALLOC
#else

static size_t counter = 0;
static void * tmalloc(size_t const size)
{
	if(counter++ == MAX_ALLOC)
		return NULL;
	else
		return malloc(size);
}

static void * tcalloc(size_t const nmemb, size_t const size)
{
	if(counter++ == MAX_ALLOC)
		return NULL;
	else
		return calloc(nmemb, size);
}

static void * trealloc(void * const ptr, size_t const size)
{
	if(counter++ == MAX_ALLOC)
		return NULL;
	else
		return realloc(ptr, size);
}

#define malloc(size) tmalloc(size)
#define calloc(nmemb, size) tcalloc(nmemb, size)
#define realloc(ptr, size) trealloc(ptr, size)

#endif
#endif
EOF

cat "$f" "$f".old > "$f".new
mv "$f".new "$f"

# compile and run
s=1
i=0
while [ $s -eq 1 ]
do
	gcc -g3 -Wall -Wextra -DMAX_ALLOC=$i -DDEBUG $CFLAGS \
		-Wno-unused-function "$f" &&
	valgrind $VFLAGS --leak-check=full --error-exitcode=2 ./a.out
	s=$?
	((i++))
done

#unpatch
mv "$f".old "$f"
