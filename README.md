# collect_tcp_sessions
This script reads current TCP connections with ss, filters sessions for configured destionation, counts them by source IP and TCP state, converts the results into Prometheus metrics, and pushes them to the configured Pushgateway.
