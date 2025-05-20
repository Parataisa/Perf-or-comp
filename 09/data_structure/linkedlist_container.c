#include <stdlib.h>
#include <stdio.h>
#include "lib/benchmark.h"

typedef struct Node {
    int value;
    struct Node* next;
} Node;

typedef struct {
    Node* head;
    size_t size;
    size_t element_size;
    Node* current;       
    int allocation_policy; 
} LinkedListData;

static Node* get_node_at(LinkedListData* list, size_t index) {
    if (index >= list->size || !list->head) {
        return NULL;
    }
    
    Node* current = list->head;
    for (size_t i = 0; i < index; i++) {
        if (!current->next) return NULL;
        current = current->next;
    }
    
    return current;
}

int linkedlist_read(void* data, size_t index) {
    LinkedListData* list = (LinkedListData*)data;
    Node* node = get_node_at(list, index);
    
    if (!node) {
        fprintf(stderr, "Error: Linked list read index out of bounds\n");
        return -1;
    }
    
    return node->value;
}

void linkedlist_write(void* data, size_t index, int value) {
    LinkedListData* list = (LinkedListData*)data;
    Node* node = get_node_at(list, index);
    
    if (!node) {
        fprintf(stderr, "Error: Linked list write index out of bounds\n");
        return;
    }
    
    node->value = value;
}

void linkedlist_insert(void* data, size_t index, int value) {
    LinkedListData* list = (LinkedListData*)data;
    
    if (index > list->size) {
        fprintf(stderr, "Error: Linked list insert index out of bounds\n");
        return;
    }
    
    // Allocate a new node each time as specified
    Node* new_node = (Node*)malloc(sizeof(Node));
    if (!new_node) {
        fprintf(stderr, "Error: Failed to allocate memory for new node\n");
        return;
    }
    
    new_node->value = value;
    
    if (index == 0) {
        new_node->next = list->head;
        list->head = new_node;
    } else {
        Node* prev = get_node_at(list, index - 1);
        if (!prev) {
            free(new_node);
            fprintf(stderr, "Error: Failed to find node for insertion\n");
            return;
        }
        
        new_node->next = prev->next;
        prev->next = new_node;
    }
    
    list->size++;
}

void linkedlist_delete(void* data, size_t index) {
    LinkedListData* list = (LinkedListData*)data;
    
    if (index >= list->size || !list->head) {
        fprintf(stderr, "Error: Linked list delete index out of bounds\n");
        return;
    }
    
    Node* to_delete;
    
    if (index == 0) {
        to_delete = list->head;
        list->head = list->head->next;
    } else {
        Node* prev = get_node_at(list, index - 1);
        if (!prev || !prev->next) {
            fprintf(stderr, "Error: Failed to find node for deletion\n");
            return;
        }
        
        to_delete = prev->next;
        prev->next = to_delete->next;
    }
    
    if (list->current == to_delete) {
        list->current = to_delete->next ? to_delete->next : list->head;
    }
    
    free(to_delete);
    list->size--;
}

void linkedlist_init(void* data, size_t size) {
    LinkedListData* list = (LinkedListData*)data;
    list->head = NULL;
    list->size = 0;
    list->current = NULL;
    
    if (size == 0) return;
    
    if (list->allocation_policy == 0) {
        Node* prev = NULL;
        
        for (size_t i = 0; i < size; i++) {
            Node* new_node = (Node*)malloc(sizeof(Node));
            if (!new_node) {
                fprintf(stderr, "Error: Failed to allocate memory for linked list node\n");
                exit(1);
            }
            
            new_node->value = rand() % 1000;
            new_node->next = NULL;
            
            if (!list->head) {
                list->head = new_node;
            } else if (prev) {
                prev->next = new_node;
            }
            
            prev = new_node;
            list->size++;
        }
    } else {
        Node** nodes = (Node**)malloc(size * sizeof(Node*));
        if (!nodes) {
            fprintf(stderr, "Error: Failed to allocate memory for node pointers\n");
            exit(1);
        }
        
        for (size_t i = 0; i < size; i++) {
            nodes[i] = (Node*)malloc(sizeof(Node));
            if (!nodes[i]) {
                fprintf(stderr, "Error: Failed to allocate memory for linked list node\n");
                exit(1);
            }
            nodes[i]->value = rand() % 1000;
            nodes[i]->next = NULL;
        }
        
        for (size_t i = size - 1; i > 0; i--) {
            size_t j = rand() % (i + 1);
            Node* temp = nodes[i];
            nodes[i] = nodes[j];
            nodes[j] = temp;
        }
        
        for (size_t i = 0; i < size - 1; i++) {
            nodes[i]->next = nodes[i + 1];
        }
        
        list->head = nodes[0];
        list->size = size;
        
        free(nodes); 
    }
    
    list->current = list->head;
}

void linkedlist_cleanup(void* data) {
    LinkedListData* list = (LinkedListData*)data;
    
    Node* current = list->head;
    while (current) {
        Node* next = current->next;
        free(current);
        current = next;
    }
    
    list->head = NULL;
    list->current = NULL;
    list->size = 0;
}

Container create_linkedlist_container(int allocation_policy) {
    Container container;
    LinkedListData* list_data = (LinkedListData*)malloc(sizeof(LinkedListData));
    if (!list_data) {
        fprintf(stderr, "Error: Failed to allocate memory for linked list container\n");
        exit(1);
    }
    
    list_data->head = NULL;
    list_data->size = 0;
    list_data->element_size = sizeof(int);
    list_data->current = NULL;
    list_data->allocation_policy = allocation_policy;
    
    container.data = list_data;
    container.element_size = sizeof(int);
    container.read = linkedlist_read;
    container.write = linkedlist_write;
    container.insert = linkedlist_insert;
    container.delete = linkedlist_delete;
    container.init = linkedlist_init;
    container.cleanup = linkedlist_cleanup;
    
    return container;
}