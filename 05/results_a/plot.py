import pandas as pd
import matplotlib.pyplot as plt
import re
import numpy as np
import seaborn as sns

plt.style.use('ggplot')
sns.set_palette("muted")

def load_data(file_path):
    df = pd.read_csv(file_path)
    
    program_data = []
    
    for _, row in df.iterrows():
        program_full = row['Program']
        description = row['Description']
        avg_time = row['Avg Time (s)']
        
        if '_gcc_-O' in program_full:
            parts = program_full.split('_gcc_')
            program_name = parts[0]
            opt_flag = parts[1]  # e.g., -O0, -O1, etc.
            
            program_data.append({
                'Program': program_name,
                'OptFlag': opt_flag,
                'AvgTime': avg_time
            })
        
        elif 'Benchmark' in description:
            program_name = program_full
            match = re.search(r'Benchmark\s+(O\w+)', description)
            if match:
                opt_flag = f'-{match.group(1)}'
                
                program_data.append({
                    'Program': program_name,
                    'OptFlag': opt_flag,
                    'AvgTime': avg_time
                })
    
    return pd.DataFrame(program_data)

def create_plots(df, output_prefix='optimization'):
    flag_order = ['-O0', '-O1', '-O2', '-O3', '-Os', '-Ofast']
    programs = df['Program'].unique()
    
    for program in programs:
        program_data = df[df['Program'] == program]
        
        plt.figure(figsize=(10, 6))
        
        flags = []
        times = []
        for flag in flag_order:
            flag_data = program_data[program_data['OptFlag'] == flag]
            if not flag_data.empty:
                flags.append(flag)
                times.append(flag_data['AvgTime'].values[0])
        
        bars = plt.bar(flags, times, color=sns.color_palette("muted"))
        for bar in bars:
            height = bar.get_height()
            plt.text(bar.get_x() + bar.get_width()/2., height,
                    f'{height:.2f}',
                    ha='center', va='bottom')
        
        plt.title(f'{program}: Execution Time with Different Optimization Levels')
        plt.xlabel('Optimization Flag')
        plt.ylabel('Average Time (seconds)')
        plt.ylim(0, max(times) * 1.15)
        plt.grid(axis='y', linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        plt.savefig(f'{output_prefix}_{program}_cluster.png')
        plt.close()
    
    plt.figure(figsize=(14, 8))
    pivot_df = pd.pivot_table(df, values='AvgTime', index=['Program'], columns=['OptFlag'])
    
    ordered_cols = [col for col in flag_order if col in pivot_df.columns]
    pivot_df = pivot_df[ordered_cols]
    
    plt.figure(figsize=(14, 8))
    pivot_df.plot(kind='bar', figsize=(14, 8))
    plt.title('Execution Time Comparison Across All Programs')
    plt.xlabel('Program')
    plt.ylabel('Average Time (seconds)')
    plt.legend(title='Optimization Flag')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig(f'{output_prefix}_summary_bars_cluster.png')

def main(file_path='performance_results_cluster.csv'):
    df = load_data(file_path)
    create_plots(df)
    print("Optimization graphs have been generated.")

if __name__ == "__main__":
    main()