import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

plt.style.use('ggplot')
sns.set_palette("muted")
df = pd.read_csv('flag_analysis.csv')

df['ProgramName'] = df['Program'].apply(lambda x: x.split('/')[-1])
def format_flag(flag):
    return flag.replace('-f', '').replace('-O3 (full)', 'O3 full')

df['FormattedFlag'] = df['Flag'].apply(format_flag)

output_dir = '.'
os.makedirs(output_dir, exist_ok=True)

plt.figure(figsize=(12, 7))

for program in df['Program'].unique():
    program_df = df[df['Program'] == program]
    program_name = program.split('/')[-1]
    
    plt.figure(figsize=(12, 7))
    ax = sns.barplot(x='FormattedFlag', y='Improvement (%)', data=program_df)
    
    plt.axhline(y=0, color='black', linestyle='-', alpha=0.3)
    plt.xticks(rotation=45, ha='right')
    
    plt.xlabel('Compiler Flag')
    plt.ylabel('Performance Improvement (%)')
    plt.title(f'Performance Improvement for {program_name}')
    
    for i, p in enumerate(ax.patches):
        height = p.get_height()
        if not np.isnan(height):
            ax.text(p.get_x() + p.get_width()/2., height + (0.3 if height >= 0 else -0.8),
                    f'{height:.2f}%', ha="center", fontsize=9)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/{program_name}_optimization.png', dpi=300)
    plt.close()

plt.figure(figsize=(14, 10))
pivot_df = df.pivot(index='FormattedFlag', columns='ProgramName', values='Improvement (%)')

ax = sns.heatmap(pivot_df, annot=True, cmap='RdYlGn', center=0, fmt='.2f',
                linewidths=.5, cbar_kws={'label': 'Performance Improvement (%)'})

plt.title('Performance Improvement for All Programs and Flags')
plt.xticks(rotation=45, ha='right')
plt.yticks(rotation=0)
plt.tight_layout()
plt.savefig(f'{output_dir}/combined_heatmap.png', dpi=300)

plt.figure(figsize=(16, 10))
ax = plt.subplot(111)

num_programs = len(df['ProgramName'].unique())
num_flags = len(df['FormattedFlag'].unique())
bar_width = 0.8 / num_programs
index = np.arange(num_flags)

for i, program in enumerate(df['ProgramName'].unique()):
    program_data = df[df['ProgramName'] == program]
    ordered_data = []
    for flag in df['FormattedFlag'].unique():
        flag_value = program_data[program_data['FormattedFlag'] == flag]['Improvement (%)'].values
        ordered_data.append(flag_value[0] if len(flag_value) > 0 else np.nan)
    
    x_positions = index + i * bar_width
    bars = ax.bar(x_positions, ordered_data, bar_width, label=program)

ax.set_xlabel('Compiler Flag')
ax.set_ylabel('Performance Improvement (%)')
ax.set_title('Performance Improvement by Program and Flag')
ax.set_xticks(index + (num_programs - 1) * bar_width / 2)
ax.set_xticklabels(df['FormattedFlag'].unique(), rotation=45, ha='right')

ax.axhline(y=0, color='black', linestyle='-', alpha=0.3)

ax.legend(loc='upper left', bbox_to_anchor=(1, 1))

plt.tight_layout()
plt.savefig(f'{output_dir}/combined_bars.png', dpi=300)

print(f"Plots saved to the '{output_dir}' directory.")