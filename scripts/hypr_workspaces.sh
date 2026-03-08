#!/usr/bin/env bash

set -euo pipefail

count="${EWW_WS_COUNT:-10}"
if ! [[ "${count}" =~ ^[0-9]+$ ]] || [ "${count}" -lt 1 ]; then
  count=10
fi

emit_fallback() {
  printf '['
  for ((i = 1; i <= count; i++)); do
    printf '{"id":%d,"state":"inactive"}' "${i}"
    if [ "${i}" -lt "${count}" ]; then
      printf ','
    fi
  done
  printf ']'
}

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  emit_fallback
  exit 0
fi

active_id="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1' 2>/dev/null || echo 1)"
opened_ids="$(hyprctl workspaces -j 2>/dev/null | jq -r '.[].id' 2>/dev/null | tr '\n' ' ')"

printf '['
for ((i = 1; i <= count; i++)); do
  state="inactive"
  if [ "${i}" = "${active_id}" ]; then
    state="active"
  elif [[ " ${opened_ids} " == *" ${i} "* ]]; then
    state="occupied"
  fi

  printf '{"id":%d,"state":"%s"}' "${i}" "${state}"
  if [ "${i}" -lt "${count}" ]; then
    printf ','
  fi
done
printf ']'
