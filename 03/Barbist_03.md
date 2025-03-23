Exercise Sheet 3
================

A) Traditional profiling
------------------------
#### Note
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