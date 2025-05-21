#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "lib/benchmark.h"

typedef struct Node
{
    int value;
    struct Node *next;
} Node;

typedef struct
{
    Node *head;
    size_t size;
    size_t element_size;
    Node *current;
    size_t current_index;
} LinkedListData;

static Node *get_node_at(LinkedListData *list, size_t index)
{
    if (index >= list->size || !list->head)
    {
        return NULL;
    }

    if (list->current && list->current_index <= index)
    {
        Node *node = list->current;
        size_t i = list->current_index;

        while (i < index)
        {
            if (!node->next)
                return NULL;
            node = node->next;
            i++;
        }

        list->current = node;
        list->current_index = index;
        return node;
    }
    else
    {
        Node *node = list->head;
        size_t i = 0;

        while (i < index)
        {
            if (!node->next)
                return NULL;
            node = node->next;
            i++;
        }

        list->current = node;
        list->current_index = index;
        return node;
    }
}

static int linkedlist_read(void *data, size_t index)
{
    LinkedListData *list = (LinkedListData *)data;

    if (list->size > 0)
    {
        index = index % list->size;
    }
    else
    {
        return -1;
    }

    Node *node = get_node_at(list, index);

    if (!node)
    {
        fprintf(stderr, "Error: Linked list read index out of bounds\n");
        return -1;
    }

    return node->value;
}

static void linkedlist_write(void *data, size_t index, int value)
{
    LinkedListData *list = (LinkedListData *)data;

    if (list->size > 0)
    {
        index = index % list->size;
    }
    else
    {
        fprintf(stderr, "Error: Cannot write to empty list\n");
        return;
    }

    Node *node = get_node_at(list, index);

    if (!node)
    {
        fprintf(stderr, "Error: Linked list write index out of bounds\n");
        return;
    }

    node->value = value;
}

static int linkedlist_insert(void *data, size_t index, int value)
{
    LinkedListData *list = (LinkedListData *)data;

    if (list->size > 0)
    {
        index = index % (list->size + 1);
    }

    if (index > list->size)
    {
        fprintf(stderr, "Error: Linked list insert index out of bounds\n");
        return -1;
    }

    Node *new_node = (Node *)malloc(sizeof(Node));
    if (!new_node)
    {
        fprintf(stderr, "Error: Failed to allocate memory for new node\n");
        return -1;
    }

    new_node->value = value;

    if (index == 0)
    {
        new_node->next = list->head;
        list->head = new_node;
    }
    else
    {
        Node *prev = get_node_at(list, index - 1);
        if (!prev)
        {
            free(new_node);
            fprintf(stderr, "Error: Failed to find node for insertion\n");
            return -1;
        }

        new_node->next = prev->next;
        prev->next = new_node;
    }

    list->size++;
    list->current = NULL;
    list->current_index = 0;
    return 0;
}

static int linkedlist_delete(void *data, size_t index)
{
    LinkedListData *list = (LinkedListData *)data;

    if (list->size > 0)
    {
        index = index % list->size;
    }
    else
    {
        fprintf(stderr, "Error: Cannot delete from empty list\n");
        return -1;
    }

    if (index >= list->size || !list->head)
    {
        fprintf(stderr, "Error: Linked list delete index out of bounds\n");
        return -1;
    }

    Node *to_delete;

    if (index == 0)
    {
        to_delete = list->head;
        list->head = list->head->next;
    }
    else
    {
        Node *prev = get_node_at(list, index - 1);
        if (!prev || !prev->next)
        {
            fprintf(stderr, "Error: Failed to find node for deletion\n");
            return -1;
        }

        to_delete = prev->next;
        prev->next = to_delete->next;
    }

    if (list->current == to_delete)
    {
        list->current = to_delete->next ? to_delete->next : list->head;
        list->current_index = list->current_index > 0 ? list->current_index - 1 : 0;
    }
    else if (list->current_index > index)
    {
        list->current_index--;
    }

    free(to_delete);
    list->size--;
    return 0;
}

static void linkedlist_init(void *data, size_t size, size_t element_size)
{
    LinkedListData *list = (LinkedListData *)data;
    list->head = NULL;
    list->size = 0;
    list->element_size = element_size;
    list->current = NULL;
    list->current_index = 0;

    if (size == 0)
        return;

    Node *prev = NULL;

    for (size_t i = 0; i < size; i++)
    {
        Node *new_node = (Node *)malloc(sizeof(Node));
        if (!new_node)
        {
            fprintf(stderr, "Error: Failed to allocate memory for linked list node\n");
            exit(1);
        }

        new_node->value = i % 1000;
        new_node->next = NULL;

        if (!list->head)
        {
            list->head = new_node;
        }
        else if (prev)
        {
            prev->next = new_node;
        }

        prev = new_node;
        list->size++;
    }

    list->current = list->head;
    list->current_index = 0;
}

static void linkedlist_cleanup(void *data)
{
    LinkedListData *list = (LinkedListData *)data;

    Node *current = list->head;
    while (current)
    {
        Node *next = current->next;
        free(current);
        current = next;
    }

    list->head = NULL;
    list->current = NULL;
    list->current_index = 0;
    list->size = 0;
}

Container create_linkedlist_sequential()
{
    Container container;
    LinkedListData *list_data = (LinkedListData *)malloc(sizeof(LinkedListData));
    if (!list_data)
    {
        fprintf(stderr, "Error: Failed to allocate memory for linked list container\n");
        exit(1);
    }

    list_data->head = NULL;
    list_data->size = 0;
    list_data->element_size = sizeof(int);
    list_data->current = NULL;
    list_data->current_index = 0;

    container.data = list_data;
    container.element_size = list_data->element_size;
    container.read = linkedlist_read;
    container.write = linkedlist_write;
    container.insert = linkedlist_insert;
    container.delete = linkedlist_delete;
    container.init = linkedlist_init;
    container.cleanup = linkedlist_cleanup;

    return container;
}