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
                if key not in results:
                    results[key] = {}
                results[key][alloc] = time
            except (ValueError, KeyError) as e:
                print(f'Warning: Error processing row: {e}')
        
        print('{:<15} {:<15} {:<15} {:<15} {:<15}'.format('Threads', 'Size Range', 'Speedup', 'Default (s)', 'Arena (s)'))
        print('-' * 75)
        
        thread_sizes = {}
        
        for key in sorted(results.keys()):
            if 'Default' in results[key] and 'Arena' in results[key] and results[key]['Default'] > 0:
                threads = key[0]
                size_range = f'{key[1]}-{key[2]}'
                speedup = results[key]['Default'] / results[key]['Arena'] if results[key]['Arena'] > 0 else float('inf')
                
                print('{:<15} {:<15} {:<15.2f} {:<15.6f} {:<15.6f}'.format(
                    threads, 
                    size_range, 
                    speedup,
                    results[key]['Default'],
                    results[key]['Arena']
                ))
                
                if threads not in thread_sizes:
                    thread_sizes[threads] = []
                thread_sizes[threads].append((size_range, speedup, results[key]['Default'], results[key]['Arena']))
        
        thread_count = 1  
        if thread_count in thread_sizes:
            sizes = [x[0] for x in thread_sizes[thread_count]]
            default_times = [x[2] for x in thread_sizes[thread_count]]
            arena_times = [x[3] for x in thread_sizes[thread_count]]
            
            x = np.arange(len(sizes))
            width = 0.35
            
            fig, ax = plt.subplots(figsize=(14, 7))
            rects1 = ax.bar(x - width/2, default_times, width, label='Default Allocator')
            rects2 = ax.bar(x + width/2, arena_times, width, label='Arena Allocator')
            
            ax.set_title('Execution Time Comparison by Allocation Size (Single-threaded)')
            ax.set_xlabel('Allocation Size Range (bytes)')
            ax.set_ylabel('Execution Time (seconds)')
            ax.set_xticks(x)
            ax.set_xticklabels(sizes, rotation=45)
            ax.legend()
            
            # Add value labels on top of bars
            def autolabel(rects):
                for rect in rects:
                    height = rect.get_height()
                    ax.annotate(f'{height:.3f}',
                                xy=(rect.get_x() + rect.get_width() / 2, height),
                                xytext=(0, 3),  # 3 points vertical offset
                                textcoords="offset points",
                                ha='center', va='bottom', fontsize=8)
            
            autolabel(rects1)
            autolabel(rects2)
            
            fig.tight_layout()
            plt.savefig('times_by_size.png')
        
        # Create a plot comparing execution times by thread count
        threads = sorted(thread_sizes.keys())
        default_times = []
        arena_times = []
        
        for t in threads:
            times = [(x[2], x[3]) for x in thread_sizes[t] if x[0] == f'{MIN_SIZE}-{MAX_SIZE}']
            if times:
                default_times.append(times[0][0])
                arena_times.append(times[0][1])
            else:
                default_times.append(0)
                arena_times.append(0)
        
        x = np.arange(len(threads))
        width = 0.35
        
        fig, ax = plt.subplots(figsize=(14, 7))
        rects1 = ax.bar(x - width/2, default_times, width, label='Default Allocator')
        rects2 = ax.bar(x + width/2, arena_times, width, label='Arena Allocator')
        
        ax.set_title(f'Execution Time Comparison by Thread Count (Size range: {MIN_SIZE}-{MAX_SIZE})')
        ax.set_xlabel('Number of Threads')
        ax.set_ylabel('Execution Time (seconds)')
        ax.set_xticks(x)
        ax.set_xticklabels(threads)
        ax.legend()
        
        autolabel(rects1)
        autolabel(rects2)
        
        fig.tight_layout()
        plt.savefig('times_by_threads.png')
        
        print("\nResults have been saved as:")
        print("- times_by_size.png (Execution time comparison by allocation size)")
        print("- times_by_threads.png (Execution time comparison by thread count)")

if __name__ == "__main__":
    # Define the allocation size for multi-threaded tests
    MIN_SIZE = 10
    MAX_SIZE = 1000
    
    analyze_results(results.csv)