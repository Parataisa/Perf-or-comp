#define ARENA_MALLOC_H

#include <stdlib.h>

// Disable the default malloc/free
#define malloc arena_malloc
#define calloc arena_calloc
#define realloc arena_realloc
#define free arena_free

// Function declarations
void* arena_malloc(size_t size);
void* arena_calloc(size_t nmemb, size_t size);
void* arena_realloc(void* ptr, size_t size);
void arena_free(void* ptr);
void arena_reset(void);

// Arena cleanup function - call at program exit
void arena_cleanup(void);
