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

# Set better figure parameters for text visibility
plt.rcParams.update({
    'figure.autolayout': True,
    'figure.figsize': (12, 7),  # Wider figure
    'axes.labelpad': 10,        # Add padding to axes labels
    'ytick.major.pad': 5,      # Add padding to y-tick labels
    'xtick.major.pad': 5       # Add padding to x-tick labels
})

# Create plots for each combination
for elem_size in df['ElemSize'].unique():
    for container_size in df['Size'].unique():
        subset = df[(df['ElemSize'] == elem_size) & (df['Size'] == container_size)]
        
        if subset.empty:
            continue
        
        # Create figure with sufficient left margin    
        fig, ax = plt.subplots()
        fig.subplots_adjust(left=0.15)  # Increase left margin
        
        # Create the plot
        sns.barplot(x='InsDelRatio', y='OpsPerSecond', hue='Container', data=subset, ax=ax)
        
        elem_size_label = format_size(elem_size)
        ax.set_title(f'Performance: {container_size} elements with {elem_size_label} each')
        ax.set_ylabel('Operations per Second')
        ax.set_xlabel('Insert/Delete Ratio')
        ax.set_yscale('log')
        
        # Adjust legend position
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
        
        # Make sure the y-axis labels are fully visible
        plt.tight_layout(pad=2.0)
        
        # Save the figure
        plt.savefig(f'plot_{container_size}_{elem_size}.png', bbox_inches='tight')
        plt.close()

print("Analysis complete. Plots saved as PNG files.")