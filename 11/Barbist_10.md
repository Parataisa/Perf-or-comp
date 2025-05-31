Exercise Sheet 11
=================


A) Applying Memoization (optional)
----------------------------------

Apply basic hash-based memoization to `small_samples/delannoy` and benchmark your implementation. 

 * What level of performance improvement can you achieve, both theoretically and practically?
    * Theoretically, memoization can reduce the time complexity of the Delannoy function from exponential to polynomial, specifically to O(x * y), where x and y are the parameters of the function. 
    * Practically, the performance improvement will depend on the specific input sizes and the overhead of managing the memoization cache.
 * What is the space complexity of your optimized version in terms of the parameters `x` and `y`?
    * The space complexity of the memoized version is O(x * y) due to the storage of results in a hash table, where each unique pair (x, y) corresponds to a computed value.


B) Algorithm Tabulation (optional)
----------------------------------

Use dynamic programming tabulation to implement the `delannoy` benchmark while only requiring `O(x)` additional space and no hashing. Benchmark this solution and compare the results to basic hash-based memoization.

