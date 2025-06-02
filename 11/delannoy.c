#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef unsigned long dn;

dn delannoy(dn x, dn y)
{
    if (x == 0 || y == 0)
        return 1;

    dn a = delannoy(x - 1, y);
    dn b = delannoy(x - 1, y - 1);
    dn c = delannoy(x, y - 1);

    return a + b + c;
}

dn delannoy_memo(dn x, dn y)
{
    static dn **memo = NULL;
    static dn memo_size = 0;

    if (memo == NULL || memo_size <= x || memo_size <= y)
    {
        dn new_size = (x > y ? x : y) + 1;

        if (memo != NULL)
        {
            for (dn i = 0; i < memo_size; i++)
            {
                free(memo[i]);
            }
            free(memo);
        }

        memo = (dn **)malloc(new_size * sizeof(dn *));
        for (dn i = 0; i < new_size; i++)
        {
            memo[i] = (dn *)malloc(new_size * sizeof(dn));

            memo[i][0] = 1;
            if (i == 0)
            {
                for (dn j = 0; j < new_size; j++)
                {
                    memo[0][j] = 1;
                }
            }
        }
        memo_size = new_size;
    }

    if (memo[x][y] != 0)
    {
        return memo[x][y];
    }

    memo[x][y] = delannoy_memo(x - 1, y) + delannoy_memo(x - 1, y - 1) + delannoy_memo(x, y - 1);
    return memo[x][y];
}

dn delannoy_tabular(dn x, dn y)
{
    if (x == 0 || y == 0)
    {
        return 1;
    }

    dn *dp = (dn *)malloc((y + 1) * sizeof(dn));

    for (dn j = 0; j <= y; j++)
    {
        dp[j] = 1;
    }

    for (dn i = 1; i <= x; i++)
    {
        dn diagonal = 1;

        for (dn j = 1; j <= y; j++)
        {
            dn temp = dp[j];     // Save D(i-1, j) before overwriting
            dp[j] = dp[j]        // D(i-1, j)
                    + diagonal   // D(i-1, j-1)
                    + dp[j - 1]; // D(i, j-1)
            diagonal = temp;     // Update diagonal for next j
        }
    }

    dn result = dp[y];
    free(dp);
    return result;
}

dn DELANNOY_RESULTS[] = {
    1, 3, 13, 63, 321, 1683, 8989, 48639, 265729, 1462563, 8097453, 45046719, 251595969, 1409933619,
    7923848253, 44642381823, 252055236609, 1425834724419, 8079317057869, 45849429914943, 260543813797441,
    1482376214227923, 8443414161166173};

int NUM_RESULTS = sizeof(DELANNOY_RESULTS) / sizeof(dn);

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        printf("Usage: delannoy N [+t]\n");
        exit(-1);
    }

    int n = atoi(argv[1]);
    if (n >= NUM_RESULTS)
    {
        printf("N too large (can only check up to %d)\n", NUM_RESULTS);
        exit(-1);
    }
    int function_type = atoi(argv[2]);

    dn result = 0;
    struct timespec start, end;
    double cpu_time_used;

    clock_gettime(CLOCK_MONOTONIC, &start);

    switch (function_type)
    {
    case 0:
        result = delannoy(n, n);
        break;
    case 1:
        result = delannoy_memo(n, n);
        break;
    case 2:
        result = delannoy_tabular(n, n);
        break;
    default:
        printf("Error: Invalid function type.");
        return EXIT_FAILURE;
    }

    clock_gettime(CLOCK_MONOTONIC, &end);
    cpu_time_used = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("Time taken: %.9f seconds\n", cpu_time_used);

    if (result == DELANNOY_RESULTS[n])
    {
        printf("Verification: OK\n");
        return EXIT_SUCCESS;
    }
    printf("Verification: ERR\n");
    return EXIT_FAILURE;
}
