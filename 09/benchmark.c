#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <stdbool.h>
#include "lib/benchmark.h"
#include "lib/args_parser.h"
#include "lib/container_registry.h"

size_t get_next_index(size_t current, size_t size) {
    return (current + 1) % (size > 0 ? size : 1); 
}

unsigned char* generate_sequence(double ins_del_ratio, double read_ratio, size_t length) {
    unsigned char* sequence = malloc(length * sizeof(unsigned char));
    if (!sequence) {
        fprintf(stderr, "Failed to allocate memory for operation sequence\n");
        exit(1);
    }
    
    size_t ins_del_ops = (size_t)(length * ins_del_ratio);
    ins_del_ops = ins_del_ops - (ins_del_ops % 2); 
    
    size_t read_write_ops = length - ins_del_ops;
    size_t read_ops = (size_t)(read_write_ops * read_ratio);
    size_t write_ops = read_write_ops - read_ops;
    
    size_t insert_ops = ins_del_ops / 2;
    size_t delete_ops = ins_del_ops / 2;
    
    printf("Operation distribution:\n");
    printf("  - Total: %zu operations\n", length);
    printf("  - Insert: %zu operations (%.1f%%)\n", insert_ops, 100.0 * insert_ops / length);
    printf("  - Delete: %zu operations (%.1f%%)\n", delete_ops, 100.0 * delete_ops / length);
    printf("  - Read: %zu operations (%.1f%%)\n", read_ops, 100.0 * read_ops / length);
    printf("  - Write: %zu operations (%.1f%%)\n", write_ops, 100.0 * write_ops / length);
    
    size_t index = 0;
    size_t r_count = 0, w_count = 0, i_count = 0, d_count = 0;
    
    while (index < length) {
        while (index + 10 <= length && 
               r_count + 4 <= read_ops && 
               w_count + 4 <= write_ops && 
               i_count + 1 <= insert_ops && 
               d_count + 1 <= delete_ops) {
            
            sequence[index++] = 0; r_count++;
            sequence[index++] = 1; w_count++;
            sequence[index++] = 0; r_count++;
            sequence[index++] = 1; w_count++;
            sequence[index++] = 2; i_count++;
            sequence[index++] = 0; r_count++;
            sequence[index++] = 1; w_count++;
            sequence[index++] = 0; r_count++;
            sequence[index++] = 1; w_count++;
            sequence[index++] = 3; d_count++;
        }
        
        if (index >= length) break;
        
        if (r_count < read_ops) {
            sequence[index++] = 0; r_count++;
        } else if (w_count < write_ops) {
            sequence[index++] = 1; w_count++;
        } else if (i_count < insert_ops) {
            sequence[index++] = 2; i_count++;
        } else if (d_count < delete_ops) {
            sequence[index++] = 3; d_count++;
        } else {
            sequence[index] = index % 2;
            index++;
        }
    }
    
    printf("Final operation counts:\n");
    printf("  - Insert: %zu\n", i_count);
    printf("  - Delete: %zu\n", d_count);
    printf("  - Read: %zu\n", r_count);
    printf("  - Write: %zu\n", w_count);
    
    return sequence;
}

double run_benchmark(Benchmark* benchmark, double seconds) {
    Container* container = &benchmark->container;
    
    container->init(container->data, benchmark->container_size);
    
    struct timeval start_time, current_time;
    gettimeofday(&start_time, NULL);
    
    size_t current_size = benchmark->container_size;
    size_t current_index = 0;
    size_t operations_completed = 0;
    volatile int result_accumulator = 0; 
    
    double elapsed = 0;
    while (elapsed < seconds * 1000.0) {
        unsigned char op = benchmark->operation_sequence[operations_completed % benchmark->sequence_length];
        
        switch (op) {
            case 0: // Read
                {
                    int value = container->read(container->data, current_index);
                    result_accumulator += value; 
                    current_index = get_next_index(current_index, current_size);
                }
                break;
                
            case 1: // Write
                {
                    int value = rand() % 10000;
                    container->write(container->data, current_index, value);
                    current_index = get_next_index(current_index, current_size);
                }
                break;
                
            case 2: // Insert
                {
                    int value = rand() % 10000;
                    container->insert(container->data, current_index, value);
                    current_size++;
                    current_index = get_next_index(current_index, current_size);
                }
                break;
                
            case 3: // Delete
                {
                    if (current_size > 0) {
                        container->delete(container->data, current_index);
                        current_size--;
                        if (current_size == 0) current_size = 1;
                        current_index = current_index % current_size;
                    }
                }
                break;
        }
        
        operations_completed++;
        
        if (operations_completed % 1000 == 0) {
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

int main(int argc, char *argv[]) {
    srand(time(NULL));
    
    init_container_registry();
    
    BenchmarkArgs args;
    if (parse_benchmark_args(argc, argv, &args) != 0) {
        cleanup_container_registry();
        printf("Error parsing arguments.\n");
        return 1;
    }
    
    Benchmark benchmark;
    if (initialize_benchmark(&args, &benchmark) != 0) {
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