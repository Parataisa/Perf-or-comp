Exercise Sheet 8
================

A) False Sharing
----------------

Have a look at this git PR:
https://github.com/KhronosGroup/Vulkan-ValidationLayers/pull/5587

Explain the problem it tries to solve, and how it attempts to do so.


B) Data Structure Selection
---------------------------

Search on Github for a merged pull request in a reasonably sized and popular project (>100 stars) which replaces a data structure in order to improve performance.

Examine the use of this data structure, evaluating all the decision criteria discussed in the lecture, and report your findings.
Do these criteria help indicate that the change in data structure would be beneficial?

### 1. Bevy Game Engine: HashMap Replacement
- **Pull Request:** [Use bevy_utils::HashMap for better performance](https://github.com/bevyengine/bevy/pull/7642)
- **Status:** Merged
- **Description:** Replaced the standard Rust HashMap with a custom implementation that uses a faster hasher, resulting in performance improvements of 10-16% in various benchmarks.
- **Performance Improvement:** Reduced processing time by up to 16.6% for operations with 6000 entities.
- **Decision Criteria Analysis:**
  - **Time Complexity**: Same asymptotic complexity (O(1) average for lookups/insertions), but improved constant factors
  - **Access Patterns**: Specialized for TypeId keys which are predefined u64 values
  - **Thread Safety**: Maintained same thread safety guarantees while improving performance
  - **Memory Usage**: Similar memory footprint, but better cache performance due to more efficient hashing
  - **Key Insight**: The standard Rust HashMap uses SipHash (cryptographically secure but slower) whereas the game engine doesn't need protection against hash-based DoS attacks since TypeIds are controlled internally

- **Benefits Validation**: The benchmarks convincingly demonstrated consistent performance improvements across different entity counts, confirming that matching the data structure properties to actual usage needs yielded substantial performance gains.

### 2. Databend: Custom HashMap for Group By Performance
- **Pull Request:** [Introducing a custom HashMap to improve group by performance](https://github.com/datafuselabs/databend/pull/1443)
- **Status:** Merged
- **Description:** Implemented a custom HashMap to improve group by query performance in this analytics database.
- **Performance Improvement:** Testing showed it was faster than the standard implementation.
- **Decision Criteria Analysis:**
  - **Time Complexity**: Same asymptotic complexity but optimized for database workloads
  - **Access Patterns**: Specialized for specific database group-by query patterns
  - **Memory Efficiency**: Likely improved memory usage through domain-specific optimizations
  - **Concurrency**: Custom implementation better aligned with the database's concurrency model
  - **Key Insight**: The implementation used custom expansion policies (4x expansion before 2^23 capacity, 2x after) tailored to their workload characteristics

- **Benefits Validation**: Performance testing in database scenarios showed improvements in query execution times, particularly for large datasets, confirming that a domain-specific data structure implementation can outperform general-purpose ones.

### 3. ClickHouse Database: HashMap and Arena with Free Lists
- **Pull Request:** [Use HashMap and arena with free lists for keeper](https://github.com/ClickHouse/ClickHouse/pull/33329)
- **Status:** Merged
- **Description:** Improved performance in the ClickHouse database by implementing a more efficient HashMap along with memory arena techniques.
- **Performance Improvement:** Also fixed several memory leaks in the process.
- **Decision Criteria Analysis:**
  - **Time Complexity**: Same lookup/insertion complexity but better real-world performance
  - **Memory Management**: Arena allocation with free lists significantly improved memory usage patterns
  - **Cache Performance**: Better memory locality through specialized allocation strategy
  - **Resource Utilization**: Fixed memory leaks, improving long-term performance stability
  - **Key Insight**: Combined data structure replacement with memory management improvements, addressing both algorithmic and systems-level performance concerns

- **Benefits Validation**: Performance testing showed improved throughput (higher RPS) and reduced latency, demonstrating that memory management strategies can be as important as the data structure choice itself.

### 4. tsParticles: Spatial Hashmap Implementation
- **Issue/PR:** [Performance improvement with Spatial Hashmap](https://github.com/tsparticles/tsparticles/issues/174)
- **Status:** Merged via PR #233
- **Description:** Implemented a spatial hashmap to replace the main loop for performance improvements in this particle system library.
- **Performance Improvement:** Reduced frame compute time from 22ms to 16ms (about 27% improvement).
- **Decision Criteria Analysis:**
  - **Time Complexity**: Reduced from O(n²) to O(n) by avoiding full particle-to-particle comparison
  - **Spatial Locality**: Leveraged physical proximity of particles in 2D/3D space
  - **Access Patterns**: Optimized for nearest-neighbor queries common in particle systems
  - **Algorithm Alignment**: Better matched the specific needs of collision detection
  - **Key Insight**: Used spatial partitioning to drastically reduce the number of comparisons needed in collision detection

- **Benefits Validation**: The 27% frame time improvement directly translated to smoother animations and higher possible particle counts, showing how specialized spatial data structures can transform algorithms with quadratic complexity into more manageable linear ones.

### 5. Flutter Framework: LinkedList for ChangeNotifier
- **Pull Request:** [Use a LinkedList to improve the performances of ChangeNotifier](https://github.com/flutter/flutter/pull/62330)
- **Description:** Improved performance by using a LinkedList instead of an ObserverList to store listeners.
- **Performance Improvement:** Tests showed significant speedup across different numbers of listeners, e.g., operations with 4 listeners were ~75% faster.
- **Decision Criteria Analysis:**
  - **Time Complexity**: Eliminated O(n) contains() checks during listener operations
  - **Memory Overhead**: Likely increased slightly due to LinkedList node overhead
  - **Access Patterns**: Better matched the add/remove/notify patterns of event listeners
  - **Trade-offs**: Sacrificed some memory efficiency for speed
  - **Key Insight**: Identified that the primary operations (adding/removing/notifying listeners) didn't require the contains() check that ObserverList was using

- **Benefits Validation**: Impressive performance gains (up to 75% faster) validated that the new data structure better matched the actual usage patterns in notification systems, where rapid traversal for notification is the dominant operation.

Submission
----------
Please submit your solutions by email to peter.thoman at UIBK, using the string "[Perf2025-sheet8]" in the subject line, before the start of the next VU at the latest.  
Try not to include attachments with a total size larger than 2 MiB.
