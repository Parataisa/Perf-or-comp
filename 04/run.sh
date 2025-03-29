TARGET_PROGRAMS=(
"build_ssca/ssca2 17"
"build_npb/npb_bt_s"
"build_npb/npb_bt_w"
"build_npb/npb_bt_a"
"build_npb/npb_bt_b"
"build_npb/npb_bt_c"
)

bash ./build.sh

echo "Running massif on programs: ${TARGET_PROGRAMS[@]}"
mkdir -p out
runtime_file="out/runtimes.csv"
> "$runtime_file"

echo "Program,Time with Valgrind (s),Time without Valgrind (s),Slowdown Factor" > "$runtime_file"

declare -A times_with_valgrind
declare -A times_without_valgrind

for program in "${TARGET_PROGRAMS[@]}"; do
    echo "Running $program with Valgrind"
    read -r cmd args <<< "$program"
    program_name=$(basename "$cmd")
    
    time_output=$(TIMEFORMAT='%3R'; { time valgrind --tool=massif --massif-out-file="out/massif.${program_name}.out" $cmd $args > /dev/null 2>&1; } 2>&1)
    times_with_valgrind["$program"]=$time_output
    
    echo "Completed $program with Valgrind (${time_output}s)"
done

echo "Done test with valgrind"

for program in "${TARGET_PROGRAMS[@]}"; do
    echo "Running $program without Valgrind"
    read -r cmd args <<< "$program"
    
    time_output=$(TIMEFORMAT='%3R'; { time $cmd $args > /dev/null 2>&1; } 2>&1)
    times_without_valgrind["$program"]=$time_output
    
    echo "Completed $program without Valgrind (${time_output}s)"
done

echo "Done test without valgrind"

for program in "${TARGET_PROGRAMS[@]}"; do
    time_with=${times_with_valgrind["$program"]}
    time_without=${times_without_valgrind["$program"]}
    slowdown=$(echo "scale=2; $time_with / $time_without" | bc)
    echo "$program,$time_with,$time_without,$slowdown" >> "$runtime_file"
done

echo "Timing results written to $runtime_file"