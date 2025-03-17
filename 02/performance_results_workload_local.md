# Performance Test Results

## System Information

- *Date:* 2025-03-17 20:43:21
- *OS:*Ubuntu 24.04.2 LTS on 5.15.167.4-microsoft-standard-WSL2
- *CPU:*AMD Ryzen 9 3900X 12-Core Processor
- *RAM:*15Gi total, 13Gi available
- *Execution Mode:* Local

## Notes on Methodology
- Each test performed  runs with statistical analysis
- Results available in CSV format at performance_results_workload.csv 
- Cache clearing attempted between test runs for consistent measurements

## small_samples/delannoy/delannoy

Delannoy number calculation

### small_samples/delannoy/delannoy parameters justification
- Delannoy number calculation
- Selected parameters for this benchmark:
- `10`
- `12`
- `13`
- `14`
- `15`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10` | 0.0198400 | 0.0138667 | 0.0030933 | 3611 | 4.000e-05 | 0.0198000 | 0.0198800 | 2.000e-09 | High precision mode (250 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `12` | 0.133867 | 0.126533 | 0.0035667 | 3616 | 6.429e-04 | 0.133400 | 0.134600 | 4.130e-07 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `13` | 0.646000 | 0.636000 | 1.000e-10 | 3623 | 0.0313050 | 0.620000 | 0.700000 | 9.800e-04 | Target precision of 0.05 reached after 5 runs, Cache cleared |
| `14` | 3.863333 | 3.853333 | 1.000e-10 | 3592 | 0.0208167 | 3.840000 | 3.880000 | 4.333e-04 | Target precision of 0.05 reached after 3 runs, Cache cleared |
| `15` | 54.783333 | 54.766667 | 0.0033333 | 3631 | 0.897905 | 53.930000 | 55.720000 | 0.806233 | Target precision of 0.05 reached after 3 runs, Cache cleared |

## small_samples/filegen/filegen

Small file benchmark

### small_samples/filegen/filegen parameters justification
- Small file benchmark
- Selected parameters for this benchmark:
- `5 10 1024 4096`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `5 10 1024 4096` | 0.0060800 | 6.533e-04 | 0.0015333 | 3552 | 1.039e-04 | 0.0060200 | 0.0062000 | 1.100e-08 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Medium file benchmark

### small_samples/filegen/filegen parameters justification
- Medium file benchmark
- Selected parameters for this benchmark:
- `10 30 4096 16384`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10 30 4096 16384` | 0.0721733 | 0.0350533 | 0.0323067 | 3587 | 6.661e-04 | 0.0716400 | 0.0729200 | 4.440e-07 | High precision mode (250 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Large file benchmark

### small_samples/filegen/filegen parameters justification
- Large file benchmark
- Selected parameters for this benchmark:
- `20 50 16384 65536`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `20 50 16384 65536` | 0.656667 | 0.470000 | 0.166667 | 3591 | 0.0152753 | 0.640000 | 0.670000 | 2.333e-04 | Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Mixed size benchmark

### small_samples/filegen/filegen parameters justification
- Mixed size benchmark
- Selected parameters for this benchmark:
- `30 60 16384 1048576`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `30 60 16384 1048576` | 12.746667 | 10.956667 | 1.773333 | 3579 | 0.0737111 | 12.690000 | 12.830000 | 0.0054333 | Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filesearch/filesearch

Simple search test

### small_samples/filesearch/filesearch parameters justification
- Simple search test
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0011933 | 1.333e-05 | 2.667e-04 | 3599 | 2.309e-05 | 0.0011800 | 0.0012200 | 1.000e-09 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 5 10 1024 4096 |
## small_samples/filesearch/filesearch

Medium complexity search

### small_samples/filesearch/filesearch parameters justification
- Medium complexity search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0022533 | 4.667e-05 | 4.067e-04 | 3533 | 4.163e-05 | 0.0022200 | 0.0023000 | 2.000e-09 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 15 45 4096 32768 |
## small_samples/filesearch/filesearch

Deep directory search

### small_samples/filesearch/filesearch parameters justification
- Deep directory search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0030200 | 1.000e-04 | 5.533e-04 | 3573 | 7.211e-05 | 0.0029600 | 0.0031000 | 5.000e-09 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 25 45 8192 16384 |
## small_samples/filesearch/filesearch

Large file search

### small_samples/filesearch/filesearch parameters justification
- Large file search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0027933 | 7.333e-05 | 5.067e-04 | 3541 | 1.102e-04 | 0.0027200 | 0.0029200 | 1.200e-08 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 20 50 262144 1048576 |
## small_samples/filesearch/filesearch

Many small files search

### small_samples/filesearch/filesearch parameters justification
- Many small files search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0043550 | 1.250e-04 | 0.0010250 | 3556 | 1.769e-04 | 0.0042600 | 0.0046200 | 3.100e-08 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 4 runs, Cache cleared, Depends on: filegen 20 100 512 4096 |
