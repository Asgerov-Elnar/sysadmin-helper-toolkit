#!/bin/bash

# ===============================
# Linux Admin Toolkit
# ===============================

CONFIG_FILE="./config.conf"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[-] Please run as root${RESET}"
  exit 1
fi

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  echo -e "${YELLOW}[!] Config file not found, using defaults${RESET}"
  DISK_LIMIT=80
fi

pause() {
  read -p "Press Enter to continue..."
}

system_info() {
  echo -e "${BLUE}=== System Information ===${RESET}"
  echo "Hostname: $(hostname)"
  echo "OS: $(lsb_release -d 2>/dev/null | cut -f2)"
  echo "Uptime: $(uptime -p)"
  echo "CPU Load: $(uptime | awk -F'load average:' '{ print $2 }')"
  echo "Memory:"
  free -h
}

service_status() {
  echo -e "${BLUE}=== Service Status ===${RESET}"
  for svc in ssh cron nginx apache2; do
    if systemctl list-unit-files | grep -q "$svc"; then
      systemctl is-active --quiet $svc \
        && echo -e "$svc: ${GREEN}running${RESET}" \
        || echo -e "$svc: ${RED}stopped${RESET}"
    else
      echo -e "$svc: ${YELLOW}not installed${RESET}"
    fi
  done
}

disk_check() {
  echo -e "${BLUE}=== Disk Usage ===${RESET}"
  df -h | awk 'NR==1 || /^\/dev/' | while read line; do
    usage=$(echo $line | awk '{print $5}' | tr -d '%')
    if [[ $usage =~ ^[0-9]+$ ]] && [[ $usage -ge $DISK_LIMIT ]]; then
      echo -e "${RED}$line${RESET}"
    else
      echo "$line"
    fi
  done
}

log_check() {
  echo -e "${BLUE}=== SSH Failed Logins ===${RESET}"
  if [[ -f /var/log/auth.log ]]; then
    grep "Failed password" /var/log/auth.log | tail -10
  else
    echo "auth.log not found"
  fi
}

cleanup() {
  echo -e "${BLUE}=== Cleanup ===${RESET}"
  apt clean >/dev/null 2>&1
  journalctl --vacuum-time=7d >/dev/null 2>&1
  echo -e "${GREEN}Cleanup completed${RESET}"
}

while true; do
  clear
  echo -e "${GREEN}===Linux Admin Toolkit===${RESET}"
  echo "1) System Info"
  echo "2) Service Status"
  echo "3) Disk Usage Check"
  echo "4) Log Analysis"
  echo "5) Cleanup"
  echo "0) Exit"
  read -p "Select option: " choice

  case $choice in
    1) system_info; pause ;;
    2) service_status; pause ;;
    3) disk_check; pause ;;
    4) log_check; pause ;;
    5) cleanup; pause ;;
    0) exit 0 ;;
    *) echo "Invalid option"; pause ;;
  esac
done
