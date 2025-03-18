# Performance Test Results

## System Information

- *Date:* 2025-03-18 22:45:06
- *OS:*Ubuntu 24.04.2 LTS on 5.15.167.4-microsoft-standard-WSL2
- *CPU:*AMD Ryzen 9 3900X 12-Core Processor
- *RAM:*15Gi total, 13Gi available
- *Execution Mode:* Local

## Notes on Methodology
- Each test performed  runs with statistical analysis
- Results available in CSV format at performance_results.csv 
- Cache clearing attempted between test runs for consistent measurements

## small_samples/delannoy/delannoy

Delannoy number calculation

### small_samples/delannoy/delannoy parameters justification
- Delannoy number calculation
- Selected parameters for this benchmark:
- `10`
- `11`
- `12`
- `13`
- `14`
- `15`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10` | 0.0097333 | 0.0048667 | 1.333e-04 | 3649 | 1.155e-04 | 0.0096000 | 0.0098000 | 1.300e-08 | High precision mode (50 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared |
| `11` | 0.0302000 | 0.0259333 | 3.333e-04 | 3619 | 5.291e-04 | 0.0296000 | 0.0306000 | 2.800e-07 | High precision mode (50 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared |
| `12` | 0.115667 | 0.116333 | 0.0010000 | 3653 | 0.0011547 | 0.115000 | 0.117000 | 1.333e-06 | High precision mode (10 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared |
| `13` | 0.593333 | 0.620000 | 1.000e-10 | 3643 | 0.0152753 | 0.580000 | 0.610000 | 2.333e-04 | Target precision of 0.10 reached after 3 runs, Cache cleared |
| `14` | 3.656667 | 3.870000 | 1.000e-10 | 3624 | 0.0461880 | 3.630000 | 3.710000 | 0.0021333 | Target precision of 0.10 reached after 3 runs, Cache cleared |
| `15` | 52.330000 | 52.783333 | 1.000e-10 | 3605 | 0.946942 | 51.600000 | 53.400000 | 0.896700 | Target precision of 0.10 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Small file benchmark

### small_samples/filegen/filegen parameters justification
- Small file benchmark
- Selected parameters for this benchmark:
- `5 10 1024 4096`
- `10 30 4096 16384`
- `20 50 16384 65536`
- `30 100 16384 1048576`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `5 10 1024 4096` | 0.0046000 | 6.667e-04 | 8.667e-04 | 3641 | 1.000e-04 | 0.0045000 | 0.0047000 | 1.000e-08 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared |
| `10 30 4096 16384` | 0.0587333 | 0.0328000 | 0.0236000 | 3616 | 0.0021385 | 0.0574000 | 0.0612000 | 4.573e-06 | High precision mode (50 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared |
| `20 50 16384 65536` | 0.546667 | 0.443333 | 0.116667 | 3628 | 0.0115470 | 0.540000 | 0.560000 | 1.333e-04 | Target precision of 0.10 reached after 3 runs, Cache cleared |
| `30 100 16384 1048576` | 19.467500 | 17.170000 | 2.445000 | 3650 | 1.787743 | 17.870000 | 21.190000 | 3.196025 | Target precision of 0.10 reached after 4 runs, Cache cleared |
## small_samples/filesearch/filesearch

Simple search test

### small_samples/filesearch/filesearch parameters justification
- Simple search test
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 6.250e-04 | 5.000e-05 | 1.500e-04 | 3637 | 5.000e-05 | 6.000e-04 | 7.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 4 runs, Cache cleared, Depends on: filegen 5 10 1024 4096 |
## small_samples/filesearch/filesearch

Medium complexity search

### small_samples/filesearch/filesearch parameters justification
- Medium complexity search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 6.500e-04 | 1.000e-04 | 7.500e-05 | 3622 | 5.773e-05 | 6.000e-04 | 7.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 4 runs, Cache cleared, Depends on: filegen 15 45 4096 32768 |
## small_samples/filesearch/filesearch

Deep directory search

### small_samples/filesearch/filesearch parameters justification
- Deep directory search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 6.250e-04 | 5.000e-05 | 1.500e-04 | 3636 | 5.000e-05 | 6.000e-04 | 7.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 4 runs, Cache cleared, Depends on: filegen 25 45 8192 16384 |
## small_samples/filesearch/filesearch

Large file search

### small_samples/filesearch/filesearch parameters justification
- Large file search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 6.250e-04 | 1.000e-04 | 1.000e-04 | 3629 | 5.000e-05 | 6.000e-04 | 7.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 4 runs, Cache cleared, Depends on: filegen 20 100 262144 1048576 |
## small_samples/filesearch/filesearch

Many small files search

### small_samples/filesearch/filesearch parameters justification
- Many small files search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 6.250e-04 | 1.000e-10 | 1.500e-04 | 3618 | 5.000e-05 | 6.000e-04 | 7.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 4 runs, Cache cleared, Depends on: filegen 20 100 512 4096 |
## small_samples/delannoy/delannoy

Delannoy number calculation

### small_samples/delannoy/delannoy parameters justification
- Delannoy number calculation
- Selected parameters for this benchmark:
- `10`
- `11`
- `12`
- `13`
- `14`
- `15`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10` | 0.207743 | 0.0176000 | 0.0024000 | 3678 | 0.0254243 | 0.182000 | 0.242000 | 6.464e-04 | High precision mode (50 iterations per measurement) Target precision of 0.10 reached after 7 runs, Cache cleared |
| `11` | 0.252560 | 0.0421600 | 0.0024400 | 3677 | 0.0278652 | 0.222800 | 0.284200 | 7.765e-04 | High precision mode (50 iterations per measurement) Target precision of 0.10 reached after 5 runs, Cache cleared |
| `12` | 0.283667 | 0.155667 | 0.0026667 | 3676 | 0.0125033 | 0.275000 | 0.298000 | 1.563e-04 | High precision mode (10 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared |
| `13` | 0.646667 | 0.640000 | 1.000e-10 | 3673 | 0.0057735 | 0.640000 | 0.650000 | 3.333e-05 | Target precision of 0.10 reached after 3 runs, Cache cleared |
| `14` | 3.833333 | 3.943333 | 0.0033333 | 3667 | 0.0152753 | 3.820000 | 3.850000 | 2.333e-04 | Target precision of 0.10 reached after 3 runs, Cache cleared |
| `15` | 57.073333 | 55.733333 | 0.0100000 | 3675 | 0.869617 | 56.070000 | 57.610000 | 0.756233 | Target precision of 0.10 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Small file benchmark

### small_samples/filegen/filegen parameters justification
- Small file benchmark
- Selected parameters for this benchmark:
- `5 10 1024 4096`
- `10 30 4096 16384`
- `20 50 16384 65536`
- `30 100 16384 1048576`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `5 10 1024 4096` | 0.0056667 | 7.667e-04 | 0.0013667 | 3637 | 1.155e-04 | 0.0056000 | 0.0058000 | 1.300e-08 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, With I/O load |
| `10 30 4096 16384` | 0.0666667 | 0.0346000 | 0.0315333 | 3620 | 2.309e-04 | 0.0664000 | 0.0668000 | 5.300e-08 | High precision mode (50 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, With I/O load |
| `20 50 16384 65536` | 0.590000 | 0.456667 | 0.153333 | 3629 | 0.0100000 | 0.580000 | 0.600000 | 1.000e-04 | Target precision of 0.10 reached after 3 runs, Cache cleared, With I/O load |
| `30 100 16384 1048576` | 20.573333 | 17.790000 | 3.390000 | 3605 | 1.413695 | 19.520000 | 22.180000 | 1.998533 | Target precision of 0.10 reached after 3 runs, Cache cleared, With I/O load |
## small_samples/filesearch/filesearch

Simple search test

### small_samples/filesearch/filesearch parameters justification
- Simple search test
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.667e-04 | 3.333e-05 | 2.333e-04 | 3603 | 5.773e-05 | 8.000e-04 | 9.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, Depends on: filegen 5 10 1024 4096, With I/O load |
## small_samples/filesearch/filesearch

Medium complexity search

### small_samples/filesearch/filesearch parameters justification
- Medium complexity search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.667e-04 | 1.000e-10 | 2.000e-04 | 3657 | 5.773e-05 | 8.000e-04 | 9.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, Depends on: filegen 15 45 4096 32768, With I/O load |
## small_samples/filesearch/filesearch

Deep directory search

### small_samples/filesearch/filesearch parameters justification
- Deep directory search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.667e-04 | 3.333e-05 | 1.667e-04 | 3621 | 5.773e-05 | 8.000e-04 | 9.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, Depends on: filegen 25 45 8192 16384, With I/O load |
## small_samples/filesearch/filesearch

Large file search

### small_samples/filesearch/filesearch parameters justification
- Large file search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.667e-04 | 6.667e-05 | 1.667e-04 | 3621 | 5.773e-05 | 8.000e-04 | 9.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, Depends on: filegen 20 100 262144 1048576, With I/O load |
## small_samples/filesearch/filesearch

Many small files search

### small_samples/filesearch/filesearch parameters justification
- Many small files search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.000e-04 | 3.333e-05 | 1.667e-04 | 3643 | 1.000e-10 | 8.000e-04 | 8.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.10 reached after 3 runs, Cache cleared, Depends on: filegen 20 100 512 4096, With I/O load |
