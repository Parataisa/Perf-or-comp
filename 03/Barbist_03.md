Exercise Sheet 3
================

A) Traditional profiling
------------------------
#### Note
- ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1(for geting the ip address)
- build.sg can be used to build the different versions of profiling(build.sh gprof/tracy/both) if no argument is passed it builds the default version
- Each profiling type will be build in there own folder(build, build_gprof, build_tracy)
- Not the full flat profile is shown here, some functions are omitted for better readability

### Program Parameter
- npb_bt_s
    - PROBLEM_SIZE   12
    - NITER_DEFAULT  60
    - DT_DEFAULT     0.010
- npb_bt_w
    - PROBLEM_SIZE   24
    - NITER_DEFAULT  200
    - DT_DEFAULT     0.0008
- npb_bt_a
    - PROBLEM_SIZE   64
    - NITER_DEFAULT  200
    - DT_DEFAULT     0.0008
- npb_bt_b
    - PROBLEM_SIZE   102
    - NITER_DEFAULT  200
    - DT_DEFAULT     0.0003
- npb_bt_c
    - PROBLEM_SIZE   162
    - NITER_DEFAULT  200
    - DT_DEFAULT     0.0001

### Observations
- O(n^3) algorithm
- Lager Problem sizes(a,b,c) show linear scaling with the problem volume(Runtime increases by ~4x when volume increases by ~4x)
- s could be a cache friendly version of the algorithm
- The number of calls to the functions seems to be constant for all the versions
- The top 6 functions account for ~90% of the runtime
- y_solve, z_solve, x_solve, compute_rhs could be vaild targets for optimization(low number of calls and high runtime)
- binvcrhs, matmul_sub, matvec_sub are called a large number of times but have a low runtime(not a priority for optimization)

### LCC3

#### npb_bt_s
  %   cumulative   self              self     total             
 time   seconds   seconds    calls  ms/call  ms/call  name      
 32.36      0.11     0.11   201300     0.00     0.00  binvcrhs  
 20.59      0.18     0.07       61     1.15     1.80  y_solve  
 17.65      0.24     0.06       62     0.97     0.97  compute_rhs  
 14.71      0.29     0.05       61     0.82     1.48  x_solve  
 11.77      0.33     0.04       61     0.66     1.31  z_solve  
  2.94      0.34     0.01   201300     0.00     0.00  matmul_sub  
  0.00      0.34     0.00   201300     0.00     0.00  matvec_sub  
  0.00      0.34     0.00    27792     0.00     0.00  exact_solution  
  0.00      0.34     0.00    18300     0.00     0.00  binvrhs  
  0.00      0.34     0.00    18300     0.00     0.00  lhsinit  

#### npb_bt_w
  %   cumulative   self              self     total             
 time   seconds   seconds    calls  ms/call  ms/call  name      
 23.79      2.70     2.70  6712596     0.00     0.00  binvcrhs  
 15.24      4.43     1.73      202     8.57     8.57  compute_rhs  
 14.72      6.10     1.67      201     8.31    15.76  z_solve  
 14.63      7.76     1.66      201     8.26    15.71  y_solve  
 14.45      9.40     1.64      201     8.16    15.62  x_solve  
 12.34     10.80     1.40  6712596     0.00     0.00  matmul_sub  
  2.34     11.07     0.27  6712596     0.00     0.00  matvec_sub  
  1.06     11.19     0.12      201     0.60     0.60  add  
  0.62     11.26     0.07   291852     0.00     0.00  lhsinit  
  0.53     11.32     0.06   291852     0.00     0.00  binvrhs  
  0.09     11.33     0.01   221472     0.00     0.00  exact_solution  
  0.09     11.34     0.01        2     5.00     8.90  initialize  

#### npb_bt_a
  %   cumulative   self              self     total             
 time   seconds   seconds    calls   s/call   s/call  name      
 25.44     64.67    64.67 146029716     0.00     0.00  binvcrhs  
 15.83    104.90    40.23      202     0.20     0.20  compute_rhs  
 15.01    143.07    38.16      201     0.19     0.36  z_solve  
 14.61    180.21    37.14      201     0.18     0.35  y_solve  
 14.01    215.83    35.61      201     0.18     0.34  x_solve  
 11.00    243.79    27.96 146029716     0.00     0.00  matmul_sub  
  2.40    249.88     6.09 146029716     0.00     0.00  matvec_sub  
  0.81    251.94     2.06      201     0.01     0.01  add  
  0.36    252.84     0.91  2317932     0.00     0.00  lhsinit  
  0.22    253.41     0.57  4195072     0.00     0.00  exact_solution  
  0.20    253.91     0.50  2317932     0.00     0.00  binvrhs  
  0.06    254.07     0.16        1     0.16     0.26  exact_rhs  
  0.02    254.13     0.06        2     0.03     0.24  initialize  

#### npb_bt_b
  %   cumulative   self              self     total             
 time   seconds   seconds    calls   s/call   s/call  name      
 25.55    267.01   267.01 609030000     0.00     0.00  binvcrhs  
 15.21    425.97   158.97      201     0.79     1.48  z_solve  
 15.14    584.25   158.27      202     0.78     0.78  compute_rhs  
 14.38    734.56   150.32      201     0.75     1.44  y_solve  
 14.25    883.48   148.92      201     0.74     1.43  x_solve  
 11.37   1002.32   118.84 609030000     0.00     0.00  matmul_sub  
  2.58   1029.31    26.99 609030000     0.00     0.00  matvec_sub  
  0.79   1037.61     8.30      201     0.04     0.04  add  
  0.28   1040.54     2.93  6030000     0.00     0.00  lhsinit  
  0.21   1042.69     2.15 16980552     0.00     0.00  exact_solution  
  0.11   1043.83     1.14  6030000     0.00     0.00  binvrhs  
  0.07   1044.54     0.71        1     0.71     1.10  exact_rhs  
  0.03   1044.88     0.34        2     0.17     0.98  initialize  

#### npb_bt_c
- Timeout

### Local

#### npb_bt_s
  %   cumulative   self              self     total           
 time   seconds   seconds    calls  ms/call  ms/call  name    
 40.00      0.06     0.06       61     0.98     1.09  z_solve
 33.33      0.11     0.05       62     0.81     0.81  compute_rhs
 13.33      0.13     0.02   201300     0.00     0.00  binvcrhs
 13.33      0.15     0.02       61     0.33     0.33  add
  0.00      0.15     0.00   201300     0.00     0.00  matmul_sub
  0.00      0.15     0.00   201300     0.00     0.00  matvec_sub
  0.00      0.15     0.00    27792     0.00     0.00  exact_solution
  0.00      0.15     0.00    18300     0.00     0.00  binvrhs
  0.00      0.15     0.00    18300     0.00     0.00  lhsinit

#### npb_bt_w
  %   cumulative   self              self     total             
 time   seconds   seconds    calls  ms/call  ms/call  name      
 20.40      1.01     1.01  6712596     0.00     0.00  binvcrhs  
 15.96      1.80     0.79      201     3.93     7.08  x_solve  
 14.95      2.54     0.74      202     3.66     3.66  compute_rhs  
 14.34      3.25     0.71      201     3.53     6.68  y_solve  
 13.74      3.93     0.68      201     3.38     6.53  z_solve  
 13.33      4.59     0.66  6712596     0.00     0.00  matmul_sub  
  2.42      4.71     0.12      201     0.60     0.60  add  
  2.22      4.82     0.11  6712596     0.00     0.00  matvec_sub  
  1.62      4.90     0.08   291852     0.00     0.00  lhsinit  
  0.81      4.94     0.04   291852     0.00     0.00  binvrhs  
  0.20      4.95     0.01   221472     0.00     0.00  exact_solution  

#### npb_bt_a
  %   cumulative   self              self     total             
 time   seconds   seconds    calls  ms/call  ms/call  name      
 21.20     22.89    22.89 146029716     0.00     0.00  binvcrhs  
 17.35     41.62    18.73      202    92.72    92.72  compute_rhs  
 15.41     58.25    16.63      201    82.74   148.81  y_solve  
 14.93     74.37    16.12      201    80.20   146.27  z_solve  
 14.20     89.70    15.33      201    76.27   142.34  x_solve  
 12.67    103.38    13.68 146029716     0.00     0.00  matmul_sub  
  2.45    106.03     2.65 146029716     0.00     0.00  matvec_sub  
  0.92    107.02     0.99      201     4.93     4.93  add  
  0.44    107.50     0.48  2317932     0.00     0.00  lhsinit  
  0.19    107.70     0.20  4195072     0.00     0.00  exact_solution  
  0.13    107.84     0.14  2317932     0.00     0.00  binvrhs  
  0.08    107.93     0.09        1    90.00   125.19  exact_rhs  
  0.02    107.95     0.02        2    10.00    86.16  initialize  

#### npb_bt_b
  %   cumulative   self              self     total             
 time   seconds   seconds    calls   s/call   s/call  name      
 20.95     93.23    93.23 609030000     0.00     0.00  binvcrhs  
 17.17    169.62    76.39      202     0.38     0.38  compute_rhs  
 15.40    238.13    68.51      201     0.34     0.61  y_solve  
 14.90    304.42    66.29      201     0.33     0.60  z_solve  
 14.25    367.83    63.41      201     0.32     0.59  x_solve  
 13.31    427.04    59.21 609030000     0.00     0.00  matmul_sub  
  2.47    438.02    10.98 609030000     0.00     0.00  matvec_sub  
  0.93    442.18     4.15      201     0.02     0.02  add  
  0.22    443.15     0.97  6030000     0.00     0.00  lhsinit  
  0.21    444.09     0.94 16980552     0.00     0.00  exact_solution  
  0.10    444.56     0.47  6030000     0.00     0.00  binvrhs  
  0.07    444.88     0.32        1     0.32     0.49  exact_rhs  
  0.01    444.94     0.06        2     0.03     0.39  initialize  
  
#### npb_bt_c
  %   cumulative   self              self     total             
 time   seconds   seconds    calls   s/call   s/call  name      
 21.32    379.83   379.83 2485324800     0.00     0.00  binvcrhs  
 17.55    692.47   312.64      202     1.55     1.55  compute_rhs  
 14.97    959.20   266.73      201     1.33     2.43  z_solve  
 14.90   1224.71   265.51      201     1.32     2.43  y_solve  
 14.03   1474.69   249.98      201     1.24     2.35  x_solve  
 13.38   1713.04   238.35 2485324800     0.00     0.00  matmul_sub  
  2.49   1757.40    44.36 2485324800     0.00     0.00  matvec_sub  
  0.82   1772.09    14.69      201     0.07     0.07  add  
  0.20   1775.70     3.61 68026392     0.00     0.00  exact_solution  
  0.16   1778.58     2.88 15436800     0.00     0.00  lhsinit  
  0.07   1779.78     1.20 15436800     0.00     0.00  binvrhs  
  0.06   1780.92     1.14        1     1.14     1.80  exact_rhs  
  0.02   1781.27     0.35        2     0.17     1.54  initialize  

B) Hybrid trace profiling
-------------------------
#### Note
- Was only run on Local
- npb_bt_w and npb_bt_a were profiled(the Memory usage in Tracy was too high for longer runs)

### Modified Files
- `bt.c` 
  - Entry point and main time step(frame)
- `rhs.c`   
  - `compute_rhs` function was annotated
- `solve_subs.c` 
  - Were annotated but were commented out due to high call count(binvcrhs, matmul_sub, matvec_sub)
- `x_solve.c`, `y_solve.c`, `z_solve.c` 
  - Those functions were annotated as they are called a moderate number of times and have a high runtime

### Runtime Overhead
- npb_bt_w   
  - No Tools: 5.55user 0.00system 0:05.09elapsed 109%CPU
  - GProf: 5.55user 0.01system 0:05.10elapsed 109%CPU
  - Tracy: 9.42user 0.36system 0:07.47elapsed 130%CPU
- npb_bt_a
  - No Tools: 120.20user 0.02system 2:01.94elapsed 98%CPU
  - GProf: 121.09user 0.03system 1:59.86elapsed 101%CPU 
  - Tracy: 185.20user 5.68system 2:49.01elapsed 112%CPU 


### Observations
- Tracy has a higher overhead than gprof also it uses a lot of memory when using a lot of annotations(also if they are called a lot)
- The overhead of gprof is negligible