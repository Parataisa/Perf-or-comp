import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path

OUTPUT_TYPE = "png"  # Options: 'png', 'svg', 'pdf'
CSV_NAME = "results.csv"


PLOT_STYLE = 'seaborn-v0_8-whitegrid'
CSV_DIR = Path("results_csv")
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

def main():
    df = load_and_prepare_data(CSV_DIR / CSV_NAME)
    
    print(f"Loaded {len(df)} rows of data")
    print(f"Sequential access: {len(df[df['random_access'] == False])} rows")
    print(f"Random access: {len(df[df['random_access'] == True])} rows")
    print(f"Unique containers: {sort_containers(df['container'].unique())}")
    
    print("\nGenerating plots...")
    
    plot_random_vs_sequential(df)
    print("✓ Created random vs sequential comparison")
    
    plot_access_pattern_by_size(df)
    print("✓ Created access pattern by size plots")

    plot_access_pattern_with_ratio(df)
    print("✓ Created access pattern by ratio plots")
    
    print(f"\nAll plots saved to {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()