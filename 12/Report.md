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
        - With `LUA_USE_JUMPTABLE` enabled, the benchmark runs ...
        - Without `LUA_USE_JUMPTABLE`, the benchmark runs ...


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
