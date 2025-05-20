#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "container_registry.h"

static ContainerFactory *registry_head = NULL;

void register_container(const char *name, const char *description,
                        Container (*create_function)(void))
{
    ContainerFactory *factory = malloc(sizeof(ContainerFactory));

    factory->name = strdup(name);
    factory->description = description ? strdup(description) : NULL;
    factory->create_function = create_function;
    factory->next = NULL;

    if (!registry_head)
    {
        registry_head = factory;
    }
    else
    {
        ContainerFactory *current = registry_head;
        while (current->next)
            current = current->next;
        current->next = factory;
    }
}

Container *create_container_by_name(const char *name)
{
    ContainerFactory *current = registry_head;
    while (current)
    {
        if (strcmp(current->name, name) == 0)
        {
            Container *container = malloc(sizeof(Container));
            *container = current->create_function();
            return container;
        }
        current = current->next;
    }

    return NULL;
}

void list_available_containers(void)
{
    printf("Available containers:\n");
    printf("%-20s | %s\n", "NAME", "DESCRIPTION");
    printf("--------------------+-------------------------\n");

    ContainerFactory *current = registry_head;
    while (current)
    {
        printf("%-20s | %s\n", current->name,
               current->description ? current->description : "");
        current = current->next;
    }
}

void init_container_registry(void)
{
    extern Container create_array_container();
    extern Container create_linkedlist_sequential();
    extern Container create_linkedlist_random();

    register_container("array", "Dynamic array container", create_array_container);
    register_container("linkedlist_seq", "Linked list with sequential allocation", create_linkedlist_sequential);
    register_container("linkedlist_rand", "Linked list with random allocation", create_linkedlist_random);
}

void cleanup_container_registry(void)
{
    ContainerFactory *current = registry_head;
    while (current)
    {
        ContainerFactory *next = current->next;
        free((void *)current->name);
        if (current->description)
            free((void *)current->description);
        free(current);
        current = next;
    }
    registry_head = NULL;
}