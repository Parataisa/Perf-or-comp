PROGRAMS=(
"build_ssca/ssca2 17"
"build_npb/npb_bt_s"
"build_npb/npb_bt_w"
#"build_npb/npb_bt_a"
#"build_npb/npb_bt_b"
#"build_npb/npb_bt_c"
)

bash ./build.sh

mkdir -p results_b

# Save all available events for reference
perf list > results_b/available_events.txt
echo "Full event list saved to results_b/available_events.txt"

# Get hardware cache events
CACHE_EVENTS=$(perf list | grep "Hardware event" | awk '{print $1}')

# Check if we have any cache events
if [ -z "$CACHE_EVENTS" ]; then
  echo "Warning: No hardware cache events found!"
  CACHE_EVENTS="cache-misses cache-references"
  echo "Using fallback events: $CACHE_EVENTS"
else
  echo "Found cache events: $CACHE_EVENTS"
fi

for program in "${PROGRAMS[@]}"; do
  echo "Testing $program"
  prog_name=$(basename $program | cut -d' ' -f1)
  
  event_file="results_b/${prog_name}_events.csv"
  echo "Event,Count,Relative(%),Overhead(%)" > $event_file
  
  baseline=$(TIMEFORMAT='%3R'; { time $program >/dev/null 2>&1; } 2>&1)
  echo "Baseline time: ${baseline}s"
  
  # Get instruction count for normalization
  echo "  Measuring instruction count"
  instr_output=$(perf stat -e instructions $program 2>&1 >/dev/null)
  instr_count=$(echo "$instr_output" | grep instructions | awk '{print $1}' | tr -d ',')
  
  if [ -z "$instr_count" ]; then
    echo "  Warning: Could not get instruction count. Using 1 as default."
    instr_count=1
  else
    echo "  Instruction count: $instr_count"
  fi
  
  # Measure each cache event
  for event in $CACHE_EVENTS; do
    echo "  Measuring $event"
    output=$(perf stat -e $event $program 2>&1 >/dev/null)
    
    # Extract count and time
    count=$(echo "$output" | grep "$event" | awk '{print $1}' | tr -d ',')
    perf_time=$(echo "$output" | grep "seconds time elapsed" | awk '{print $1}')
    
    if [ -z "$count" ]; then
      echo "  Warning: No data for $event"
      continue
    fi
    
    # Calculate metrics
    relative=$(echo "scale=6; 100 * $count / $instr_count" | bc)
    overhead=$(echo "scale=2; 100 * ($perf_time - $baseline) / $baseline" | bc)
    
    echo "$event,$count,$relative,$overhead" >> $event_file
    echo "  Result: $count events, ${relative}% relative, ${overhead}% overhead"
  done
done

# Create comparison between first two programs
echo "Creating comparison..."
echo "Event,${PROGRAMS[0]}(%),${PROGRAMS[1]}(%),Ratio" > results_b/comparison.csv

prog1=$(basename ${PROGRAMS[0]} | cut -d' ' -f1)
prog2=$(basename ${PROGRAMS[1]} | cut -d' ' -f1)

# Get all events that were measured
all_events=$(cat results_b/${prog1}_events.csv results_b/${prog2}_events.csv | grep -v "Event" | cut -d, -f1 | sort | uniq)

for event in $all_events; do
  val1=$(grep "^$event," results_b/${prog1}_events.csv | cut -d, -f3)
  val2=$(grep "^$event," results_b/${prog2}_events.csv | cut -d, -f3)
  
  if [ -n "$val1" ] && [ -n "$val2" ] && [ "$val1" != "0" ]; then
    ratio=$(echo "scale=2; $val2 / $val1" | bc)
    echo "$event,$val1,$val2,$ratio" >> results_b/comparison.csv
  fi
done

# Create overhead summary
echo "Program,Average_Overhead(%)" > results_b/overhead_summary.csv
for program in "${PROGRAMS[@]}"; do
  prog_name=$(basename $program | cut -d' ' -f1)
  
  # Check if file has data beyond header
  if [ $(wc -l < results_b/${prog_name}_events.csv) -gt 1 ]; then
    avg_overhead=$(awk -F, 'NR>1 && $4 != "" {sum+=$4; count++} END {if(count>0) print sum/count; else print "0"}' results_b/${prog_name}_events.csv)
  else
    avg_overhead="0"
  fi
  
  echo "$program,$avg_overhead" >> results_b/overhead_summary.csv
  echo "Average overhead for $program: ${avg_overhead}%"
done

echo "Done! Results saved as CSV files in results_b/ directory"