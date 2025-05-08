import os
import re
import matplotlib.pyplot as plt
import numpy as np

results_dir = "results"

data = {
    'default': {},
    'rpmalloc': {},
    'mimalloc': {}
}

for allocator in data.keys():
    file_path = os.path.join(results_dir, f"time_{allocator}.txt")
    if not os.path.exists(file_path):
        print(f"Warning: File not found: {file_path}")
        continue
        
    with open(file_path, 'r') as f:
        content = f.read()
        
    user_time = re.search(r'User time \(seconds\): (.+)', content)
    system_time = re.search(r'System time \(seconds\): (.+)', content)
    wall_time = re.search(r'Elapsed \(wall clock\) time \(h:mm:ss or m:ss\): (.+)', content)
    memory = re.search(r'Maximum resident set size \(kbytes\): (.+)', content)
    
    if user_time:
        data[allocator]['user_time'] = float(user_time.group(1))
    if system_time:
        data[allocator]['system_time'] = float(system_time.group(1))
    if wall_time:
        time_str = wall_time.group(1)
        if ':' in time_str:
            parts = time_str.split(':')
            if len(parts) == 2:  # m:ss
                data[allocator]['wall_time'] = float(parts[0]) * 60 + float(parts[1])
            else:  # h:mm:ss
                data[allocator]['wall_time'] = float(parts[0]) * 3600 + float(parts[1]) * 60 + float(parts[2])
        else:
            data[allocator]['wall_time'] = float(time_str)
    if memory:
        data[allocator]['memory'] = float(memory.group(1)) / 1024  # Convert to MB

allocators = list(data.keys())
metrics = ['user_time', 'system_time', 'wall_time', 'memory']
metric_labels = ['User Time (seconds)', 'System Time (seconds)', 'Wall Time (seconds)', 'Memory Usage (MB)']

fig, axs = plt.subplots(2, 2, figsize=(12, 10))
axs = axs.flatten()

for i, (metric, label) in enumerate(zip(metrics, metric_labels)):
    values = [data[allocator].get(metric, 0) for allocator in allocators]
    axs[i].bar(allocators, values)
    axs[i].set_title(label)
    axs[i].set_ylabel(label)
    axs[i].grid(axis='y', linestyle='--', alpha=0.7)
    
    for j, v in enumerate(values):
        axs[i].text(j, v + (max(values) * 0.01), f"{v:.2f}", ha='center')

plt.tight_layout()
plt.savefig(os.path.join(results_dir, 'results/allocator_comparison.png'))

print("\nPerformance Comparison Report")
print("============================\n")
print(f"{'Allocator':<12} {'User Time (s)':<15} {'System Time (s)':<16} {'Wall Time (s)':<15} {'Memory (MB)':<12}")
print("-" * 70)

for allocator in allocators:
    user = data[allocator].get('user_time', 0)
    system = data[allocator].get('system_time', 0)
    wall = data[allocator].get('wall_time', 0)
    mem = data[allocator].get('memory', 0)
    print(f"{allocator:<12} {user:<15.2f} {system:<16.2f} {wall:<15.2f} {mem:<12.2f}")

with open(os.path.join(results_dir, 'report.txt'), 'w') as f:
    f.write("Performance Comparison Report\n")
    f.write("============================\n\n")
    f.write(f"{'Allocator':<12} {'User Time (s)':<15} {'System Time (s)':<16} {'Wall Time (s)':<15} {'Memory (MB)':<12}\n")
    f.write("-" * 70 + "\n")
    
    for allocator in allocators:
        user = data[allocator].get('user_time', 0)
        system = data[allocator].get('system_time', 0)
        wall = data[allocator].get('wall_time', 0)
        mem = data[allocator].get('memory', 0)
        f.write(f"{allocator:<12} {user:<15.2f} {system:<16.2f} {wall:<15.2f} {mem:<12.2f}\n")
    
    if 'user_time' in data['default'] and all('user_time' in data[a] for a in allocators):
        f.write("\nPerformance Improvements (compared to default allocator)\n")
        f.write("===================================================\n\n")
        f.write(f"{'Allocator':<12} {'User Time (%)':<15} {'System Time (%)':<16} {'Wall Time (%)':<15} {'Memory (%)':<12}\n")
        f.write("-" * 70 + "\n")
        
        for allocator in allocators:
            if allocator == 'default':
                continue
            user_imp = (data['default']['user_time'] - data[allocator]['user_time']) / data['default']['user_time'] * 100
            sys_imp = (data['default']['system_time'] - data[allocator]['system_time']) / data['default']['system_time'] * 100
            wall_imp = (data['default']['wall_time'] - data[allocator]['wall_time']) / data['default']['wall_time'] * 100
            mem_imp = (data['default']['memory'] - data[allocator]['memory']) / data['default']['memory'] * 100
            f.write(f"{allocator:<12} {user_imp:<15.2f} {sys_imp:<16.2f} {wall_imp:<15.2f} {mem_imp:<12.2f}\n")

print(f"\nReports and charts saved to {results_dir}")