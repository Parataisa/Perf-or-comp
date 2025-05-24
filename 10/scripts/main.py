#!/usr/bin/env python3

import os
import sys
from pathlib import Path
import logging
import time
import datetime

from config import DATA_STRUCTURES, NUM_REPETITIONS
from slurm_manager import SlurmManager
from result_parser import ResultParser
from plot_generator import PlotGenerator
from markdown_generator import MarkdownGenerator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def get_user_configuration():
    """Get configuration from user input."""
    print("=" * 60)
    print("Data Structure Benchmark Suite")
    print("=" * 60)
    
    # Ask for benchmark type
    print("\n1. Local benchmarking")
    print("2. LCC3 (SLURM) benchmarking")
    
    while True:
        choice = input("\nSelect benchmark type (1/2): ").strip()
        if choice in ["1", "2"]:
            is_local = choice == "1"
            break
        print("Invalid choice. Please enter 1 or 2.")
    
    # Ask for executable path
    while True:
        executable_path = input("\nEnter path to benchmark executable: ").strip()
        if Path(executable_path).exists():
            break
        print(f"File not found: {executable_path}")
        print("Please enter a valid path.")
    
    # Ask for output directory
    default_dir = Path.cwd() / "benchmark_results"
    output_dir = input(f"\nOutput directory (default: {default_dir}): ").strip()
    if not output_dir:
        output_dir = default_dir
    else:
        output_dir = Path(output_dir)
    
    return {
        "is_local": is_local,
        "executable_path": Path(executable_path),
        "output_dir": Path(output_dir),
    }


def setup_directories(base_dir):
    """Create necessary directories."""
    directories = {
        "base": base_dir,
        "slurm_scripts": base_dir / "slurm_scripts",
        "slurm_logs": base_dir / "slurm_logs", 
        "results": base_dir / "results",
        "plots": base_dir / "results" / "plots",
        "tables": base_dir / "results" / "tables"
    }
    
    for directory in directories.values():
        directory.mkdir(parents=True, exist_ok=True)
    
    logger.info(f"Working directory: {base_dir}")
    return directories


def main():
    """Main function to orchestrate the benchmark suite."""
    start_time = time.time()
    
    # Get user configuration
    config = get_user_configuration()
    
    # Setup directories
    directories = setup_directories(config["output_dir"])
    
    # Initialize managers
    if config["is_local"]:
        logger.info("Local benchmarking not yet implemented")
        sys.exit(1)
    else:
        slurm_manager = SlurmManager(
            directories["slurm_scripts"],
            directories["slurm_logs"],
            config["executable_path"]
        )
    
    result_parser = ResultParser()
    plot_generator = PlotGenerator(directories["plots"])
    markdown_generator = MarkdownGenerator(directories["tables"])
    
    logger.info("Starting comprehensive data structure benchmark suite")
    
    # Generate combinations and submit jobs
    combinations = slurm_manager.generate_combinations()
    logger.info(f"Total combinations: {len(combinations)}")
    logger.info(f"Total jobs: {len(combinations) * NUM_REPETITIONS}")
    
    # Submit jobs
    job_ids = slurm_manager.submit_all_jobs(combinations)
    
    if job_ids:
        # Wait for completion
        slurm_manager.wait_for_jobs(job_ids)
        
        # Collect results
        logger.info("Collecting results...")
        results_df = result_parser.collect_all_results(
            combinations, directories["slurm_logs"]
        )
        
        if not results_df.empty:
            # Save raw results
            results_df.to_csv(directories["results"] / "raw_results.csv", index=False)
            
            # Generate plots
            plot_generator.create_all_plots(results_df)
            
            # Generate markdown report
            markdown_generator.generate_full_report(results_df)
            
            # Print summary
            logger.info("\n" + "=" * 50)
            logger.info("BENCHMARK SUMMARY")
            logger.info("=" * 50)
            
            success_df = results_df[~results_df.get("error", True)]
            logger.info(f"Total runs: {len(results_df)}")
            logger.info(f"Successful runs: {len(success_df)}")
            logger.info(f"Failed runs: {len(results_df) - len(success_df)}")
            
            if not success_df.empty:
                fastest = success_df.loc[success_df["ops_per_second"].idxmax()]
                logger.info(f"\nFastest: {fastest['data_structure']} "
                           f"({fastest['ops_per_second']:.0f} ops/sec)")
        else:
            logger.error("No results collected!")
    
    end_time = time.time()
    total_time = datetime.timedelta(seconds=end_time - start_time)
    logger.info(f"\nTotal execution time: {total_time}")
    logger.info(f"Results saved in: {directories['results']}")


if __name__ == "__main__":
    main()
