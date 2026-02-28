#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_FILE="$ROOT_DIR/src/modules/npc/npc_activity_route_resolution_inc.nss"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "[FAIL] target file not found: $TARGET_FILE"
  exit 1
fi

is_valid_route() {
  local route="$1"
  [[ "$route" =~ ^[a-z0-9_]{1,32}$ ]]
}

normalize_configured_route_or_empty() {
  local route="$1"
  if [[ -z "$route" ]]; then
    echo ""
    return 0
  fi

  if is_valid_route "$route"; then
    echo "$route"
    return 0
  fi

  echo ""
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
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "[FAIL] $message (expected='$expected', actual='$actual')"
    exit 1
  fi
}

assert_case() {
  local case_name="$1"
  local mode="$2"
  local npc_alert_profile="$3"
  local npc_slot_profile="$4"
  local area_slot_profile="$5"
  local area_default_profile="$6"
  local expected_effective_route="$7"

  local effective_route

  effective_route="$(resolve_route_profile "$mode" "$npc_alert_profile" "$npc_slot_profile" "$area_slot_profile" "$area_default_profile")"

  assert_eq "$effective_route" "$expected_effective_route" "${case_name}: npc_activity_route_effective invariant"

  echo "[OK] $case_name"
}

assert_case "daily mode uses npc slot route" "daily" "critical_safe" "priority_patrol" "default_route" "critical_safe" "priority_patrol"
assert_case "alert mode uses alert override first" "alert" "critical_safe" "priority_patrol" "default_route" "priority_patrol" "critical_safe"
assert_case "fallback to area slot route when npc slot route missing" "daily" "" "" "priority_patrol" "default_route" "priority_patrol"
assert_case "all sources empty-or-invalid uses default_route" "daily" "bad-route" "wrong-route" "" "invalid-area-default" "default_route"

echo "[OK] npc_activity route contract tests passed"
