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

normalize_slot() {
  local slot="$1"
  case "$slot" in
    dawn|morning|afternoon|evening|night) echo "$slot" ;;
    default) echo "afternoon" ;;
    priority) echo "morning" ;;
    critical) echo "night" ;;
    *) echo "afternoon" ;;
  esac
}

normalize_mode() {
  local mode="$1"
  if [[ "$mode" == "alert" ]]; then
    echo "alert"
  else
    echo "daily"
  fi
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

assert_eq "$(resolve_time_slot 5)" "dawn" "05 -> dawn"
assert_eq "$(resolve_time_slot 9)" "morning" "09 -> morning"
assert_eq "$(resolve_time_slot 13)" "afternoon" "13 -> afternoon"
assert_eq "$(resolve_time_slot 18)" "evening" "18 -> evening"
assert_eq "$(resolve_time_slot 23)" "night" "23 -> night"

assert_eq "$(normalize_slot default)" "afternoon" "legacy default alias"
assert_eq "$(normalize_slot priority)" "morning" "legacy priority alias"
assert_eq "$(normalize_slot critical)" "night" "legacy critical alias"

assert_eq "$(normalize_mode '')" "daily" "empty mode -> daily"
assert_eq "$(normalize_mode daily)" "daily" "daily mode"
assert_eq "$(normalize_mode alert)" "alert" "alert mode"
assert_eq "$(normalize_mode emergency)" "daily" "unknown mode -> daily"

echo "[OK] npc_activity slot contract tests passed"
