# Performance Test Results

## System Information

- *Date:* 2025-04-26 13:57:52
- *OS:*Rocky Linux 8.10 (Green Obsidian) on 4.18.0-477.21.1.el8_8.x86_64
- *CPU:*Intel(R) Xeon(R) CPU           X5650  @ 2.67GHz
- *RAM:*62Gi total, 44Gi available
- *Execution Mode:* Cluster (SLURM)

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
| `` | 73.040000 | 72.240000000 | .020000000 | 99768 | 72.843333 | 0.0166667 | 0.751132 | 72.450000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=8

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=8
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 14.203333 | 14.200000000 | .030000000 | 99784 | 14.123333 | 0.0300000 | 0.0471404 | 14.170000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=16

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=16
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 16.013333 | 15.920000000 | .030000000 | 99820 | 15.916667 | 0.0333333 | 0.0612826 | 15.940000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=32

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=32
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 19.770000 | 19.800000000 | .020000000 | 99836 | 19.703333 | 0.0233333 | 0.177951 | 19.520000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=64

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=64
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.593333 | 18.490000000 | .030000000 | 99840 | 18.530000 | 0.0233333 | 0.132749 | 18.450000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=128

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=128
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.333333 | 18.350000000 | .020000000 | 99840 | 18.273333 | 0.0266667 | 0.101434 | 18.190000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=256

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=256
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.090000 | 18.040000000 | .030000000 | 99816 | 18.016667 | 0.0300000 | 0.0432049 | 18.030000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=512

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=512
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 18.003333 | 17.820000000 | .030000000 | 99792 | 17.930000 | 0.0300000 | 0.0817856 | 17.890000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |


Tiling S=2048 T=1024

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=1024
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 61.900000 | 61.340000000 | .060000000 | 99844 | 61.653333 | 0.0566667 | 0.267333 | 61.620000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
## mmul/mmul_tiling

Tiling S=2048 T=2048

### mmul/mmul_tiling parameters justification
- Tiling S=2048 T=2048
- Selected parameters for this benchmark:



| Parameters | Avg Time (s) | User CPU (s) | System CPU (s) | Memory (KB) | Std Dev (s) | Min Time (s) | Max Time (s) | Variance (s²) | Notes |
|------------|--------------|--------------|----------------|-------------|-------------|-------------|-------------|--------------|-------|
| `` | 72.186667 | 71.630000000 | .070000000 | 99820 | 71.923333 | 0.0666667 | 0.448504 | 71.840000 | Target precision of 0.15 reached after 3 runs , Cluster execution, Cache cleared |
