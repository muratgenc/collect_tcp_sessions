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
```


## systemd Service and Timer Definition

The following configuration defines a `systemd` **oneshot service** and a `systemd` **timer** to run the TCP session push script automatically every 15 seconds.

### Check Timer Status

To verify whether the timer is active and running:

```bash
systemctl status push-tcp-sessions.timer
```

### Service Unit Definition

Create the service file at:

```bash
sudo vi /etc/systemd/system/push-tcp-sessions.service
```

Add the following content:

```ini
[Unit]
Description=Push TCP session metrics to Pushgateway

[Service]
Type=oneshot
ExecStart=/usr/local/bin/push_tcp_sessions.sh
```

### Timer Unit Definition

Create the timer file at:

```bash
sudo vi /etc/systemd/system/push-tcp-sessions.timer
```

Add the following content:

```ini
[Unit]
Description=Run TCP session push every 15 seconds

[Timer]
OnBootSec=10s
OnUnitActiveSec=15s
AccuracySec=1s

[Install]
WantedBy=timers.target
```

#### Explanation

- `Description=Run TCP session push every 15 seconds`  
  A short description of the timer.

- `OnBootSec=10s`  
  The timer starts 10 seconds after the system boots.

- `OnUnitActiveSec=15s`  
  The service is triggered again 15 seconds after the previous run.

- `AccuracySec=1s`  
  The timer accuracy is set to 1 second.

- `WantedBy=timers.target`  
  This allows the timer to be enabled at boot time.

### Reload systemd

After creating both files, reload `systemd`:

```bash
sudo systemctl daemon-reload
```

### Enable and Start the Timer

Enable the timer and start it immediately:

```bash
sudo systemctl enable --now push-tcp-sessions.timer
```

### Verify the Configuration

Check the timer:

```bash
systemctl status push-tcp-sessions.timer
```

Check the service:

```bash
systemctl status push-tcp-sessions.service
```

### Summary

This is a simple and reliable way to schedule periodic metric collection with native `systemd` components.
