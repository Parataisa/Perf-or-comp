A) Setup and Basic Execution

Timestamp: 2025-06-11-14-18-16 is the baseline

B) Profiling
------------
See [profiling_report](./profiling/profiling_report.md)


C) Code Understanding
---------------------

* Describe the overall process of Lua execution in the interpreter. What are the major phases, and how much time do they take for the benchmark?  
    - 
* What does the option `LUA_USE_JUMPTABLE` do? Measure its performance impact on the benchmark.  
    - `LUA_USE_JUMPTABLE` -> use a jump table for the Lua VM instructions instead of a switch statement.
    - Performance impact: 
        - With `LUA_USE_JUMPTABLE` enabled: [with_LUA_USE_JUMPTABLE](./results/benchmark-2025-06-11-14-33-24.txt)
        - Without `LUA_USE_JUMPTABLE`: [without_LUA_USE_JUMPTABLE](./results/benchmark-2025-06-11-14-38-10.txt)
    - Normaly you would expect a performance improvement with `LUA_USE_JUMPTABLE` enabled, but in this case it seems to have a negative impact on the benchmark performance(its very slime, less than a second) and could also be to standard deviation).
    - One possible reason for this could be that the benchmark is not complex enough to benefit from the jump table optimization, or maybe the compiler already optimizes the switch statement well enough that the jump table does not provide a significant advantage.

D) Optimization
---------------

Optimize the Lua interpreter to more efficiently execute the benchmark.  
Valid strategies include:

 * Compiler optimizations or hints
 * Any manual procedural or algorithmic optimizations
 * Making suitable assumptions / implementing heuristics based on the properties of the benchmark

**Invalid** strategies are:

 * Anything which checks the source code (or its hash etc) against a table of pre-built or pre-optimized solutions
 * Anything which touches the input program
 * Obviously, anything which breaks the interpreter for any other valid Lua program

Your tuned interpreters' best times for all 3 benchmarks will be compared against all other groups' times.
