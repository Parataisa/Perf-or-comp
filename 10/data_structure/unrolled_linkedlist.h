#ifndef UNROLLED_LINKEDLIST_H
#define UNROLLED_LINKEDLIST_H

#include <stddef.h>
#include "benchmark.h"

#define DEFAULT_CHUNK_SIZE 32

typedef struct UnrolledNode UnrolledNode;

typedef struct UnrolledNode
{
    int *elements;             // Array of elements in this chunk
    size_t count;              // Current number of elements
    size_t capacity;           // Maximum elements this chunk can hold
    struct UnrolledNode *next; // Pointer to next chunk
    struct UnrolledNode *prev; // Pointer to previous chunk
} UnrolledNode;

typedef struct
{
    UnrolledNode *head;    // First chunk in the list
    UnrolledNode *tail;    // Last chunk in the list
    size_t total_elements; // Total elements across all chunks
    size_t chunk_capacity; // Default capacity for new chunks
} UnrolledLinkedList;

Container create_unrolled_linkedlist(size_t chunk_size);

#endif // UNROLLED_LINKEDLIST_H