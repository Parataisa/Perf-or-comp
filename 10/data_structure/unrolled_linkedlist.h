#ifndef UNROLLED_LINKEDLIST_H
#define UNROLLED_LINKEDLIST_H

#include <stddef.h>
#include "lib/benchmark.h"

#define CHUNK_SIZE 32 // Define the default chunk size

typedef struct Chunk {
    void *data;           // Pointer to the array of integers
    size_t size;        // Current number of elements in the chunk
    struct Chunk *next; // Pointer to the next chunk
} Chunk;

typedef struct UnrolledLinkedList {
    Chunk *head;       // Pointer to the first chunk
    size_t chunk_count; // Number of chunks in the list
} UnrolledLinkedList;

// Function declarations
UnrolledLinkedList* create_unrolled_linkedlist();
void read_unrolled(void *data, size_t index);
void write_unrolled(void *data, size_t index, int value);
int insert_unrolled(void *data, size_t index, int value);
void delete_unrolled(void *data, size_t index);
void traverse_unrolled(UnrolledLinkedList *list);
void free_unrolled_linkedlist(UnrolledLinkedList *list);

#endif // UNROLLED_LINKEDLIST_H