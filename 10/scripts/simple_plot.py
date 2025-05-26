import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path

OUTPUT_TYPE = "png"  # Options: 'png', 'svg', 'pdf'
CSV_NAME = "results.csv"


PLOT_STYLE = 'seaborn-v0_8-whitegrid'
CSV_DIR = Path("results")
OUTPUT_DIR = Path("plots_"+CSV_NAME[:-4])
OUTPUT_DIR.mkdir(exist_ok=True)

plt.style.use(PLOT_STYLE)
sns.set_palette("tab20")

DATA_STRUCTURE_SORT_ORDER = [
    "array",
    "linkedlist_seq",
    "linkedlist_rand",
    "unrolled_linkedlist_8",
    "unrolled_linkedlist_16",
    "unrolled_linkedlist_32",
    "unrolled_linkedlist_64",
    "unrolled_linkedlist_128",
    "unrolled_linkedlist_256",
    "tiered_array_8",
    "tiered_array_16",
    "tiered_array_32",
    "tiered_array_64",
    "tiered_array_128",
    "tiered_array_256",
]

def load_and_prepare_data(csv_file):
    df = pd.read_csv(csv_file)
    
    df = df[df['ops_per_second'].notna()]
    if 'error' in df.columns:
        df = df[df['error'] == False]
    
    numeric_cols = ['ops_per_second', 'ratio', 'size', 'elem_size']
    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
    
    df['random_access'] = df['random_access'].astype(bool)
    
    return df

def sort_containers(containers):
    sort_order = {ds: i for i, ds in enumerate(DATA_STRUCTURE_SORT_ORDER)}
    
    return sorted(containers, key=lambda x: sort_order.get(x, float('inf')))

def plot_random_vs_sequential(df):
    agg_df = df.groupby(['container', 'random_access'])['ops_per_second'].mean().reset_index()
    
    containers = sort_containers(df['container'].unique())
    
    seq_data = agg_df[agg_df['random_access'] == False]
    rand_data = agg_df[agg_df['random_access'] == True]
    
    fig, ax = plt.subplots(figsize=(14, 8))
    
    x = np.arange(len(containers))
    width = 0.35
    
    seq_values = []
    rand_values = []
    
    for container in containers:
        seq_val = seq_data[seq_data['container'] == container]['ops_per_second']
        seq_values.append(seq_val.iloc[0] if not seq_val.empty else 0)
        
        rand_val = rand_data[rand_data['container'] == container]['ops_per_second']
        rand_values.append(rand_val.iloc[0] if not rand_val.empty else 0)
    
    bars1 = ax.bar(x - width/2, seq_values, width, label='Sequential Access', color='#1f77b4')
    bars2 = ax.bar(x + width/2, rand_values, width, label='Random Access', color='#ff7f0e')
    
    ax.set_title('Performance: Sequential vs Random Access Patterns', fontsize=16)
    ax.set_xlabel('Data Structure', fontsize=14)
    ax.set_ylabel('Avg Operations per Second (Log Scale)', fontsize=14)
    ax.set_yscale('log')
    ax.set_xticks(x)
    ax.set_xticklabels(containers, rotation=45, ha='right')
    ax.legend(fontsize=12)
    ax.grid(True, alpha=0.3, axis='y')
    
    def add_labels(bars):
        for bar in bars:
            height = bar.get_height()
            if height > 0:
                ax.text(bar.get_x() + bar.get_width()/2., height*1.05,
                       f'{height:.1e}', ha='center', va='bottom', fontsize=8)
    
    add_labels(bars1)
    add_labels(bars2)
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"random_vs_sequential_comparison_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_access_pattern_by_size(df):
    sizes = sorted(df['size'].unique())
    
    n_sizes = len(sizes)
    ncols = min(2, n_sizes)
    nrows = (n_sizes + ncols - 1) // ncols
    
    fig, axes = plt.subplots(nrows, ncols, figsize=(12 * ncols, 8 * nrows))
    if n_sizes == 1:
        axes = [axes]
    else:
        axes = axes.flatten() if n_sizes > 1 else [axes]
    
    fig.suptitle('Access Pattern Impact by Data Size', fontsize=18)
    
    for idx, size in enumerate(sizes):
        if idx >= len(axes):
            break
        
        ax = axes[idx]
        
        size_df = df[df['size'] == size]
        agg_df = size_df.groupby(['container', 'random_access'])['ops_per_second'].mean().reset_index()
        
        containers = sort_containers(agg_df['container'].unique())
        x = np.arange(len(containers))
        width = 0.35
        
        seq_values = []
        rand_values = []
        
        for container in containers:
            seq_val = agg_df[(agg_df['container'] == container) & (agg_df['random_access'] == False)]['ops_per_second']
            rand_val = agg_df[(agg_df['container'] == container) & (agg_df['random_access'] == True)]['ops_per_second']
            
            seq_values.append(seq_val.iloc[0] if not seq_val.empty else 0)
            rand_values.append(rand_val.iloc[0] if not rand_val.empty else 0)
        
        ax.bar(x - width/2, seq_values, width, label='Sequential', color='#1f77b4')
        ax.bar(x + width/2, rand_values, width, label='Random', color='#ff7f0e')
        
        ax.set_title(f'Size: {size} elements', fontsize=14)
        ax.set_xlabel('Data Structure', fontsize=12)
        ax.set_ylabel('Ops/sec (Log Scale)', fontsize=12)
        ax.set_yscale('log')
        ax.set_xticks(x)
        ax.set_xticklabels(containers, rotation=45, ha='right')
        ax.legend()
        ax.grid(True, alpha=0.3, axis='y')
    
    for idx in range(len(sizes), len(axes)):
        fig.delaxes(axes[idx])
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"access_pattern_by_size_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_access_pattern_with_ratio(df):
    ratios = sorted(df['ratio'].unique())
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    axes = axes.flatten()
    
    for idx, ratio in enumerate(ratios[:4]):  
        ax = axes[idx]
        
        ratio_df = df[df['ratio'] == ratio]
        agg_df = ratio_df.groupby(['container', 'random_access'])['ops_per_second'].mean().reset_index()
        
        pivot_df = agg_df.pivot(index='container', columns='random_access', values='ops_per_second')
        pivot_df.columns = ['Sequential', 'Random']
        
        containers = sort_containers(pivot_df.index)
        x = np.arange(len(containers))
        width = 0.35
        
        bars1 = ax.bar(x - width/2, pivot_df['Sequential'], width, label='Sequential', color='#1f77b4')
        bars2 = ax.bar(x + width/2, pivot_df['Random'], width, label='Random', color='#ff7f0e')
        
        ax.set_title(f'Insert/Delete Ratio: {ratio*100:.0f}%', fontsize=14)
        ax.set_xlabel('Data Structure', fontsize=12)
        ax.set_ylabel('Ops/sec (Log Scale)', fontsize=12)
        ax.set_yscale('log')
        ax.set_xticks(x)
        ax.set_xticklabels(containers, rotation=45, ha='right')
        ax.legend()
        ax.grid(True, alpha=0.3, axis='y')
    
    fig.suptitle('Access Pattern Performance by Insert/Delete Ratio', fontsize=18)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"access_pattern_by_ratio_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_relative_performance_to_array_by_ratio(df):
    ratios = sorted(df['ratio'].unique())
    
    fig, axes = plt.subplots(2, 2, figsize=(18, 12))
    axes = axes.flatten()
    
    for idx, ratio in enumerate(ratios[:4]):
        ax = axes[idx]
        
        ratio_df = df[df['ratio'] == ratio]
        agg_df = ratio_df.groupby(['container', 'random_access', 'size', 'elem_size'])['ops_per_second'].mean().reset_index()
        
        array_df = agg_df[agg_df['container'] == 'array'].copy()
        array_df['baseline_key'] = array_df['random_access'].astype(str) + '_' + array_df['size'].astype(str) + '_' + array_df['elem_size'].astype(str)
        baseline_dict = dict(zip(array_df['baseline_key'], array_df['ops_per_second']))
        
        agg_df['baseline_key'] = agg_df['random_access'].astype(str) + '_' + agg_df['size'].astype(str) + '_' + agg_df['elem_size'].astype(str)
        agg_df['relative_performance'] = agg_df.apply(
            lambda row: row['ops_per_second'] / baseline_dict.get(row['baseline_key'], 1.0), axis=1
        )
        
        non_array_df = agg_df[agg_df['container'] != 'array']
        containers = sort_containers(non_array_df['container'].unique())
        
        if len(containers) == 0:
            continue
            
        x = np.arange(len(containers))
        width = 0.35
        
        seq_data = non_array_df[non_array_df['random_access'] == False]
        rand_data = non_array_df[non_array_df['random_access'] == True]
        
        seq_grouped = seq_data.groupby('container')['relative_performance'].mean()
        rand_grouped = rand_data.groupby('container')['relative_performance'].mean()
        
        seq_values = [seq_grouped.get(c, 0) for c in containers]
        rand_values = [rand_grouped.get(c, 0) for c in containers]
        
        ax.bar(x - width/2, seq_values, width, label='Sequential', color='#1f77b4', alpha=0.8)
        ax.bar(x + width/2, rand_values, width, label='Random', color='#ff7f0e', alpha=0.8)
        ax.axhline(y=1.0, color='red', linestyle='--', alpha=0.7, label='Array Baseline')
        
        ax.set_title(f'Ratio {ratio*100:.0f}% Insert/Delete\n(Relative to Array)', fontsize=12)
        ax.set_xlabel('Data Structure', fontsize=10)
        ax.set_ylabel('Relative Performance', fontsize=10)
        ax.set_xticks(x)
        ax.set_xticklabels(containers, rotation=45, ha='right', fontsize=8)
        ax.legend(fontsize=9)
        ax.grid(True, alpha=0.3, axis='y')
    
    for idx in range(len(ratios), len(axes)):
        fig.delaxes(axes[idx])
    
    fig.suptitle('Relative Performance by Insert/Delete Ratio', fontsize=16)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"relative_performance_by_ratio_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_performance_scaling_by_size_and_ratio(df):
    ratios = sorted(df['ratio'].unique())
    sizes = sorted(df['size'].unique())
    containers = sort_containers(df['container'].unique())
    
    fig, axes = plt.subplots(2, 2, figsize=(20, 12))
    axes = axes.flatten()
    
    for idx, ratio in enumerate(ratios[:4]):
        ax = axes[idx]
        
        ratio_df = df[df['ratio'] == ratio]
        
        for access_type, marker, color in [('Sequential', 'o', '#1f77b4'), ('Random', 's', '#ff7f0e')]:
            is_random = access_type == 'Random'
            access_df = ratio_df[ratio_df['random_access'] == is_random]
            
            for container in containers:
                container_df = access_df[access_df['container'] == container]
                if container_df.empty:
                    continue
                    
                perf_by_size = container_df.groupby('size')['ops_per_second'].mean()
                
                if not perf_by_size.empty:
                    ax.plot(sizes, [perf_by_size.get(s, np.nan) for s in sizes], 
                           marker=marker, label=f'{container}_{access_type}', 
                           linewidth=2, markersize=4, alpha=0.8)
        
        ax.set_title(f'Ratio {ratio*100:.0f}% Insert/Delete', fontsize=12)
        ax.set_xlabel('Data Size (elements)', fontsize=10)
        ax.set_ylabel('Ops/sec (Log Scale)', fontsize=10)
        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)
        ax.grid(True, alpha=0.3)
    
    for idx in range(len(ratios), len(axes)):
        fig.delaxes(axes[idx])
    
    fig.suptitle('Performance Scaling by Size and Ratio', fontsize=16)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"performance_scaling_by_ratio_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_element_size_impact_by_ratio(df):
    ratios = sorted(df['ratio'].unique())
    elem_sizes = sorted(df['elem_size'].unique())
    
    key_ratios = [0.0, 0.5] if 0.0 in ratios and 0.5 in ratios else ratios[:2]
    
    fig, axes = plt.subplots(len(key_ratios), len(elem_sizes), figsize=(5*len(elem_sizes), 6*len(key_ratios)))
    if len(key_ratios) == 1:
        axes = axes.reshape(1, -1)
    if len(elem_sizes) == 1:
        axes = axes.reshape(-1, 1)
    
    for ratio_idx, ratio in enumerate(key_ratios):
        for elem_idx, elem_size in enumerate(elem_sizes):
            ax = axes[ratio_idx, elem_idx]
            
            subset_df = df[(df['ratio'] == ratio) & (df['elem_size'] == elem_size)]
            if subset_df.empty:
                ax.set_visible(False)
                continue
                
            agg_df = subset_df.groupby(['container', 'random_access'])['ops_per_second'].mean().reset_index()
            containers = sort_containers(agg_df['container'].unique())
            
            x = np.arange(len(containers))
            width = 0.35
            
            seq_values = []
            rand_values = []
            
            for container in containers:
                seq_val = agg_df[(agg_df['container'] == container) & (agg_df['random_access'] == False)]['ops_per_second']
                rand_val = agg_df[(agg_df['container'] == container) & (agg_df['random_access'] == True)]['ops_per_second']
                
                seq_values.append(seq_val.iloc[0] if not seq_val.empty else 0)
                rand_values.append(rand_val.iloc[0] if not rand_val.empty else 0)
            
            ax.bar(x - width/2, seq_values, width, label='Sequential', color='#1f77b4', alpha=0.8)
            ax.bar(x + width/2, rand_values, width, label='Random', color='#ff7f0e', alpha=0.8)
            
            ax.set_title(f'Ratio {ratio*100:.0f}%, Size {elem_size}B', fontsize=10)
            ax.set_ylabel('Ops/sec (Log Scale)', fontsize=9)
            ax.set_yscale('log')
            ax.set_xticks(x)
            ax.set_xticklabels(containers, rotation=45, ha='right', fontsize=8)
            if ratio_idx == 0 and elem_idx == 0:
                ax.legend(fontsize=9)
            ax.grid(True, alpha=0.3, axis='y')
    
    fig.suptitle('Element Size Impact by Ratio', fontsize=16)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"element_size_impact_by_ratio_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_performance_heatmap_by_ratio(df):
    ratios = sorted(df['ratio'].unique())
    
    fig, axes = plt.subplots(2, 2, figsize=(20, 12))
    axes = axes.flatten()
    
    for idx, ratio in enumerate(ratios[:4]):
        ax = axes[idx]
        
        ratio_df = df[df['ratio'] == ratio]
        agg_df = ratio_df.groupby(['container', 'size', 'random_access'])['ops_per_second'].mean().reset_index()

        seq_data = agg_df[agg_df['random_access'] == False]
        rand_data = agg_df[agg_df['random_access'] == True]
        
        combined_data = []
        for container in sort_containers(agg_df['container'].unique()):
            for size in sorted(agg_df['size'].unique()):
                seq_perf = seq_data[(seq_data['container'] == container) & (seq_data['size'] == size)]['ops_per_second']
                rand_perf = rand_data[(rand_data['container'] == container) & (rand_data['size'] == size)]['ops_per_second']
                
                seq_val = seq_perf.iloc[0] if not seq_perf.empty else np.nan
                rand_val = rand_perf.iloc[0] if not rand_perf.empty else np.nan
                
                combined_data.append({
                    'container_access': f"{container}_seq",
                    'size': size,
                    'ops_per_second': seq_val
                })
                combined_data.append({
                    'container_access': f"{container}_rand",
                    'size': size,
                    'ops_per_second': rand_val
                })
        
        combined_df = pd.DataFrame(combined_data)
        heatmap_data = combined_df.pivot(index='container_access', columns='size', values='ops_per_second')
        
        mask = np.isnan(heatmap_data.values)
        log_data = np.log10(heatmap_data.values)
        log_data[mask] = np.nan
        
        im = ax.imshow(log_data, cmap='viridis', aspect='auto')
        ax.set_title(f'Ratio {ratio*100:.0f}% Insert/Delete\n(Log10 Ops/sec)', fontsize=12)
        ax.set_xlabel('Data Size', fontsize=10)
        ax.set_ylabel('Container_AccessType', fontsize=10)
        ax.set_xticks(range(len(heatmap_data.columns)))
        ax.set_xticklabels(heatmap_data.columns, rotation=45, fontsize=8)
        ax.set_yticks(range(len(heatmap_data.index)))
        ax.set_yticklabels(heatmap_data.index, fontsize=8)
        
        cbar = plt.colorbar(im, ax=ax)
        cbar.set_label('Log10(Ops/sec)', fontsize=9)
    
    for idx in range(len(ratios), len(axes)):
        fig.delaxes(axes[idx])
    
    fig.suptitle('Performance Heatmaps by Insert/Delete Ratio', fontsize=16)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"performance_heatmap_by_ratio_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_ratio_impact_summary(df):
    all_containers = sort_containers(df['container'].unique())
    ratios = sorted(df['ratio'].unique())
    
    key_containers = []
    for container in all_containers:
        if container in ['array', 'linkedlist_seq', 'linkedlist_rand']:
            key_containers.append(container)
        elif container.startswith('unrolled_linkedlist') and container.endswith(('32', '64', '128')):
            key_containers.append(container)
        elif container.startswith('tiered_array') and container.endswith(('32', '64', '128')):
            key_containers.append(container)
    
    n_containers = len(key_containers)
    ncols = 3
    nrows = (n_containers + ncols - 1) // ncols
    
    fig, axes = plt.subplots(nrows, ncols, figsize=(20, 5*nrows))
    
    if nrows == 1:
        axes = axes.reshape(1, -1)
    axes_flat = axes.flatten() if n_containers > 1 else [axes]
    
    for idx, container in enumerate(key_containers):
        ax = axes_flat[idx]
        
        container_df = df[df['container'] == container]
        
        for access_type, color, marker in [('Sequential', '#1f77b4', 'o'), ('Random', '#ff7f0e', 's')]:
            is_random = access_type == 'Random'
            access_df = container_df[container_df['random_access'] == is_random]
            
            perf_by_ratio = access_df.groupby('ratio')['ops_per_second'].mean()
            
            if not perf_by_ratio.empty and len(perf_by_ratio) > 1:
                baseline = perf_by_ratio.iloc[0] if perf_by_ratio.iloc[0] > 0 else 1
                normalized_perf = perf_by_ratio / baseline
                
                ax.plot(ratios, [normalized_perf.get(r, np.nan) for r in ratios], 
                       marker=marker, label=access_type, color=color, linewidth=2, markersize=6)
        
        ax.set_title(f'{container}', fontsize=12)
        ax.set_xlabel('Insert/Delete Ratio', fontsize=10)
        ax.set_ylabel('Relative Performance', fontsize=10)
        ax.legend(fontsize=9)
        ax.grid(True, alpha=0.3)
        ax.set_ylim(bottom=0)
    
    for idx in range(n_containers, len(axes_flat)):
        axes_flat[idx].set_visible(False)
    
    fig.suptitle('Ratio Impact Summary: Performance Degradation by Container', fontsize=16)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"ratio_impact_summary_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def plot_memory_efficiency_by_ratio(df):
    ratios = sorted(df['ratio'].unique())
    
    key_ratios = [0.0, 0.5] if 0.0 in ratios and 0.5 in ratios else ratios[:2]
    
    fig, axes = plt.subplots(1, len(key_ratios), figsize=(8*len(key_ratios), 8))
    if len(key_ratios) == 1:
        axes = [axes]
    
    for idx, ratio in enumerate(key_ratios):
        ax = axes[idx]
        
        ratio_df = df[df['ratio'] == ratio].copy()
        ratio_df['ops_per_mb'] = ratio_df['ops_per_second'] / ratio_df['peak_memory_mb']
        
        agg_df = ratio_df.groupby(['container', 'random_access']).agg({
            'ops_per_mb': 'mean',
            'peak_memory_mb': 'mean',
            'ops_per_second': 'mean'
        }).reset_index()
        
        containers = sort_containers(agg_df['container'].unique())
        x = np.arange(len(containers))
        width = 0.35
        
        seq_efficiency = []
        rand_efficiency = []
        
        for container in containers:
            seq_val = agg_df[(agg_df['container'] == container) & (agg_df['random_access'] == False)]['ops_per_mb']
            rand_val = agg_df[(agg_df['container'] == container) & (agg_df['random_access'] == True)]['ops_per_mb']
            
            seq_efficiency.append(seq_val.iloc[0] if not seq_val.empty else 0)
            rand_efficiency.append(rand_val.iloc[0] if not rand_val.empty else 0)
        
        ax.bar(x - width/2, seq_efficiency, width, label='Sequential', color='#1f77b4', alpha=0.8)
        ax.bar(x + width/2, rand_efficiency, width, label='Random', color='#ff7f0e', alpha=0.8)
        
        ax.set_title(f'Memory Efficiency\nRatio {ratio*100:.0f}% Insert/Delete', fontsize=12)
        ax.set_xlabel('Data Structure', fontsize=10)
        ax.set_ylabel('Ops per MB (Log Scale)', fontsize=10)
        ax.set_yscale('log')
        ax.set_xticks(x)
        ax.set_xticklabels(containers, rotation=45, ha='right', fontsize=9)
        ax.legend()
        ax.grid(True, alpha=0.3, axis='y')
    
    fig.suptitle('Memory Efficiency by Insert/Delete Ratio', fontsize=16)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / f"memory_efficiency_by_ratio_{CSV_NAME[:-4]}.{OUTPUT_TYPE}", bbox_inches='tight')
    plt.close()

def main():
    df = load_and_prepare_data(CSV_DIR / CSV_NAME)
    
    print(f"Loaded {len(df)} rows of data")
    print(f"Sequential access: {len(df[df['random_access'] == False])} rows")
    print(f"Random access: {len(df[df['random_access'] == True])} rows")
    print(f"Unique containers: {sort_containers(df['container'].unique())}")
    print(f"Unique ratios: {sorted(df['ratio'].unique())}")
    
    print("\nGenerating plots...")
    
    plot_random_vs_sequential(df)
    print("✓ Created random vs sequential comparison")
    
    plot_access_pattern_by_size(df)
    print("✓ Created access pattern by size plots")

    plot_access_pattern_with_ratio(df)
    print("✓ Created access pattern by ratio plots")
    
    plot_relative_performance_to_array_by_ratio(df)
    print("✓ Created ratio-aware relative performance analysis")
    
    plot_performance_scaling_by_size_and_ratio(df)
    print("✓ Created ratio-aware performance scaling analysis")
    
    plot_element_size_impact_by_ratio(df)
    print("✓ Created ratio-aware element size impact analysis")
    
    plot_performance_heatmap_by_ratio(df)
    print("✓ Created ratio-aware performance heatmap")
    
    plot_ratio_impact_summary(df)
    print("✓ Created ratio impact summary")
    
    plot_memory_efficiency_by_ratio(df)
    print("✓ Created ratio-aware memory efficiency analysis")
    
    print(f"\nAll plots saved to {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()