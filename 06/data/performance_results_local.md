# Performance Test Results

## System Information

- *Date:* 2025-04-25 14:07:31
- *OS:*Ubuntu 24.04.2 LTS on 5.15.167.4-microsoft-standard-WSL2
- *CPU:*AMD Ryzen 9 3900X 12-Core Processor
- *RAM:*15Gi total, 13Gi available
- *Execution Mode:* Local

## Notes on Methodology
- Each test performed  runs with statistical analysis
- Results available in CSV format at performance_results.csv 
- Cache clearing attempted between test runs for consistent measurements

## mmul/mmul

Baseline S=2048

### mmul/mmul parameters justification
- Baseline S=2048
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 89.946000 | 90.486000 | 0.0340000 | 99523 | 18.381176 | 64.550000 | 111.460000 | 337.867630 | Target precision of 0.15 not reached after 5 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=8

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=8
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 7.412000 | 6.860000 | 0.0260000 | 99560 | 1.027945 | 5.950000 | 8.760000 | 1.056670 | Target precision of 0.15 not reached after 5 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=16

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=16
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 12.780000 | 12.240000 | 0.0575000 | 99566 | 1.802572 | 11.210000 | 14.640000 | 3.249267 | Target precision of 0.15 reached after 4 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=32

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=32
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 25.200000 | 25.085000 | 0.0400000 | 99548 | 3.642463 | 22.100000 | 30.460000 | 13.267533 | Target precision of 0.15 reached after 4 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=64

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=64
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 52.000000 | 51.638000 | 0.0300000 | 99541 | 9.766752 | 43.050000 | 65.440000 | 95.389450 | Target precision of 0.15 not reached after 5 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=128

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=128
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 58.157500 | 57.872500 | 0.0325000 | 99529 | 8.156361 | 46.440000 | 63.870000 | 66.526225 | Target precision of 0.15 reached after 4 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=256

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=256
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 64.354000 | 64.456000 | 0.0200000 | 99550 | 19.195951 | 47.290000 | 91.280000 | 368.484530 | Target precision of 0.15 not reached after 5 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=512

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=512
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 72.894000 | 73.074000 | 0.0400000 | 99557 | 16.209049 | 52.490000 | 87.990000 | 262.733280 | Target precision of 0.15 not reached after 5 runs, Cache cleared |
