#!/usr/bin/env bash

set -euo pipefail

clamp_percent() {
  local value="$1"
  if [ "${value}" -lt 0 ]; then
    echo 0
  elif [ "${value}" -gt 100 ]; then
    echo 100
  else
    echo "${value}"
  fi
}

ram_percent=35
cpu_percent=42

if [ -r /proc/meminfo ]; then
  ram_percent="$(
    awk '
      /MemTotal:/ { total = $2 }
      /MemAvailable:/ { available = $2 }
      END {
        if (total > 0) {
          used = total - available
          printf("%.0f\n", (used / total) * 100)
        } else {
          print "0"
        }
      }
    ' /proc/meminfo 2>/dev/null || echo 35
  )"
fi

if [ -r /proc/stat ]; then
  u1=0; n1=0; s1=0; i1=0; w1=0; irq1=0; soft1=0; steal1=0
  u2=0; n2=0; s2=0; i2=0; w2=0; irq2=0; soft2=0; steal2=0
  read -r _ u1 n1 s1 i1 w1 irq1 soft1 steal1 _ < /proc/stat || true
  total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + soft1 + steal1))
  idle1=$((i1 + w1))

  sleep 0.15

  read -r _ u2 n2 s2 i2 w2 irq2 soft2 steal2 _ < /proc/stat || true
  total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + soft2 + steal2))
  idle2=$((i2 + w2))

  delta_total=$((total2 - total1))
  delta_idle=$((idle2 - idle1))

  if [ "${delta_total}" -gt 0 ]; then
    cpu_percent=$((100 * (delta_total - delta_idle) / delta_total))
  else
    cpu_percent=0
  fi
fi

battery_percent=78
battery_present=false
battery_dir="$(find /sys/class/power_supply -maxdepth 1 -type d -name 'BAT*' 2>/dev/null | head -n 1 || true)"

if [ -n "${battery_dir}" ]; then
  battery_present=true
  if [ -f "${battery_dir}/capacity" ]; then
    battery_percent="$(cat "${battery_dir}/capacity" 2>/dev/null || echo 0)"
  elif [ -f "${battery_dir}/energy_now" ] && [ -f "${battery_dir}/energy_full" ]; then
    now="$(cat "${battery_dir}/energy_now" 2>/dev/null || echo 0)"
    full="$(cat "${battery_dir}/energy_full" 2>/dev/null || echo 0)"
    if [ "${full}" -gt 0 ]; then
      battery_percent=$((100 * now / full))
    fi
  elif [ -f "${battery_dir}/charge_now" ] && [ -f "${battery_dir}/charge_full" ]; then
    now="$(cat "${battery_dir}/charge_now" 2>/dev/null || echo 0)"
    full="$(cat "${battery_dir}/charge_full" 2>/dev/null || echo 0)"
    if [ "${full}" -gt 0 ]; then
      battery_percent=$((100 * now / full))
    fi
  fi
fi

ram_percent="$(clamp_percent "${ram_percent}")"
cpu_percent="$(clamp_percent "${cpu_percent}")"
battery_percent="$(clamp_percent "${battery_percent}")"

printf '{"ram":%s,"cpu":%s,"battery":%s,"battery_present":%s}\n' \
  "${ram_percent}" \
  "${cpu_percent}" \
  "${battery_percent}" \
  "${battery_present}"
