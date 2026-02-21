#!/usr/bin/env python3
"""Analyze area queue fairness metrics exported as CSV.

Expected columns:
- tick
- lifecycle_state (optional; RUNNING/PAUSED/STOPPED)
- processed_low
- processed_normal
- processed_high (optional)
- processed_critical (optional)
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


BUCKET_COLUMN = {
    "LOW": "processed_low",
    "NORMAL": "processed_normal",
    "HIGH": "processed_high",
    "CRITICAL": "processed_critical",
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True, help="Path to fairness CSV")
    p.add_argument("--max-starvation-window", type=int, default=10)
    p.add_argument("--buckets", default="LOW,NORMAL", help="Comma-separated buckets to validate")
    p.add_argument("--enforce-pause-zero", action="store_true", help="Fail if any processed_* > 0 during PAUSED")
    return p.parse_args()


def to_int(value: str) -> int:
    try:
        return int(value)
    except Exception:
        return 0


def main() -> int:
    args = parse_args()
    path = Path(args.input)
    if not path.exists():
        print(f"[FAIL] input file not found: {path}")
        return 2

    buckets = [b.strip().upper() for b in args.buckets.split(",") if b.strip()]
    if not buckets:
        print("[FAIL] no buckets specified")
        return 2

    for b in buckets:
        if b not in BUCKET_COLUMN:
            print(f"[FAIL] unknown bucket: {b}")
            return 2

    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if not rows:
        print("[FAIL] csv is empty")
        return 2

    missing = [BUCKET_COLUMN[b] for b in buckets if BUCKET_COLUMN[b] not in reader.fieldnames]
    if missing:
        print(f"[FAIL] csv missing required columns: {', '.join(missing)}")
        return 2

    streak = {b: 0 for b in buckets}
    worst = {b: 0 for b in buckets}

    pause_violation_rows = 0
    running_ticks = 0

    for row in rows:
        state = (row.get("lifecycle_state") or "RUNNING").strip().upper()

        if state == "PAUSED" and args.enforce_pause_zero:
            row_has_processing = False
            for col in ("processed_low", "processed_normal", "processed_high", "processed_critical"):
                if to_int(row.get(col, "0")) > 0:
                    row_has_processing = True
                    break
            if row_has_processing:
                pause_violation_rows += 1

        if state != "RUNNING":
            continue

        running_ticks += 1
        for b in buckets:
            col = BUCKET_COLUMN[b]
            if to_int(row.get(col, "0")) > 0:
                worst[b] = max(worst[b], streak[b])
                streak[b] = 0
            else:
                streak[b] += 1

    for b in buckets:
        worst[b] = max(worst[b], streak[b])

    print(f"[INFO] analyzed rows: {len(rows)}, running_ticks: {running_ticks}")
    for b in buckets:
        print(f"[INFO] bucket={b} worst_starvation_window={worst[b]}")

    failed = False
    for b in buckets:
        if worst[b] > args.max_starvation_window:
            print(
                f"[FAIL] bucket={b} starvation window {worst[b]} exceeds limit {args.max_starvation_window}"
            )
            failed = True

    if args.enforce_pause_zero and pause_violation_rows > 0:
        print(f"[FAIL] pause-zero invariant violated on {pause_violation_rows} rows")
        failed = True

    if failed:
        return 1

    print("[OK] fairness checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
