Exercise Sheet 4
================
- use make run_test_cluster and make run_test_local to run the tests

A) Memory profiling
-------------------
- Use the valgrind "massif" tool in Valgrind to determine the largest sources of heap memory utilization, and visualize the results with "massif-visualizer".
  - For the npb_bt program, we do not really have a lot of heap memory usage, just a short peak at the beginning for some io operations.
  - For the SSCA2 program, we have a lot more heap memory, with a peak at around 24,5MB. It looks like the generation of data and computation of the graph is the main source of memory usage. After some time "betweennessCentrality" is called, which starts to use some memory.
  
- How significant is the perturbation in execution time caused by using massif?
  - See runtimes.csv in results_a_local/cluster. 


B) Measuring CPU counters
-------------------------
- See results_b_local/cluster for the results of the CPU counters.
- It looks like the cluster has an additional counter "ref-cycles" which is not available on my local machine.
- The counters have an noticable impact on the runtime of the programs and the number of instructions executed.
- Counters like "cpu-cycles" and "ref-cycles" have a really high count, considering of more than 50% of the total instructions executed when enabling the counters.
- "branch-instructions", "stalled-cycles-frontend", and "stalled-cycles-backend" are also have an quite high count, but not as high as the cycle counters.
- "cache-misses", "brach-misses", and "cache-references" are more or less dismissible, with a count of less than 1% of the total instructions executed.(In this use case, probably not in general) 