# Performance Test Results

## System Information

- *Date:* 2025-03-19 14:05:55
- *OS:*Ubuntu 24.04.2 LTS on 5.15.167.4-microsoft-standard-WSL2
- *CPU:*AMD Ryzen 9 3900X 12-Core Processor
- *RAM:*15Gi total, 14Gi available
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


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10` | 0.0100000 | 0.0045333 | 4.000e-04 | 3632 | 1.000e-10 | 0.0100000 | 0.0100000 | 1.000e-10 | High precision mode (50 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `11` | 0.0300667 | 0.0266667 | 2.667e-04 | 3645 | 2.309e-04 | 0.0298000 | 0.0302000 | 5.300e-08 | High precision mode (50 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `12` | 0.116333 | 0.119333 | 3.333e-04 | 3615 | 0.0037859 | 0.112000 | 0.119000 | 1.433e-05 | High precision mode (10 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `13` | 0.556667 | 0.613333 | 1.000e-10 | 3624 | 0.0057735 | 0.550000 | 0.560000 | 3.333e-05 | Target precision of 0.05 reached after 3 runs, Cache cleared |
| `14` | 3.613333 | 3.790000 | 1.000e-10 | 3640 | 0.0378594 | 3.570000 | 3.640000 | 0.0014333 | Target precision of 0.05 reached after 3 runs, Cache cleared |
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
| `5 10 1024 4096` | 0.0046000 | 5.667e-04 | 9.667e-04 | 3625 | 1.732e-04 | 0.0045000 | 0.0048000 | 3.000e-08 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `10 30 4096 16384` | 0.0593333 | 0.0318000 | 0.0249333 | 3619 | 3.055e-04 | 0.0590000 | 0.0596000 | 9.300e-08 | High precision mode (50 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `20 50 16384 65536` | 0.543333 | 0.450000 | 0.110000 | 3664 | 0.0057735 | 0.540000 | 0.550000 | 3.333e-05 | Target precision of 0.05 reached after 3 runs, Cache cleared |
| `30 100 16384 1048576` | 20.624000 | 17.760000 | 2.910000 | 3618 | 0.984825 | 19.530000 | 21.690000 | 0.969880 | Target precision of 0.05 reached after 5 runs, Cache cleared |
## small_samples/filesearch/filesearch

Simple search test

### small_samples/filesearch/filesearch parameters justification
- Simple search test
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 7.000e-04 | 6.667e-05 | 1.333e-04 | 3648 | 1.000e-10 | 7.000e-04 | 7.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 5 10 1024 4096 |
## small_samples/filesearch/filesearch

Medium complexity search

### small_samples/filesearch/filesearch parameters justification
- Medium complexity search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 7.167e-04 | 3.333e-05 | 1.667e-04 | 3647 | 4.082e-05 | 7.000e-04 | 8.000e-04 | 2.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 6 runs, Cache cleared, Depends on: filegen 15 45 4096 32768 |
## small_samples/filesearch/filesearch

Deep directory search

### small_samples/filesearch/filesearch parameters justification
- Deep directory search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 7.375e-04 | 1.000e-04 | 1.125e-04 | 3622 | 5.175e-05 | 7.000e-04 | 8.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 8 runs, Cache cleared, Depends on: filegen 25 45 8192 16384 |
## small_samples/filesearch/filesearch

Large file search

### small_samples/filesearch/filesearch parameters justification
- Large file search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 7.556e-04 | 1.111e-05 | 1.889e-04 | 3610 | 5.270e-05 | 7.000e-04 | 8.000e-04 | 3.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 9 runs, Cache cleared, Depends on: filegen 20 100 262144 1048576 |
## small_samples/filesearch/filesearch

Many small files search

### small_samples/filesearch/filesearch parameters justification
- Many small files search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.000e-04 | 3.333e-05 | 1.667e-04 | 3596 | 1.000e-10 | 8.000e-04 | 8.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 20 100 512 4096 |
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


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `10` | 0.0181333 | 0.0120000 | 0.0016000 | 3685 | 5.033e-04 | 0.0176000 | 0.0186000 | 2.530e-07 | High precision mode (50 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `11` | 0.0360667 | 0.0310667 | 0.0013333 | 3645 | 4.163e-04 | 0.0356000 | 0.0364000 | 1.730e-07 | High precision mode (50 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `12` | 0.124000 | 0.122000 | 0.0010000 | 3667 | 0.0026458 | 0.121000 | 0.126000 | 7.000e-06 | High precision mode (10 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared |
| `13` | 0.616667 | 0.626667 | 1.000e-10 | 3676 | 0.0152753 | 0.600000 | 0.630000 | 2.333e-04 | Target precision of 0.05 reached after 3 runs, Cache cleared |
| `14` | 3.887000 | 3.836000 | 0.0010000 | 3667 | 0.864366 | 3.370000 | 6.330000 | 0.747129 | Target precision of 0.05 not reached after 40 runs, Cache cleared |
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
| `5 10 1024 4096` | 0.0056667 | 5.333e-04 | 0.0014667 | 3621 | 2.082e-04 | 0.0055000 | 0.0059000 | 4.300e-08 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, With I/O load |
| `10 30 4096 16384` | 0.0680000 | 0.0342667 | 0.0321333 | 3595 | 4.000e-04 | 0.0676000 | 0.0684000 | 1.600e-07 | High precision mode (50 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, With I/O load |
| `20 50 16384 65536` | 0.580000 | 0.523333 | 0.0933333 | 3655 | 1.100e-08 | 0.580000 | 0.580000 | 1.000e-10 | Target precision of 0.05 reached after 3 runs, Cache cleared, With I/O load |
| `30 100 16384 1048576` | 21.413333 | 18.043333 | 3.651667 | 3647 | 1.278447 | 20.200000 | 23.120000 | 1.634427 | Target precision of 0.05 reached after 6 runs, Cache cleared, With I/O load |
## small_samples/filesearch/filesearch

Simple search test

### small_samples/filesearch/filesearch parameters justification
- Simple search test
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 9.000e-04 | 3.333e-05 | 2.000e-04 | 3653 | 1.000e-10 | 9.000e-04 | 9.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 5 10 1024 4096, With I/O load |
## small_samples/filesearch/filesearch

Medium complexity search

### small_samples/filesearch/filesearch parameters justification
- Medium complexity search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 9.000e-04 | 1.000e-10 | 2.333e-04 | 3643 | 1.000e-10 | 9.000e-04 | 9.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 15 45 4096 32768, With I/O load |
## small_samples/filesearch/filesearch

Deep directory search

### small_samples/filesearch/filesearch parameters justification
- Deep directory search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 9.000e-04 | 1.000e-10 | 2.333e-04 | 3603 | 1.000e-10 | 9.000e-04 | 9.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 25 45 8192 16384, With I/O load |
## small_samples/filesearch/filesearch

Large file search

### small_samples/filesearch/filesearch parameters justification
- Large file search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 9.000e-04 | 3.333e-05 | 2.000e-04 | 3628 | 1.000e-10 | 9.000e-04 | 9.000e-04 | 1.000e-10 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 3 runs, Cache cleared, Depends on: filegen 20 100 262144 1048576, With I/O load |
## small_samples/filesearch/filesearch

Many small files search

### small_samples/filesearch/filesearch parameters justification
- Many small files search
- Selected parameters for this benchmark:
- `/tmp/benchmarks/generated/`


| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `/tmp/benchmarks/generated/` | 8.111e-04 | 4.444e-05 | 1.556e-04 | 3619 | 6.009e-05 | 7.000e-04 | 9.000e-04 | 4.000e-09 | High precision mode (100 iterations per measurement) Target precision of 0.05 reached after 9 runs, Cache cleared, Depends on: filegen 20 100 512 4096, With I/O load |
