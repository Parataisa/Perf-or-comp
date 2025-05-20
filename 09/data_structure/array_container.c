#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "lib/benchmark.h"

typedef struct {
    int* elements;
    size_t capacity;
    size_t size;
    size_t element_size;
    size_t current_pos;
} ArrayData;

int array_read(void* data, size_t index) {
    ArrayData* array = (ArrayData*)data;
    if (index >= array->size) {
        fprintf(stderr, "Error: Array read index out of bounds\n");
        return -1;
    }
    return array->elements[index];
}

void array_write(void* data, size_t index, int value) {
    ArrayData* array = (ArrayData*)data;
    if (index >= array->size) {
        fprintf(stderr, "Error: Array write index out of bounds\n");
        return;
    }
    array->elements[index] = value;
}

void array_insert(void* data, size_t index, int value) {
    ArrayData* array = (ArrayData*)data;
    if (index > array->size) {
        fprintf(stderr, "Error: Array insert index out of bounds\n");
        return;
    }
    
    if (array->size >= array->capacity) {
        fprintf(stderr, "Error: Array capacity reached\n");
        return;
    }
    
    if (index < array->size) {
        memmove(&array->elements[index + 1], 
                &array->elements[index], 
                (array->size - index) * sizeof(int));
    }
    
    array->elements[index] = value;
    array->size++;
}

void array_delete(void* data, size_t index) {
    ArrayData* array = (ArrayData*)data;
    if (index >= array->size) {
        fprintf(stderr, "Error: Array delete index out of bounds\n");
        return;
    }
    
    if (index < array->size - 1) {
        memmove(&array->elements[index], 
                &array->elements[index + 1], 
                (array->size - index - 1) * sizeof(int));
    }
    
    array->size--;
}

void array_init(void* data, size_t size) {
    ArrayData* array = (ArrayData*)data;
    array->capacity = size + 1;  
    array->size = size;
    array->current_pos = 0;
    
    array->elements = (int*)malloc(array->capacity * sizeof(int));
    if (!array->elements) {
        fprintf(stderr, "Error: Failed to allocate memory for array\n");
        exit(1);
    }
    
    for (size_t i = 0; i < size; i++) {
        array->elements[i] = rand() % 1000;
    }
}

void array_cleanup(void* data) {
    ArrayData* array = (ArrayData*)data;
    free(array->elements);
    array->elements = NULL;
    array->size = 0;
    array->capacity = 0;
    array->current_pos = 0;
}

Container create_array_container() {
    Container container;
    ArrayData* array_data = (ArrayData*)malloc(sizeof(ArrayData));
    if (!array_data) {
        fprintf(stderr, "Error: Failed to allocate memory for array container\n");
        exit(1);
    }
    
    array_data->elements = NULL;
    array_data->capacity = 0;
    array_data->size = 0;
    array_data->element_size = sizeof(int);
    array_data->current_pos = 0;
    
    container.data = array_data;
    container.element_size = sizeof(int);
    container.read = array_read;
    container.write = array_write;
    container.insert = array_insert;
    container.delete = array_delete;
    container.init = array_init;
    container.cleanup = array_cleanup;
    
    return container;
}