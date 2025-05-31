import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import warnings

def load_and_process_data(csv_path):
    df = pd.read_csv(csv_path)
    
    average_data = df[df['Run'] == 'Average'].copy()
    
    average_data['Runtime(s)'] = pd.to_numeric(average_data['Runtime(s)'])
    average_data['MemoryUsage(KB)'] = pd.to_numeric(average_data['MemoryUsage(KB)'])
    
    return average_data

def create_runtime_line_chart(average_data):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
    
    for impl in average_data['Implementation'].unique():
        impl_data = average_data[average_data['Implementation'] == impl]
        ax1.plot(impl_data['Size'], impl_data['Runtime(s)'], 
                marker='o', linewidth=2, markersize=6, label=impl.capitalize())
    
    ax1.set_xlabel('Input Size')
    ax1.set_ylabel('Runtime (seconds)')
    ax1.set_title('Runtime Comparison (Linear Scale)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    for impl in average_data['Implementation'].unique():
        impl_data = average_data[average_data['Implementation'] == impl]
        ax2.semilogy(impl_data['Size'], impl_data['Runtime(s)'], 
                    marker='o', linewidth=2, markersize=6, label=impl.capitalize())
    
    ax2.set_xlabel('Input Size')
    ax2.set_ylabel('Runtime (seconds, log scale)')
    ax2.set_title('Runtime Comparison (Logarithmic Scale)')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    return fig

def create_memory_line_chart(average_data):
    fig, ax = plt.subplots(1, 1, figsize=(10, 6))
    
    for impl in average_data['Implementation'].unique():
        impl_data = average_data[average_data['Implementation'] == impl]
        ax.plot(impl_data['Size'], impl_data['MemoryUsage(KB)'], 
               marker='s', linewidth=2, markersize=6, label=impl.capitalize())
    
    ax.set_xlabel('Input Size')
    ax.set_ylabel('Memory Usage (KB)')
    ax.set_title('Memory Usage Comparison')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    return fig

def create_performance_bar_chart(average_data):
    all_sizes = sorted(average_data['Size'].unique())
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(20, 12))
    
    runtime_pivot = average_data.pivot(index='Size', columns='Implementation', values='Runtime(s)')
    runtime_pivot.plot(kind='bar', ax=ax1, rot=45)
    ax1.set_xlabel('Input Size')
    ax1.set_ylabel('Runtime (seconds)')
    ax1.set_title('Runtime Comparison - All Sizes')
    ax1.legend(title='Implementation')
    ax1.set_yscale('log')
    
    memory_pivot = average_data.pivot(index='Size', columns='Implementation', values='MemoryUsage(KB)')
    memory_pivot.plot(kind='bar', ax=ax2, rot=45)
    ax2.set_xlabel('Input Size')
    ax2.set_ylabel('Memory Usage (KB)')
    ax2.set_title('Memory Usage Comparison - All Sizes')
    ax2.legend(title='Implementation')
    
    efficient_data = average_data[average_data['Implementation'].isin(['memoized', 'tabular'])]
    efficient_runtime_pivot = efficient_data.pivot(index='Size', columns='Implementation', values='Runtime(s)')
    efficient_runtime_pivot.plot(kind='bar', ax=ax3, rot=45)
    ax3.set_xlabel('Input Size')
    ax3.set_ylabel('Runtime (seconds)')
    ax3.set_title('Efficient Implementations Runtime - Extended Range')
    ax3.legend(title='Implementation')
    
    efficient_memory_pivot = efficient_data.pivot(index='Size', columns='Implementation', values='MemoryUsage(KB)')
    efficient_memory_pivot.plot(kind='bar', ax=ax4, rot=45)
    ax4.set_xlabel('Input Size')
    ax4.set_ylabel('Memory Usage (KB)')
    ax4.set_title('Efficient Implementations Memory - Extended Range')
    ax4.legend(title='Implementation')
    
    plt.tight_layout()
    return fig

def create_speedup_bar_chart(average_data):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
    
    recursive_sizes = average_data[average_data['Implementation'] == 'recursive']['Size'].unique()
    
    speedup_data = []
    for size in recursive_sizes:
        size_data = average_data[average_data['Size'] == size]
        recursive_time = size_data[size_data['Implementation'] == 'recursive']['Runtime(s)'].iloc[0]
        
        for impl in size_data['Implementation'].unique():
            impl_time = size_data[size_data['Implementation'] == impl]['Runtime(s)'].iloc[0]
            speedup = recursive_time / impl_time
            speedup_data.append({
                'Size': size,
                'Implementation': impl,
                'Speedup': speedup
            })
    
    speedup_df = pd.DataFrame(speedup_data)
    speedup_pivot = speedup_df.pivot(index='Size', columns='Implementation', values='Speedup')
    speedup_pivot.plot(kind='bar', ax=ax1, rot=0)
    
    ax1.set_xlabel('Input Size')
    ax1.set_ylabel('Speedup Factor (vs Recursive)')
    ax1.set_title('Speedup vs Recursive Implementation (Sizes 10-14)')
    ax1.legend(title='Implementation')
    ax1.set_yscale('log')
    ax1.grid(True, alpha=0.3)
    
    efficient_data = average_data[average_data['Implementation'].isin(['memoized', 'tabular'])]
    
    sizes = sorted(efficient_data['Size'].unique())
    memoized_times = []
    tabular_times = []
    
    for size in sizes:
        size_data = efficient_data[efficient_data['Size'] == size]
        if len(size_data) == 2: 
            memoized_time = size_data[size_data['Implementation'] == 'memoized']['Runtime(s)'].iloc[0]
            tabular_time = size_data[size_data['Implementation'] == 'tabular']['Runtime(s)'].iloc[0]
            memoized_times.append(memoized_time)
            tabular_times.append(tabular_time)
        else:
            memoized_times.append(None)
            tabular_times.append(None)
    
    x_pos = np.arange(len(sizes))
    width = 0.35
    
    valid_indices = [i for i, (m, t) in enumerate(zip(memoized_times, tabular_times)) 
                     if m is not None and t is not None]
    valid_sizes = [sizes[i] for i in valid_indices]
    valid_memoized = [memoized_times[i] for i in valid_indices]
    valid_tabular = [tabular_times[i] for i in valid_indices]
    
    x_valid = np.arange(len(valid_sizes))
    
    bars1 = ax2.bar(x_valid - width/2, valid_memoized, width, label='Memoized', 
                    color='lightcoral', alpha=0.8)
    bars2 = ax2.bar(x_valid + width/2, valid_tabular, width, label='Tabular', 
                    color='lightblue', alpha=0.8)
    
    ax2.set_xlabel('Input Size')
    ax2.set_ylabel('Runtime (seconds)')
    ax2.set_title('Memoized vs Tabular: Direct Runtime Comparison (All Sizes)')
    ax2.set_xticks(x_valid)
    ax2.set_xticklabels(valid_sizes, rotation=45)
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    for i, (mem_time, tab_time) in enumerate(zip(valid_memoized, valid_tabular)):
        if tab_time > 0:
            pct_diff = ((mem_time - tab_time) / tab_time) * 100
            y_pos = max(mem_time, tab_time) * 1.05
            color = 'red' if pct_diff > 0 else 'green'
            ax2.text(x_valid[i], y_pos, f'{pct_diff:+.1f}%', 
                    ha='center', va='bottom', fontsize=8, color=color)
    
    plt.tight_layout()
    return fig

def create_efficiency_line_chart(average_data):
    efficient_impls = average_data[average_data['Implementation'].isin(['memoized', 'tabular'])]
    
    fig, ax = plt.subplots(1, 1, figsize=(10, 6))
    
    for impl in efficient_impls['Implementation'].unique():
        impl_data = efficient_impls[efficient_impls['Implementation'] == impl]
        ax.plot(impl_data['Size'], impl_data['Runtime(s)'], 
               marker='D', linewidth=2, markersize=6, label=f'{impl.capitalize()}')
    
    ax.set_xlabel('Input Size')
    ax.set_ylabel('Runtime (seconds)')
    ax.set_title('Efficient Implementations: Runtime Scaling')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    return fig

def create_comprehensive_overview(average_data):
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(18, 12))
    
    for impl in average_data['Implementation'].unique():
        impl_data = average_data[average_data['Implementation'] == impl]
        ax1.plot(impl_data['Size'], impl_data['Runtime(s)'], 
                marker='o', linewidth=2, markersize=6, label=impl.capitalize())
    
    ax1.set_xlabel('Input Size')
    ax1.set_ylabel('Runtime (seconds, log scale)')
    ax1.set_title('Complete Runtime Overview - All Implementations')
    ax1.legend()
    ax1.set_yscale('log')
    ax1.grid(True, alpha=0.3)
    
    for impl in average_data['Implementation'].unique():
        impl_data = average_data[average_data['Implementation'] == impl]
        ax2.plot(impl_data['Size'], impl_data['MemoryUsage(KB)'], 
               marker='s', linewidth=2, markersize=6, label=impl.capitalize())
    
    ax2.set_xlabel('Input Size')
    ax2.set_ylabel('Memory Usage (KB)')
    ax2.set_title('Complete Memory Usage Overview - All Implementations')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    efficient_data = average_data[average_data['Implementation'].isin(['memoized', 'tabular'])]
    efficient_pivot = efficient_data.pivot(index='Size', columns='Implementation', values='Runtime(s)')
    
    x_pos = np.arange(len(efficient_pivot.index))
    width = 0.35
    
    ax3.bar(x_pos - width/2, efficient_pivot['memoized'], width, label='Memoized', alpha=0.8)
    ax3.bar(x_pos + width/2, efficient_pivot['tabular'], width, label='Tabular', alpha=0.8)
    
    ax3.set_xlabel('Input Size')
    ax3.set_ylabel('Runtime (seconds)')
    ax3.set_title('Efficient Implementations Runtime Comparison (All Sizes)')
    ax3.set_xticks(x_pos)
    ax3.set_xticklabels(efficient_pivot.index, rotation=45)
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    ratio_data = []
    for size in efficient_data['Size'].unique():
        size_data = efficient_data[efficient_data['Size'] == size]
        if len(size_data) == 2:
            memoized_time = size_data[size_data['Implementation'] == 'memoized']['Runtime(s)'].iloc[0]
            tabular_time = size_data[size_data['Implementation'] == 'tabular']['Runtime(s)'].iloc[0]
            ratio = memoized_time / tabular_time
            ratio_data.append({'Size': size, 'Ratio': ratio})
    
    ratio_df = pd.DataFrame(ratio_data)
    ax4.plot(ratio_df['Size'], ratio_df['Ratio'], marker='D', linewidth=2, markersize=6, color='purple')
    ax4.axhline(y=1, color='red', linestyle='--', alpha=0.7, label='Equal Performance')
    ax4.set_xlabel('Input Size')
    ax4.set_ylabel('Runtime Ratio (Memoized/Tabular)')
    ax4.set_title('Memoized vs Tabular Performance Ratio (All Sizes)')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    return fig

def create_summary_bar_chart(average_data):
    key_sizes = [10, 14, 22] 
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    
    size_10_data = average_data[average_data['Size'] == 10]
    implementations = size_10_data['Implementation']
    runtimes_10 = size_10_data['Runtime(s)']
    
    bars1 = ax1.bar(implementations, runtimes_10, color=['#ff7f0e', '#2ca02c', '#1f77b4'])
    ax1.set_ylabel('Runtime (seconds)')
    ax1.set_title(f'Runtime at Size 10 (All Implementations)')
    ax1.set_yscale('log')
    
    for bar, runtime in zip(bars1, runtimes_10):
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height,
                f'{runtime:.6f}s', ha='center', va='bottom')
    
    size_14_data = average_data[average_data['Size'] == 14]
    implementations_14 = size_14_data['Implementation']
    runtimes_14 = size_14_data['Runtime(s)']
    
    bars2 = ax2.bar(implementations_14, runtimes_14, color=['#ff7f0e', '#2ca02c', '#1f77b4'])
    ax2.set_ylabel('Runtime (seconds)')
    ax2.set_title(f'Runtime at Size 14 (All Implementations)')
    ax2.set_yscale('log')
    
    for bar, runtime in zip(bars2, runtimes_14):
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height,
                f'{runtime:.6f}s', ha='center', va='bottom')
    
    size_22_data = average_data[average_data['Size'] == 22]
    implementations_22 = size_22_data['Implementation']
    runtimes_22 = size_22_data['Runtime(s)']
    
    bars3 = ax3.bar(implementations_22, runtimes_22, color=['#2ca02c', '#1f77b4'])
    ax3.set_ylabel('Runtime (seconds)')
    ax3.set_title(f'Runtime at Size 22 (Efficient Implementations)')
    
    for bar, runtime in zip(bars3, runtimes_22):
        height = bar.get_height()
        ax3.text(bar.get_x() + bar.get_width()/2., height,
                f'{runtime:.6f}s', ha='center', va='bottom')
    
    efficient_data = average_data[average_data['Implementation'].isin(['memoized', 'tabular'])]
    memory_pivot = efficient_data.pivot(index='Size', columns='Implementation', values='MemoryUsage(KB)')
    
    key_memory_sizes = [10, 15, 20, 22]
    key_memory_data = memory_pivot.loc[memory_pivot.index.isin(key_memory_sizes)]
    
    key_memory_data.plot(kind='bar', ax=ax4, rot=0)
    ax4.set_xlabel('Input Size')
    ax4.set_ylabel('Memory Usage (KB)')
    ax4.set_title('Memory Usage at Key Sizes (Efficient Implementations)')
    ax4.legend(title='Implementation')
    
    plt.tight_layout()
    return fig

def main():
    csv_file = 'results/benchmark_results.csv'
    output_dir = 'results/performance_plots'
    
    average_data = load_and_process_data(csv_file)
    
    plt.style.use('default')
    plt.rcParams['figure.facecolor'] = 'white'
    
    print("Generating runtime line charts...")
    fig1 = create_runtime_line_chart(average_data)
    fig1.savefig(os.path.join(output_dir, 'runtime_line_chart.png'), bbox_inches='tight')
    plt.close(fig1)
    
    print("Generating memory line chart...")
    fig2 = create_memory_line_chart(average_data)
    fig2.savefig(os.path.join(output_dir, 'memory_line_chart.png'), bbox_inches='tight')
    plt.close(fig2)
    
    print("Generating performance bar charts...")
    fig3 = create_performance_bar_chart(average_data)
    fig3.savefig(os.path.join(output_dir, 'performance_bar_chart.png'), bbox_inches='tight')
    plt.close(fig3)
    
    print("Generating speedup bar chart...")
    fig4 = create_speedup_bar_chart(average_data)
    fig4.savefig(os.path.join(output_dir, 'speedup_bar_chart.png'), bbox_inches='tight')
    plt.close(fig4)
    
    print("Generating efficiency line chart...")
    fig5 = create_efficiency_line_chart(average_data)
    fig5.savefig(os.path.join(output_dir, 'efficiency_line_chart.png'), bbox_inches='tight')
    plt.close(fig5)
    
    print("Generating comprehensive overview...")
    fig6 = create_comprehensive_overview(average_data)
    fig6.savefig(os.path.join(output_dir, 'comprehensive_overview.png'), bbox_inches='tight')
    plt.close(fig6)
    
    print("Generating summary bar chart...")
    fig7 = create_summary_bar_chart(average_data)
    fig7.savefig(os.path.join(output_dir, 'summary_bar_chart.png'), bbox_inches='tight')
    plt.close(fig7)
    
if __name__ == "__main__":
    main()