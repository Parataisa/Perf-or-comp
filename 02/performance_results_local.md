# Performance Test Results

## System Information

- *Date:* 2025-03-17 20:33:23
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
- `12`
- `13`
- `14`
- `15`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10` | 0.0107067 | 0.0062267 | 4.933e-04 | 3532 | 4.619e-05 | 0.0106800 | 0.0107600 | 2.000e-09 | High precision mode (250 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `12` | 0.122733 | 0.117600 | 6.333e-04 | 3541 | 5.686e-04 | 0.122100 | 0.123200 | 3.230e-07 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `13` | 0.623333 | 0.616667 | 1.000e-10 | 3587 | 0.0057735 | 0.620000 | 0.630000 | 3.333e-05 | Target precision of 0.05 reached after 3 runs, Cache cleared |
| `14` | 3.896667 | 3.890000 | 1.000e-10 | 3516 | 0.0152753 | 3.880000 | 3.910000 | 2.333e-04 | Target precision of 0.05 reached after 3 runs, Cache cleared |
| `15` | 53.790000 | 53.780000 | 0.0033333 | 3557 | 0.425793 | 53.380000 | 54.230000 | 0.181300 | Target precision of 0.05 reached after 3 runs, Cache cleared |


## small_samples/filegen/filegen

Small file benchmark

### small_samples/filegen/filegen parameters justification
- Small file benchmark
- Selected parameters for this benchmark:
- `5 10 1024 4096`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `5 10 1024 4096` | 0.0048133 | 5.933e-04 | 9.000e-04 | 3581 | 1.301e-04 | 0.0046800 | 0.0049400 | 1.700e-08 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Medium file benchmark

### small_samples/filegen/filegen parameters justification
- Medium file benchmark
- Selected parameters for this benchmark:
- `10 30 4096 16384`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10 30 4096 16384` | 0.0633067 | 0.0336533 | 0.0247467 | 3583 | 6.004e-04 | 0.0629600 | 0.0640000 | 3.610e-07 | High precision mode (250 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Large file benchmark

### small_samples/filegen/filegen parameters justification
- Large file benchmark
- Selected parameters for this benchmark:
- `20 50 16384 65536`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `20 50 16384 65536` | 0.590000 | 0.453333 | 0.120000 | 3521 | 0.0100000 | 0.580000 | 0.600000 | 1.000e-04 | Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filegen/filegen

Mixed size benchmark

### small_samples/filegen/filegen parameters justification
- Mixed size benchmark
- Selected parameters for this benchmark:
- `30 60 16384 1048576`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `30 60 16384 1048576` | 12.150000 | 10.393333 | 1.733333 | 3547 | 0.204206 | 11.920000 | 12.310000 | 0.0417000 | Target precision of 0.05 reached after 3 runs, Cache cleared |
## small_samples/filesearch/filesearch

Simple search test

### small_samples/filesearch/filesearch parameters justification
- Simple search test
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 9.733e-04 | 2.667e-05 | 1.867e-04 | 3597 | 1.155e-05 | 9.600e-04 | 9.800e-04 | 1.000e-10 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 5 10 1024 4096 |
## small_samples/filesearch/filesearch

Medium complexity search

### small_samples/filesearch/filesearch parameters justification
- Medium complexity search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0019467 | 4.000e-05 | 3.200e-04 | 3560 | 5.033e-05 | 0.0019000 | 0.0020000 | 3.000e-09 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 15 45 4096 32768 |
## small_samples/filesearch/filesearch

Deep directory search

### small_samples/filesearch/filesearch parameters justification
- Deep directory search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0026467 | 8.000e-05 | 5.000e-04 | 3561 | 6.429e-05 | 0.0026000 | 0.0027200 | 4.000e-09 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 25 45 8192 16384 |
## small_samples/filesearch/filesearch

Large file search

### small_samples/filesearch/filesearch parameters justification
- Large file search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0024480 | 1.080e-04 | 4.440e-04 | 3564 | 1.308e-04 | 0.0023000 | 0.0026200 | 1.700e-08 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 5 runs, Cache cleared, Depends on: filegen 20 50 262144 1048576 |
## small_samples/filesearch/filesearch

Many small files search

### small_samples/filesearch/filesearch parameters justification
- Many small files search
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 0.0038733 | 1.933e-04 | 8.600e-04 | 3573 | 1.155e-05 | 0.0038600 | 0.0038800 | 1.000e-10 | High precision mode (500 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 20 100 512 4096 |
