#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import ScalarFormatter, LogLocator
import matplotlib.gridspec as gridspec

# Set up nicer plotting styles
plt.style.use('ggplot')
plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['font.size'] = 11

try:
    data = pd.read_csv('memory_latency.csv')
    print(f"Successfully loaded data with {len(data)} rows")
    print(f"Block size range: {data['Block Size (bytes)'].min()} to {data['Block Size (bytes)'].max()} bytes")
except Exception as e:
    print(f"Error loading data: {e}")

# Convert block size to KiB for better readability
data['Block Size (KiB)'] = data['Block Size (bytes)'] / 1024

# Create a figure with a grid layout for multiple plots
fig = plt.figure(figsize=[14, 12])
gs = gridspec.GridSpec(3, 1, height_ratios=[2, 2, 2])

# Function to format x-axis tick labels to avoid overlapping
def format_tick_labels(ax, xticks):
    # Format labels - using K for kilobytes and M for megabytes
    labels = []
    for x in xticks:
        if x >= 1024:
            labels.append(f"{x/1024:.0f}M")  # Convert to MB
        else:
            labels.append(f"{x:.0f}K")  # Keep as KB
    
    ax.set_xticks(xticks)
    ax.set_xticklabels(labels)
    
    # Apply slight rotation for better readability
    plt.setp(ax.get_xticklabels(), rotation=30, ha='right')

# ------- LATENCY PLOT (Top Left) -------
ax1 = plt.subplot(gs[0, 0])

# Plot latency vs block size with logarithmic x-axis
latency_line, = ax1.semilogx(data['Block Size (KiB)'], data['Latency (cycles)'], 
                            'o-', linewidth=2.5, color='blue', markersize=8)

# Define cache boundaries (adjust based on your CPU)
l1_boundary = 768    # L1 cache boundary in KiB (updated to your 768KB value)
l2_boundary = 6 * 1024   # L2 boundary in KiB (updated to your 6MB value)
l3_boundary = 64 * 1024  # L3 boundary in KiB (updated to your 64MB value)

# Add colored regions for different cache levels
ax1.axvspan(data['Block Size (KiB)'].min(), l1_boundary, alpha=0.12, color='limegreen', label='L1 Cache')
ax1.axvspan(l1_boundary, l2_boundary, alpha=0.12, color='gold', label='L2 Cache')
ax1.axvspan(l2_boundary, l3_boundary, alpha=0.12, color='orange', label='L3 Cache')
ax1.axvspan(l3_boundary, data['Block Size (KiB)'].max()*1.1, alpha=0.12, color='tomato', label='Main Memory')

# Add vertical lines at cache boundaries
ax1.axvline(x=l1_boundary, color='darkgreen', linestyle='--', alpha=0.7)
ax1.axvline(x=l2_boundary, color='goldenrod', linestyle='--', alpha=0.7)
ax1.axvline(x=l3_boundary, color='darkred', linestyle='--', alpha=0.7)

# Label axes and add title
ax1.set_xlabel('Block Size', fontsize=12, fontweight='bold')
ax1.set_ylabel('Access Latency (CPU cycles)', fontsize=12, fontweight='bold', color='blue')
ax1.set_title('Memory Access Latency vs. Block Size', fontsize=14, fontweight='bold')

# Add a legend with better positioning
legend = ax1.legend(loc='upper left', fontsize=10, 
                   bbox_to_anchor=(0.01, 0.99),
                   borderaxespad=0,
                   framealpha=0.9)

# Customize x-axis ticks to show powers of 2
# Make sure to include larger values if they exist in the data
max_power = int(np.ceil(np.log2(data['Block Size (KiB)'].max())))
xticks = [2**i for i in range(-1, max_power+1)]  # Go one power beyond the max

# Make sure ticks aren't larger than 2x the max data value (to avoid too much empty space)
xticks = [x for x in xticks if x <= data['Block Size (KiB)'].max() * 2]

format_tick_labels(ax1, xticks)
ax1.grid(True, which="both", ls="-", alpha=0.2)

# ------- LATENCY IN NANOSECONDS PLOT (Top Right) -------
ax2 = plt.subplot(gs[1, 0])

# Plot latency in nanoseconds
ns_line, = ax2.semilogx(data['Block Size (KiB)'], data['Latency (ns)'], 
                       'o-', linewidth=2.5, color='red', markersize=8)

# Add cache boundary indicators (same as ax1)
ax2.axvspan(data['Block Size (KiB)'].min(), l1_boundary, alpha=0.12, color='limegreen')
ax2.axvspan(l1_boundary, l2_boundary, alpha=0.12, color='gold')
ax2.axvspan(l2_boundary, l3_boundary, alpha=0.12, color='orange')
ax2.axvspan(l3_boundary, data['Block Size (KiB)'].max()*1.1, alpha=0.12, color='tomato')

# Add vertical lines
ax2.axvline(x=l1_boundary, color='darkgreen', linestyle='--', alpha=0.7)
ax2.axvline(x=l2_boundary, color='goldenrod', linestyle='--', alpha=0.7)
ax2.axvline(x=l3_boundary, color='darkred', linestyle='--', alpha=0.7)

# Label axes and add title
ax2.set_xlabel('Block Size', fontsize=12, fontweight='bold')
ax2.set_ylabel('Access Latency (nanoseconds)', fontsize=12, fontweight='bold', color='red')
ax2.set_title('Memory Access Latency (ns) vs. Block Size', fontsize=14, fontweight='bold')

# Apply the same formatting to the second plot's x-axis
format_tick_labels(ax2, xticks)
ax2.grid(True, which="both", ls="-", alpha=0.2)

# ------- BANDWIDTH PLOT  -------
ax3 = plt.subplot(gs[2 ,0])

bandwidth_line, = ax3.loglog(data['Block Size (KiB)'], data['Bandwidth (MB/s)'], 
                              'o-', linewidth=2.5, color='green', markersize=8)

ax3.axvspan(data['Block Size (KiB)'].min(), l1_boundary, alpha=0.12, color='limegreen')
ax3.axvspan(l1_boundary, l2_boundary, alpha=0.12, color='gold')
ax3.axvspan(l2_boundary, l3_boundary, alpha=0.12, color='orange')
ax3.axvspan(l3_boundary, data['Block Size (KiB)'].max()*1.1, alpha=0.12, color='tomato')

# Add vertical lines
ax3.axvline(x=l1_boundary, color='darkgreen', linestyle='--', alpha=0.7)
ax3.axvline(x=l2_boundary, color='goldenrod', linestyle='--', alpha=0.7)
ax3.axvline(x=l3_boundary, color='darkred', linestyle='--', alpha=0.7)

# Label axes and add title
ax3.set_xlabel('Block Size', fontsize=12, fontweight='bold')
ax3.set_ylabel('Bandwidth (MB/s)', fontsize=12, fontweight='bold', color='green')
ax3.set_title('Memory Bandwidth vs. Block Size', fontsize=14, fontweight='bold')

ax3.set_yscale('log')
ax3.yaxis.set_major_locator(LogLocator(numticks=8))
ax3.yaxis.set_major_formatter(ScalarFormatter(useOffset=False))
ax3.tick_params(axis='y', which='major', pad=8) 
ax3.yaxis.set_tick_params(labelrotation=0) 

# Apply the same tick formatting to the bandwidth plot
format_tick_labels(ax3, xticks)
ax3.grid(True, which="both", ls="-", alpha=0.2)
ax3.xaxis.set_major_formatter(ScalarFormatter())

# Add overall title for the figure
fig.suptitle('Memory Hierarchy Performance Analysis', fontsize=16, fontweight='bold', y=0.98)

# Adjust layout and save
plt.tight_layout(rect=[0, 0.05, 1, 0.95])
plt.subplots_adjust(bottom=0.15)  
plt.savefig('cache_hierarchy_analysis.png', dpi=300, bbox_inches='tight')
plt.show()

print("Plot saved as cache_hierarchy_analysis.png")