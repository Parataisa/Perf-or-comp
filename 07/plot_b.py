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
        
        # Plot single-threaded performance by allocation size
        thread_count = 1  
        if thread_count in thread_sizes:
            sizes = [x[0] for x in thread_sizes[thread_count]]
            default_times = [x[2] for x in thread_sizes[thread_count]]
            arena_times = [x[3] for x in thread_sizes[thread_count]]
            default_memory = [x[4] for x in thread_sizes[thread_count]]
            arena_memory = [x[5] for x in thread_sizes[thread_count]]
            
            x = np.arange(len(sizes))
            width = 0.35
            
            # Create figure with 2 subplots (time and memory)
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 14))
            
            # Plot execution times
            rects1 = ax1.bar(x - width/2, default_times, width, label='Default Allocator')
            rects2 = ax1.bar(x + width/2, arena_times, width, label='Arena Allocator')
            
            ax1.set_title('Execution Time Comparison by Allocation Size (Single-threaded)')
            ax1.set_xlabel('Allocation Size Range (bytes)')
            ax1.set_ylabel('Execution Time (seconds)')
            ax1.set_xticks(x)
            ax1.set_xticklabels(sizes, rotation=45)
            ax1.legend()
            
            # Plot memory usage
            rects3 = ax2.bar(x - width/2, default_memory, width, label='Default Allocator')
            rects4 = ax2.bar(x + width/2, arena_memory, width, label='Arena Allocator')
            
            ax2.set_title('Memory Usage Comparison by Allocation Size (Single-threaded)')
            ax2.set_xlabel('Allocation Size Range (bytes)')
            ax2.set_ylabel('Memory Usage (MB)')
            ax2.set_xticks(x)
            ax2.set_xticklabels(sizes, rotation=45)
            ax2.legend()
            
            # Add value labels on top of bars
            def autolabel(rects, ax, fmt='.3f'):
                for rect in rects:
                    height = rect.get_height()
                    ax.annotate(f'{height:{fmt}}',
                                xy=(rect.get_x() + rect.get_width() / 2, height),
                                xytext=(0, 3),  # 3 points vertical offset
                                textcoords="offset points",
                                ha='center', va='bottom', fontsize=8)
            
            autolabel(rects1, ax1)
            autolabel(rects2, ax1)
            autolabel(rects3, ax2, '.2f')
            autolabel(rects4, ax2, '.2f')
            
            fig.tight_layout()
            plt.savefig('single_thread_comparison.png')
        
        # Create plots comparing performance by thread count
        threads = sorted(thread_sizes.keys())
        default_times = []
        arena_times = []
        default_memory = []
        arena_memory = []
        
        for t in threads:
            # Filter for the specific size range we're interested in for multi-threaded tests
            data = [(x[2], x[3], x[4], x[5]) for x in thread_sizes[t] if x[0] == f'{MIN_SIZE}-{MAX_SIZE}']
            if data:
                default_times.append(data[0][0])
                arena_times.append(data[0][1])
                default_memory.append(data[0][2])
                arena_memory.append(data[0][3])
            else:
                default_times.append(0)
                arena_times.append(0)
                default_memory.append(0)
                arena_memory.append(0)
        
        x = np.arange(len(threads))
        width = 0.35
        
        # Create figure with 2 subplots (time and memory)
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 14))
        
        # Plot execution times
        rects1 = ax1.bar(x - width/2, default_times, width, label='Default Allocator')
        rects2 = ax1.bar(x + width/2, arena_times, width, label='Arena Allocator')
        
        ax1.set_title(f'Execution Time Comparison by Thread Count (Size range: {MIN_SIZE}-{MAX_SIZE})')
        ax1.set_xlabel('Number of Threads')
        ax1.set_ylabel('Execution Time (seconds)')
        ax1.set_xticks(x)
        ax1.set_xticklabels(threads)
        ax1.legend()
        
        # Plot memory usage
        rects3 = ax2.bar(x - width/2, default_memory, width, label='Default Allocator')
        rects4 = ax2.bar(x + width/2, arena_memory, width, label='Arena Allocator')
        
        ax2.set_title(f'Memory Usage Comparison by Thread Count (Size range: {MIN_SIZE}-{MAX_SIZE})')
        ax2.set_xlabel('Number of Threads')
        ax2.set_ylabel('Memory Usage (MB)')
        ax2.set_xticks(x)
        ax2.set_xticklabels(threads)
        ax2.legend()
        
        autolabel(rects1, ax1)
        autolabel(rects2, ax1)
        autolabel(rects3, ax2, '.2f')
        autolabel(rects4, ax2, '.2f')
        
        fig.tight_layout()
        plt.savefig('thread_comparison.png')
        
        print("\nResults have been saved as:")
        print("- single_thread_comparison.png (Time and memory comparison by allocation size)")
        print("- thread_comparison.png (Time and memory comparison by thread count)")

if __name__ == "__main__":
    # Define the allocation size for multi-threaded tests
    MIN_SIZE = 10
    MAX_SIZE = 1000
    
    # Fix the path to your results file
    analyze_results("/scratch/cb761222/Perf-or-comp/07/my_arena/results.csv")