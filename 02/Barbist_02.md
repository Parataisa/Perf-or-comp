Exercise Sheet 2
================

A) External CPU load
--------------------

- While the option flag ´sim_workload´ is set true in the script, the script will run the `loadgen` tool with the `exec_with_workstation_heavy.sh` script. Sadly i did see any huge impact on the number of requered runs.
See note at the last column of the table in performance_results_workload_local.md/.csv and performance_results_workload_cluster.md/.csv
- But some increase in the execution time was observed. Again,see .csv/.md files for more details.


B) External I/O load
--------------------

- For the implementation see loadgen_io.c and run_tests_with_io_load.sh
- To run the tests, `make test-with-io-load` is used, for cache cleaning sudo is requiert.(see Makefile)
- To config the I/O load, the following parameters can be set in the run_tests_with_io_load.sh script:
    - `IO_THREADS` number of threads to use for I/O load
    - `READ_PERCENT` percentage of read operations
    - `DELAY_MS` delay between I/O operations in milliseconds
    - `MIN_FILE_SIZE` minimum file size in bytes
    - `MAX_FILE_SIZE` maximum file size in bytes
- On my local machine, the I/O load was not very high, most of the time the CPU was the bottleneck.(NVMe SSD Samsung 980 Pro)
- Again the number of requiered runs did not change significantly, but like before the execution time increased slightly. 
  
  