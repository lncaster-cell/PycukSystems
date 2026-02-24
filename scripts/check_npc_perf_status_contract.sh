#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE_FILE="$ROOT_DIR/docs/perf/npc_baseline_report.md"
DESIGN_FILE="$ROOT_DIR/docs/design.md"

if [[ ! -f "$BASELINE_FILE" ]]; then
  echo "[FAIL] Baseline report not found: $BASELINE_FILE"
  exit 1
fi

if [[ ! -f "$DESIGN_FILE" ]]; then
  echo "[FAIL] Design doc not found: $DESIGN_FILE"
  exit 1
fi

baseline_decision_line="$(rg -n "^- Решение:" "$BASELINE_FILE" | head -n1 || true)"
if [[ -z "$baseline_decision_line" ]]; then
  echo "[FAIL] Unable to locate baseline decision line in $BASELINE_FILE"
  exit 1
fi

if [[ "$baseline_decision_line" == *"GO (PASS)"* ]]; then
  expected_checkbox="x"
  expected_label="PASS"
else
  expected_checkbox=" "
  expected_label="NON-PASS"
fi

design_line="$(rg -n "^- \[[ x]\] Perf-gate пороги не нарушены относительно baseline\." "$DESIGN_FILE" | head -n1 || true)"
if [[ -z "$design_line" ]]; then
  echo "[FAIL] Unable to locate perf-gate checklist line in $DESIGN_FILE"
  exit 1
fi

line_no="${design_line%%:*}"
line_text="${design_line#*:}"
actual_checkbox="${line_text:3:1}"

if [[ "$actual_checkbox" != "$expected_checkbox" ]]; then
  echo "[FAIL] Perf status mismatch between baseline and design checklist"
  echo "       Baseline decision: $baseline_decision_line"
  echo "       Design checklist:  $design_line"
  echo "       Expected checkbox='$expected_checkbox' for baseline status=$expected_label"
  exit 1
fi

evidence_line="$(sed -n "$((line_no+1)),$((line_no+3))p" "$DESIGN_FILE" | rg "\*\*(DONE|FAIL|BLOCKED)\*\*" | head -n1 || true)"
if [[ -z "$evidence_line" ]]; then
  echo "[FAIL] Missing status evidence block (**DONE**/**FAIL**/**BLOCKED**) near perf-gate checklist in $DESIGN_FILE"
  exit 1
fi

if [[ "$expected_checkbox" == "x" && "$evidence_line" != *"**DONE**"* ]]; then
  echo "[FAIL] Expected **DONE** evidence for PASS baseline, found: $evidence_line"
  exit 1
fi

if [[ "$expected_checkbox" == " " && "$evidence_line" == *"**DONE**"* ]]; then
  echo "[FAIL] Expected non-DONE evidence for NON-PASS baseline, found: $evidence_line"
  exit 1
fi

echo "[OK] NPC perf status contract passed (baseline=$expected_label, checklist=[${actual_checkbox}])"
