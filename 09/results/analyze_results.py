import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load results
df = pd.read_csv('benchmark_results.csv')
df['OpsPerSecond'] = pd.to_numeric(df['OpsPerSecond'])
df['ElemSize'] = pd.to_numeric(df['ElemSize'])
df['Size'] = pd.to_numeric(df['Size'])

# Convert element sizes to human-readable format for display
def format_size(size):
    if size >= 1048576:
        return f"{size/1048576:.0f} MB"
    elif size >= 1024:
        return f"{size/1024:.0f} KB"
    else:
        return f"{size} B"

df['ElemSizeLabel'] = df['ElemSize'].apply(format_size)

# Create plots for each combination
for elem_size in df['ElemSize'].unique():
    for container_size in df['Size'].unique():
        subset = df[(df['ElemSize'] == elem_size) & (df['Size'] == container_size)]
        
        if subset.empty:
            continue
            
        plt.figure(figsize=(10, 6))
        sns.barplot(x='InsDelRatio', y='OpsPerSecond', hue='Container', data=subset)
        
        elem_size_label = format_size(elem_size)
        plt.title(f'Performance: {container_size} elements with {elem_size_label} each')
        plt.ylabel('Operations per Second')
        plt.xlabel('Insert/Delete Ratio')
        plt.tight_layout()
        
        plt.savefig(f'plot_{container_size}_{elem_size}.png')
        plt.close()

print("Analysis complete. Plots saved as PNG files.")