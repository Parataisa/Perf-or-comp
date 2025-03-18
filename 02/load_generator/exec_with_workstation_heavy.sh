NUMBER_LOADS=6
ENABLE_LOGGING=false  # Set to false to disable logging

if $ENABLE_LOGGING; then
    LOG_FILE="./loadgen_$(date +%s).log"
    echo "Starting workload simulation at $(date)" > $LOG_FILE
else
    LOG_FILE="/dev/null"
fi

killall loadgen &> /dev/null

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOADGEN_PATH="${SCRIPT_DIR}/loadgen"

for ((i=1; i<=$NUMBER_LOADS; i++)); do
    if $ENABLE_LOGGING; then
        echo "Starting load generator $i" >> $LOG_FILE
    fi
    "$LOADGEN_PATH" mc3 ${SCRIPT_DIR}/workstation/sys_load_profile_workstation_excerpt.txt &>> $LOG_FILE &
done

if $ENABLE_LOGGING; then
    echo "Running program with nice priority" >> $LOG_FILE
fi

nice -n 1000 "$@"
PROGRAM_EXIT=$?

if $ENABLE_LOGGING; then
    echo "Program exited with code: $PROGRAM_EXIT" >> $LOG_FILE
fi

killall loadgen &> /dev/null

exit $PROGRAM_EXIT