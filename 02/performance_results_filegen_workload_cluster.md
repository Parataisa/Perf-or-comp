# Performance Test Results

## System Information

- *Date:* 2025-03-18 18:30:05
- *OS:*Rocky Linux 8.10 (Green Obsidian) on 4.18.0-477.21.1.el8_8.x86_64
- *CPU:*Intel(R) Xeon(R) CPU           X5650  @ 2.67GHz
- *RAM:*62Gi total, 45Gi available
- *Execution Mode:* Cluster (SLURM)

## Notes on Methodology
- Each test performed  runs with statistical analysis
- Results available in CSV format at performance_results.csv 
- Cache clearing attempted between test runs for consistent measurements

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
| `5 10 1024 4096` | 0.425000 | 0 | 0 | 3492 | 5.000e-04 | 1.000e-10 | 0.0459891 | 0.360000 | Target precision of 0.05 reached after 20 runs , Cluster execution, Cache cleared |
| `10 30 4096 16384` | 2.520000 | .070000000 | .030000000 | 3464 | 0.0620000 | 0.0320000 | 0.0903327 | 2.440000 | Target precision of 0.05 reached after 5 runs , Cluster execution, Cache cleared |
| `20 50 16384 65536` | 9.085714 | .820000000 | .140000000 | 3432 | 0.820000 | 0.130000 | 0.535773 | 8.050000 | Target precision of 0.05 reached after 7 runs , Cluster execution, Cache cleared |
| `30 100 16384 1048576` | 48.624000 | 30.460000000 | 1.580000000 | 3448 | 30.542000 | 1.600000 | 1.111370 | 47.350000 | Target precision of 0.05 reached after 5 runs , Cluster execution, Cache cleared |
