#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "args_parser.h"
#include "benchmark.h"
#include "container_registry.h"

extern unsigned char* generate_sequence(double ins_del_ratio, double read_ratio, size_t length);

int parse_benchmark_args(int argc, char* argv[], BenchmarkArgs* args) {
    if (argc > 1 && strcmp(argv[1], "--list-containers") == 0) {
        list_available_containers();
        exit(0);
    }

    if (argc < 6) {
        printf("Usage: %s <container_type> <num_elements> <element_size> <ins_del_ratio> <read_ratio> [benchmark_seconds]\n", argv[0]);
        printf("       %s --list-containers\n", argv[0]);
        return 1;
    }

    strncpy(args->container_type, argv[1], sizeof(args->container_type) - 1);
    args->container_type[sizeof(args->container_type) - 1] = '\0';
    
    args->num_elements = strtoul(argv[2], NULL, 10);
    args->element_size = strtoul(argv[3], NULL, 10);
    args->ins_del_ratio = strtod(argv[4], NULL);
    args->read_ratio = strtod(argv[5], NULL);
    args->benchmark_seconds = (argc > 6) ? strtod(argv[6], NULL) : 5.0;

    return 0;
}

int initialize_benchmark(const BenchmarkArgs* args, Benchmark* benchmark) {
    benchmark->container_size = args->num_elements;
    benchmark->insert_delete_ratio = args->ins_del_ratio;
    benchmark->read_write_ratio = args->read_ratio;
    
    benchmark->operation_sequence = generate_sequence(args->ins_del_ratio, args->read_ratio, args->num_elements);
    benchmark->sequence_length = args->num_elements;
    
    Container* container = create_container_by_name(args->container_type);
    if (!container) {
        printf("Unknown container type '%s'. Use --list-containers to see options.\n", args->container_type);
        free(benchmark->operation_sequence);
        return 1;
    }
    
    benchmark->container = *container;
    free(container);
    
    benchmark->container.element_size = args->element_size;
    printf("Using container: %s\n", args->container_type);
    
    return 0;
}