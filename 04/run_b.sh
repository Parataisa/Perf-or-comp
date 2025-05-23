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

CACHE_EVENTS=$(perf list hwcache| awk '{print $1}')
echo "Found cache events: $CACHE_EVENTS"

for program in "${PROGRAMS[@]}"; do
  echo "Testing $program"
  prog_name=$(basename $program | cut -d' ' -f1)
  
  event_file="results_b/${prog_name}_events.csv"
  echo "Event,Count,Relative(%),Overhead(%)" > $event_file
  
  baseline=$(TIMEFORMAT='%3R'; { time $program >/dev/null 2>&1; } 2>&1)
  echo "Baseline time: ${baseline}s"
  
  echo "  Measuring instruction count"
  instr_output=$(perf stat -e instructions $program 2>&1)
  instr_count=$(echo "$instr_output" | grep instructions | awk '{print $1}' | tr -d ',')
  
  echo "  Instruction count: $instr_count"
  FILTERED_EVENTS=$(echo "$CACHE_EVENTS" | tr ' ' '\n' | grep -v "^instructions$" | tr '\n' ' ')
  
  count=$(echo "$instr_output" | grep instructions | awk '{print $1}' | tr -d ',')
  perf_time=$(echo "$instr_output" | grep "seconds time elapsed" | awk '{print $1}')
  
  overhead=$(echo "scale=2; 100 * ($perf_time - $baseline) / $baseline" | bc 2>/dev/null)
  echo "instructions,$count,100,$overhead" >> $event_file
  echo "  Result: $count events, 100% relative, ${overhead}% overhead"
  
  for event in $FILTERED_EVENTS; do
    echo "  Measuring $event"
    output=$(perf stat -e $event $program 2>&1 >/dev/null)
    
    count=$(echo "$output" | grep "$event" | awk '{print $1}' | tr -d ',')
    perf_time=$(echo "$output" | grep "seconds time elapsed" | awk '{print $1}')
    
    relative=$(echo "scale=6; 100 * $count / $instr_count" | bc 2>/dev/null)
    overhead=$(echo "scale=2; 100 * ($perf_time - $baseline) / $baseline" | bc 2>/dev/null)
    
    echo "$event,$count,$relative,$overhead" >> $event_file
    echo "  Result: $count events, ${relative}% relative, ${overhead}% overhead"
  done
done

all_events=""
for program in "${PROGRAMS[@]}"; do
  prog_name=$(basename $program | cut -d' ' -f1)
  all_events="$all_events $(grep -v "Event" "results_b/${prog_name}_events.csv" | cut -d, -f1)"
done
all_events=$(echo "$all_events" | tr ' ' '\n' | sort | uniq)

for event in $all_events; do
  line="$event"
  for program in "${PROGRAMS[@]}"; do
    prog_name=$(basename $program | cut -d' ' -f1)
    val=$(grep "^$event," "results_b/${prog_name}_events.csv" | cut -d, -f3)
    if [ -z "$val" ]; then
      val="N/A"
    fi
    line="$line,$val"
  done
done

for program in "${PROGRAMS[@]}"; do
  prog_name=$(basename $program | cut -d' ' -f1)
  avg_overhead=$(awk -F, 'NR>1 && $1 != "instructions" && $4 != "" {sum+=$4; count++} END {if(count>0) print sum/count; else print "0"}' results_b/${prog_name}_events.csv)
done

echo "Done! Results saved as CSV files in results_b/ directory"