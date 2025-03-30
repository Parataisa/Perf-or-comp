run_test_cluster:
	sbatch ./run_cluster.sh ./run_a.sh --output=perf_analysis_a.out
	sbatch ./run_cluster.sh ./run_b.sh --output=perf_analysis_b.out

run_test_local:
	./run_a.sh
	./run_b.sh