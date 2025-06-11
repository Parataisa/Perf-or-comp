A) Setup and Basic Execution
------------

See [baseline_times](./results/benchmark-2025-06-11-14-18-16.txt)

B) Profiling
------------

See [profiling_report](./profiling/profiling_report.md)

C) Code Understanding
---------------------

### Describe the overall process of Lua execution in the interpreter. What are the major phases, and how much time do they take for the benchmark?(O3 where used for the times)

- luaV_execute is the main function that executes Lua bytecode instructions (14,04 seconds/79,19%)
- The major phases of Lua execution are:
    1. **Instruction Fetch** - `vmfetch()` extracts bytecode with automatic PC increment
    2. **Opcode Decode** - `GET_OPCODE(i)` extracts 6-bit operation code from 32-bit instruction
    3. **Instruction Dispatch** - Switch/jump table routes to specific instruction implementation
    4. **Execution** - Performs operation and advances to next instruction
- The profiling shows the following time distribution:
    - **luaD_pretailcall (10,10%)** - Tail call optimization to prevent stack growth
    - **luaD_precall (5,58%)** - Function call setup and CallInfo management  
    - **luaH_getshortstr (2,37%)** - Hash table lookups for short string keys
    - **Memory operations (~2,18%)** - Allocation/deallocation overhead
    - **Function call overhead (15,68% total)** - Significant bottleneck for optimization
- Function calling overhead is significant:
    - Function calls (pretailcall + precall): ~15,68% of execution time
    - This suggests that optimizing function call mechanisms could yield performance improvements
- Garbage collection and memory management are relatively efficient in this benchmark
    - Still it could be interesting to swap the memory allocator to a more efficient one
### What does the option `LUA_USE_JUMPTABLE` do? Measure its performance impact on the benchmark.
- `LUA_USE_JUMPTABLE` -> use a jump table for the Lua VM instructions instead of a switch statement.
- In code:  
    - Replaces `switch(o)` with computed goto `*disptab[x]` to eliminate branch prediction overhead
- Performance impact: 
    - With `LUA_USE_JUMPTABLE` enabled: [with_LUA_USE_JUMPTABLE](./results/benchmark-2025-06-11-14-33-24.txt)
    - Without `LUA_USE_JUMPTABLE`: [without_LUA_USE_JUMPTABLE](./results/benchmark-2025-06-11-14-38-10.txt)
- Normaly you would expect a performance improvement with `LUA_USE_JUMPTABLE` enabled, but in this case it seems to have a negativeimpact on the benchmark performance(its very slime, less than a second and could also be to standard deviation).
- One possible reason for this could be that the benchmark is not complex enough to benefit from the jump table optimization, or maybe the compiler already optimizes the switch statement well enough that the jump table does not provide a significant advantage.
- It looks like that on modern processors, the branch prediction is so good that the jump table does not provide a significantadvantage over the switch statement.

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
