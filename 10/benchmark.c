#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <stdbool.h>
#include "benchmark.h"
#include "args_parser.h"
#include "container_registry.h"

size_t get_next_index(size_t current, size_t size)
{
    return (current + 1) % (size > 0 ? size : 1);
}

double run_benchmark(Benchmark *benchmark, double seconds)
{
    Container *container = &benchmark->container;

    container->init(container->data, benchmark->container_size, benchmark->container.element_size);

    struct timeval start_time, current_time;
    gettimeofday(&start_time, NULL);

    size_t current_size = benchmark->container_size;
    size_t current_index = 0;
    size_t safe_index = current_index % current_size;
    size_t operations_completed = 0;
    volatile int result_accumulator = 0;

    double elapsed = 0;
    while (elapsed < seconds * 1000.0)
    {
        unsigned char op = benchmark->operation_sequence[operations_completed % benchmark->sequence_length];

        switch (op)
        {
        case 0: // Read
        {
            safe_index = current_index % current_size;
            int value = container->read(container->data, safe_index);
            result_accumulator += value;
            current_index = get_next_index(current_index, current_size);
        }
        break;

        case 1: // Write
        {
            safe_index = current_index % current_size;
            int value = rand() % 10000;
            container->write(container->data, safe_index, value);
            current_index = get_next_index(current_index, current_size);
        }
        break;

        case 2: // Insert
        {
            safe_index = current_index % current_size;
            int value = rand() % 10000;
            int success = container->insert(container->data, safe_index, value);
            if (success == 0)
            {
                current_size++;
            }
            current_index = get_next_index(current_index, current_size);
        }
        break;

        case 3: // Delete
        {
            safe_index = current_index % current_size;
            int success = container->delete(container->data, safe_index);
            if (success == 0)
            {
                current_size--;
            }
            current_index = current_index % current_size;
        }
        break;
        }

        operations_completed++;

        if (operations_completed % 1000 == 0)
        {
            gettimeofday(&current_time, NULL);
            elapsed = (current_time.tv_sec - start_time.tv_sec) * 1000.0;
            elapsed += (current_time.tv_usec - start_time.tv_usec) / 1000.0;
        }
    }

    gettimeofday(&current_time, NULL);
    elapsed = (current_time.tv_sec - start_time.tv_sec) * 1000.0;
    elapsed += (current_time.tv_usec - start_time.tv_usec) / 1000.0;

    printf("Validation checksum: %d\n", result_accumulator);
    container->cleanup(container->data);

    return (double)operations_completed / (elapsed / 1000.0);
}

int main(int argc, char *argv[])
{
    srand(time(NULL));

    init_container_registry();

    BenchmarkArgs args;
    if (parse_benchmark_args(argc, argv, &args) != 0)
    {
        cleanup_container_registry();
        printf("Error parsing arguments.\n");
        return 1;
    }

    Benchmark benchmark;
    if (initialize_benchmark(&args, &benchmark) != 0)
    {
        cleanup_container_registry();
        printf("Error initializing benchmark.\n");
        return 1;
    }

    printf("\nRunning benchmark for %.1f seconds on container with %zu elements of size %zu bytes\n",
           args.benchmark_seconds, args.num_elements, args.element_size);
    printf("Operation mix: %.1f%% Insert/Delete, %.1f%% Read/Write\n",
           args.ins_del_ratio * 100.0,
           (1.0 - args.ins_del_ratio) * 100.0);
    printf("Within Read/Write: %.1f%% Read, %.1f%% Write\n",
           args.read_ratio * 100.0,
           (1.0 - args.read_ratio) * 100.0);

    double ops_per_second = run_benchmark(&benchmark, args.benchmark_seconds);

    printf("\nBenchmark Results:\n");
    printf("Operations per second: %.2f\n", ops_per_second);

    free(benchmark.operation_sequence);
    free(benchmark.container.data);

    cleanup_container_registry();

    return 0;
}