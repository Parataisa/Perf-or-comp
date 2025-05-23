#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "args_parser.h"
#include "benchmark.h"
#include "container_registry.h"

unsigned char *generate_sequence(double ins_del_ratio, double read_ratio, size_t length)
{
    unsigned char *sequence = malloc(length * sizeof(unsigned char));
    if (!sequence)
    {
        fprintf(stderr, "Failed to allocate memory for operation sequence\n");
        exit(1);
    }

    size_t num_patterns = length / 10;

    size_t index = 0;
    for (size_t i = 0; i < num_patterns; i++)
    {
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
    if (remaining > 0)
    {
        if (remaining >= 1)
            sequence[index++] = 0; // Read
        if (remaining >= 2)
            sequence[index++] = 1; // Write
        if (remaining >= 3)
            sequence[index++] = 0; // Read
        if (remaining >= 4)
            sequence[index++] = 1; // Write
        if (remaining >= 5)
            sequence[index++] = 2; // Insert
        if (remaining >= 6)
            sequence[index++] = 0; // Read
        if (remaining >= 7)
            sequence[index++] = 1; // Write
        if (remaining >= 8)
            sequence[index++] = 0; // Read
        if (remaining >= 9)
            sequence[index++] = 1; // Write
    }

    size_t r_count = 0, w_count = 0, i_count = 0, d_count = 0;
    for (size_t i = 0; i < length; i++)
    {
        switch (sequence[i])
        {
        case 0:
            r_count++;
            break;
        case 1:
            w_count++;
            break;
        case 2:
            i_count++;
            break;
        case 3:
            d_count++;
            break;
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
    for (size_t i = 0; i < length; i++)
    {
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
    if (!sequence)
    {
        fprintf(stderr, "❌ Failed to allocate memory for operation sequence\n");
        exit(1);
    }

    size_t ins_del_ops = (size_t)(length * ins_del_ratio);

    if (ins_del_ops % 2 != 0)
    {
        ins_del_ops = (ins_del_ops > 0) ? ins_del_ops - 1 : 0;
    }

    size_t insert_pairs = ins_del_ops / 2; // Number of insert-delete pairs
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

    for (size_t pair = 0; pair < insert_pairs && pos < length; pair++)
    {
        sequence[pos++] = 2; // Insert

        size_t remaining_pairs = insert_pairs - pair - 1;
        size_t remaining_positions = length - pos - 1;

        size_t ops_for_this_section = 0;
        if (remaining_pairs > 0)
        {
            size_t reserved_for_remaining = remaining_pairs * 2;
            size_t available_for_rw = (remaining_positions > reserved_for_remaining) ? remaining_positions - reserved_for_remaining : 0;

            ops_for_this_section = (remaining_reads + remaining_writes > 0) ? (available_for_rw * (remaining_reads + remaining_writes)) /
                                                                                  (remaining_reads + remaining_writes + remaining_pairs * 2)
                                                                            : 0;
        }
        else
        {
            ops_for_this_section = remaining_reads + remaining_writes;
        }

        for (size_t i = 0; i < ops_for_this_section && pos < length - 1; i++)
        {
            if (remaining_reads > 0 && remaining_writes > 0)
            {

                double current_read_ratio = (double)remaining_reads / (remaining_reads + remaining_writes);
                if ((double)rand() / RAND_MAX < current_read_ratio)
                {
                    sequence[pos++] = 0; // Read
                    remaining_reads--;
                }
                else
                {
                    sequence[pos++] = 1; // Write
                    remaining_writes--;
                }
            }
            else if (remaining_reads > 0)
            {
                sequence[pos++] = 0; // Read
                remaining_reads--;
            }
            else if (remaining_writes > 0)
            {
                sequence[pos++] = 1; // Write
                remaining_writes--;
            }
        }

        if (pos < length)
        {
            sequence[pos++] = 3; // Delete
        }
    }

    while (pos < length)
    {
        if (remaining_reads > 0 && remaining_writes > 0)
        {
            double current_read_ratio = (double)remaining_reads / (remaining_reads + remaining_writes);
            if ((double)rand() / RAND_MAX < current_read_ratio)
            {
                sequence[pos++] = 0; // Read
                remaining_reads--;
            }
            else
            {
                sequence[pos++] = 1; // Write
                remaining_writes--;
            }
        }
        else if (remaining_reads > 0)
        {
            sequence[pos++] = 0; // Read
            remaining_reads--;
        }
        else if (remaining_writes > 0)
        {
            sequence[pos++] = 1; // Write
            remaining_writes--;
        }
        else
        {
            break;
        }
    }

    size_t r_count = 0, w_count = 0, i_count = 0, d_count = 0;
    for (size_t i = 0; i < length; i++)
    {
        switch (sequence[i])
        {
        case 0:
            r_count++;
            break;
        case 1:
            w_count++;
            break;
        case 2:
            i_count++;
            break;
        case 3:
            d_count++;
            break;
        }
    }

    int unpaired_inserts = 0;
    int insert_balance = 0;
    for (size_t i = 0; i < length; i++)
    {
        if (sequence[i] == 2)
        { // Insert
            insert_balance++;
        }
        else if (sequence[i] == 3)
        { // Delete
            insert_balance--;
        }
        if (insert_balance > 1)
            unpaired_inserts++;
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
    for (size_t i = 0; i < length; i++)
    {
        char op_char = (sequence[i] == 0) ? 'R' : (sequence[i] == 1) ? 'W'
                                              : (sequence[i] == 2)   ? 'I'
                                                                     : 'D';
        printf("%c ", op_char);
        if ((i + 1) % 20 == 0)
            printf("\n   ");
    }
    printf("\n");

    return sequence;
}

int parse_benchmark_args(int argc, char *argv[], BenchmarkArgs *args)
{
    if (argc > 1 && strcmp(argv[1], "--list-containers") == 0)
    {
        list_available_containers();
        exit(0);
    }

    if (argc < 6)
    {
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

int initialize_benchmark(const BenchmarkArgs *args, Benchmark *benchmark)
{
    benchmark->container_size = args->num_elements;
    benchmark->insert_delete_ratio = args->ins_del_ratio;
    benchmark->read_write_ratio = args->read_ratio;

    benchmark->operation_sequence = generate_sequence_fixed(args->ins_del_ratio, args->read_ratio, args->num_elements);
    benchmark->sequence_length = args->num_elements;

    Container *container = create_container_by_name(args->container_type);
    if (!container)
    {
        printf("Unknown container type '%s'. Use --list-containers to see options.\n", args->container_type);
        free(benchmark->operation_sequence);
        return 1;
    }

    benchmark->container = *container;
    free(container);

    benchmark->container.element_size = args->element_size;
    printf("Using container: %s\n", args->container_type);
    printf("Container size: %zu\n", benchmark->container_size);
    printf("Element size: %zu\n", benchmark->container.element_size);
    printf("Total Memory: %zu bytes -> %zu MB\n", benchmark->container_size * benchmark->container.element_size,
           (benchmark->container_size * benchmark->container.element_size) / (1024 * 1024));

    return 0;
}