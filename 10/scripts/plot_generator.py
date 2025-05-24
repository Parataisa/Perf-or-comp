#!/usr/bin/env python3

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
import logging
from pathlib import Path
from typing import List, Optional

from config import PLOT_FORMAT, PLOT_DPI, PLOT_STYLE

logger = logging.getLogger(__name__)


class PlotGenerator:
    DATA_STRUCTURE_SORT_ORDER = [
        "array",
        "linkedlist_seq",
        "linkedlist_rand",
        "unrolled_linkedlist_8",
        "unrolled_linkedlist_16",
        "unrolled_linkedlist_32",
        "unrolled_linkedlist_64",
        "unrolled_linkedlist_128",
        "unrolled_linkedlist_256",
        "tiered_array_8",
        "tiered_array_16",
        "tiered_array_32",
        "tiered_array_64",
        "tiered_array_128",
        "tiered_array_256",
    ]

    def __init__(self, plots_dir: Path):
        self.plots_dir = Path(plots_dir)
        self.plots_dir.mkdir(parents=True, exist_ok=True)  # Ensure it exists
        plt.style.use(PLOT_STYLE)
        self.palette = sns.color_palette(
            "viridis", n_colors=max(20, len(self.DATA_STRUCTURE_SORT_ORDER))
        )

    def save_plot(self, filename: str, fig=None):
        """Save plot with configured format and DPI."""
        filepath = self.plots_dir / f"{filename}.{PLOT_FORMAT}"
        if fig is None:
            fig = plt.gcf()

        fig.tight_layout()
        fig.savefig(filepath, format=PLOT_FORMAT, dpi=PLOT_DPI, bbox_inches="tight")
        plt.close(fig)
        logger.info(f"Saved plot: {filepath}")

    def _get_plot_order(self, present_structures: List[str]) -> List[str]:
        """
        Returns a sorted list of structures for plotting,
        based on DATA_STRUCTURE_SORT_ORDER.
        Structures not in DATA_STRUCTURE_SORT_ORDER are appended at the end.
        """
        ordered_list = [
            s for s in self.DATA_STRUCTURE_SORT_ORDER if s in present_structures
        ]
        for s in present_structures:
            if s not in ordered_list:
                ordered_list.append(s)
        return ordered_list

    def _get_success_df(self, df: pd.DataFrame) -> pd.DataFrame:
        """Filters for successful runs and ensures correct column names."""
        rename_map = {
            "container": "data_structure",
            "size": "num_elements",
            "elem_size": "element_size",
            "ratio": "ins_del_ratio",
        }
        current_columns = df.columns.tolist()
        actual_renames = {k: v for k, v in rename_map.items() if k in current_columns}

        df_renamed = df.rename(columns=actual_renames) if actual_renames else df.copy()

        required_cols = [
            "data_structure",
            "num_elements",
            "ops_per_second",
            "element_size",
        ]
        missing_req_cols = [
            col for col in required_cols if col not in df_renamed.columns
        ]
        if missing_req_cols:
            logger.error(
                f"Missing required columns for plotting: {missing_req_cols}. "
                f"DataFrame columns: {df_renamed.columns.tolist()}."
            )
            return pd.DataFrame()

        success_df = df_renamed[
            df_renamed["ops_per_second"].notna()
            & ~df_renamed.get("error", pd.Series(False, index=df_renamed.index))
        ].copy()

        for col in [
            "num_elements",
            "element_size",
            "ins_del_ratio",
            "ops_per_second",
            "peak_memory_mb",
        ]:
            if col in success_df.columns:
                success_df[col] = pd.to_numeric(success_df[col], errors="coerce")

        return success_df.dropna(subset=["ops_per_second", "element_size"])

    def create_performance_comparison_unified_bars(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty:
            logger.warning("No data for unified performance comparison bars.")
            return

        agg_df = (
            success_df.groupby(["data_structure", "num_elements"])["ops_per_second"]
            .mean()
            .reset_index()
        )
        if agg_df.empty:
            logger.warning("Aggregated data empty for unified performance bars.")
            return

        unique_num_elements = sorted(agg_df["num_elements"].unique())
        plot_hue_order = self._get_plot_order(agg_df["data_structure"].unique())

        fig, ax = plt.subplots(figsize=(18, 10))
        sns.barplot(
            x="num_elements",
            y="ops_per_second",
            hue="data_structure",
            data=agg_df,
            order=unique_num_elements,
            hue_order=plot_hue_order,
            palette=self.palette,
            ax=ax,
            estimator=np.mean,
            errorbar=None,
        )
        ax.set_title("Performance Comparison Across Data Structures", fontsize=16)
        ax.set_xlabel("Number of Elements", fontsize=14)
        ax.set_ylabel("Mean Operations per Second (Log Scale)", fontsize=14)
        ax.set_yscale("log")
        ax.tick_params(axis="x", rotation=45)
        ax.grid(True, which="both", ls="-", alpha=0.7)
        ax.legend(
            title="Data Structure",
            bbox_to_anchor=(1.02, 1),
            loc="upper left",
            borderaxespad=0.0,
        )
        self.save_plot("performance_comparison_unified_bars", fig=fig)

    def create_performance_relative_to_baseline_array(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty:
            logger.warning("No data for baseline comparison.")
            return

        perf_agg = (
            success_df.groupby(["data_structure", "num_elements"])["ops_per_second"]
            .mean()
            .reset_index()
        )
        array_perf = perf_agg[perf_agg["data_structure"] == "array"].copy()
        if array_perf.empty:
            logger.warning("No 'array' data for baseline. Skipping plot.")
            return

        array_perf = array_perf.rename(
            columns={"ops_per_second": "array_ops_per_second"}
        ).drop(columns=["data_structure"])

        comparison_df = perf_agg[perf_agg["data_structure"] != "array"].copy()
        comparison_df = pd.merge(
            comparison_df, array_perf, on=["num_elements"], how="left"
        )
        comparison_df.dropna(subset=["array_ops_per_second"], inplace=True)
        if comparison_df.empty:
            logger.warning("No data to compare against 'array' baseline.")
            return

        comparison_df["speedup_vs_array"] = (
            comparison_df["ops_per_second"] / comparison_df["array_ops_per_second"]
        )
        plot_hue_order = self._get_plot_order(comparison_df["data_structure"].unique())

        fig, ax = plt.subplots(figsize=(14, 8))
        sns.barplot(
            x="num_elements",
            y="speedup_vs_array",
            hue="data_structure",
            data=comparison_df,
            palette=self.palette,
            ax=ax,
            hue_order=plot_hue_order,
        )
        ax.set_title("Performance Relative to 'array' (Speedup)", fontsize=16)
        ax.set_xlabel("Number of Elements", fontsize=14)
        ax.set_ylabel("Speedup vs. 'array' (Higher is Better)", fontsize=14)
        ax.axhline(1.0, color="red", linestyle="--", label="Baseline ('array')")
        ax.tick_params(
            axis="x",
            rotation=45,
        )
        ax.legend(title="Data Structure", bbox_to_anchor=(1.02, 1), loc="upper left")
        ax.grid(True, axis="y", linestyle="--", alpha=0.7)
        self.save_plot("performance_vs_baseline_array", fig=fig)

    def create_performance_heatmap(
        self,
        df: pd.DataFrame,
        element_size_filter: Optional[int] = 512,
        ins_del_ratio_filter: Optional[float] = 0.01,
    ):
        success_df = self._get_success_df(df)
        if success_df.empty:
            logger.warning("No data for performance heatmap.")
            return

        filtered_df = success_df
        title_suffix = " (Avg over all element sizes & ratios)"
        # Apply filters (code omitted for brevity, same as original)
        if element_size_filter is not None and "element_size" in filtered_df.columns:
            if element_size_filter in filtered_df["element_size"].unique():
                filtered_df = filtered_df[
                    filtered_df["element_size"] == element_size_filter
                ]
                title_suffix = f" (Element Size: {element_size_filter}B"
            else:
                logger.warning(
                    f"Elem size {element_size_filter}B not found for heatmap. Using all."
                )
                element_size_filter = None

        if ins_del_ratio_filter is not None and "ins_del_ratio" in filtered_df.columns:
            if any(
                np.isclose(filtered_df["ins_del_ratio"].unique(), ins_del_ratio_filter)
            ):
                filtered_df = filtered_df[
                    np.isclose(filtered_df["ins_del_ratio"], ins_del_ratio_filter)
                ]
                if element_size_filter is not None:
                    title_suffix += f", Ins/Del: {ins_del_ratio_filter*100:.0f}%)"
                else:
                    title_suffix = f" (Ins/Del: {ins_del_ratio_filter*100:.0f}%)"
            else:
                logger.warning(
                    f"Ratio {ins_del_ratio_filter} not found for heatmap. Using all."
                )
                if element_size_filter is not None and title_suffix.endswith("B"):
                    title_suffix += ", Avg over ratios)"
                elif element_size_filter is None:
                    title_suffix = " (Avg over all element sizes & ratios)"
        if filtered_df.empty:
            logger.warning("No data after filtering for heatmap. Skipping.")
            return

        heatmap_data = (
            filtered_df.groupby(["data_structure", "num_elements"])["ops_per_second"]
            .mean()
            .unstack()
            .fillna(0)
        )
        if heatmap_data.empty:
            logger.warning("Pivoted heatmap data empty. Skipping.")
            return

        sorted_index = self._get_plot_order(heatmap_data.index.tolist())
        if sorted_index and list(heatmap_data.index) != sorted_index:
            heatmap_data = heatmap_data.reindex(sorted_index)

        plt.figure(figsize=(16, max(8, len(heatmap_data.index) * 0.6)))
        sns.heatmap(
            heatmap_data,
            annot=True,
            fmt=".1e",
            cmap="viridis",
            linewidths=0.5,
            cbar_kws={"label": "Mean Operations per Second"},
        )
        plt.title(f"Performance Heatmap{title_suffix}", fontsize=16)
        plt.xlabel("Number of Elements", fontsize=14)
        plt.ylabel("Data Structure", fontsize=14)
        plt.xticks(rotation=45)
        plt.yticks(rotation=0)
        self.save_plot(
            f"performance_heatmap_elem{element_size_filter}_ratio{str(ins_del_ratio_filter).replace('.', '_')}"
        )

    def create_element_size_impact_plot(
        self, df: pd.DataFrame, ins_del_ratio_filter: Optional[float] = 0.01
    ):
        success_df = self._get_success_df(df)
        if success_df.empty or "element_size" not in success_df.columns:
            logger.warning("No data or 'element_size' for impact plot.")
            return

        filtered_df = success_df
        title_suffix = f" (Ins/Del: {ins_del_ratio_filter*100:.0f}%)"
        # Apply ins_del_ratio_filter (code omitted for brevity, same as original)
        if ins_del_ratio_filter is not None and "ins_del_ratio" in filtered_df.columns:
            if any(
                np.isclose(filtered_df["ins_del_ratio"].unique(), ins_del_ratio_filter)
            ):
                filtered_df = filtered_df[
                    np.isclose(filtered_df["ins_del_ratio"], ins_del_ratio_filter)
                ]
            else:
                logger.warning(f"Ratio {ins_del_ratio_filter} not found. Using all.")
                title_suffix = " (Avg over Ins/Del Ratios)"
        if filtered_df.empty:
            logger.warning("No data after filtering for element size plot. Skipping.")
            return

        plot_data = (
            filtered_df.groupby(["data_structure", "num_elements", "element_size"])[
                "ops_per_second"
            ]
            .mean()
            .reset_index()
        )
        if plot_data.empty:
            logger.warning("Aggregated data for element size plot empty.")
            return

        plot_hue_order = self._get_plot_order(plot_data["data_structure"].unique())

        g = sns.catplot(
            x="element_size",
            y="ops_per_second",
            hue="data_structure",
            col="num_elements",
            data=plot_data,
            kind="point",
            sharey=False,
            height=5,
            aspect=1.2,
            palette=self.palette,
            legend="full",
            hue_order=plot_hue_order,
        )
        g.set_axis_labels("Element Size (Bytes)", "Mean Ops per Second")
        g.set_titles("Num Elements: {col_name}")
        g.set(yscale="log")
        g.fig.suptitle(
            f"Impact of Element Size on Performance{title_suffix}", fontsize=16, y=1.03
        )
        for ax in g.axes.flat:
            for label in ax.get_xticklabels():
                label.set_rotation(45)
                label.set_horizontalalignment("right")
        self.save_plot(
            f"element_size_impact_ratio{str(ins_del_ratio_filter).replace('.', '_')}",
            fig=g.fig,
        )

    def create_performance_comparison_bars_categorized(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty:
            logger.warning("No data for categorized performance bars.")
            return

        ds_categories = {
            "Basic": ["array", "linkedlist_seq", "linkedlist_rand"],
            "Unrolled": [
                ds for ds in success_df["data_structure"].unique() if "unrolled" in ds
            ],
            "Tiered": [
                ds for ds in success_df["data_structure"].unique() if "tiered" in ds
            ],
        }
        ds_categories = {
            k: v
            for k, v in ds_categories.items()
            if v and any(ds in success_df["data_structure"].unique() for ds in v)
        }
        if not ds_categories:
            logger.warning("No categories for categorized plot.")
            return

        num_categories = len(ds_categories)
        ncols = min(2, num_categories)
        nrows = (num_categories + ncols - 1) // ncols
        fig, axes = plt.subplots(
            nrows, ncols, figsize=(8 * ncols, 6 * nrows), squeeze=False
        )
        axes_flat = axes.flatten()
        fig.suptitle("Performance Comparison (Categorized)", fontsize=16)
        plot_made = False

        cat_idx = 0
        for category, structures_in_cat in ds_categories.items():
            ax = axes_flat[cat_idx]
            cat_data = success_df[success_df["data_structure"].isin(structures_in_cat)]
            if cat_data.empty:
                ax.set_title(f"{category} (No Data)")
                ax.text(
                    0.5,
                    0.5,
                    "No data",
                    ha="center",
                    va="center",
                    transform=ax.transAxes,
                )
                cat_idx += 1
                continue

            perf_data = (
                cat_data.groupby(["data_structure", "num_elements"])["ops_per_second"]
                .mean()
                .reset_index()
            )
            pivot_data = perf_data.pivot(
                index="num_elements", columns="data_structure", values="ops_per_second"
            )
            if pivot_data.empty:
                ax.set_title(f"{category} (No Pivot Data)")
                cat_idx += 1
                continue

            # Sort columns of pivot_data according to the defined order
            plot_col_order = self._get_plot_order(pivot_data.columns.tolist())
            pivot_data = pivot_data.reindex(columns=plot_col_order)

            pivot_data.plot(
                kind="bar", ax=ax, width=0.8, colormap="viridis"
            )  # Use a consistent palette if possible
            plot_made = True
            ax.set_title(f"{category} Data Structures")
            ax.set_xlabel("Number of Elements")
            ax.set_ylabel("Ops per Second (Log Scale)")
            ax.set_yscale("log")
            ax.legend(loc="upper right", fontsize="small", title=None)
            ax.tick_params(axis="x", rotation=45)
            ax.grid(True, which="both", ls="-", alpha=0.7)
            cat_idx += 1

        for j in range(cat_idx, nrows * ncols):
            fig.delaxes(axes_flat[j])

        if plot_made:
            self.save_plot("performance_comparison_bars_categorized", fig=fig)
        else:
            plt.close(fig)

    def create_chunk_size_analysis(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty:
            logger.warning("No data for chunk size analysis.")
            return

        fig, axes = plt.subplots(1, 2, figsize=(18, 7), sharey=True)
        fig.suptitle("Chunk Size vs. Performance", fontsize=16)
        plot_created = False

        unrolled_data = success_df[
            success_df["data_structure"].str.contains("unrolled", case=False, na=False)
        ].copy()
        if not unrolled_data.empty:
            unrolled_data["chunk_size"] = (
                unrolled_data["data_structure"]
                .str.extract(r"unrolled_linkedlist_(\d+)|unrolled_(\d+)")
                .bfill(axis=1)
                .iloc[:, 0]
                .astype(float)
            )
            unrolled_data.dropna(subset=["chunk_size"], inplace=True)
            unrolled_data["chunk_size"] = unrolled_data["chunk_size"].astype(int)
            if not unrolled_data.empty:
                sns.barplot(
                    x="chunk_size",
                    y="ops_per_second",
                    hue="num_elements",
                    data=unrolled_data,
                    ax=axes[0],
                    palette="crest",
                )
                axes[0].set_title("Unrolled Linked Lists")
                axes[0].set_xlabel("Chunk Size")
                axes[0].set_ylabel("Ops/sec (Log)")
                axes[0].set_yscale("log")
                axes[0].legend(title="Num Elements")
                plot_created = True
            else:
                axes[0].set_title("Unrolled (No Data)")
        else:
            axes[0].set_title("Unrolled (No Data)")

        tiered_data = success_df[
            success_df["data_structure"].str.contains(
                "tiered_array", case=False, na=False
            )
        ].copy()
        if not tiered_data.empty:
            tiered_data["chunk_size"] = (
                tiered_data["data_structure"]
                .str.extract(r"tiered_array_(\d+)")
                .iloc[:, 0]
                .astype(float)
            )
            tiered_data.dropna(subset=["chunk_size"], inplace=True)
            tiered_data["chunk_size"] = tiered_data["chunk_size"].astype(int)
            if not tiered_data.empty:
                sns.barplot(
                    x="chunk_size",
                    y="ops_per_second",
                    hue="num_elements",
                    data=tiered_data,
                    ax=axes[1],
                    palette="flare",
                )
                axes[1].set_title("Tiered Arrays")
                axes[1].set_xlabel("Chunk Size")
                axes[1].set_ylabel("")
                axes[1].set_yscale("log")
                axes[1].legend(title="Num Elements")
                plot_created = True
            else:
                axes[1].set_title("Tiered (No Data)")
        else:
            axes[1].set_title("Tiered (No Data)")

        if plot_created:
            self.save_plot("chunk_size_analysis", fig=fig)
        else:
            plt.close(fig)

    def create_instruction_mix_analysis(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty or "ins_del_ratio" not in success_df.columns:
            logger.warning("No data or 'ins_del_ratio' for mix analysis.")
            return

        plot_data = (
            success_df.groupby(["data_structure", "num_elements", "ins_del_ratio"])[
                "ops_per_second"
            ]
            .mean()
            .reset_index()
        )
        if plot_data.empty:
            logger.warning("Aggregated data for instruction mix empty.")
            return

        plot_col_order = self._get_plot_order(plot_data["data_structure"].unique())

        g = sns.catplot(
            x="ins_del_ratio",
            y="ops_per_second",
            hue="num_elements",  # Could also be data_structure if col is num_elements
            col="data_structure",
            col_wrap=min(3, len(plot_col_order)),  # Adjust col_wrap
            data=plot_data,
            kind="bar",
            sharey=False,
            height=4,
            aspect=1.3,
            palette="magma",
            legend="full",
            col_order=plot_col_order,
        )
        g.set_axis_labels("Insert/Delete Ratio (%)", "Mean Ops per Second")
        g.set_titles("{col_name}")
        g.set(yscale="log")
        g.fig.suptitle("Performance vs. Instruction Mix", fontsize=16, y=1.02)
        for ax in g.axes.flat:
            ax.set_xticklabels(
                [f"{float(t.get_text())*100:.0f}%" for t in ax.get_xticklabels()]
            )
        self.save_plot("instruction_mix_analysis", fig=g.fig)

    def create_memory_efficiency_plot(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty or "peak_memory_mb" not in success_df.columns:
            logger.warning("No data or 'peak_memory_mb' for memory plot.")
            return

        fig, axes = plt.subplots(1, 2, figsize=(18, 7))
        fig.suptitle("Memory Usage and Efficiency", fontsize=16)

        mem_data_avg = (
            success_df.groupby(["data_structure", "num_elements"])["peak_memory_mb"]
            .mean()
            .reset_index()
        )
        if not mem_data_avg.empty:
            plot_hue_order = self._get_plot_order(
                mem_data_avg["data_structure"].unique()
            )
            sns.lineplot(
                data=mem_data_avg,
                x="num_elements",
                y="peak_memory_mb",
                hue="data_structure",
                style="data_structure",
                markers=True,
                dashes=False,
                ax=axes[0],
                palette=self.palette,
                hue_order=plot_hue_order,
            )
            axes[0].set_xscale("log")
            axes[0].set_yscale("log")
            axes[0].set_title("Memory Usage vs. Data Size")
            axes[0].set_xlabel("Num Elements (Log)")
            axes[0].set_ylabel("Peak Mem (MB, Log)")
            axes[0].legend(title="Data Structure", fontsize="small", loc="upper left")
            axes[0].grid(True, which="both", ls="-", alpha=0.7)
        else:
            axes[0].set_title("Memory Usage (No Data)")

        efficiency_data = success_df[success_df["peak_memory_mb"] > 0.01].copy()
        if not efficiency_data.empty:
            efficiency_data["ops_per_mb"] = (
                efficiency_data["ops_per_second"] / efficiency_data["peak_memory_mb"]
            )
            eff_grouped = (
                efficiency_data.groupby("data_structure")["ops_per_mb"]
                .mean()
                .reset_index()
            )
            if not eff_grouped.empty:
                plot_y_order = self._get_plot_order(
                    eff_grouped["data_structure"].unique()
                )
                # For horizontal bar plot, higher values are typically at the top.
                # So, we might want to sort by 'ops_per_mb' descending, then apply categorical order.
                # Or, just use the categorical order. Let's use categorical for consistency.
                # eff_grouped = eff_grouped.set_index('data_structure').reindex(plot_y_order).reset_index()

                sns.barplot(
                    x="ops_per_mb",
                    y="data_structure",
                    data=eff_grouped,
                    ax=axes[1],
                    palette="coolwarm",
                    orient="h",
                    order=plot_y_order,
                )
                axes[1].set_title("Memory Efficiency (Ops/sec per MB)")
                axes[1].set_xlabel("Mean Ops/sec per MB (Higher is Better)")
                axes[1].set_ylabel("Data Structure")
            else:
                axes[1].set_title("Memory Efficiency (No Data)")
        else:
            axes[1].set_title("Memory Efficiency (No Data)")
        self.save_plot("memory_usage_and_efficiency", fig=fig)

    def create_scalability_analysis(self, df: pd.DataFrame):
        success_df = self._get_success_df(df)
        if success_df.empty:
            logger.warning("No data for scalability analysis.")
            return

        perf_by_size_ds = (
            success_df.groupby(["data_structure", "num_elements"])["ops_per_second"]
            .mean()
            .reset_index()
        )
        scalability_data = []
        for ds_name, group in perf_by_size_ds.groupby("data_structure"):
            group = group.sort_values("num_elements")
            if not group.empty and len(group) > 1:
                baseline_perf = group["ops_per_second"].iloc[0]
                baseline_size = group["num_elements"].iloc[0]
                if baseline_perf > 0:
                    for _, row in group.iterrows():
                        scalability_data.append(
                            {
                                "data_structure": ds_name,
                                "num_elements": row["num_elements"],
                                "performance_ratio": row["ops_per_second"]
                                / baseline_perf,
                                "baseline_size": baseline_size,
                            }
                        )
        if not scalability_data:
            logger.warning("Not enough data for scalability ratios.")
            return

        scalability_df = pd.DataFrame(scalability_data)
        plot_hue_order = self._get_plot_order(scalability_df["data_structure"].unique())

        plt.figure(figsize=(14, 8))
        sns.lineplot(
            data=scalability_df,
            x="num_elements",
            y="performance_ratio",
            hue="data_structure",
            style="data_structure",
            markers=True,
            dashes=False,
            palette=self.palette,
            hue_order=plot_hue_order,
        )
        plt.xscale("log")
        plt.title("Performance Scalability (Relative to Smallest Size)", fontsize=16)
        plt.xlabel("Num Elements (Log)", fontsize=14)
        plt.ylabel("Performance Ratio (Higher is Better Scalability)", fontsize=14)
        plt.axhline(1.0, color="grey", linestyle="--", label="Baseline Perf Level")
        plt.legend(title="Data Structure", bbox_to_anchor=(1.02, 1), loc="upper left")
        plt.grid(True, which="both", ls="-", alpha=0.7)
        self.save_plot("scalability_analysis")

    def create_all_plots(self, df: pd.DataFrame):
        if df.empty:
            logger.error("Input DataFrame empty. No plots generated.")
            return

        logger.info("Generating plots...")
        self.create_performance_comparison_unified_bars(df.copy())
        self.create_performance_relative_to_baseline_array(df.copy())
        self.create_performance_heatmap(
            df.copy(), element_size_filter=512, ins_del_ratio_filter=0.01
        )
        self.create_performance_heatmap(  # Example with different params
            df.copy(), element_size_filter=64, ins_del_ratio_filter=0.0
        )
        self.create_element_size_impact_plot(df.copy(), ins_del_ratio_filter=0.01)
        self.create_performance_comparison_bars_categorized(df.copy())
        self.create_chunk_size_analysis(df.copy())
        self.create_instruction_mix_analysis(df.copy())
        self.create_memory_efficiency_plot(df.copy())
        self.create_scalability_analysis(df.copy())
        logger.info(f"All plots saved to {self.plots_dir.resolve()}")
