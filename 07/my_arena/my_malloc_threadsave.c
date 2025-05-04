#include "my_malloc.h"
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <pthread.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>

#define DEFAULT_ARENA_SIZE (1024 * 1024)
#define SIZE_MAX ((size_t)-1)
#define PAGE_SIZE (getpagesize())
#define ALIGN_TO_PAGE(size) (((size) + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1))

typedef struct arena {
    size_t size;        // total size of the arena
    size_t used;        // amount of memory used
    struct arena *next; // pointer to the next arena
    struct arena *prev; // pointer to the previous arena
    char data[];        // flexible array member for the arena data
} arena_t;

// Global state
static arena_t* current_arena = NULL;
static pthread_mutex_t arena_mutex = PTHREAD_MUTEX_INITIALIZER;

static void* os_alloc(size_t size) {
    size_t aligned_size = ALIGN_TO_PAGE(size);
    
    void* mem = mmap(NULL, aligned_size, 
                    PROT_READ | PROT_WRITE, 
                    MAP_PRIVATE | MAP_ANONYMOUS, 
                    -1, 0);
    
    if (mem == MAP_FAILED) {
        fprintf(stderr, "mmap failed: %s\n", strerror(errno));
        return NULL;
    }
    
    return mem;
}

// Free memory allocated with os_alloc
static void os_free(void* ptr, size_t size) {
    if (!ptr) return;
    
    size_t aligned_size = ALIGN_TO_PAGE(size);
    if (munmap(ptr, aligned_size) != 0) {
        fprintf(stderr, "munmap failed: %s\n", strerror(errno));
    }
}

// Allocate arena with flexible array member
static arena_t* arena_create(size_t size) {
    size_t total_size = sizeof(arena_t) + size;
    
    arena_t* arena = (arena_t*)os_alloc(total_size);
    if (!arena) return NULL;
    
    arena->size = size;
    arena->used = 0;
    arena->next = NULL;
    arena->prev = NULL;
    
    return arena;
}

void* arena_malloc(size_t size) {
    if (size == 0) return NULL;
    
    pthread_mutex_lock(&arena_mutex);
    
    // Make sure we have an arena
    if (!current_arena)
        current_arena = arena_create(size);
    if (!current_arena) {
        pthread_mutex_unlock(&arena_mutex);
        return NULL;
    }
    
    size_t total_size = size + sizeof(size_t);
    total_size = (total_size + 7) & ~7;
    
    if (current_arena->used + total_size > current_arena->size) {
        size_t new_size = (total_size > DEFAULT_ARENA_SIZE) ? total_size : DEFAULT_ARENA_SIZE;
        arena_t* new_arena = arena_create(new_size);
        
        if (!new_arena) {
            pthread_mutex_unlock(&arena_mutex);
            return NULL;
        }
        
        new_arena->prev = current_arena;
        current_arena->next = new_arena;
        current_arena = new_arena;
    }
    
    size_t* header = (size_t*)&current_arena->data[current_arena->used];
    
    *header = size;
    current_arena->used += total_size;
    void* result = header + 1;
    
    pthread_mutex_unlock(&arena_mutex);
    return result;
}

void* arena_calloc(size_t nmemb, size_t size) {
    size_t total;
    
    // Check for multiplication overflow
    if (nmemb > 0 && size > SIZE_MAX / nmemb) {
        return NULL;
    }
    
    total = nmemb * size;
    void* ptr = arena_malloc(total);
    if (ptr) {
        memset(ptr, 0, total);
    }
    return ptr;
}

void* arena_realloc(void* ptr, size_t size) {
    if (!ptr) return arena_malloc(size);
    if (size == 0) {
        return NULL;
    }
    
    // Get the header with original size
    size_t* header = ((size_t*)ptr) - 1;
    size_t old_size = *header;
    
    // If new size is smaller, just return the same pointer
    if (size <= old_size) {
        return ptr;
    }
    
    void* new_ptr = arena_malloc(size);
    if (!new_ptr) return NULL;
    
    memcpy(new_ptr, ptr, old_size);
    return new_ptr;
}

void arena_cleanup(void) {
    pthread_mutex_lock(&arena_mutex);
    
    while (current_arena) {
        arena_t* prev = current_arena->prev;
        os_free(current_arena, sizeof(arena_t) + current_arena->size);
        current_arena = prev;
    }
    
    pthread_mutex_unlock(&arena_mutex);
}