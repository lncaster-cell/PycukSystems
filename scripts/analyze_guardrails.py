#!/usr/bin/env python3
"""Aggregate NPC guardrail checks from a single CSV pass."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from lib.guardrail_metrics import aggregate_guardrail_metrics


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
        metrics = aggregate_guardrail_metrics(reader, reader.fieldnames)

    if metrics.has_overflow:
        result["overflow"] = "PASS" if metrics.running_rows > 0 and metrics.overflow_hits > 0 else "FAIL"

    if metrics.has_budget:
        result["budget"] = (
            "PASS" if metrics.running_rows > 0 and metrics.budget_hits > 0 and metrics.deferred_hits > 0 else "FAIL"
        )

    if metrics.has_warmup:
        result["warmup"] = (
            "PASS"
            if metrics.warmup_rows > 0 and metrics.warmup_all_ok and metrics.rescan_all_ok and metrics.guardrail_all_ok
            else "FAIL"
        )

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
