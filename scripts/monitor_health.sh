#!/usr/bin/env bash
set -euo pipefail

CPU_THRESHOLD=${CPU_THRESHOLD:-80}
MEM_THRESHOLD=${MEM_THRESHOLD:-80}
DISK_THRESHOLD=${DISK_THRESHOLD:-90}
PROC_THRESHOLD=${PROC_THRESHOLD:-300}
INTERVAL=${INTERVAL:-0}
LOG_FILE=${LOG_FILE:-}

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  if [ -n "$LOG_FILE" ]; then
    echo "$msg" | tee -a "$LOG_FILE"
  else
    echo "$msg"
  fi
}

cpu_usage() {
  read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  local total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
  local idle1=$((idle + iowait))
  sleep 1
  read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  local total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
  local idle2=$((idle + iowait))

  local total_diff=$((total2 - total1))
  local idle_diff=$((idle2 - idle1))
  if [ "$total_diff" -le 0 ]; then
    echo "0"
    return
  fi
  awk "BEGIN {printf \"%.2f\", (1 - ($idle_diff / $total_diff)) * 100}"
}

mem_usage() {
  local total available
  total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  if [ -z "$total" ] || [ "$total" -eq 0 ]; then
    echo "0"
    return
  fi
  awk "BEGIN {printf \"%.2f\", (1 - ($available / $total)) * 100}"
}

disk_usage() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

proc_count() {
  ps -e --no-headers | wc -l | tr -d ' '
}

check_thresholds() {
  local cpu mem disk procs
  cpu=$(cpu_usage)
  mem=$(mem_usage)
  disk=$(disk_usage)
  procs=$(proc_count)

  log "CPU: ${cpu}% | Memory: ${mem}% | Disk: ${disk}% | Processes: ${procs}"

  local alerts=()
  if awk -v v="$cpu" -v t="$CPU_THRESHOLD" 'BEGIN {exit (v > t) ? 0 : 1}'; then
    alerts+=("CPU usage ${cpu}% > ${CPU_THRESHOLD}%")
  fi
  if awk -v v="$mem" -v t="$MEM_THRESHOLD" 'BEGIN {exit (v > t) ? 0 : 1}'; then
    alerts+=("Memory usage ${mem}% > ${MEM_THRESHOLD}%")
  fi
  [ "$disk" -gt "$DISK_THRESHOLD" ] && alerts+=("Disk usage ${disk}% > ${DISK_THRESHOLD}%")
  [ "$procs" -gt "$PROC_THRESHOLD" ] && alerts+=("Process count ${procs} > ${PROC_THRESHOLD}")

  if [ "${#alerts[@]}" -gt 0 ]; then
    for alert in "${alerts[@]}"; do
      log "ALERT: $alert"
    done
    return 1
  fi
  return 0
}

main() {
  while true; do
    check_thresholds || true
    if [ "$INTERVAL" -gt 0 ]; then
      sleep "$INTERVAL"
    else
      break
    fi
  done
}

main "$@"
