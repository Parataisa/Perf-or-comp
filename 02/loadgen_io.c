#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <signal.h>

#define MAX_FILENAME_LENGTH 256
#define MAX_THREADS 16

// Global control flag for continuous operation
volatile int keep_running = 1;

typedef struct
{
    int thread_id;
    int read_percent;       // Percentage of read operations vs write
    int operation_delay_ms; // Delay between operations in milliseconds
    int file_size_min;
    int file_size_max;
    char base_dir[MAX_FILENAME_LENGTH];
} IOConfig;

// Signal handler to gracefully stop
void handle_signal(int sig)
{
    printf("\nReceived signal %d, shutting down...\n", sig);
    keep_running = 0;
}

void random_string(char *s, const int len)
{
    static const char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i = 0; i < len; i++)
    {
        int r = rand() % (int)(sizeof(charset) - 1);
        s[i] = charset[r];
    }
    s[len - 1] = '\0';
}

int random_number(int min, int max)
{
    return min + rand() % (max - min + 1);
}

void write_random_file(const char *filepath, int size)
{
    char *data = (char *)malloc(size);
    if (!data)
    {
        perror("Failed to allocate memory");
        return;
    }

    random_string(data, size);

    FILE *fp = fopen(filepath, "wb");
    if (!fp)
    {
        perror("Failed to open file for writing");
        free(data);
        return;
    }

    fwrite(data, 1, size, fp);
    fclose(fp);
    free(data);
}

void read_file(const char *filepath)
{
    FILE *fp = fopen(filepath, "rb");
    if (!fp)
    {
        return;
    }

    if (fseek(fp, 0, SEEK_END) != 0)
    {
        perror("Failed to seek to end of file");
        fclose(fp);
        return;
    }

    long size = ftell(fp);
    if (size < 0)
    {
        perror("Failed to get file size");
        fclose(fp);
        return;
    }

    if (fseek(fp, 0, SEEK_SET) != 0)
    {
        perror("Failed to seek to start of file");
        fclose(fp);
        return;
    }

    if (size <= 0 || size > 100 * 1024 * 1024)
    { // Limit to 100MB
        fclose(fp);
        return;
    }

    char *buffer = (char *)malloc(size);
    if (!buffer)
    {
        perror("Failed to allocate memory for reading");
        fclose(fp);
        return;
    }

    size_t bytes_read = fread(buffer, 1, size, fp);
    if (bytes_read != size)
    {
        if (ferror(fp))
        {
            perror("Error reading file");
        }
    }

    fclose(fp);
    free(buffer);
}

// In io_worker function:
void *io_worker(void *arg)
{
    IOConfig *config = (IOConfig *)arg;
    char filepath[MAX_FILENAME_LENGTH];
    int file_counter = 0;

    printf("Thread %d started with read_percent=%d%%, delay=%dms\n",
           config->thread_id, config->read_percent, config->operation_delay_ms);

    // Create thread directory with length checking
    char thread_dir[MAX_FILENAME_LENGTH];
    size_t base_len = strlen(config->base_dir);
    if (base_len + 15 >= MAX_FILENAME_LENGTH) {  
        fprintf(stderr, "Thread %d: Base directory path too long\n", config->thread_id);
        return NULL;
    }
    strcpy(thread_dir, config->base_dir);
    snprintf(thread_dir + base_len, MAX_FILENAME_LENGTH - base_len, 
             "/thread_%d", config->thread_id);
    
    mkdir(config->base_dir, 0777);   
    mkdir(thread_dir, 0777);         

    size_t thread_dir_len = strlen(thread_dir);

    while (keep_running)
    {
        int do_read = (random_number(1, 100) <= config->read_percent);

        if (thread_dir_len + 15 >= MAX_FILENAME_LENGTH) {  
            fprintf(stderr, "Thread %d: Thread directory path too long\n", config->thread_id);
            break;
        }
        
        strcpy(filepath, thread_dir);
        snprintf(filepath + thread_dir_len, MAX_FILENAME_LENGTH - thread_dir_len,
                 "/file_%d", file_counter++ % 1000);

        if (do_read)
        {
            read_file(filepath);
        }
        else
        {
            int size = random_number(config->file_size_min, config->file_size_max);
            write_random_file(filepath, size);
        }

        if (config->operation_delay_ms > 0)
        {
            usleep(config->operation_delay_ms * 1000); // Convert to microseconds
        }
    }

    printf("Thread %d shutting down\n", config->thread_id);
    return NULL;
}

int main(int argc, char **argv)
{
    int num_threads, read_percent, delay_ms, min_size, max_size, duration_sec;
    char base_dir[MAX_FILENAME_LENGTH] = "io_load";

    if (argc < 7)
    {
        fprintf(stderr, "Usage: %s <threads> <read_percent> <op_delay_ms> <min_file_size> <max_file_size> <duration_sec> [base_dir]\n\n", argv[0]);
        return 1;
    }

    num_threads = atoi(argv[1]);
    read_percent = atoi(argv[2]);
    delay_ms = atoi(argv[3]);
    min_size = atoi(argv[4]);
    max_size = atoi(argv[5]);
    duration_sec = atoi(argv[6]);

    if (argc >= 8)
    {
        strncpy(base_dir, argv[7], MAX_FILENAME_LENGTH - 1);
        base_dir[MAX_FILENAME_LENGTH - 1] = '\0';
    }

    // Validate parameters
    if (num_threads < 1 || num_threads > MAX_THREADS)
    {
        fprintf(stderr, "Error: threads must be between 1 and %d\n", MAX_THREADS);
        return 1;
    }

    if (read_percent < 0 || read_percent > 100)
    {
        fprintf(stderr, "Error: read_percent must be between 0 and 100\n");
        return 1;
    }

    if (min_size <= 0 || max_size <= 0 || min_size > max_size)
    {
        fprintf(stderr, "Error: invalid file size range\n");
        return 1;
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    srand(1234);

    mkdir(base_dir, 0777);
    printf("Starting I/O load generator with %d threads\n", num_threads);
    printf("Configuration: read_percent=%d%%, delay=%dms, file_size=%d-%d bytes\n",
           read_percent, delay_ms, min_size, max_size);

    pthread_t threads[MAX_THREADS];
    IOConfig configs[MAX_THREADS];

    for (int i = 0; i < num_threads; i++)
    {
        configs[i].thread_id = i;
        configs[i].read_percent = read_percent;
        configs[i].operation_delay_ms = delay_ms;
        configs[i].file_size_min = min_size;
        configs[i].file_size_max = max_size;
        snprintf(configs[i].base_dir, MAX_FILENAME_LENGTH, "%s", base_dir);

        if (pthread_create(&threads[i], NULL, io_worker, &configs[i]))
        {
            perror("Failed to create thread");
            return 1;
        }
    }

    if (duration_sec > 0)
    {
        printf("Running for %d seconds...\n", duration_sec);
        sleep(duration_sec);
        keep_running = 0;
    }
    else
    {
        printf("Running indefinitely. Press Ctrl+C to stop.\n");
    }

    for (int i = 0; i < num_threads; i++)
    {
        pthread_join(threads[i], NULL);
    }

    printf("I/O load generator finished\n");
    return 0;
}