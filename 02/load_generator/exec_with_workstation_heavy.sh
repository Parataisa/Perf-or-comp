NUMBER_LOADS=20

killall loadgen &> /dev/null

for ((i=1; i<=$NUMBER_LOADS; i++)); do
    ../build/loadgen mc3 workstation/sys_load_profile_workstation_excerpt.txt &> /dev/null &
done
#time -p nice -n 100 $1
nice -n 19 "$@"
PROGRAM_EXIT=$?
killall loadgen &> /dev/null

exit $PROGRAM_EXIT