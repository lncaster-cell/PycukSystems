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
  local mode="$1"
  local npc_alert_profile="$2"
  local npc_slot_profile="$3"
  local area_slot_profile="$4"
  local area_default_profile="$5"

  local route

  if [[ "$mode" == "alert" ]]; then
    route="$(normalize_configured_route_or_empty "$npc_alert_profile")"
    if [[ -n "$route" ]]; then
      echo "$route"
      return 0
    fi
  fi

  route="$(normalize_configured_route_or_empty "$npc_slot_profile")"
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
  local mode="$2"
  local npc_alert_profile="$3"
  local npc_slot_profile="$4"
  local area_slot_profile="$5"
  local area_default_profile="$6"
  local expected="$7"

  local effective
  effective="$(resolve_route_profile "$mode" "$npc_alert_profile" "$npc_slot_profile" "$area_slot_profile" "$area_default_profile")"
  assert_eq "$effective" "$expected" "$name"
  echo "[OK] $name"
}

assert_case "daily uses npc slot route" "daily" "critical_safe" "priority_patrol" "default_route" "critical_safe" "priority_patrol"
assert_case "alert uses alert route" "alert" "critical_safe" "priority_patrol" "default_route" "critical_safe" "critical_safe"
assert_case "fallback to area slot route" "daily" "" "" "priority_patrol" "default_route" "priority_patrol"
assert_case "fallback to area default route" "daily" "" "" "" "default_route" "default_route"
assert_case "fallback to default_route when all invalid" "daily" "bad-route" "wrong-route" "wrong-route" "wrong-route" "default_route"

echo "[OK] npc_activity route_effective contract tests passed"
