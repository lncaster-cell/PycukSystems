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
    echo 1
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

  if [[ "$(is_hour_in_window "$hour" "$critical_start" "$critical_end")" == "1" ]]; then
    echo "critical"
    return 0
  fi

  if [[ "$(is_hour_in_window "$hour" "$priority_start" "$priority_end")" == "1" ]]; then
    echo "priority"
    return 0
  fi

  echo "default"
}

route_for_slot() {
  local slot="$1"
  case "$slot" in
    critical) echo "critical_safe" ;;
    priority) echo "priority_patrol" ;;
    *) echo "default_route" ;;
  esac
}

dispatch_branch_for_slot() {
  local slot="$1"
  case "$slot" in
    critical) echo "NpcBhvrActivityApplyCriticalSafeRoute" ;;
    priority) echo "NpcBhvrActivityApplyPriorityRoute" ;;
    *) echo "NpcBhvrActivityApplyDefaultRoute" ;;
  esac
}

cooldown_for_slot() {
  local slot="$1"
  case "$slot" in
    priority) echo "2" ;;
    *) echo "1" ;;
  esac
}

simulate_schedule_resolve_idle_tick() {
  local enabled="$1"
  local hour="$2"
  local c_start="$3"
  local c_end="$4"
  local p_start="$5"
  local p_end="$6"
  local current_slot="$7"

  local resolved_slot
  resolved_slot="$(resolve_scheduled_slot "$enabled" "$hour" "$c_start" "$c_end" "$p_start" "$p_end" "$current_slot")"

  local effective_route
  effective_route="$(route_for_slot "$resolved_slot")"

  local branch
  branch="$(dispatch_branch_for_slot "$resolved_slot")"

  local cooldown
  cooldown="$(cooldown_for_slot "$resolved_slot")"

  # stdout protocol: branch|npc_activity_slot|npc_activity_route_effective|npc_activity_last|npc_activity_cooldown
  echo "$branch|$resolved_slot|$effective_route|$hour|$cooldown"
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
assert_case "full-day priority window works" 1 3 -1 -1 0 0 "default" "priority"

assert_dispatch_case() {
  local name="$1"
  local enabled="$2"
  local hour="$3"
  local c_start="$4"
  local c_end="$5"
  local p_start="$6"
  local p_end="$7"
  local current_slot="$8"
  local expected_branch="$9"
  local expected_slot="${10}"
  local expected_route="${11}"
  local expected_last="${12}"
  local expected_cooldown="${13}"

  local result branch slot route last cooldown
  result="$(simulate_schedule_resolve_idle_tick "$enabled" "$hour" "$c_start" "$c_end" "$p_start" "$p_end" "$current_slot")"
  IFS='|' read -r branch slot route last cooldown <<<"$result"

  assert_eq "$branch" "$expected_branch" "$name branch"
  assert_eq "$slot" "$expected_slot" "$name npc_activity_slot"
  assert_eq "$route" "$expected_route" "$name npc_activity_route_effective"
  assert_eq "$last" "$expected_last" "$name npc_activity_last"
  assert_eq "$cooldown" "$expected_cooldown" "$name npc_activity_cooldown"
  echo "[OK] $name"
}

assert_dispatch_case \
  "schedule-resolve prefers critical branch and updates locals" \
  1 23 22 6 8 18 "default" \
  "NpcBhvrActivityApplyCriticalSafeRoute" "critical" "critical_safe" "23" "1"

assert_dispatch_case \
  "schedule-resolve picks priority branch when critical inactive and updates locals" \
  1 10 22 6 8 18 "default" \
  "NpcBhvrActivityApplyPriorityRoute" "priority" "priority_patrol" "10" "2"

assert_dispatch_case \
  "schedule-resolve falls back to default branch and updates locals" \
  1 7 22 6 8 18 "critical" \
  "NpcBhvrActivityApplyDefaultRoute" "default" "default_route" "7" "1"

echo "[OK] npc_activity schedule contract tests passed"
