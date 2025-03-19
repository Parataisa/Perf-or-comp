Exercise Sheet 2
================

A) External CPU load
--------------------

- To use the external CPU load, the option flag `sim_cpu_load` in the `test_config.txt` file must be set to `true`.
See note at the last column of the table in performance_results_workload_local.md/.csv and performance_results_workload_cluster.md/.csv to see the number of runs needed to reach the target precision.
- Also increases in the execution time was observed. Again,see .csv/.md files for more details.


B) External I/O load
--------------------

- For the implementation see loadgen_io.c.
- To use the io load, the option flag `simulate_io_load` in the `test_config.txt` file must be set to `true`.(Please use a interactive shell to run the program `srun --pty bash -i`)
- To config the I/O load, the following parameters can be set in the `config.sh` script:
    - `IO_THREADS` number of threads to use for I/O load
    - `READ_PERCENT` percentage of read operations
    - `DELAY_MS` delay between I/O operations in milliseconds
    - `MIN_FILE_SIZE` minimum file size in bytes
    - `MAX_FILE_SIZE` maximum file size in bytes
    - `RUN_DURATION` duration of the I/O load in seconds(0 means infinite)
    - `IO_LOAD_DIR` directory to use for I/O load
- On my local machine, the I/O load was not very high, most of the time the CPU was the bottleneck.(NVMe SSD Samsung 980 Pro)
- Also increases in the execution time was observed. Again, see .csv/.md files for more details.

  
- Note: For figures look at the `figures` and `figures_cluster` directories.
- Also to run the performance tests, `make test` can be used.
- I had to remove the `workstation` in the `load_generator` because of its size, it needs to be added back in. 