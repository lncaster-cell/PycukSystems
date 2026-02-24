#!/usr/bin/env python3
"""Aggregate guardrail checks for NPC benchmark CSV fixtures."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


PASS_TOKENS = {"1", "true", "TRUE", "pass", "PASS"}


def analyze(path: Path) -> dict[str, str]:
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        fields = set(reader.fieldnames or [])

        overflow_enabled = "overflow_events" in fields
        budget_enabled = {"budget_overrun", "deferred_events"}.issubset(fields)
        warmup_enabled = {
            "route_cache_warmup_ok",
            "route_cache_rescan_ok",
            "route_cache_guardrail_status",
        }.issubset(fields)

        overflow_failed_parse = False
        budget_failed_parse = False
        running_rows = 0
        overflow_rows = 0
        budget_rows = 0
        deferred_rows = 0

        warmup_has_rows = False
        warmup_all_ok = True
        rescan_all_ok = True
        guardrail_all_ok = True

        for row in reader:
            if warmup_enabled:
                warmup_has_rows = True
                warmup_all_ok = warmup_all_ok and (
                    (row.get("route_cache_warmup_ok") or "").strip() in PASS_TOKENS
                )
                rescan_all_ok = rescan_all_ok and (
                    (row.get("route_cache_rescan_ok") or "").strip() in PASS_TOKENS
                )
                guardrail_all_ok = guardrail_all_ok and (
                    (row.get("route_cache_guardrail_status") or "").strip().upper() == "PASS"
                )

            if (row.get("lifecycle_state") or "").strip().upper() != "RUNNING":
                continue

            running_rows += 1

            if overflow_enabled and not overflow_failed_parse:
                try:
                    if int(row.get("overflow_events") or "0") > 0:
                        overflow_rows += 1
                except Exception:
                    overflow_failed_parse = True

            if budget_enabled and not budget_failed_parse:
                try:
                    if int(row.get("budget_overrun") or "0") > 0:
                        budget_rows += 1
                    if int(row.get("deferred_events") or "0") > 0:
                        deferred_rows += 1
                except Exception:
                    budget_failed_parse = True

    if not overflow_enabled:
        overflow_result = "NA"
    elif overflow_failed_parse:
        overflow_result = "FAIL"
    else:
        overflow_result = "PASS" if running_rows > 0 and overflow_rows > 0 else "FAIL"

    if not budget_enabled:
        budget_result = "NA"
    elif budget_failed_parse:
        budget_result = "FAIL"
    else:
        budget_result = "PASS" if running_rows > 0 and budget_rows > 0 and deferred_rows > 0 else "FAIL"

    if not warmup_enabled:
        warmup_result = "NA"
    else:
        warmup_result = "PASS" if warmup_has_rows and warmup_all_ok and rescan_all_ok and guardrail_all_ok else "FAIL"

    return {
        "OVERFLOW_RESULT": overflow_result,
        "BUDGET_RESULT": budget_result,
        "WARMUP_RESULT": warmup_result,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze guardrail status from NPC benchmark CSV")
    parser.add_argument("--input", required=True, type=Path, help="Path to input CSV file")
    args = parser.parse_args()

    result = analyze(args.input)
    for key, value in result.items():
        print(f"{key}={value}")


if __name__ == "__main__":
    main()
