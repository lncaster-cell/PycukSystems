#!/usr/bin/env python3
"""Aggregate NPC guardrail checks from a single CSV pass."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

PASS_TOKENS = {"1", "true", "pass"}


def parse_int(raw: str | None, row_index: int, column_name: str) -> int:
    if raw is None:
        raise ValueError(
            f"invalid numeric value (row index={row_index}, column name={column_name}, raw value={raw!r})"
        )

    value = raw.strip()
    if not value:
        raise ValueError(
            f"invalid numeric value (row index={row_index}, column name={column_name}, raw value={raw!r})"
        )

    try:
        return int(value)
    except ValueError as exc:
        raise ValueError(
            f"invalid numeric value (row index={row_index}, column name={column_name}, raw value={raw!r})"
        ) from exc


def _pass_bool(raw: str | None) -> bool:
    return (raw or "").strip().lower() in PASS_TOKENS


def fail_payload(reason: str) -> dict[str, str]:
    return {"status": "INVALID", "error": reason}


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

        for row_index, row in enumerate(reader, start=1):
            is_running = (row.get("lifecycle_state") or "").strip().upper() == "RUNNING"
            if is_running and (has_overflow or has_budget):
                running_rows += 1

            overflow_events = None
            budget_overrun = None
            deferred_events = None
            if has_overflow:
                overflow_events = parse_int(row.get("overflow_events"), row_index, "overflow_events")
            if has_budget:
                budget_overrun = parse_int(row.get("budget_overrun"), row_index, "budget_overrun")
                deferred_events = parse_int(row.get("deferred_events"), row_index, "deferred_events")

            if has_overflow and is_running and overflow_events is not None and overflow_events > 0:
                overflow_hits += 1

            if has_budget and is_running and budget_overrun is not None and deferred_events is not None:
                if budget_overrun > 0:
                    budget_hits += 1
                if deferred_events > 0:
                    deferred_hits += 1

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

    try:
        payload = analyze(Path(args.input))
    except ValueError as exc:
        print(json.dumps(fail_payload(str(exc)), ensure_ascii=False))
        return 2
    except (OSError, UnicodeDecodeError) as exc:
        print(json.dumps(fail_payload(f"failed to read csv: {exc}"), ensure_ascii=False))
        return 2

    if args.format == "json":
        print(json.dumps(payload, ensure_ascii=False))
    else:
        print(f"OVERFLOW={payload['overflow']}")
        print(f"BUDGET={payload['budget']}")
        print(f"WARMUP={payload['warmup']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
