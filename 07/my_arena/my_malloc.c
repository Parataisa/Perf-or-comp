#define _GNU_SOURCE

#include "my_malloc.h"
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>

#define ARENA_SIZE (10 * 1024 * 1024) 

typedef struct arena {
    size_t size;        // total size of the arena
    size_t used;        // amount of memory used
    char data[];        // array for the arena data
} arena_t;

// Global state
static arena_t* arena = NULL;

void* arena_malloc(size_t size) {
    if (size == 0) return NULL;
    
    // Initialize arena on first use
    if (!arena) {
        size_t total_size = sizeof(arena_t) + ARENA_SIZE;
        
        arena = (arena_t*)mmap(NULL, total_size, 
                              PROT_READ | PROT_WRITE, 
                              MAP_PRIVATE | MAP_ANONYMOUS, 
                              -1, 0);
        
        if (arena == MAP_FAILED) {
            return NULL;
        }
        
        arena->size = ARENA_SIZE;
        arena->used = 0;
        printf("Arena initialized with size: %d bytes\n", ARENA_SIZE);
    }
    
    // Align to 8 bytes
    size_t aligned_size = (size + 7) & ~7;
    
    if (arena->used + aligned_size > arena->size) {
        // Calculate the current and new total size
        size_t old_total = sizeof(arena_t) + arena->size;
        size_t new_total = sizeof(arena_t) + arena->size * 2;
        
        void* new_arena = mremap(arena, old_total, new_total, MREMAP_MAYMOVE);
        
        if (new_arena == MAP_FAILED) {
            perror("mremap failed");
            return NULL;
        }
        
        // Update arena pointer to the new location
        arena = (arena_t*)new_arena;
        arena->size *= 2;
        printf("Arena resized to: %lu bytes\n", arena->size);
    }
    
    void* ptr = &arena->data[arena->used];
    arena->used += aligned_size;
    
    return ptr;
}
void arena_free(void* ptr) {
    (void)ptr;
}

void* arena_calloc(size_t nmemb, size_t size) {
    size_t total = nmemb * size;
    void* ptr = arena_malloc(total);
    if (ptr) {
        memset(ptr, 0, total);
    }
    return ptr;
}

void* arena_realloc(void* ptr, size_t size) {
    if (!ptr) return arena_malloc(size);
    if (size == 0) return NULL;
    
    void* new_ptr = arena_malloc(size);
    if (!new_ptr) return NULL;
    
    return new_ptr;
}

void arena_cleanup(void) {
    if (arena) {
        munmap(arena, sizeof(arena_t) + arena->size);
        arena = NULL;
    }
}

void arena_reset(void) {
    if (arena) {
        arena->used = 0;
    }
}