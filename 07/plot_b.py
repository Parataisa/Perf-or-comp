import csv
import sys
import matplotlib.pyplot as plt
import numpy as np

def analyze_results(csv_file):
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        results = {}
        for row in reader:
            try:
                key = (int(float(row['Threads'])), int(float(row['MinSize'])), int(float(row['MaxSize'])))
                alloc = row['Allocator']
                # Skip rows with missing data
                if row['RealTime'] == 'N/A' or not row['RealTime']:
                    continue
                    
                time = float(row['RealTime'])
                memory = float(row['MemoryKB']) / 1024  # Convert KB to MB
                
                if key not in results:
                    results[key] = {}
                if alloc not in results[key]:
                    results[key][alloc] = {}
                
                results[key][alloc]['time'] = time
                results[key][alloc]['memory'] = memory
                
            except (ValueError, KeyError) as e:
                print(f'Warning: Error processing row: {e}')
        
        print('{:<15} {:<15} {:<15} {:<15} {:<15} {:<15} {:<15}'.format(
            'Threads', 'Size Range', 'Time Speedup', 'Default (s)', 'Arena (s)', 'Default (MB)', 'Arena (MB)'))
        print('-' * 105)
        
        thread_sizes = {}
        
        for key in sorted(results.keys()):
            if 'Default' in results[key] and 'Arena' in results[key]:
                threads = key[0]
                size_range = f'{key[1]}-{key[2]}'
                
                default_time = results[key]['Default']['time']
                arena_time = results[key]['Arena']['time']
                
                default_memory = results[key]['Default']['memory']
                arena_memory = results[key]['Arena']['memory']
                
                time_speedup = default_time / arena_time if arena_time > 0 else float('inf')
                
                print('{:<15} {:<15} {:<15.2f} {:<15.6f} {:<15.6f} {:<15.2f} {:<15.2f}'.format(
                    threads, 
                    size_range, 
                    time_speedup,
                    default_time,
                    arena_time,
                    default_memory,
                    arena_memory
                ))
                
                if threads not in thread_sizes:
                    thread_sizes[threads] = []
                thread_sizes[threads].append((size_range, time_speedup, default_time, arena_time, default_memory, arena_memory))
        
        # Create detailed single-threaded comparison
        thread_count = 1
        if thread_count in thread_sizes:
            sizes = [x[0] for x in thread_sizes[thread_count]]
            default_times = [x[2] for x in thread_sizes[thread_count]]
            arena_times = [x[3] for x in thread_sizes[thread_count]]
            default_memory = [x[4] for x in thread_sizes[thread_count]]
            arena_memory = [x[5] for x in thread_sizes[thread_count]]
            
            # Create a figure showing execution times with focused y-axis
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
            
            x = np.arange(len(sizes))
            width = 0.35
            
            rects1 = ax1.bar(x - width/2, default_times, width, label='Default', alpha=0.8, color='#1f77b4')
            rects2 = ax1.bar(x + width/2, arena_times, width, label='Arena', alpha=0.8, color='#ff7f0e')
            
            # Calculate appropriate y-axis limits to show differences
            all_times = default_times + arena_times
            min_time = min(all_times)
            max_time = max(all_times)
            margin = (max_time - min_time) * 0.1
            
            if margin < max_time * 0.05:
                margin = max_time * 0.1
                ax1.set_ylim(min_time - margin, max_time + margin)
            
            ax1.set_title('Execution Time Comparison (Single-threaded)', fontsize=14)
            ax1.set_xlabel('Allocation Size Range', fontsize=12)
            ax1.set_ylabel('Time (seconds)', fontsize=12)
            ax1.set_xticks(x)
            ax1.set_xticklabels(sizes, rotation=45)
            ax1.legend()
            ax1.grid(axis='y', alpha=0.3)
            ax1.set_yscale('log')
            
            # Add precise value labels
            for rect in rects1 + rects2:
                height = rect.get_height()
                ax1.annotate(f'{height:.3f}',
                            xy=(rect.get_x() + rect.get_width() / 2, height),
                            xytext=(0, 3),
                            textcoords="offset points",
                            ha='center', va='bottom', fontsize=9)
            
            # Plot percentage difference
            differences = [(d - a) / d * 100 if d > 0 else 0 for d, a in zip(default_times, arena_times)]
            
            bars = ax2.bar(sizes, differences, alpha=0.8, 
                          color=['red' if diff < 0 else 'green' for diff in differences])
            
            ax2.set_title('Performance Difference (% faster/slower than default)', fontsize=14)
            ax2.set_xlabel('Allocation Size Range', fontsize=12)
            ax2.set_ylabel('Difference (%)', fontsize=12)
            ax2.axhline(y=0, color='black', linestyle='-', linewidth=1)
            ax2.grid(axis='y', alpha=0.3)
            
            # Add value labels
            for bar, diff in zip(bars, differences):
                height = bar.get_height()
                ax2.annotate(f'{diff:.2f}%',
                            xy=(bar.get_x() + bar.get_width() / 2, height),
                            xytext=(0, 3 if height >= 0 else -15),
                            textcoords="offset points",
                            ha='center', va='bottom' if height >= 0 else 'top',
                            fontsize=10)
            
            plt.xticks(rotation=45)
            fig.tight_layout()
            plt.savefig('results/arena_detailed_comparison.png', bbox_inches='tight')
            plt.close()
            
            # Create a table showing exact numbers
            fig, ax = plt.subplots(figsize=(10, 6))
            ax.axis('tight')
            ax.axis('off')
            
            # Create table data
            table_data = [['Size Range', 'Default (s)', 'Arena (s)', 'Difference (s)', 'Difference (%)']]
            for i, size in enumerate(sizes):
                def_time = default_times[i]
                arena_time = arena_times[i]
                diff_time = arena_time - def_time
                diff_pct = (def_time - arena_time) / def_time * 100 if def_time > 0 else 0
                
                table_data.append([
                    size,
                    f'{def_time:.6f}',
                    f'{arena_time:.6f}',
                    f'{diff_time:+.6f}',
                    f'{diff_pct:+.2f}%'
                ])
            
            # Create the table
            table = ax.table(cellText=table_data, loc='center', cellLoc='center')
            table.auto_set_font_size(False)
            table.set_fontsize(12)
            table.scale(1.2, 1.5)
            
            # Style the header row
            for i in range(len(table_data[0])):
                table[(0, i)].set_facecolor('#4CAF50')
                table[(0, i)].set_text_props(weight='bold', color='white')
            
            # Color-code the differences
            for i in range(1, len(table_data)):
                diff_cell = table[(i, 4)]
                if float(table_data[i][3]) > 0:  # Arena is slower
                    diff_cell.set_facecolor('#ffcdd2')
                elif float(table_data[i][3]) < 0:  # Arena is faster
                    diff_cell.set_facecolor('#c8e6c9')
            
            plt.title('Detailed Performance Comparison', fontsize=16, pad=20)
            plt.savefig('results/arena_performance_table.png', bbox_inches='tight')
            plt.close()  

if __name__ == "__main__":
    analyze_results("my_arena/results1.csv")