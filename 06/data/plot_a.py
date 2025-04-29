import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import re

df = pd.read_csv("performance_results_local.csv")

def extract_tiling_size(program):
    match = re.search(r'_-DT=(\d+)', program)
    if match:
        return int(match.group(1))
    return 0

df['Tiling_Size'] = df['Program'].apply(extract_tiling_size)
baseline = df[df['Tiling_Size'] == 0].copy()
tiled = df[df['Tiling_Size'] > 0].copy()

time_column = 'Avg Time (s)'
baseline_time = baseline[time_column].values[0]
print(f"Baseline time: {baseline_time:.2f}s")

df['Speedup'] = baseline_time / df[time_column]
tiled['Speedup'] = baseline_time / tiled[time_column]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

baseline_label = f"Baseline (No Tiling): {baseline_time:.2f}s"
ax1.axhline(y=baseline_time, color='r', linestyle='--', label=baseline_label)

tiled = tiled.sort_values('Tiling_Size')

ax1.plot(tiled['Tiling_Size'], tiled[time_column], 'bo-', markersize=8)
ax1.errorbar(tiled['Tiling_Size'], tiled[time_column], 
            yerr=tiled['Std Dev (s)'], fmt='none', capsize=5, color='b', alpha=0.5)
for i, row in tiled.iterrows():
    ax1.annotate(f"{row[time_column]:.2f}s", 
                 (row['Tiling_Size'], row[time_column]),
                 textcoords="offset points", 
                 xytext=(0,10), 
                 ha='center')

ax1.set_title('Matrix Multiplication Performance (S=2048)', fontsize=14)
ax1.set_xlabel('Tile Size (T)', fontsize=12)
ax1.set_ylabel('Average Execution Time (seconds)', fontsize=12)

if len(tiled['Tiling_Size'].unique()) > 1:
    ax1.set_xscale('log', base=2)

ax1.set_xticks(tiled['Tiling_Size'])
ax1.set_xticklabels(tiled['Tiling_Size'])
ax1.grid(True, alpha=0.3)
ax1.legend()

ax2.plot(tiled['Tiling_Size'], tiled['Speedup'], 'go-', markersize=8)
for i, row in tiled.iterrows():
    ax2.annotate(f"{row['Speedup']:.2f}x", 
                 (row['Tiling_Size'], row['Speedup']),
                 textcoords="offset points", 
                 xytext=(0,10), 
                 ha='center')

ax2.set_title('Speedup Relative to Baseline', fontsize=14)
ax2.set_xlabel('Tile Size (T)', fontsize=12)
ax2.set_ylabel('Speedup (x times faster)', fontsize=12)

if len(tiled['Tiling_Size'].unique()) > 1:
    ax2.set_xscale('log', base=2)

ax2.set_xticks(tiled['Tiling_Size'])
ax2.set_xticklabels(tiled['Tiling_Size'])
ax2.grid(True, alpha=0.3)

if not tiled.empty:
    best_tile_idx = tiled['Speedup'].idxmax()
    best_tile = tiled.loc[best_tile_idx]
    ax2.annotate(f"Best: T={best_tile['Tiling_Size']} ({best_tile['Speedup']:.2f}x faster)",
                (best_tile['Tiling_Size'], best_tile['Speedup']),
                textcoords="offset points", 
                xytext=(0,25), 
                ha='center',
                fontweight='bold',
                arrowprops=dict(arrowstyle='->', color='green'))

plt.tight_layout()
plt.savefig("matrix_multiplication_performance.png")
print(f"Plot saved to matrix_multiplication_performance.png")
plt.show()