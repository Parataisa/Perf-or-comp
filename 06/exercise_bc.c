#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <x86intrin.h>

#define CACHE_LINE_SIZE 64

// Benchmark parameters
#define MIN_ARRAY_SIZE (512)                // Start with 512 bytes
#define MAX_ARRAY_SIZE (16 * 1024 * 1024)   // End with 16 MiB
#define ITERATIONS_PER_SIZE 20              // More iterations for better statistics
#define CHASE_ITERATIONS 1000000            // Pointer chase iterations

typedef struct CacheLineNode {
    struct CacheLineNode* next;
    char padding[CACHE_LINE_SIZE - sizeof(void*)];
} CacheLineNode;

double measure_cpu_freq_ghz() {
    uint64_t start_cycles, end_cycles;
    struct timespec start_time, end_time;
    
    printf("Measuring CPU frequency... ");
    fflush(stdout);
    
    clock_gettime(CLOCK_MONOTONIC, &start_time);
    start_cycles = __rdtsc();
    
    usleep(500000);  
    
    end_cycles = __rdtsc();
    clock_gettime(CLOCK_MONOTONIC, &end_time);
    
    double elapsed_seconds = (end_time.tv_sec - start_time.tv_sec) + 
                            (end_time.tv_nsec - start_time.tv_nsec) / 1e9;
    double freq_ghz = (end_cycles - start_cycles) / elapsed_seconds / 1e9;
    
    printf("Done!\n");
    printf("Estimated CPU frequency: %.2f GHz\n", freq_ghz);
    
    return freq_ghz;
}

CacheLineNode* create_random_chase_array(size_t array_size) {
    size_t num_nodes = array_size / sizeof(CacheLineNode);
    if (num_nodes < 2) num_nodes = 2; 
    
    printf("  Creating array with %zu nodes (%zu bytes)\n", num_nodes, num_nodes * sizeof(CacheLineNode));
    
    CacheLineNode* nodes = (CacheLineNode*)aligned_alloc(CACHE_LINE_SIZE, num_nodes * sizeof(CacheLineNode));
    if (!nodes) {
        fprintf(stderr, "Failed to allocate memory for chase array\n");
        exit(1);
    }
    
    size_t* permutation = (size_t*)malloc(num_nodes * sizeof(size_t));
    if (!permutation) {
        fprintf(stderr, "Failed to allocate permutation array\n");
        free(nodes);
        exit(1);
    }
    
    for (size_t i = 0; i < num_nodes; i++) {
        permutation[i] = i;
    }
    
    // Fisher-Yates shuffle to create random permutation https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    srand(time(NULL));
    for (size_t i = num_nodes - 1; i > 0; i--) {
        size_t j = rand() % (i + 1);
        size_t temp = permutation[i];
        permutation[i] = permutation[j];
        permutation[j] = temp;
    }
    
    for (size_t i = 0; i < num_nodes - 1; i++) {
        nodes[permutation[i]].next = &nodes[permutation[i + 1]];
    }
    
    nodes[permutation[num_nodes - 1]].next = &nodes[permutation[0]];
    
    free(permutation);
    return nodes;
}

void flush_caches() {
    size_t flush_size = 32 * 1024 * 1024;
    volatile unsigned char* cleaner = (volatile unsigned char*)malloc(flush_size);
    if (cleaner) {
        for (size_t i = 0; i < flush_size; i += CACHE_LINE_SIZE) {
            cleaner[i] = (unsigned char)i;
        }
        free((void*)cleaner);
    }
}

double measure_chase_latency(CacheLineNode* start, size_t iterations) {
    flush_caches();
    
    volatile CacheLineNode* p = start;
    for (size_t i = 0; i < 1000; i++) {
        p = (volatile CacheLineNode*)p->next;
    }
    
    uint64_t start_time = __rdtsc();
    for (size_t i = 0; i < iterations; i++) {
        p = (volatile CacheLineNode*)p->next;
        __asm__ volatile("" ::: "memory");  // Prevent compiler optimizations
    }
    uint64_t end_time = __rdtsc();
    
    // Prevent optimizing away the loop
    printf("  [Validation ptr: %p] ", (void*)p);
    return (double)(end_time - start_time) / iterations;
}

int main() {
    FILE* fp = fopen("memory_latency.csv", "w");
    if (!fp) {
        fprintf(stderr, "Error opening output file\n");
        return 1;
    }
    
    fprintf(fp, "Block Size (bytes),Latency (cycles),Latency (ns),Bandwidth (MB/s)\n");
    
    const double cpu_freq_ghz = measure_cpu_freq_ghz();
    
    printf("=== Memory Access Latency Benchmark ===\n");
    printf("CPU frequency: %.2f GHz\n", cpu_freq_ghz);
    printf("Testing block sizes from %d bytes to %d bytes\n", MIN_ARRAY_SIZE, MAX_ARRAY_SIZE);
    
    for (size_t array_size = MIN_ARRAY_SIZE; array_size <= MAX_ARRAY_SIZE; array_size *= 2) {
        printf("\nTesting block size: %zu bytes\n", array_size);
        double total_latency = 0;
        size_t valid_iterations = 0;
        
        for (int iter = 0; iter < ITERATIONS_PER_SIZE; iter++) {
            CacheLineNode* chase_array = create_random_chase_array(array_size);
            
            double latency = measure_chase_latency(chase_array, CHASE_ITERATIONS);
            printf("  Iteration %d: %.2f cycles (%d iterations)\n", 
                   iter, latency, CHASE_ITERATIONS);
            total_latency += latency;
            valid_iterations++;
            
            
            free(chase_array);
        }
        
        if (valid_iterations == 0) {
            printf("No valid measurements for this block size, skipping\n");
            continue;
        }
        
        double avg_latency = total_latency / valid_iterations;
        double latency_ns = avg_latency / cpu_freq_ghz;
        double bandwidth_mb_per_s = (CACHE_LINE_SIZE / latency_ns) * 1000;
        
        printf("Block size: %zu bytes - Average latency: %.2f cycles (%.2f ns)\n", 
               array_size, avg_latency, latency_ns);
        printf("Estimated bandwidth: %.2f MB/s\n", bandwidth_mb_per_s);
        
        fprintf(fp, "%zu,%.2f,%.2f,%.2f\n", array_size, avg_latency, latency_ns, bandwidth_mb_per_s);
    }
    
    fclose(fp);
    printf("\nResults saved to memory_latency.csv\n");
    
    return 0;
}