## TCP Session Export Script for Prometheus Pushgateway

This script collects TCP session statistics from the local host using `ss`, filters connections for a fixed destination IP and port, converts the results into Prometheus metric format, and pushes them to a Prometheus Pushgateway.

It is useful for monitoring how many TCP sessions exist per source IP and per TCP state for a specific target service.

---

## What the Script Does

The script:

1. Runs `ss -tanH` to read current TCP socket information.
2. Filters connections related to a fixed target:
   - Destination IP: `9.30.45.102` (It must be modified based on your env)
   - Destination port: `9080` (It must be modified based on your env)
3. Detects connections from both perspectives:
   - **Client side**: remote endpoint matches the target
   - **Server side**: local endpoint matches the target
4. Extracts the source IP address.
5. Counts TCP sessions by:
   - `src_ip`
   - `dst_ip`
   - `dst_port`
   - `state`
6. Generates Prometheus metrics.
7. Pushes the metrics to the configured Pushgateway.
8. PUSHGW="http://10.11.91.46:9091"  (It must be modified based on your env)

---

## Exported Metrics

### `tcp_sessions`

Number of TCP sockets grouped by source IP and TCP state.

Example:

```text
tcp_sessions{instance="host1",src_ip="10.11.17.162",dst_ip="9.30.45.102",dst_port="9080",state="ESTAB"} 12
