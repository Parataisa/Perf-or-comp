#ifndef ARGS_PARSER_H
#define ARGS_PARSER_H

#include <stddef.h>
#include "benchmark.h"

typedef struct
{
    char container_type[32];  // Type of container (array, linkedlist_seq, linkedlist_rand)
    size_t num_elements;      // Initial number of elements in container
    size_t element_size;      // Size of each element in bytes
    double ins_del_ratio;     // Ratio of insert/delete operations (0.0-1.0)
    double read_ratio;        // Ratio of read operations within read/write operations (0.0-1.0)
    double benchmark_seconds; // Duration of benchmark in seconds
} BenchmarkArgs;

int parse_benchmark_args(int argc, char *argv[], BenchmarkArgs *args);
int initialize_benchmark(const BenchmarkArgs *args, Benchmark *benchmark);

#endif // ARGS_PARSER_H