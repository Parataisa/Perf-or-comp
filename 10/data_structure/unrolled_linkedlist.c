#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "unrolled_linkedlist.h"

typedef struct UnrolledNode {
    int *elements;             
    size_t count;              
    size_t chunk_size;         
    struct UnrolledNode *next; 
    struct UnrolledNode *prev; 
} UnrolledNode;

typedef struct {
    UnrolledNode *head;
    UnrolledNode *tail;
    size_t total_elements;
    size_t chunk_size;
    size_t element_size;
} UnrolledLinkedList;

UnrolledNode* create_node(size_t chunk_size) {
    UnrolledNode *node = (UnrolledNode*)malloc(sizeof(UnrolledNode));
    if (!node) return NULL;
    
    node->elements = (int*)calloc(chunk_size, sizeof(int));
    if (!node->elements) {
        free(node);
        return NULL;
    }
    
    node->count = 0;
    node->chunk_size = chunk_size;
    node->next = NULL;
    node->prev = NULL;
    
    return node;
}

static void free_node(UnrolledNode *node) {
    if (node) {
        free(node->elements);
        free(node);
    }
}

UnrolledNode* find_node_and_index(UnrolledLinkedList *list, size_t index, size_t *local_index) {
    if (index >= list->total_elements) return NULL;
    
    UnrolledNode *current = list->head;
    size_t accumulated = 0;
    
    while (current) {
        if (accumulated + current->count > index) {
            *local_index = index - accumulated;
            return current;
        }
        accumulated += current->count;
        current = current->next;
    }
    
    return NULL;
}

void split_node(UnrolledLinkedList *list, UnrolledNode *node) {
    if (node->count < node->chunk_size) return;
    
    UnrolledNode *new_node = create_node(node->chunk_size);
    if (!new_node) return;
    
    // Move half of the elements to the new node
    size_t split_point = node->count / 2;
    new_node->count = node->count - split_point;
    
    memcpy(new_node->elements, &node->elements[split_point], 
           new_node->count * sizeof(int));
    
    node->count = split_point;
    
    // Update links
    new_node->next = node->next;
    new_node->prev = node;
    
    if (node->next) {
        node->next->prev = new_node;
    } else {
        list->tail = new_node;
    }
    
    node->next = new_node;
}

void merge_nodes(UnrolledLinkedList *list, UnrolledNode *node) {
    if (!node || !node->next) return;
    
    // Only merge if combined size fits in one chunk
    if (node->count + node->next->count > node->chunk_size) return;
    
    UnrolledNode *next = node->next;
    
    // Copy elements from next node
    memcpy(&node->elements[node->count], next->elements, 
           next->count * sizeof(int));
    
    node->count += next->count;
    
    // Update links
    node->next = next->next;
    if (next->next) {
        next->next->prev = node;
    } else {
        list->tail = node;
    }
    
    free_node(next);
}

void unrolled_init(void *data, size_t size, size_t element_size) {
    UnrolledLinkedList *list = (UnrolledLinkedList*)data;
    
    list->head = NULL;
    list->tail = NULL;
    list->total_elements = 0;
    list->element_size = element_size;
    
    // Pre-allocate nodes for initial size
    if (size > 0) {
        size_t nodes_needed = (size + list->chunk_size - 1) / list->chunk_size;
        UnrolledNode *prev = NULL;
        
        for (size_t i = 0; i < nodes_needed; i++) {
            UnrolledNode *node = create_node(list->chunk_size);
            if (!node) break;
            
            if (!list->head) {
                list->head = node;
            } else {
                prev->next = node;
                node->prev = prev;
            }
            
            // Fill node with elements
            size_t elements_to_add = (i == nodes_needed - 1) ? 
                                   (size % list->chunk_size ? size % list->chunk_size : list->chunk_size) : 
                                   list->chunk_size;
            
            for (size_t j = 0; j < elements_to_add; j++) {
                node->elements[j] = 0;
            }
            node->count = elements_to_add;
            
            prev = node;
            list->tail = node;
        }
        
        list->total_elements = size;
    }
}

int unrolled_read(void *data, size_t index) {
    UnrolledLinkedList *list = (UnrolledLinkedList*)data;
    size_t local_index;
    
    UnrolledNode *node = find_node_and_index(list, index, &local_index);
    if (!node) return -1;
    
    return node->elements[local_index];
}

void unrolled_write(void *data, size_t index, int value) {
    UnrolledLinkedList *list = (UnrolledLinkedList*)data;
    size_t local_index;
    
    UnrolledNode *node = find_node_and_index(list, index, &local_index);
    if (!node) return;
    
    node->elements[local_index] = value;
}

int unrolled_insert(void *data, size_t index, int value) {
    UnrolledLinkedList *list = (UnrolledLinkedList*)data;
    
    // Handle empty list
    if (!list->head) {
        UnrolledNode *node = create_node(list->chunk_size);
        if (!node) return -1;
        
        node->elements[0] = value;
        node->count = 1;
        list->head = list->tail = node;
        list->total_elements = 1;
        return 0;
    }

    if (index >= list->total_elements) {
        UnrolledNode *node = list->tail;
        
        if (node->count < node->chunk_size) {
            node->elements[node->count++] = value;
        } else {
            // Need new node
            UnrolledNode *new_node = create_node(list->chunk_size);
            if (!new_node) return -1;
            
            new_node->elements[0] = value;
            new_node->count = 1;
            new_node->prev = node;
            node->next = new_node;
            list->tail = new_node;
        }
        
        list->total_elements++;
        return 0;
    }
    
    size_t local_index;
    UnrolledNode *node = find_node_and_index(list, index, &local_index);
    if (!node) return -1;
    
    if (node->count < node->chunk_size) {
        memmove(&node->elements[local_index + 1], 
                &node->elements[local_index], 
                (node->count - local_index) * sizeof(int));
        
        node->elements[local_index] = value;
        node->count++;
        list->total_elements++;
        return 0;
    }
    
    split_node(list, node);
    
    if (local_index >= node->count) {
        local_index -= node->count;
        node = node->next;
    }
    
    memmove(&node->elements[local_index + 1], 
            &node->elements[local_index], 
            (node->count - local_index) * sizeof(int));
    
    node->elements[local_index] = value;
    node->count++;
    list->total_elements++;
    
    return 0;
}

static int unrolled_delete(void *data, size_t index) {
    UnrolledLinkedList *list = (UnrolledLinkedList*)data;
    
    if (index >= list->total_elements) return -1;
    
    size_t local_index;
    UnrolledNode *node = find_node_and_index(list, index, &local_index);
    if (!node) return -1;
    
    memmove(&node->elements[local_index], 
            &node->elements[local_index + 1], 
            (node->count - local_index - 1) * sizeof(int));
    
    node->count--;
    list->total_elements--;
    
    if (node->count == 0) {
        if (node->prev) {
            node->prev->next = node->next;
        } else {
            list->head = node->next;
        }
        
        if (node->next) {
            node->next->prev = node->prev;
        } else {
            list->tail = node->prev;
        }
        
        free_node(node);
    } else if (node->count < node->chunk_size / 4) {
        merge_nodes(list, node);
    }
    
    return 0;
}

static void unrolled_cleanup(void *data) {
    UnrolledLinkedList *list = (UnrolledLinkedList*)data;
    
    UnrolledNode *current = list->head;
    while (current) {
        UnrolledNode *next = current->next;
        free_node(current);
        current = next;
    }
    
    list->head = NULL;
    list->tail = NULL;
    list->total_elements = 0;
}

Container create_unrolled_linkedlist(size_t chunk_size) {
    Container container;
    UnrolledLinkedList *list = (UnrolledLinkedList*)malloc(sizeof(UnrolledLinkedList));
    
    if (!list) {
        container.data = NULL;
        return container;
    }
    
    if (chunk_size == 0 || chunk_size > 1024) {
        free(list);
        container.data = NULL;
        return container;
    }
    
    list->chunk_size = chunk_size;
    list->head = NULL;
    list->tail = NULL;
    list->total_elements = 0;
    list->element_size = sizeof(int);
    
    container.data = list;
    container.element_size = sizeof(int);
    container.read = unrolled_read;
    container.write = unrolled_write;
    container.insert = unrolled_insert;
    container.delete = unrolled_delete;
    container.init = unrolled_init;
    container.cleanup = unrolled_cleanup;
    
    return container;
}