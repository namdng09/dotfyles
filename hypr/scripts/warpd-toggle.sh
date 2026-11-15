#!/usr/bin/env bash
set -euo pipefail

BIN="/home/namdng09/src/warpd-local/bin/warpd"
CONF="/home/namdng09/.config/hypr/warpd.conf"
STATE="/tmp/warpd-toggle.mode"

kill_all() {
  local pids
  pids="$(pgrep -f "$BIN" || true)"
  if [[ -n "$pids" ]]; then
    kill $pids 2>/dev/null || true
    sleep 0.15
    pids="$(pgrep -f "$BIN" || true)"
    [[ -n "$pids" ]] && kill -9 $pids 2>/dev/null || true
  fi
  rm -f "$STATE"
}

mode="${1:-}"
[[ -z "$mode" ]] && exit 1

case "$mode" in
  hint)
    args=(--hint --oneshot)
    ;;
  hint-click)
    args=(--hint --click 1 --oneshot)
    ;;
  grid)
    args=(--grid)
    ;;
  normal)
    args=(--normal)
    ;;
  kill)
    kill_all
    exit 0
    ;;
  *)
    exit 1
    ;;
esac

current=""
[[ -f "$STATE" ]] && current="$(cat "$STATE" 2>/dev/null || true)"

if pgrep -f "$BIN" >/dev/null 2>&1; then
  kill_all
  if [[ "$current" == "$mode" ]]; then
    exit 0
  fi
fi

printf '%s\n' "$mode" > "$STATE"
"$BIN" -c "$CONF" "${args[@]}" >/tmp/warpd-${mode}.log 2>&1 &
disown || true
