Exercise Sheet 3
================

A) Traditional profiling
------------------------
#### Note
- add_link_options(-pg) needed to be added to the CMakeLists.txt file to enable profiling
- ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1(for geting the ip address)
- The runtimes for npb_bt_s and npb_bt_w were way to short to get any meaningful profiling data.
- 

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
- 

### LCC3

#### npb_bt_s
  %   cumulative   self               
 time   seconds   seconds   name      
 33.34      0.03     0.03   matmul_sub  
 22.23      0.05     0.02   z_solve  
 11.11      0.06     0.01   binvcrhs  
 11.11      0.07     0.01   binvrhs  
 11.11      0.08     0.01   matvec_sub  
 11.11      0.09     0.01   x_solve  

#### npb_bt_w
  %   cumulative   self                
 time   seconds   seconds   name      
 30.22      0.97     0.97   binvcrhs  
 21.81      1.67     0.70   matmul_sub  
 13.40      2.10     0.43   z_solve  
 11.22      2.46     0.36   y_solve  
  9.35      2.76     0.30   x_solve  
  7.48      3.00     0.24   compute_rhs  
  5.61      3.18     0.18   matvec_sub  
  0.62      3.20     0.02   lhsinit  
  0.31      3.21     0.01   binvrhs  

#### npb_bt_a
  %   cumulative   self               
 time   seconds   seconds   name      
 31.69     23.48    23.48   binvcrhs  
 17.34     36.33    12.85   matmul_sub  
 12.77     45.79     9.46   y_solve  
 11.80     54.53     8.74   z_solve  
 10.78     62.52     7.99   x_solve  
  9.94     69.88     7.36   compute_rhs  
  4.37     73.12     3.24   matvec_sub  
  0.41     73.42     0.30   add  
  0.31     73.65     0.23   binvrhs  
  0.28     73.86     0.21   lhsinit  
  0.18     73.99     0.13   exact_solution  
  0.05     74.03     0.04   set_constants  
  0.04     74.06     0.03   exact_rhs  
  0.01     74.07     0.01   adi  
  0.01     74.08     0.01   initialize  

#### npb_bt_b
  %   cumulative   self               
 time   seconds   seconds   name      
 30.24     94.50    94.50   binvcrhs  
 17.75    149.97    55.48   matmul_sub  
 12.90    190.29    40.32   z_solve  
 12.07    228.01    37.72   y_solve  
 11.45    263.78    35.78   x_solve  
  9.85    294.57    30.79   compute_rhs  
  4.67    309.16    14.59   matvec_sub  
  0.51    310.74     1.58   add  
  0.19    311.33     0.59   lhsinit  
  0.15    311.79     0.46   exact_solution  
  0.12    312.18     0.39   binvrhs  
  0.06    312.38     0.20   exact_rhs  
  0.03    312.47     0.09   set_constants  
  0.02    312.54     0.07   initialize  
  0.01    312.56     0.02   error_norm  
  0.00    312.57     0.01   rhs_norm  

#### npb_bt_c
  %   cumulative   self               
 time   seconds   seconds   name      
 29.30    382.02   382.02   binvcrhs  
 16.82    601.36   219.34   matmul_sub  
 13.51    777.58   176.22   y_solve  
 12.78    944.26   166.68   z_solve  
 11.88   1099.21   154.95   x_solve  
 10.22   1232.44   133.23   compute_rhs  
  4.43   1290.19    57.75   matvec_sub  
  0.54   1297.19     7.00   add  
  0.19   1299.61     2.42   lhsinit  
  0.14   1301.48     1.87   exact_solution  
  0.07   1302.39     0.91   binvrhs  
  0.06   1303.18     0.79   exact_rhs  
  0.03   1303.61     0.43   initialize  
  0.03   1304.03     0.42   set_constants  
  0.00   1304.08     0.05   error_norm  
  0.00   1304.10     0.02   rhs_norm  

### Local

#### npb_bt_s
  %   cumulative   self               
 time   seconds   seconds   name      
 40.00      0.02     0.02   binvcrhs  
 20.00      0.03     0.01   binvrhs  
 20.00      0.04     0.01   matmul_sub  
 20.00      0.05     0.01   z_solve  

#### npb_bt_w
  %   cumulative   self               
 time   seconds   seconds   name      
 36.55      0.53     0.53   binvcrhs  
 15.86      0.76     0.23   x_solve  
 13.10      0.95     0.19   matmul_sub  
 11.03      1.11     0.16   y_solve  
  9.66      1.25     0.14   compute_rhs  
  9.66      1.39     0.14   z_solve  
  2.76      1.43     0.04   matvec_sub  
  0.69      1.44     0.01   binvrhs  
  0.69      1.45     0.01   lhsinit  

#### npb_bt_a
  %   cumulative   self               
 time   seconds   seconds   name      
 32.11      9.68     9.68   binvcrhs  
 14.59     14.08     4.40   matmul_sub  
 13.73     18.22     4.14   z_solve  
 12.70     22.05     3.83   x_solve  
 12.54     25.83     3.78   y_solve  
  9.45     28.68     2.85   compute_rhs  
  3.48     29.73     1.05   matvec_sub  
  0.46     29.87     0.14   add  
  0.36     29.98     0.11   binvrhs  
  0.33     30.08     0.10   lhsinit  
  0.17     30.13     0.05   exact_solution  
  0.07     30.15     0.02   exact_rhs  

#### npb_bt_b
  %   cumulative   self               
 time   seconds   seconds   name      
 32.51     39.94    39.94   binvcrhs  
 14.34     57.56    17.62   matmul_sub  
 13.36     73.97    16.41   y_solve  
 12.68     89.55    15.58   z_solve  
 12.43    104.82    15.27   x_solve  
  9.17    116.09    11.27   compute_rhs  
  4.11    121.14     5.05   matvec_sub  
  0.72    122.02     0.88   add  
  0.24    122.31     0.29   lhsinit  
  0.18    122.53     0.22   binvrhs  
  0.16    122.73     0.20   exact_solution  
  0.09    122.84     0.11   exact_rhs  
  0.02    122.86     0.02   initialize  
  
#### npb_bt_c
  %   cumulative   self               
 time   seconds   seconds   name      
 31.34    159.08   159.08   binvcrhs  
 15.07    235.59    76.51   matmul_sub  
 14.29    308.11    72.52   z_solve  
 13.03    374.25    66.14   y_solve  
 12.56    438.02    63.77   x_solve  
  8.91    483.23    45.21   compute_rhs  
  3.58    501.39    18.16   matvec_sub  
  0.67    504.77     3.38   add  
  0.15    505.55     0.78   lhsinit  
  0.14    506.25     0.70   exact_solution  
  0.12    506.86     0.61   binvrhs  
  0.11    507.40     0.54   exact_rhs  
  0.02    507.49     0.09   initialize  
  0.01    507.52     0.03   error_norm  
  0.00    507.54     0.02   rhs_norm  

B) Hybrid trace profiling
-------------------------