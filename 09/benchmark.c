#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <stdbool.h>
#include "lib/benchmark.h"
#include "lib/args_parser.h"
#include "lib/container_registry.h"

size_t get_next_index(size_t current, size_t size)
{
    return (current + 1) % (size > 0 ? size : 1);
}

unsigned char *generate_sequence(double ins_del_ratio, double read_ratio, size_t length)
{
    unsigned char *sequence = malloc(length * sizeof(unsigned char));
    if (!sequence) {
        fprintf(stderr, "Failed to allocate memory for operation sequence\n");
        exit(1);
    }

    size_t num_patterns = length / 10;
    
    size_t index = 0;
    for (size_t i = 0; i < num_patterns; i++) {
        sequence[index++] = 0; // Read
        sequence[index++] = 1; // Write
        sequence[index++] = 0; // Read
        sequence[index++] = 1; // Write
        sequence[index++] = 2; // Insert
        sequence[index++] = 0; // Read
        sequence[index++] = 1; // Write
        sequence[index++] = 0; // Read
        sequence[index++] = 1; // Write
        sequence[index++] = 3; // Delete
    }
    
    // Fill remaining operations (less than 10)
    size_t remaining = length - (num_patterns * 10);
    if (remaining > 0) {
        if (remaining >= 1) sequence[index++] = 0; // Read
        if (remaining >= 2) sequence[index++] = 1; // Write
        if (remaining >= 3) sequence[index++] = 0; // Read
        if (remaining >= 4) sequence[index++] = 1; // Write
        if (remaining >= 5) sequence[index++] = 2; // Insert
        if (remaining >= 6) sequence[index++] = 0; // Read
        if (remaining >= 7) sequence[index++] = 1; // Write
        if (remaining >= 8) sequence[index++] = 0; // Read
        if (remaining >= 9) sequence[index++] = 1; // Write
    }
    
    size_t r_count = 0, w_count = 0, i_count = 0, d_count = 0;
    for (size_t i = 0; i < length; i++) {
        switch (sequence[i]) {
            case 0: r_count++; break;
            case 1: w_count++; break;
            case 2: i_count++; break;
            case 3: d_count++; break;
        }
    }
    
    double actual_ins_del_ratio = (i_count + d_count) / (double)length;
    double actual_read_ratio = r_count / (double)(r_count + w_count);
    
    printf("Operation distribution:\n");
    printf("  - Total: %zu operations\n", length);
    printf("  - Insert: %zu operations (%.1f%%)\n", i_count, 100.0 * i_count / length);
    printf("  - Delete: %zu operations (%.1f%%)\n", d_count, 100.0 * d_count / length);
    printf("  - Read: %zu operations (%.1f%%)\n", r_count, 100.0 * r_count / length);
    printf("  - Write: %zu operations (%.1f%%)\n", w_count, 100.0 * w_count / length);
    printf("Requested ins/del ratio: %.2f, Actual: %.2f\n", ins_del_ratio, actual_ins_del_ratio);
    printf("Requested read ratio: %.2f, Actual: %.2f\n", read_ratio, actual_read_ratio);

    printf("Final operation counts:\n");
    printf("  - Insert: %zu\n", i_count);
    printf("  - Delete: %zu\n", d_count);
    printf("  - Read: %zu\n", r_count);
    printf("  - Write: %zu\n", w_count);
    
    printf("Order of operations:\n");
    for (size_t i = 0; i < length; i++) {
        printf("%d ", sequence[i]);
        if ((i + 1) % 10 == 0)
            printf("\n");
    }
    printf("\n");

    return sequence;
}

unsigned char *generate_sequence_fixed(double ins_del_ratio, double read_ratio, size_t length)
{
    unsigned char *sequence = malloc(length * sizeof(unsigned char));
    if (!sequence) {
        fprintf(stderr, "❌ Failed to allocate memory for operation sequence\n");
        exit(1);
    }

    size_t ins_del_ops = (size_t)(length * ins_del_ratio);
    
    if (ins_del_ops % 2 != 0) {
        ins_del_ops = (ins_del_ops > 0) ? ins_del_ops - 1 : 0;
    }
    
    size_t insert_pairs = ins_del_ops / 2;  // Number of insert-delete pairs
    size_t read_write_ops = length - ins_del_ops;
    
    size_t read_ops = (size_t)(read_write_ops * read_ratio);
    size_t write_ops = read_write_ops - read_ops;
    
    printf("🎯 **Target Operation Distribution:**\n");
    printf("   📈 Insert-Delete Pairs: %zu pairs (%zu ops, %.1f%%)\n", 
           insert_pairs, ins_del_ops, 100.0 * ins_del_ops / length);
    printf("   📖 Read Operations: %zu (%.1f%%)\n", read_ops, 100.0 * read_ops / length);
    printf("   ✏️  Write Operations: %zu (%.1f%%)\n", write_ops, 100.0 * write_ops / length);
    printf("   📏 Total Length: %zu operations\n\n", length);
    
    size_t pos = 0;
    size_t remaining_reads = read_ops;
    size_t remaining_writes = write_ops;
    
    for (size_t pair = 0; pair < insert_pairs && pos < length; pair++) {
        sequence[pos++] = 2;  // Insert
        
        size_t remaining_pairs = insert_pairs - pair - 1;
        size_t remaining_positions = length - pos - 1;  

        size_t ops_for_this_section = 0;
        if (remaining_pairs > 0) {
            size_t reserved_for_remaining = remaining_pairs * 2;
            size_t available_for_rw = (remaining_positions > reserved_for_remaining) ? 
                                     remaining_positions - reserved_for_remaining : 0;
            
            ops_for_this_section = (remaining_reads + remaining_writes > 0) ? 
                                  (available_for_rw * (remaining_reads + remaining_writes)) / 
                                  (remaining_reads + remaining_writes + remaining_pairs * 2) : 0;
        } else {
            ops_for_this_section = remaining_reads + remaining_writes;
        }
        
        for (size_t i = 0; i < ops_for_this_section && pos < length - 1; i++) {
            if (remaining_reads > 0 && remaining_writes > 0) {

                double current_read_ratio = (double)remaining_reads / (remaining_reads + remaining_writes);
                if ((double)rand() / RAND_MAX < current_read_ratio) {
                    sequence[pos++] = 0;  // Read
                    remaining_reads--;
                } else {
                    sequence[pos++] = 1;  // Write
                    remaining_writes--;
                }
            } else if (remaining_reads > 0) {
                sequence[pos++] = 0;  // Read
                remaining_reads--;
            } else if (remaining_writes > 0) {
                sequence[pos++] = 1;  // Write
                remaining_writes--;
            }
        }
        
        if (pos < length) {
            sequence[pos++] = 3;  // Delete
        }
    }
    
    while (pos < length) {
        if (remaining_reads > 0 && remaining_writes > 0) {
            double current_read_ratio = (double)remaining_reads / (remaining_reads + remaining_writes);
            if ((double)rand() / RAND_MAX < current_read_ratio) {
                sequence[pos++] = 0;  // Read
                remaining_reads--;
            } else {
                sequence[pos++] = 1;  // Write
                remaining_writes--;
            }
        } else if (remaining_reads > 0) {
            sequence[pos++] = 0;  // Read
            remaining_reads--;
        } else if (remaining_writes > 0) {
            sequence[pos++] = 1;  // Write
            remaining_writes--;
        } else {
            break;
        }
    }
    
    // ✅ Verify actual counts and pairing
    size_t r_count = 0, w_count = 0, i_count = 0, d_count = 0;
    for (size_t i = 0; i < length; i++) {
        switch (sequence[i]) {
            case 0: r_count++; break;
            case 1: w_count++; break;
            case 2: i_count++; break;
            case 3: d_count++; break;
        }
    }
    
    // 🔍 Verify insert-delete pairing
    int unpaired_inserts = 0;
    int insert_balance = 0;
    printf("🔍 **Insert-Delete Pairing Verification:**\n");
    for (size_t i = 0; i < length; i++) {
        if (sequence[i] == 2) {  // Insert
            insert_balance++;
            printf("   📥 INSERT at position %zu (balance: %d)\n", i, insert_balance);
        } else if (sequence[i] == 3) {  // Delete
            insert_balance--;
            printf("   📤 DELETE at position %zu (balance: %d)\n", i, insert_balance);
        }
        if (insert_balance > 1) unpaired_inserts++;
    }
    
    double actual_ins_del_ratio = (i_count + d_count) / (double)length;
    double actual_read_ratio = (r_count + w_count > 0) ? r_count / (double)(r_count + w_count) : 0.0;
    
    printf("\n📊 **Final Operation Statistics:**\n");
    printf("   📈 Insert Operations: %zu (%.1f%%)\n", i_count, 100.0 * i_count / length);
    printf("   📉 Delete Operations: %zu (%.1f%%)\n", d_count, 100.0 * d_count / length);
    printf("   📖 Read Operations: %zu (%.1f%%)\n", r_count, 100.0 * r_count / length);
    printf("   ✏️  Write Operations: %zu (%.1f%%)\n", w_count, 100.0 * w_count / length);
    printf("   🎯 Requested ins/del ratio: %.2f → Actual: %.2f\n", ins_del_ratio, actual_ins_del_ratio);
    printf("   📚 Requested read ratio: %.2f → Actual: %.2f\n", read_ratio, actual_read_ratio);
    printf("   ⚖️  Insert-Delete Balance: %s\n", 
           (insert_balance == 0 && i_count == d_count) ? "✅ PERFECT" : "⚠️  IMBALANCED");
    
    printf("\n🔢 **Operation Sequence (first 50):**\n   ");
    for (size_t i = 0; i < length && i < 50; i++) {
        char op_char = (sequence[i] == 0) ? 'R' : (sequence[i] == 1) ? 'W' : 
                      (sequence[i] == 2) ? 'I' : 'D';
        printf("%c ", op_char);
        if ((i + 1) % 20 == 0) printf("\n   ");
    }
    if (length > 50) printf("...");
    printf("\n");

    return sequence;
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
            { // Assuming 0 return value means success
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