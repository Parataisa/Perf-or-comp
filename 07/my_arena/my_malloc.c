#include "my_malloc.h"
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <pthread.h>

#define DEFAULT_ARENA_SIZE (1024 * 1024)
#define SIZE_MAX ((size_t)-1)

typedef struct arena {
    size_t size;        // total size of the arena
    size_t used;        // amount of memory used
    struct arena *next; // pointer to the next arena
    struct arena *prev; // pointer to the previous arena
    char data[];        // flexible array member for the arena data
} arena_t;

// Track allocations for realloc/free support
typedef struct alloc_info {
    void* ptr;             // pointer returned to user
    size_t size;           // size of allocation
    struct arena* arena;   // arena it belongs to
    struct alloc_info* next;
} alloc_info_t;

// Global state
static arena_t* current_arena = NULL;
static alloc_info_t* alloc_list = NULL;

// Mutex for thread safety
static pthread_mutex_t arena_mutex = PTHREAD_MUTEX_INITIALIZER;

// Get the real malloc
static void* system_malloc(size_t size) {
    static void* (*real_malloc)(size_t) = NULL;
    if (!real_malloc) {
        real_malloc = dlsym(RTLD_NEXT, "malloc");
        if (!real_malloc) {
            fprintf(stderr, "Error: failed to get real malloc\n");
            return NULL;
        }
    }
    return real_malloc(size);
}

// Get the real free function
static void system_free(void* ptr) {
    static void (*real_free)(void*) = NULL;
    if (!real_free) {
        real_free = dlsym(RTLD_NEXT, "free");
        if (!real_free) {
            fprintf(stderr, "Error: failed to get real free\n");
            return;
        }
    }
    real_free(ptr);
}

// Allocate arena with flexible array member
static arena_t* arena_create(size_t size) {
    arena_t* arena = (arena_t*)system_malloc(sizeof(arena_t) + size);
    if (!arena) return NULL;
    
    arena->size = size;
    arena->used = 0;
    arena->next = NULL;
    arena->prev = NULL;
    
    return arena;
}

void* arena_malloc(size_t size) {
    if (size == 0) return NULL;
    
    void* result = NULL;
    
    pthread_mutex_lock(&arena_mutex);
    
    // Make sure we have an arena
    if (!current_arena)
        current_arena = arena_create(DEFAULT_ARENA_SIZE);
    // If arena creation failed, unlock and return NULL
    if (!current_arena) {
        pthread_mutex_unlock(&arena_mutex);
        return NULL;
    }
    
    // Align size to 8-byte boundary
    size = (size + 7) & ~7;
    
    // Check if we need a new arena
    if (current_arena->used + size > current_arena->size) {
        size_t new_size = (size > DEFAULT_ARENA_SIZE) ? size : DEFAULT_ARENA_SIZE;
        arena_t* new_arena = arena_create(new_size);
        
        if (!new_arena) {
            pthread_mutex_unlock(&arena_mutex);
            return NULL;
        }
        
        new_arena->prev = current_arena;
        current_arena->next = new_arena;
        current_arena = new_arena;
    }
    
    // Allocate from the current arena
    result = &current_arena->data[current_arena->used];
    current_arena->used += size;
    
    // Track this allocation
    alloc_info_t* info = system_malloc(sizeof(alloc_info_t));
    if (info) {
        info->ptr = result;
        info->size = size;
        info->arena = current_arena;
        info->next = alloc_list;
        alloc_list = info;
    }
    
    pthread_mutex_unlock(&arena_mutex);
    return result;
}

void arena_free(void* ptr) {
    if (!ptr) return;
    
    pthread_mutex_lock(&arena_mutex);
    
    alloc_info_t** current = &alloc_list;
    while (*current) {
        if ((*current)->ptr == ptr) {
            alloc_info_t* to_free = *current;
            *current = to_free->next;
            system_free(to_free);
            pthread_mutex_unlock(&arena_mutex);
            return;
        }
        current = &(*current)->next;
    }
    
    pthread_mutex_unlock(&arena_mutex);
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
        arena_free(ptr);
        return NULL;
    }
    
    pthread_mutex_lock(&arena_mutex);
    
    alloc_info_t* info = NULL;
    for (alloc_info_t* cur = alloc_list; cur; cur = cur->next) {
        if (cur->ptr == ptr) {
            info = cur;
            break;
        }
    }
    
    if (!info) {
        pthread_mutex_unlock(&arena_mutex);
        return NULL;
    }
    
    // If new size is smaller, just return the same pointer
    if (size <= info->size) {
        pthread_mutex_unlock(&arena_mutex);
        return ptr;
    }
    
    pthread_mutex_unlock(&arena_mutex);
    
    // Otherwise allocate new space and copy data
    void* new_ptr = arena_malloc(size);
    if (!new_ptr) return NULL;
    
    memcpy(new_ptr, ptr, info->size);
    arena_free(ptr);
    
    return new_ptr;
}

void arena_cleanup(void) {
    pthread_mutex_lock(&arena_mutex);
    
    // Free all allocation tracking info
    while (alloc_list) {
        alloc_info_t* next = alloc_list->next;
        system_free(alloc_list);
        alloc_list = next;
    }
    
    // Free all arenas
    while (current_arena) {
        arena_t* prev = current_arena->prev;
        system_free(current_arena);
        current_arena = prev;
    }
    
    pthread_mutex_unlock(&arena_mutex);
}