#!/usr/bin/env bash
set -euo pipefail

# ===== Fixed target =====
DST_IP="9.30.45.102"
DST_PORT="9080"

# ===== Pushgateway =====
PUSHGW="http://10.11.91.46:9091"
JOB="tcp_sessions"
INSTANCE="$(hostname -s 2>/dev/null || hostname)"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

SS_OUT="$(ss -tanH)"

{
  echo "# HELP tcp_sessions TCP sockets by src/dst/port/state (from ss)"
  echo "# TYPE tcp_sessions gauge"
  echo "# HELP tcp_sessions_total Total TCP sockets by src/dst/port (from ss)"
  echo "# TYPE tcp_sessions_total gauge"

  awk -v dip="$DST_IP" -v dport="$DST_PORT" -v inst="$INSTANCE" '
    function ip_only(ep, a) {
      # IPv4 ip:port
      if (match(ep, /^([0-9.]+):[0-9]+$/, a)) return a[1]
      # IPv6 [ip]:port
      if (match(ep, /^\[([0-9a-fA-F:]+)\]:[0-9]+$/, a)) return a[1]
      return ""
    }
    function is_dst(ep) { return (ep == dip ":" dport) }

    {
      state=$1; local=$4; peer=$5
      if (state=="LISTEN") next

      # Two orientations (works whether you run on client or server):
      # client view: peer is dst => src is local ip
      if (is_dst(peer)) {
        src=ip_only(local)
        if (src!="") c[src,state]++
      }
      # server view: local is dst => src is peer ip
      else if (is_dst(local)) {
        src=ip_only(peer)
        if (src!="") c[src,state]++
      }
    }

    END {
      for (k in c) {
        split(k, a, SUBSEP)
        src=a[1]; st=a[2]; cnt=c[k]
        printf "tcp_sessions{instance=\"%s\",src_ip=\"%s\",dst_ip=\"%s\",dst_port=\"%s\",state=\"%s\"} %d\n",
               inst, src, dip, dport, st, cnt
        tot[src]+=cnt
      }
      for (s in tot) {
        printf "tcp_sessions_total{instance=\"%s\",src_ip=\"%s\",dst_ip=\"%s\",dst_port=\"%s\"} %d\n",
               inst, s, dip, dport, tot[s]
      }
    }
  ' <<<"$SS_OUT"
} > "$TMP"

# Push (overwrite this group)
curl -fsS --data-binary @"$TMP" \
  "${PUSHGW}/metrics/job/${JOB}/instance/${INSTANCE}"
