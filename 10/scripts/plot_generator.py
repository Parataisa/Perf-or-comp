#!/usr/bin/env python3

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
import logging
from pathlib import Path

from config import PLOT_FORMAT, PLOT_DPI, PLOT_STYLE

logger = logging.getLogger(__name__)


class PlotGenerator:
    def __init__(self, plots_dir):
        self.plots_dir = Path(plots_dir)
        plt.style.use(PLOT_STYLE)
        sns.set_palette("husl")

    def save_plot(self, filename):
        """Save plot with configured format and DPI."""
        filepath = self.plots_dir / f"{filename}.{PLOT_FORMAT}"
        plt.tight_layout()
        plt.savefig(filepath, format=PLOT_FORMAT, dpi=PLOT_DPI, bbox_inches="tight")
        plt.close()
        logger.info(f"Saved plot: {filepath}")

    def create_performance_comparison_bars(self, df):
        """Create bar plots comparing performance across data structures."""
        success_df = df[~df.get("error", True)].copy()
        if success_df.empty:
            return

        # Group data structures by category
        ds_categories = {
            "Basic": ["array", "list_seq", "list_rand"],
            "Unrolled": [
                ds
                for ds in success_df["container"].unique()
                if ds.startswith("unrolled")
            ],
            "Tiered": [
                ds for ds in success_df["container"].unique() if ds.startswith("tiered")
            ],
        }

        # Performance by element count
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle("Performance Comparison Across Data Structures", fontsize=16)

        for i, (category, structures) in enumerate(ds_categories.items()):
            if not structures or i >= 4:
                continue

            cat_data = success_df[success_df["container"].isin(structures)]
            if cat_data.empty:
                continue

            ax = axes[i // 2, i % 2]

            # Group by number of elements and calculate mean performance
            perf_data = (
                cat_data.groupby(["container", "size"])["ops_per_second"]
                .mean()
                .reset_index()
            )

            # Create bar plot
            pivot_data = perf_data.pivot(
                index="size", columns="container", values="ops_per_second"
            )
            pivot_data.plot(kind="bar", ax=ax, width=0.8)

            ax.set_title(f"{category} Data Structures")
            ax.set_xlabel("Number of Elements")
            ax.set_ylabel("Operations per Second")
            ax.set_yscale("log")
            ax.tick_params(axis="x")

        # Remove empty subplot
        if len(ds_categories) < 4:
            for i in range(len(ds_categories), 4):
                fig.delaxes(axes[i // 2, i % 2])

        self.save_plot("performance_comparison_bars")

    def create_chunk_size_analysis(self, df):
        """Analyze performance vs chunk sizes for unrolled and tiered structures."""
        success_df = df[~df.get("error", True)].copy()

        fig, axes = plt.subplots(1, 2, figsize=(16, 6))

        # Unrolled linked lists
        unrolled_data = success_df[
            success_df["container"].str.startswith("unrolled")
        ]
        if not unrolled_data.empty:
            # Extract chunk sizes
            unrolled_data = unrolled_data.copy()
            unrolled_data["chunk_size"] = (
                unrolled_data["container"]
                .str.extract(r"unrolled_linkedlist_(\d+)")
                .astype(int)
            )

            chunk_perf = (
                unrolled_data.groupby(["chunk_size", "size"])["ops_per_second"]
                .mean()
                .reset_index()
            )

            for num_elem in sorted(chunk_perf["size"].unique()):
                elem_data = chunk_perf[chunk_perf["size"] == num_elem]
                axes[0].bar(
                    elem_data["chunk_size"],
                    elem_data["ops_per_second"],
                    alpha=0.7,
                    label=f"{num_elem} elements",
                )

            axes[0].set_title("Unrolled Linked Lists: Chunk Size vs Performance")
            axes[0].set_xlabel("Chunk Size")
            axes[0].set_ylabel("Operations per Second")
            axes[0].set_yscale("log")
            axes[0].legend()

        # Tiered arrays
        tiered_data = success_df[success_df["container"].str.startswith("tiered")]
        if not tiered_data.empty:
            tiered_data = tiered_data.copy()
            tiered_data["chunk_size"] = (
                tiered_data["container"]
                .str.extract(r"tiered_array_(\d+)")
                .astype(int)
            )

            chunk_perf = (
                tiered_data.groupby(["chunk_size", "size"])["ops_per_second"]
                .mean()
                .reset_index()
            )

            for num_elem in sorted(chunk_perf["size"].unique()):
                elem_data = chunk_perf[chunk_perf["size"] == num_elem]
                axes[1].bar(
                    elem_data["chunk_size"],
                    elem_data["ops_per_second"],
                    alpha=0.7,
                    label=f"{num_elem} elements",
                )

            axes[1].set_title("Tiered Arrays: Chunk Size vs Performance")
            axes[1].set_xlabel("Chunk Size")
            axes[1].set_ylabel("Operations per Second")
            axes[1].set_yscale("log")
            axes[1].legend()

        self.save_plot("chunk_size_analysis")

    def create_instruction_mix_analysis(self, df):
        """Analyze how instruction mix affects different data structures."""
        success_df = df[~df.get("error", True)].copy()

        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle("Performance vs Instruction Mix", fontsize=16)

        # Select representative data structures
        representative_ds = ["array", "list_seq", "unrolled_32", "tiered_array_32"]

        for i, ds in enumerate(representative_ds):
            if i >= 4:
                break

            ax = axes[i // 2, i % 2]
            ds_data = success_df[success_df["container"] == ds]

            if ds_data.empty:
                continue

            # Group by instruction mix and element count
            mix_perf = (
                ds_data.groupby(["ratio", "size"])["ops_per_second"]
                .mean()
                .reset_index()
            )

            for num_elem in sorted(mix_perf["size"].unique()):
                elem_data = mix_perf[mix_perf["size"] == num_elem]
                ax.bar(
                    elem_data["ratio"] * 100,
                    elem_data["ops_per_second"],
                    alpha=0.7,
                    label=f"{num_elem} elements",
                )

            ax.set_title(f"{ds.replace('_', ' ').title()}")
            ax.set_xlabel("Insert/Delete Ratio (%)")
            ax.set_ylabel("Operations per Second")
            ax.set_yscale("log")
            ax.legend()

        self.save_plot("instruction_mix_analysis")

    def create_memory_efficiency_plot(self, df):
        """Compare memory efficiency across data structures."""
        success_df = df[~df.get("error", True)].copy()

        if "peak_memory_mb" not in success_df.columns:
            return

        fig, axes = plt.subplots(1, 2, figsize=(16, 6))

        # Memory usage vs number of elements
        mem_data = (
            success_df.groupby(["container", "size"])["peak_memory_mb"]
            .mean()
            .reset_index()
        )

        for ds in mem_data["container"].unique():
            ds_data = mem_data[mem_data["container"] == ds]
            axes[0].loglog(
                ds_data["size"],
                ds_data["peak_memory_mb"],
                marker="o",
                label=ds,
                linewidth=2,
            )

        axes[0].set_title("Memory Usage vs Data Structure Size")
        axes[0].set_xlabel("Number of Elements")
        axes[0].set_ylabel("Peak Memory (MB)")
        axes[0].legend()
        axes[0].grid(True, alpha=0.3)

        # Memory efficiency (ops per MB)
        efficiency_data = success_df.copy()
        efficiency_data["ops_per_mb"] = (
            efficiency_data["ops_per_second"] / efficiency_data["peak_memory_mb"]
        )

        eff_grouped = (
            efficiency_data.groupby("container")["ops_per_mb"]
            .mean()
            .sort_values(ascending=True)
        )

        axes[1].barh(range(len(eff_grouped)), eff_grouped.values)
        axes[1].set_yticks(range(len(eff_grouped)))
        axes[1].set_yticklabels(eff_grouped.index)
        axes[1].set_title("Memory Efficiency (Ops/sec per MB)")
        axes[1].set_xlabel("Operations per Second per MB")

        self.save_plot("memory_efficiency")

    def create_scalability_analysis(self, df):
        """Analyze how performance scales with data size."""
        success_df = df[~df.get("error", True)].copy()

        fig, ax = plt.subplots(1, 1, figsize=(12, 8))

        # Calculate performance degradation
        baseline_performance = {}
        scalability_data = []

        for ds in success_df["container"].unique():
            ds_data = success_df[success_df["container"] == ds]
            perf_by_size = (
                ds_data.groupby("size")["ops_per_second"].mean().sort_index()
            )

            if len(perf_by_size) > 1:
                baseline = perf_by_size.iloc[0]  # Performance with smallest dataset

                for size, perf in perf_by_size.items():
                    scalability_data.append(
                        {
                            "container": ds,
                            "size": size,
                            "ratio": perf / baseline,
                        }
                    )

        scalability_df = pd.DataFrame(scalability_data)

        if not scalability_df.empty:
            for ds in scalability_df["container"].unique():
                ds_data = scalability_df[scalability_df["container"] == ds]
                ax.semilogx(
                    ds_data["size"],
                    ds_data["ratio"],
                    marker="o",
                    label=ds,
                    linewidth=2,
                )

            ax.set_title("Performance Scalability (Relative to Smallest Dataset)")
            ax.set_xlabel("Number of Elements")
            ax.set_ylabel("Performance Ratio")
            ax.legend()
            ax.grid(True, alpha=0.3)
            ax.axhline(y=1.0, color="black", linestyle="--", alpha=0.5)

        self.save_plot("scalability_analysis")

    def create_all_plots(self, df):
        """Create all plots for the benchmark results."""
        logger.info("Generating plots...")

        self.create_performance_comparison_bars(df)
        self.create_chunk_size_analysis(df)
        self.create_instruction_mix_analysis(df)
        self.create_memory_efficiency_plot(df)
        self.create_scalability_analysis(df)

        logger.info(f"All plots saved to {self.plots_dir}")
