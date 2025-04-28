# Performance Test Results

## System Information

- *Date:* 2025-04-28 16:54:24
- *OS:*Rocky Linux 8.10 (Green Obsidian) on 4.18.0-477.21.1.el8_8.x86_64
- *CPU:*Intel(R) Xeon(R) CPU           X5650  @ 2.67GHz
- *RAM:*46Gi total, 41Gi available
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
| `` | 72.573333 | 72.400000 | 0.0166667 | 99792 | 0.156950 | 72.450000 | 72.750000 | 0.0246333 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=8

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=8
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 14.260000 | 14.193333 | 0.0266667 | 99788 | 0.0624500 | 14.210000 | 14.330000 | 0.0039000 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=16

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=16
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 16.013333 | 15.936667 | 0.0266667 | 99809 | 0.0404145 | 15.990000 | 16.060000 | 0.0016333 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=32

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=32
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 19.980000 | 19.916667 | 0.0300000 | 99808 | 0.0173205 | 19.960000 | 19.990000 | 3.000e-04 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=64

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=64
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.776667 | 18.720000 | 0.0266667 | 99781 | 0.0602771 | 18.720000 | 18.840000 | 0.0036333 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=128

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=128
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.400000 | 18.330000 | 0.0300000 | 99807 | 0.0173205 | 18.380000 | 18.410000 | 3.000e-04 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=256

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=256
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.170000 | 18.103333 | 0.0266667 | 99816 | 0.0458258 | 18.120000 | 18.210000 | 0.0021000 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=512

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=512
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.070000 | 18.000000 | 0.0333333 | 99800 | 0.0519615 | 18.040000 | 18.130000 | 0.0027000 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=1024

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=1024
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 61.996667 | 61.783333 | 0.0500000 | 99813 | 0.550121 | 61.440000 | 62.540000 | 0.302633 | Target precision of 0.15 reached after 3 runs, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=2048

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=2048
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 72.753333 | 72.540000 | 0.0533333 | 99743 | 0.430387 | 72.490000 | 73.250000 | 0.185233 | Target precision of 0.15 reached after 3 runs, Cache cleared |
