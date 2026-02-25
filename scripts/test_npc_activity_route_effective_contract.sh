#!/usr/bin/env bash
set -euo pipefail

normalize_configured_route_or_empty() {
  local route="$1"
  if [[ -z "$route" ]]; then
    echo ""
  elif [[ "$route" =~ ^[a-z0-9_]{1,32}$ ]]; then
    echo "$route"
  else
    echo ""
  fi
}

resolve_route_profile() {
  local npc_activity_route="$1"
  local npc_slot_profile="$2"
  local npc_default_profile="$3"
  local area_slot_profile="$4"
  local area_default_profile="$5"

  local route
  route="$(normalize_configured_route_or_empty "$npc_activity_route")"
  if [[ -n "$route" ]]; then
    echo "$route"
    return 0
  fi

  route="$(normalize_configured_route_or_empty "$npc_slot_profile")"
  if [[ -n "$route" ]]; then
    echo "$route"
    return 0
  fi

  route="$(normalize_configured_route_or_empty "$npc_default_profile")"
  if [[ -n "$route" ]]; then
    echo "$route"
    return 0
  fi

  route="$(normalize_configured_route_or_empty "$area_slot_profile")"
  if [[ -n "$route" ]]; then
    echo "$route"
    return 0
  fi

  route="$(normalize_configured_route_or_empty "$area_default_profile")"
  if [[ -n "$route" ]]; then
    echo "$route"
    return 0
  fi

  echo "default_route"
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local name="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "[FAIL] $name (expected='$expected', actual='$actual')"
    exit 1
  fi
}

assert_case() {
  local name="$1"
  local npc_activity_route="$2"
  local npc_slot_profile="$3"
  local npc_default_profile="$4"
  local area_slot_profile="$5"
  local area_default_profile="$6"
  local expected="$7"

  local effective
  effective="$(resolve_route_profile "$npc_activity_route" "$npc_slot_profile" "$npc_default_profile" "$area_slot_profile" "$area_default_profile")"
  assert_eq "$effective" "$expected" "$name"
  echo "[OK] $name"
}

assert_case "configured npc route dominates" "priority_patrol" "critical_safe" "default_route" "default_route" "critical_safe" "priority_patrol"
assert_case "fallback to npc slot route" "" "critical_safe" "default_route" "priority_patrol" "default_route" "critical_safe"
assert_case "fallback to area slot route" "bad-route" "" "" "priority_patrol" "default_route" "priority_patrol"
assert_case "fallback to default_route when all invalid" "bad-route" "wrong-route" "wrong-route" "wrong-route" "wrong-route" "default_route"

echo "[OK] npc_activity route_effective contract tests passed"
