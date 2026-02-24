#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_FILE="$ROOT_DIR/src/modules/npc/npc_activity_inc.nss"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "[FAIL] target file not found: $TARGET_FILE"
  exit 1
fi

is_valid_route() {
  local route="$1"
  [[ "$route" == "default_route" || "$route" == "priority_patrol" || "$route" == "critical_safe" ]]
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
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "[FAIL] $message (expected='$expected', actual='$actual')"
    exit 1
  fi
}

assert_case() {
  local case_name="$1"
  local npc_activity_route_input="$2"
  local npc_slot_profile="$3"
  local npc_default_profile="$4"
  local area_slot_profile="$5"
  local area_default_profile="$6"
  local expected_stored_route="$7"
  local expected_effective_route="$8"

  local normalized_activity_route
  local effective_route

  normalized_activity_route="$(normalize_configured_route_or_empty "$npc_activity_route_input")"
  effective_route="$(resolve_route_profile "$npc_activity_route_input" "$npc_slot_profile" "$npc_default_profile" "$area_slot_profile" "$area_default_profile")"

  assert_eq "$normalized_activity_route" "$expected_stored_route" "${case_name}: npc_activity_route invariant"
  assert_eq "$effective_route" "$expected_effective_route" "${case_name}: npc_activity_route_effective invariant"

  echo "[OK] $case_name"
}

# static fixtures / emulated inputs (contract scenarios for npc_activity_inc.nss)
assert_case \
  "valid explicit npc_activity_route on NPC" \
  "priority_patrol" \
  "critical_safe" \
  "default_route" \
  "default_route" \
  "critical_safe" \
  "priority_patrol" \
  "priority_patrol"

assert_case \
  "empty npc_activity_route on NPC with fallback to npc_route_profile_slot_<slot>" \
  "" \
  "critical_safe" \
  "default_route" \
  "priority_patrol" \
  "default_route" \
  "" \
  "critical_safe"

assert_case \
  "invalid npc_activity_route on NPC and valid slot route on area" \
  "not_supported" \
  "" \
  "" \
  "priority_patrol" \
  "default_route" \
  "" \
  "priority_patrol"

assert_case \
  "all sources empty-or-invalid uses default_route" \
  "bad_route" \
  "" \
  "wrong_default" \
  "" \
  "invalid_area_default" \
  "" \
  "default_route"

echo "[OK] npc_activity route contract tests passed"
