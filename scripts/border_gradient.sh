#!/usr/bin/env bash

set -euo pipefail

step_seconds="${EWW_BORDER_STEP_SECONDS:-12}"
if ! [[ "${step_seconds}" =~ ^[0-9]+$ ]] || [ "${step_seconds}" -lt 1 ]; then
  step_seconds=12
fi

tick=$(( $(date +%s) / step_seconds ))
offset=$(( tick % 200 ))
if [ "${offset}" -gt 100 ]; then
  offset=$((200 - offset))
fi

printf 'background-image: linear-gradient(45deg, #5C9FB2, #54846B, #F7A967, #f7b5c7, #cabbed, #5C9FB2); background-size: 260%% 260%%; background-position: %d%% %d%%;' \
  "${offset}" \
  "${offset}"
