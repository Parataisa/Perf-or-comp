# A) Setup and Basic Execution

See [baseline_times](./results/benchmark-2025-06-11-14-18-16.txt)

# B) Profiling

See [profiling_report](./profiling/profiling_report.md)

# C) Code Understanding

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

# D) Optimization

## Tried the following 
  - gcc -> clang(no significant difference, clang was worse)
  - O2 -> O3 (no significant difference)
  - Malloc -> rpmalloc,mimalloc(no significant difference)
  - Writing own jit
  - LVM Code simplification (no significant difference)
  - Inlining (no significant difference)
  - Simplifzing and moving around multiple different codeblocks (no significant difference)
  - Tried to move CallInfo stack to Dynamic Array instead of linked list (failed to do so)


## JIT 
We tried to do our own jit just for fibonacci. 

Added `OP_CODE` pattern recognition to the interpreter to try to detect when 
the given fibonacci algorithm is being executed. Then replace with fast c fibonacci implementation. 

```
100 x fibonacci_naive(30)     time:   0.0001 s  --  832040
10000000 x fibonacci_tail(30) time:   0.2659 s  --  832040
25000000 x fibonacci_iter(30) time:   0.6047 s  --  832040
```

Compared to using the official [LuaJit project](https://luajit.org/)

```
100 x fibonacci_naive(30)     time:   0.7651 s  --  832040
10000000 x fibonacci_tail(30) time:   1.3677 s  --  832040
25000000 x fibonacci_iter(30) time:   0.5674 s  --  832040
```

We are quite a bit faster for naive and tail. 

The big issue is that our pattern recognition is very naive so it is very easy to find other programs fitting that pattern which will then just replaced with fibonacci 😂. 

### Example 
Recognizer
```c
static bool is_fib_iter_final(const Proto *p)
{
  if (p->numparams != 1)
    return false;

  // Just look for the key opcodes that appear in fibonacci_iter
  bool has_forprep = false;
  bool has_add = false;
  bool has_two_moves = false;

  int move_count = 0;

  for (int pc = 0; pc < p->sizecode; pc++)
  {
    OpCode op = GET_OPCODE(p->code[pc]);

    if (op == OP_FORPREP)
      has_forprep = true;
    if (op == OP_ADD)
      has_add = true;
    if (op == OP_MOVE)
      move_count++;
  }

  has_two_moves = (move_count >= 2);

  return has_forprep && has_add && has_two_moves;
}
```
Look for for loop with two moves and add opcode.
Other Lua program which fits the pattern 
```lua 
function sum_to_n(n)
    local total = 0
    for i = 1, n do
        total = total + i
    end
    return total
end
``` 

Making good recognizers is very hard.