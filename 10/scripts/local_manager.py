#!/usr/bin/env python3

import os
import sys
import subprocess
import multiprocessing as mp
from pathlib import Path
import logging
import time
import itertools
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import List, Tuple, Dict, Any

from config import (
    DATA_STRUCTURES, RATIOS, ELEMENT_SIZES, NUM_ELEMENTS, TEST_DURATION,
    NUM_REPETITIONS
)

logger = logging.getLogger(__name__)


class LocalManager:
    """Manager for running benchmarks locally."""

    def __init__(self, results_dir: Path, executable_path: Path):
        """
        Initialize LocalManager.

        Args:
            results_dir: Directory to save results
            executable_path: Path to benchmark executable
        """
        self.results_dir = results_dir
        self.executable_path = executable_path
        self.max_workers = mp.cpu_count()

        # Ensure results directory exists
        self.results_dir.mkdir(parents=True, exist_ok=True)

        # Verify executable exists and is executable
        if not self.executable_path.exists():
            raise FileNotFoundError(f"Executable not found: {self.executable_path}")

        if not os.access(self.executable_path, os.X_OK):
            raise PermissionError(f"File is not executable: {self.executable_path}")

    def estimate_memory_usage(self, num_elements, element_size):
        """Estimate memory usage in MB."""
        base_memory = num_elements * element_size / (1024 * 1024)
        
        if element_size == 8:
            overhead = num_elements * 16 / (1024 * 1024)
        else:
            overhead = num_elements * (element_size + 16) / (1024 * 1024)
        
        extra_space = base_memory * 0.1
        return base_memory + overhead + extra_space

    def should_exclude_combination(self, ds, num_elements, element_size):
        """Determine if combination should be excluded."""
        memory_mb = self.estimate_memory_usage(num_elements, element_size)
        
        # More conservative limits for local execution
        if memory_mb > 8 * 1024:  # 8GB limit for local
            logger.info(
                f"Excluding {ds} with {num_elements} elements of {element_size} bytes "
                f"(estimated {memory_mb:.1f} MB)"
            )
            return True
        
        if ds.startswith("list") and num_elements >= 1000000 and element_size >= 512:
            logger.info(f"Excluding slow combination: {ds}")
            return True
        
        return False

    def generate_combinations(self) -> List[Dict[str, Any]]:
        """
        Generate all valid benchmark combinations.

        Returns:
            List of combination dictionaries
        """
        combinations = []
        excluded_count = 0
        
        for ds, ratio, num_elem, elem_size in itertools.product(
            DATA_STRUCTURES, RATIOS, NUM_ELEMENTS, ELEMENT_SIZES
        ):
            if self.should_exclude_combination(ds, num_elem, elem_size):
                excluded_count += 1
                continue
            
            combinations.append({
                "container": ds,
                "size": num_elem,
                "elem_size": elem_size,
                "ratio": ratio,
                "test_duration": TEST_DURATION,
                "estimated_memory_mb": self.estimate_memory_usage(num_elem, elem_size),
            })
        
        logger.info(f"Generated {len(combinations)} combinations, excluded {excluded_count}")
        return combinations

    def get_execution_mode(self) -> Tuple[bool, int]:
        """
        Get execution mode from user.

        Returns:
            Tuple of (is_parallel, num_workers)
        """
        print(f"\nExecution mode options:")
        print(f"1. Sequential (one benchmark at a time)")
        print(f"2. Parallel (multiple benchmarks simultaneously)")

        while True:
            choice = input("\nSelect execution mode (1/2): ").strip()
            if choice == "1":
                return False, 1
            elif choice == "2":
                break
            else:
                print("Invalid choice. Please enter 1 or 2.")

        # Get number of parallel workers
        max_workers = min(self.max_workers, 8)  # Limit to 8 for safety
        print(f"\nSystem has {self.max_workers} CPU cores available.")

        while True:
            worker_input = input(
                f"Number of parallel workers (1-{max_workers}, default: {max_workers}): "
            ).strip()

            if not worker_input:
                return True, max_workers

            try:
                num_workers = int(worker_input)
                if 1 <= num_workers <= max_workers:
                    return True, num_workers
                else:
                    print(f"Please enter a number between 1 and {max_workers}.")
            except ValueError:
                print("Please enter a valid number.")

    def run_single_benchmark(
        self, combination: Dict[str, Any], repetition: int
    ) -> Dict[str, Any]:
        """
        Run a single benchmark.

        Args:
            combination: Benchmark combination dictionary
            repetition: Repetition number

        Returns:
            Dictionary with benchmark results
        """
        # Generate unique filename for this run
        timestamp = int(time.time() * 1000000)  # microseconds for uniqueness
        result_file = (
            self.results_dir / 
            f"{combination['container']}_{combination['size']}_{combination['elem_size']}_"
            f"{combination['ratio']}_{repetition}_{timestamp}.txt"
        )

        # Prepare command: $BENCHMARK_EXE $container $size $elem_size $RATIO $TEST_DURATION
        cmd = [
            str(self.executable_path), 
            combination['container'],
            str(combination['size']),
            str(combination['elem_size']),
            str(combination['ratio']),
            str(combination['test_duration'])
        ]

        logger.debug(f"Running: {' '.join(cmd)}")

        start_time = time.time()

        try:
            # Run benchmark with time measurement
            with open(result_file, "w") as f:
                # Write header info
                f.write(f"Container: {combination['container']}\n")
                f.write(f"Size: {combination['size']}\n")
                f.write(f"Element Size: {combination['elem_size']} bytes\n")
                f.write(f"Ratio: {combination['ratio']}\n")
                f.write(f"Test Duration: {combination['test_duration']} seconds\n")
                f.write(f"Timestamp: {time.ctime()}\n")
                f.write("----------------------------------------\n")
                f.flush()
                
                # Run with /usr/bin/time if available, otherwise just run normally
                if os.path.exists("/usr/bin/time"):
                    time_cmd = ["/usr/bin/time", "-v"] + cmd
                    result = subprocess.run(
                        time_cmd,
                        stdout=f,
                        stderr=subprocess.STDOUT,  # Combine stderr with stdout
                        timeout=300,  # 5 minute timeout
                        text=True,
                    )
                else:
                    result = subprocess.run(
                        cmd,
                        stdout=f,
                        stderr=subprocess.STDOUT,
                        timeout=300,
                        text=True,
                    )
                
                f.write("----------------------------------------\n")
                f.write(f"Benchmark completed at: {time.ctime()}\n")

            end_time = time.time()
            execution_time = end_time - start_time

            if result.returncode == 0:
                logger.debug(
                    f"✓ {combination['container']} size={combination['size']} "
                    f"elem_size={combination['elem_size']} ratio={combination['ratio']} "
                    f"rep={repetition} ({execution_time:.1f}s)"
                )
                return {
                    "combination": combination,
                    "repetition": repetition,
                    "result_file": result_file,
                    "execution_time": execution_time,
                    "success": True,
                    "error": None,
                }
            else:
                logger.error(
                    f"✗ {combination['container']} failed with exit code {result.returncode}"
                )
                return {
                    "combination": combination,
                    "repetition": repetition,
                    "result_file": result_file,  # Keep file for error analysis
                    "execution_time": execution_time,
                    "success": False,
                    "error": f"Exit code {result.returncode}",
                }

        except subprocess.TimeoutExpired:
            logger.error(f"✗ {combination['container']} timed out")
            return {
                "combination": combination,
                "repetition": repetition,
                "result_file": None,
                "execution_time": 300,
                "success": False,
                "error": "Timeout after 300 seconds",
            }
        except Exception as e:
            logger.error(f"✗ {combination['container']} exception: {str(e)}")
            return {
                "combination": combination,
                "repetition": repetition,
                "result_file": None,
                "execution_time": 0,
                "success": False,
                "error": str(e),
            }

    def run_sequential(self, combinations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Run benchmarks sequentially."""
        total_runs = len(combinations) * NUM_REPETITIONS
        results = []

        logger.info(f"Running {total_runs} benchmarks sequentially...")

        run_count = 0
        for combination in combinations:
            for repetition in range(NUM_REPETITIONS):
                run_count += 1

                logger.info(
                    f"[{run_count}/{total_runs}] "
                    f"{combination['container']} size={combination['size']} "
                    f"elem_size={combination['elem_size']} ratio={combination['ratio']} "
                    f"rep={repetition+1}"
                )

                result = self.run_single_benchmark(combination, repetition)
                results.append(result)

        return results

    def run_parallel(
        self, combinations: List[Dict[str, Any]], num_workers: int
    ) -> List[Dict[str, Any]]:
        """Run benchmarks in parallel."""
        total_runs = len(combinations) * NUM_REPETITIONS
        results = []

        logger.info(f"Running {total_runs} benchmarks with {num_workers} workers...")

        # Create list of all tasks
        tasks = []
        for combination in combinations:
            for repetition in range(NUM_REPETITIONS):
                tasks.append((combination, repetition))

        # Run tasks in parallel
        completed_count = 0

        with ProcessPoolExecutor(max_workers=num_workers) as executor:
            # Submit all tasks
            future_to_task = {
                executor.submit(self.run_single_benchmark, combo, rep): (combo, rep)
                for combo, rep in tasks
            }

            # Collect results as they complete
            for future in as_completed(future_to_task):
                completed_count += 1
                combination, repetition = future_to_task[future]

                try:
                    result = future.result()
                    results.append(result)

                    status = "✓" if result["success"] else "✗"
                    logger.info(
                        f"[{completed_count}/{total_runs}] {status} "
                        f"{combination['container']} size={combination['size']} "
                        f"rep={repetition+1}"
                    )

                except Exception as e:
                    logger.error(
                        f"[{completed_count}/{total_runs}] ✗ "
                        f"{combination['container']} failed with exception: {e}"
                    )
                    results.append(
                        {
                            "combination": combination,
                            "repetition": repetition,
                            "result_file": None,
                            "execution_time": 0,
                            "success": False,
                            "error": str(e),
                        }
                    )

        return results

    def run_all_benchmarks(self) -> List[Dict[str, Any]]:
        """Run all benchmarks with user-selected execution mode."""
        combinations = self.generate_combinations()

        logger.info(f"Generated {len(combinations)} combinations")
        logger.info(f"Total runs: {len(combinations) * NUM_REPETITIONS}")

        # Get execution mode from user
        is_parallel, num_workers = self.get_execution_mode()

        start_time = time.time()

        if is_parallel:
            results = self.run_parallel(combinations, num_workers)
        else:
            results = self.run_sequential(combinations)

        end_time = time.time()
        total_time = end_time - start_time

        # Summary
        successful = sum(1 for r in results if r["success"])
        failed = len(results) - successful

        logger.info("\n" + "=" * 50)
        logger.info("LOCAL BENCHMARK SUMMARY")
        logger.info("=" * 50)
        logger.info(f"Total runs: {len(results)}")
        logger.info(f"Successful: {successful}")
        logger.info(f"Failed: {failed}")
        logger.info(f"Total time: {total_time:.1f} seconds")

        if is_parallel and num_workers > 1:
            logger.info(
                f"Average time per worker: {total_time/num_workers:.1f} seconds"
            )

        return results


if __name__ == "__main__":
    # Simple test
    if len(sys.argv) != 3:
        print("Usage: python local_manager.py <executable_path> <results_dir>")
        sys.exit(1)

    executable_path = Path(sys.argv[1])
    results_dir = Path(sys.argv[2])

    logging.basicConfig(level=logging.INFO)

    manager = LocalManager(results_dir, executable_path)
    results = manager.run_all_benchmarks()

    print(f"\nResults saved to: {results_dir}")
