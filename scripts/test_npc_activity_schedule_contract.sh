#!/usr/bin/env bash
set -euo pipefail

is_hour_in_window() {
  local hour="$1"
  local start="$2"
  local end="$3"

  if (( start < 0 || start > 23 || end < 0 || end > 23 )); then
    echo 0
    return 0
  fi

  if (( start == end )); then
    echo 0
    return 0
  fi

  if (( start < end )); then
    if (( hour >= start && hour < end )); then
      echo 1
    else
      echo 0
    fi
    return 0
  fi

  if (( hour >= start || hour < end )); then
    echo 1
  else
    echo 0
  fi
}

is_slot_window_active() {
  local hour="$1"
  local start_raw="$2"
  local end_raw="$3"

  if [[ -z "$start_raw" || -z "$end_raw" ]]; then
    echo 0
    return 0
  fi

  echo "$(is_hour_in_window "$hour" "$start_raw" "$end_raw")"
}

resolve_scheduled_slot() {
  local schedule_enabled="$1"
  local hour="$2"
  local critical_start="$3"
  local critical_end="$4"
  local priority_start="$5"
  local priority_end="$6"
  local current_slot="$7"

  if (( schedule_enabled == 0 )); then
    echo "$current_slot"
    return 0
  fi

  if [[ "$(is_slot_window_active "$hour" "$critical_start" "$critical_end")" == "1" ]]; then
    echo "critical"
    return 0
  fi

  if [[ "$(is_slot_window_active "$hour" "$priority_start" "$priority_end")" == "1" ]]; then
    echo "priority"
    return 0
  fi

  echo "default"
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local msg="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "[FAIL] $msg (expected='$expected', actual='$actual')"
    exit 1
  fi
}

assert_case() {
  local name="$1"
  local enabled="$2"
  local hour="$3"
  local c_start="$4"
  local c_end="$5"
  local p_start="$6"
  local p_end="$7"
  local current_slot="$8"
  local expected="$9"

  local actual
  actual="$(resolve_scheduled_slot "$enabled" "$hour" "$c_start" "$c_end" "$p_start" "$p_end" "$current_slot")"
  assert_eq "$actual" "$expected" "$name"
  echo "[OK] $name"
}

assert_case "schedule disabled keeps runtime slot" 0 12 22 6 8 18 "priority" "priority"
assert_case "critical window overrides" 1 23 22 6 8 18 "default" "critical"
assert_case "priority window picked when critical not active" 1 10 22 6 8 18 "default" "priority"
assert_case "outside all windows falls back to default" 1 7 22 6 8 18 "critical" "default"
assert_case "invalid equal bounds do not activate slot" 1 3 -1 -1 0 0 "default" "default"
assert_case "missing critical end does not activate critical slot" 1 23 22 "" 8 18 "default" "default"
assert_case "missing priority start does not activate priority slot" 1 10 22 6 "" 18 "default" "default"
assert_case "missing both priority bounds does not activate priority slot" 1 10 22 6 "" "" "default" "default"

echo "[OK] npc_activity schedule contract tests passed"
