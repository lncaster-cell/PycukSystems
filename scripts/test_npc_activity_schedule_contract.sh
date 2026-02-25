#!/usr/bin/env bash
set -euo pipefail

resolve_time_slot() {
  local hour="$1"

  if (( hour < 0 || hour > 23 )); then
    echo "afternoon"
    return 0
  fi

  if (( hour >= 5 && hour < 8 )); then
    echo "dawn"
  elif (( hour >= 8 && hour < 12 )); then
    echo "morning"
  elif (( hour >= 12 && hour < 17 )); then
    echo "afternoon"
  elif (( hour >= 17 && hour < 22 )); then
    echo "evening"
  else
    echo "night"
  fi
}

resolve_idle_dispatch() {
  local route_effective="$1"
  if [[ -z "$route_effective" ]]; then
    route_effective="default_route"
  fi

  # stdout protocol: dispatch_fn|route|base_state|cooldown
  echo "NpcBhvrActivityApplyRouteState|$route_effective|idle_route|1"
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

assert_slot() {
  local name="$1"
  local hour="$2"
  local expected="$3"

  local actual
  actual="$(resolve_time_slot "$hour")"
  assert_eq "$actual" "$expected" "$name"
  echo "[OK] $name"
}

assert_dispatch() {
  local name="$1"
  local route_effective="$2"
  local expected_route="$3"

  local result fn route base cooldown
  result="$(resolve_idle_dispatch "$route_effective")"
  IFS='|' read -r fn route base cooldown <<<"$result"

  assert_eq "$fn" "NpcBhvrActivityApplyRouteState" "$name function"
  assert_eq "$route" "$expected_route" "$name route"
  assert_eq "$base" "idle_route" "$name base state"
  assert_eq "$cooldown" "1" "$name cooldown"
  echo "[OK] $name"
}

assert_slot "05:00 -> dawn" 5 "dawn"
assert_slot "08:00 -> morning" 8 "morning"
assert_slot "12:00 -> afternoon" 12 "afternoon"
assert_slot "17:00 -> evening" 17 "evening"
assert_slot "23:00 -> night" 23 "night"

assert_dispatch "empty effective route falls back to default_route" "" "default_route"
assert_dispatch "semantic critical_safe route stays data-only route" "critical_safe" "critical_safe"
assert_dispatch "semantic priority_patrol route stays data-only route" "priority_patrol" "priority_patrol"
assert_dispatch "custom route is applied without semantic branching" "market_evening_walk" "market_evening_walk"

echo "[OK] npc_activity schedule contract tests passed"
