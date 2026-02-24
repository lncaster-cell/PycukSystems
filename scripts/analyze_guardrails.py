#!/usr/bin/env python3
"""Aggregate NPC guardrail checks from a single CSV pass."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

PASS_TOKENS = {"1", "true", "pass"}


def _safe_int(raw: str | None) -> int:
    return int((raw or "0").strip() or "0")


def _pass_bool(raw: str | None) -> bool:
    return (raw or "").strip().lower() in PASS_TOKENS


def analyze(path: Path) -> dict[str, str]:
    result = {
        "overflow": "NA",
        "budget": "NA",
        "warmup": "NA",
    }

    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        fields = set(reader.fieldnames or [])

        has_overflow = "overflow_events" in fields
        has_budget = {"budget_overrun", "deferred_events"}.issubset(fields)
        has_warmup = {
            "route_cache_warmup_ok",
            "route_cache_rescan_ok",
            "route_cache_guardrail_status",
        }.issubset(fields)

        running_rows = 0
        overflow_hits = 0
        budget_hits = 0
        deferred_hits = 0
        warmup_rows = 0
        warmup_all_ok = True
        rescan_all_ok = True
        guardrail_all_ok = True

        for row in reader:
            is_running = (row.get("lifecycle_state") or "RUNNING").strip().upper() == "RUNNING"
            if is_running and (has_overflow or has_budget):
                running_rows += 1

            try:
                if has_overflow and is_running and _safe_int(row.get("overflow_events")) > 0:
                    overflow_hits += 1

                if has_budget and is_running:
                    if _safe_int(row.get("budget_overrun")) > 0:
                        budget_hits += 1
                    if _safe_int(row.get("deferred_events")) > 0:
                        deferred_hits += 1
            except Exception:
                if has_overflow:
                    result["overflow"] = "FAIL"
                if has_budget:
                    result["budget"] = "FAIL"
                if has_warmup and warmup_rows == 0:
                    result["warmup"] = "FAIL"
                return result

            if has_warmup:
                warmup_rows += 1
                warmup_all_ok = warmup_all_ok and _pass_bool(row.get("route_cache_warmup_ok"))
                rescan_all_ok = rescan_all_ok and _pass_bool(row.get("route_cache_rescan_ok"))
                guardrail_all_ok = (
                    guardrail_all_ok
                    and (row.get("route_cache_guardrail_status") or "").strip().upper() == "PASS"
                )

    if has_overflow and result["overflow"] != "FAIL":
        result["overflow"] = "PASS" if running_rows > 0 and overflow_hits > 0 else "FAIL"

    if has_budget and result["budget"] != "FAIL":
        result["budget"] = "PASS" if running_rows > 0 and budget_hits > 0 and deferred_hits > 0 else "FAIL"

    if has_warmup and result["warmup"] != "FAIL":
        result["warmup"] = "PASS" if warmup_rows > 0 and warmup_all_ok and rescan_all_ok and guardrail_all_ok else "FAIL"

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze NPC guardrails from CSV in one pass")
    parser.add_argument("--input", required=True, help="Path to benchmark CSV")
    parser.add_argument(
        "--format",
        choices=("env", "json"),
        default="env",
        help="Output format: KEY=VALUE lines (env) or JSON",
    )
    args = parser.parse_args()

    payload = analyze(Path(args.input))
    if args.format == "json":
        print(json.dumps(payload, ensure_ascii=False))
    else:
        print(f"OVERFLOW={payload['overflow']}")
        print(f"BUDGET={payload['budget']}")
        print(f"WARMUP={payload['warmup']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
