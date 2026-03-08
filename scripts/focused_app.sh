#!/usr/bin/env bash

set -euo pipefail

if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "Desktop"
  exit 0
fi

focused_app="$(
  hyprctl activewindow -j 2>/dev/null \
    | jq -r '.class // .initialClass // .title // empty' 2>/dev/null \
    || true
)"

if [ -z "${focused_app}" ] || [ "${focused_app}" = "null" ]; then
  echo "Desktop"
else
  echo "${focused_app}"
fi
