#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <x86intrin.h>

#define CACHE_LINE_SIZE 64

// Benchmark parameters
#define MIN_BLOCK_SIZE (512)
#define MAX_BLOCK_SIZE (256 * 1024 * 1024) // 256 MiB for my home system
//#define MAX_BLOCK_SIZE (16 * 1024 * 1024)
#define ITERATIONS_PER_TEST 4
#define ARRAY_SIZE (1024 * 1024 * 1024) // 512 MiB for my home system
//#define ARRAY_SIZE (128 * 1024 * 1024)
#define MEASURE_ACCESSES 1000000

#define PRIME_NUMBER 7919 // A large prime number for randomization


typedef struct {
    void* next_ptr;              
    char padding[CACHE_LINE_SIZE - sizeof(void*)];
} Pointer;

double measure_cpu_freq_ghz() {
    uint64_t start_cycles, end_cycles;
    double elapsed_seconds;
    
    printf("Measuring CPU frequency... ");
    fflush(stdout);

    struct timespec start_time, end_time;
    
    clock_gettime(CLOCK_MONOTONIC, &start_time);
    start_cycles = __rdtsc();
    
    usleep(500000);
    
    end_cycles = __rdtsc();
    clock_gettime(CLOCK_MONOTONIC, &end_time);
    
    elapsed_seconds = (end_time.tv_sec - start_time.tv_sec) + 
                      (end_time.tv_nsec - start_time.tv_nsec) / 1e9;
    double freq_ghz = (end_cycles - start_cycles) / elapsed_seconds / 1e9;
    
    printf("Done!\n");
    printf("Estimated CPU frequency: %.2f GHz\n", freq_ghz);
    
    return freq_ghz;
}

Pointer* create_chase_array(size_t block_size, size_t array_size) {
    size_t num_elements = array_size / sizeof(Pointer);
    printf("Creating array with %zu elements (%zu bytes)\n", num_elements, array_size);
    
    Pointer* array = (Pointer*)aligned_alloc(CACHE_LINE_SIZE, array_size);
    if (!array) {
        fprintf(stderr, "Failed to allocate memory\n");
        exit(1);
    }
    
    size_t stride_elements = block_size / sizeof(Pointer);
    if (stride_elements < 1) stride_elements = 1;
    printf("Using stride of %zu elements (%zu bytes)\n", stride_elements, stride_elements * sizeof(Pointer));
    
    
    // Create a permutation array for pseudorandom access while maintaining stride distance
    size_t* permutation = (size_t*)malloc(num_elements * sizeof(size_t));
    if (!permutation) {
        fprintf(stderr, "Failed to allocate permutation array\n");
        free(array);
        exit(1);
    }
    
    // Initialize with sequential indices
    for (size_t i = 0; i < num_elements; i++) {
        permutation[i] = i;
    }
    
    // Create a pseudorandom permutation using the Fisher-Yates shuffle algorithm
    // but ensure the permutation respects our stride requirement
    srand(time(NULL));
    for (size_t i = 0; i < num_elements; i++) {
        size_t j = ((i * PRIME_NUMBER) + rand()) % num_elements;
        
        size_t temp = permutation[i];
        permutation[i] = permutation[j];
        permutation[j] = temp;
    }
    
    for (size_t i = 0; i < num_elements - 1; i++) {
        array[permutation[i]].next_ptr = &array[permutation[i + 1]];
    }
    array[permutation[num_elements - 1]].next_ptr = &array[permutation[0]];
    
    free(permutation);
    return array;
}

double measure_chase_latency(Pointer* start, size_t num_accesses) {
    volatile unsigned char* cleaner = (volatile unsigned char*)malloc(MAX_BLOCK_SIZE * 4);
    for (size_t i = 0; i < MAX_BLOCK_SIZE * 4; i += CACHE_LINE_SIZE) {
        cleaner[i] = (unsigned char)i;
    }
    free((void*)cleaner);
    
    volatile Pointer* p = start;
    
    uint64_t start_time = __rdtsc();
    
    for (size_t i = 0; i < num_accesses; i++) {
        p = (volatile Pointer*)p->next_ptr;
        __asm__ volatile("" ::: "memory");
    }
    
    uint64_t end_time = __rdtsc();
    
    // Prevent the compiler from optimizing away the loop by using its result
    printf("  [Validation ptr: %p] ", (void*)p);
    
    // Calculate average cycles per memory access
    return (double)(end_time - start_time) / num_accesses;
}

int main() {
    FILE* fp = fopen("cache_latency.csv", "w");
    if (!fp) {
        fprintf(stderr, "Error opening output file\n");
        return 1;
    }
    
    fprintf(fp, "Block Size (bytes),Latency (cycles),Latency (ns),Bandwidth (MB/s)\n");
    
    const double cpu_freq_ghz = measure_cpu_freq_ghz();
    
    printf("=== Cache Latency Benchmark ===\n");
    printf("CPU frequency: %.2f GHz\n", cpu_freq_ghz);
    printf("Testing block sizes from %d bytes to %d bytes\n", MIN_BLOCK_SIZE, MAX_BLOCK_SIZE);
    
    for (size_t block_size = MIN_BLOCK_SIZE; block_size <= MAX_BLOCK_SIZE; block_size *= 2) {
        printf("\nTesting block size: %zu bytes\n", block_size);
        double min_latency = 1e9; 
        
        for (int iter = 0; iter < ITERATIONS_PER_TEST; iter++) {
            Pointer* chase_array = create_chase_array(block_size, ARRAY_SIZE);
            
            double latency = measure_chase_latency(chase_array, MEASURE_ACCESSES);
            printf("  Iteration %d: %.2f cycles\n", iter, latency);
            
            if (latency < min_latency) {
                min_latency = latency;
            }
            
            free(chase_array);
        }
        
        // Calculate derived metrics
        double latency_ns = min_latency / cpu_freq_ghz;
        double bandwidth_mb_per_s = (CACHE_LINE_SIZE / latency_ns) * 1000;
        
        printf("Block size: %zu bytes - Best latency: %.2f cycles (%.2f ns)\n", 
               block_size, min_latency, latency_ns);
        printf("Estimated bandwidth: %.2f MB/s\n", bandwidth_mb_per_s);
        
        fprintf(fp, "%zu,%.2f,%.2f,%.2f\n", block_size, min_latency, latency_ns, bandwidth_mb_per_s);
    }
    
    fclose(fp);
    printf("\nResults saved to cache_latency.csv\n");
    printf("Clock speed: %.2f GHz\n", cpu_freq_ghz);
    
    return 0;
}