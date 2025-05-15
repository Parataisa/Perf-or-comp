Exercise Sheet 8
================

A) False Sharing
----------------
https://github.com/KhronosGroup/Vulkan-ValidationLayers/pull/5587

The original implementation, was using byte arrays for padding between variables in structures/classes to prevent false sharing. This approach, works but, it isn't the most modern or maintainable way to handle alignment issues.

### Definition of False Sharing
```
In computer science, false sharing is a performance-degrading usage pattern that can arise in systems with distributed, coherent caches at the size of the smallest resource block managed by the caching mechanism. When a system participant attempts to periodically access data that is not being altered by another party, but that data shares a cache block with data that is being altered, the caching protocol may force the first participant to reload the whole cache block despite a lack of logical necessity.
Source: https://en.wikipedia.org/wiki/False_sharing#cite_note-Patterson_2012_p._537-1 
```
layers/generated/thread_safety.h see removed line 103-108  
layers/utils/vk_layer_utils.h  see removed line 655 - 659  
scripts/thread_safety_generator.py see removed line 237 - 242  

To solve the problem, the developer replaced the manual byte array padding with the `alignas`(https://en.cppreference.com/w/cpp/language/alignas) specifier, which explicitly tells the compiler to align the variable to a specified byte boundary(64 bytes in this case). 

### Side note 
In the PR description, the developer initially tried using ```std::hardware_destructive_interference_size``` (a C++17 feature that represents the minimum recommended alignment to prevent false sharing), but encountered issues on Linux/Android platforms.

B) Data Structure Selection
---------------------------

# Analysis of Godot's AHashMap Implementation (PR #92554)

[PR #92554](https://github.com/godotengine/godot/pull/92554) implements a new data structure called `AHashMap` to replace the existing `HashMap` implementation in certain parts of the Godot game engine, particularly focusing on animation code paths that are performance-critical.

# 🧠 Core Performance Differentiators: HashMap vs AHashMap 📊

### 1️⃣ Memory Layout & Data Organization

```cpp
// Memory Layout Comparison - The Foundation of Performance Difference
// ====================================================================

// HashMap: Separate memory pools with pointer indirection
struct HashMapElement {
    HashMapElement *next = nullptr;  // Linked list overhead
    HashMapElement *prev = nullptr;  // Linked list overhead
    KeyValue<TKey, TValue> data;     // Actual element data
};

// Key member variables
private:
    HashMapElement<TKey, TValue> **elements = nullptr;  // Array of pointers (double indirection)
    uint32_t *hashes = nullptr;                         // Separate hash table
    HashMapElement<TKey, TValue> *head_element = nullptr; // Linked list maintenance
    HashMapElement<TKey, TValue> *tail_element = nullptr; // Linked list maintenance

// AHashMap: Unified, compact memory representation
struct HashMapData {
    union {  // Memory-optimized mapping using union (8 bytes total)
        uint64_t data;  // Single 64-bit access for hash operations
        struct { uint32_t hash; uint32_t hash_to_key; };
    };
};

// Key member variables
private:
    MapKeyValue *elements = nullptr;           // Direct array of elements
    HashMapData *map_data = nullptr;           // Compact hash mapping
```

🔍 **Insight**: The AHashMap implementation demonstrates imporved **spatial locality**.

### 2️⃣ Element Access Pattern

```cpp
// Element Access Pattern Comparison
// =================================

// HashMap: Multiple indirections for element access
bool _lookup(...) const {
	const uint32_t capacity = hash_table_size_primes[capacity_index];
	const uint64_t capacity_inv = hash_table_size_primes_inv[capacity_index];
	uint32_t pos = fastmod(p_hash, capacity_inv, capacity);
	uint32_t distance = 0;
	while (true) {
		if (hashes[pos] == EMPTY_HASH) {
			return false;
		}
		if (distance > _get_probe_length(pos, hashes[pos], capacity, capacity_inv)) {
			return false;
		}
		if (hashes[pos] == p_hash && Comparator::compare(elements[pos]->data.key, p_key)) {
			r_pos = pos;
			return true;
		}
		pos = fastmod((pos + 1), capacity_inv, capacity);
		distance++;
	}
}

// AHashMap: Minimized indirections using direct indexing
bool _lookup(...) const {
    uint32_t pos = p_hash & capacity;
	HashMapData data = map_data[pos];
	if (data.hash == p_hash && Comparator::compare(elements[data.hash_to_key].key, p_key)) {
		r_pos = data.hash_to_key;
		r_hash_pos = pos;
		return true;
	}
    // A collision occurred.
	pos = (pos + 1) & capacity;
	uint32_t distance = 1;
	while (true) {
		data = map_data[pos];
		if (data.hash == p_hash && Comparator::compare(elements[data.hash_to_key].key, p_key)) {
			r_pos = data.hash_to_key;
			r_hash_pos = pos;
			return true;
		}
		if (data.data == EMPTY_HASH) {
			return false;
		}
		if (distance > _get_probe_length(pos, data.hash, capacity)) {
			return false;
		}
		pos = (pos + 1) & capacity;
		distance++;
	}
}

```

🔍 **Insight**: The elimination of one level of indirection significantly reduces pointer chasing, resulting in measured improvements of 25% in lookup operations.

### 3️⃣ Iteration Implementation

```cpp
// Iteration Implementation Comparison - 2000% Performance Difference
// =================================================================

// HashMap: Iterator implementation requiring pointer traversal
struct Iterator {
    _FORCE_INLINE_ Iterator &operator++() {
        if (E) {
            E = E->next;  // Pointer chasing - severe cache penalty
        }
        return *this;
    }
};

// AHashMap: Cache-friendly array-based iteration
struct Iterator {
    _FORCE_INLINE_ Iterator &operator++() {
        pair++;  // Simple pointer arithmetic on contiguous memory
        return *this;
    }
};
```

📊 **Performance Analysis**: The 2000% (20×) iteration performance improvement is primarily attributable to the elimination of pointer chasing during traversal.

### 4️⃣ Memory Allocation Strategy

```cpp
// Memory Management Comparison
// ===========================

// HashMap: Individual element allocation and pointer management
_FORCE_INLINE_ HashMapElement<TKey, TValue> *_insert(...) {
    // Separate allocation for each element
    HashMapElement<TKey, TValue> *elem = Allocator::new_allocation(
        HashMapElement<TKey, TValue>(p_key, p_value));
    
    // Linked list maintenance
    if (tail_element == nullptr) {
        head_element = elem;
        tail_element = elem;
    } else if (p_front_insert) {
        head_element->prev = elem;
        elem->next = head_element;
        head_element = elem;
    } else {
        tail_element->next = elem;
        elem->prev = tail_element;
        tail_element = elem;
    }
    // ...
}

// AHashMap: Efficient bulk allocation and placement new
int32_t _insert_element(...) {
    // Direct placement at end of array - no separate allocation
    memnew_placement(&elements[num_elements], MapKeyValue(p_key, p_value));
    
    // Update hash mapping
    _insert_with_hash(p_hash, num_elements);
    return num_elements++;  // Return index for direct future access
}
```

🧮 **Memory Efficiency**: AHashMap achieves a 2.5× reduction in memory usage by eliminating per-element allocation overhead and pointer fields, which typically consume 16 bytes (2 pointers × 8 bytes) per element on 64-bit systems.

### 5️⃣ Hash Table Optimization

```cpp
// Hash Table Implementation Comparison
// ==================================

// HashMap: Prime-based hash table sizing with complex modulo calculation
static _FORCE_INLINE_ uint32_t _get_probe_length(...) {
    const uint32_t original_pos = fastmod(p_hash, p_capacity_inv, p_capacity);
    return fastmod(p_pos - original_pos + p_capacity, p_capacity_inv, p_capacity);
}

// AHashMap: Power-of-2 capacity with fast bitwise masking
static _FORCE_INLINE_ uint32_t _get_probe_length(...) {
    const uint32_t original_pos = p_hash & p_local_capacity;
    return (p_pos - original_pos + p_local_capacity + 1) & p_local_capacity;
}
```

⚙️ **Algorithmic Optimization**: The replacement of modulo arithmetic with bitwise masking operations represents a significant micro-optimization.

## 📈 Comprehensive Performance Impact Analysis

| Implementation | Test Run | Frames Per Second | Frame Time (ms) |
|:--------------:|:-------:|:-----------------:|:---------------:|
| **ListHashMap (Master)** | 1 | 77 | 12.98 |
| | 2 | 78 | 12.82 |
| | 3 | 78 | 12.82 |
| | 4 | 79 | 12.65 |
| | **Mean** | **78.0** | **12.82** |
| **AHashMap (Current PR)** | 1 | 103 | 9.70 |
| | 2 | 104 | 9.61 |
| | 3 | 103 | 9.70 |
| | 4 | 103 | 9.70 |
| | 5 | 102 | 9.80 |
| | **Mean** | **103.0** | **9.70** |
| **Performance Gain** | | **+32.05%** | **-24.34%** |

*Note: Lower frame time (mspf) values indicate better performance.*

| Operation | Improvement | Primary Mechanism | Secondary Factors |
|-----------|-------------|-------------------|-------------------|
| Iteration | 🚀 2000% | Contiguous memory access | Elimination of pointer dereferencing |
| Lookup | ⚡ 25% | Reduced memory indirection | Better cache utilization |
| Insertion | 🔥 300% | Simplified allocation | Elimination of linked list maintenance |
| Memory Usage | 📉 2.5× | Elimination of per-element overhead | Compact hash representation |
| Application FPS | 📈 27% | Combined effects in critical path | Reduced CPU cache pressure |

*Note: The results were only copied from the PR description, and not verified by me.*

## 🔬 Conclusion

The AHashMap implementation demonstrates that even when algorithmic complexity (O-notation) remains unchanged, actual performance can improve by orders of magnitude through architecture-aware design. The primary performance drivers are:

1. **Cache-conscious memory layout** 
2. **Reduction of pointer indirections** 
3. **Hardware-friendly access patterns** 