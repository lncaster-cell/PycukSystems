#!/usr/bin/env bash
set -euo pipefail

to_last_ts() {
  local hour="$1"
  local minute="$2"
  local second="$3"
  echo $((hour * 3600 + minute * 60 + second))
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
  local hour="$2"
  local minute="$3"
  local second="$4"
  local expected="$5"

  local actual
  actual="$(to_last_ts "$hour" "$minute" "$second")"
  assert_eq "$actual" "$expected" "$name"
  echo "[OK] $name"
}

assert_case "hour boundary at exact hh:00:00" 13 0 0 46800
assert_case "end of day converts to max second" 23 59 59 86399
assert_case "start of day resets to zero" 0 0 0 0

pre_midnight="$(to_last_ts 23 59 59)"
post_midnight="$(to_last_ts 0 0 0)"
if (( post_midnight >= pre_midnight )); then
  echo "[FAIL] day rollover must reset npc_activity_last_ts (pre='$pre_midnight', post='$post_midnight')"
  exit 1
fi

echo "[OK] day rollover resets npc_activity_last_ts"
echo "[OK] npc_activity last_ts contract tests passed"
