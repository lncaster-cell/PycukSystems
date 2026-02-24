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


def evaluate_post_resume_window(
    args: argparse.Namespace,
    buckets: list[str],
    parsed_numbers: dict[str, int],
    resume_window_tick: int,
    resume_window_violations: int,
) -> tuple[int, int]:
    if resume_window_tick < 0 or args.max_post_resume_drain_ticks < 0:
        return resume_window_tick, resume_window_violations

    bucket_processed = False
    for b in buckets:
        col = BUCKET_COLUMN[b]
        if parsed_numbers.get(col, 0) > 0:
            bucket_processed = True
            break

    if bucket_processed:
        return -1, resume_window_violations

    resume_window_tick += 1
    if resume_window_tick > args.max_post_resume_drain_ticks:
        return -1, resume_window_violations + 1

    return resume_window_tick, resume_window_violations


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True, help="Path to fairness CSV")
    p.add_argument("--max-starvation-window", type=int, default=10)
    p.add_argument("--buckets", default="LOW,NORMAL", help="Comma-separated buckets to validate")
    p.add_argument("--enforce-pause-zero", action="store_true", help="Fail if any processed_* > 0 during PAUSED")
    p.add_argument(
        "--max-post-resume-drain-ticks",
        type=int,
        default=-1,
        help="Fail if queue does not resume processing within N RUNNING ticks after PAUSED->RUNNING",
    )
    p.add_argument(
        "--min-resume-transitions",
        type=int,
        default=0,
        help="Fail if PAUSED->RUNNING transitions are fewer than this value",
    )
    return p.parse_args()


def to_int(value: str, row_index: int, column_name: str, parse_errors: list[str]) -> int | None:
    try:
        return int(value)
    except Exception:
        parse_errors.append(
            f"[FAIL] invalid numeric value (row index={row_index}, column name={column_name}, raw value={value!r})"
        )
        return None


def main() -> int:
    args = parse_args()
    path = Path(args.input)
    if not path.exists() or not path.is_file():
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

    try:
        with path.open("r", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            if fieldnames is None:
                print("[FAIL] csv is empty")
                return 2

            required_columns = ["tick", *[BUCKET_COLUMN[b] for b in buckets]]
            missing = [column for column in required_columns if column not in fieldnames]
            if missing:
                print(f"[FAIL] csv missing required columns: {', '.join(missing)}")
                return 2

            pause_zero_columns = [
                column
                for column in ("processed_low", "processed_normal", "processed_high", "processed_critical")
                if column in fieldnames
            ]

            streak = {b: 0 for b in buckets}
            worst = {b: 0 for b in buckets}

            total_rows = 0
            pause_violation_rows = 0
            running_ticks = 0
            resume_transitions = 0
            resume_window_tick = -1
            resume_window_violations = 0
            previous_state = "RUNNING"
            parse_errors: list[str] = []

            for row_index, row in enumerate(reader, start=1):
                total_rows += 1
                state = (row.get("lifecycle_state") or "RUNNING").strip().upper()

                numeric_columns = {"tick", *[BUCKET_COLUMN[b] for b in buckets]}
                if args.enforce_pause_zero:
                    numeric_columns.update(pause_zero_columns)

                parsed_numbers: dict[str, int] = {}
                for column in numeric_columns:
                    parsed = to_int(row.get(column, ""), row_index, column, parse_errors)
                    if parsed is not None:
                        parsed_numbers[column] = parsed

                if parse_errors:
                    print(parse_errors[0])
                    return 2

                if previous_state == "PAUSED" and state == "RUNNING":
                    resume_transitions += 1
                    resume_window_tick = 0

                if state == "PAUSED" and args.enforce_pause_zero:
                    row_has_processing = False
                    for col in pause_zero_columns:
                        if parsed_numbers.get(col, 0) > 0:
                            row_has_processing = True
                            break
                    if row_has_processing:
                        pause_violation_rows += 1

                if state != "RUNNING":
                    previous_state = state
                    continue

                running_ticks += 1

                resume_window_tick, resume_window_violations = evaluate_post_resume_window(
                    args,
                    buckets,
                    parsed_numbers,
                    resume_window_tick,
                    resume_window_violations,
                )

                for b in buckets:
                    col = BUCKET_COLUMN[b]
                    if parsed_numbers.get(col, 0) > 0:
                        worst[b] = max(worst[b], streak[b])
                        streak[b] = 0
                    else:
                        streak[b] += 1

                previous_state = state

            if total_rows == 0:
                print("[FAIL] csv is empty")
                return 2
    except (OSError, UnicodeDecodeError) as exc:
        print(f"[FAIL] failed to read csv input: {path} ({exc})")
        return 2

    for b in buckets:
        worst[b] = max(worst[b], streak[b])

    if running_ticks == 0:
        print("[FAIL] no RUNNING rows in input")
        return 2

    if args.max_post_resume_drain_ticks >= 0 and resume_window_tick >= 0:
        resume_window_tick, resume_window_violations = evaluate_post_resume_window(
            args,
            buckets,
            {},
            resume_window_tick,
            resume_window_violations,
        )

    print(f"[INFO] analyzed rows: {total_rows}, running_ticks: {running_ticks}")
    print(f"[INFO] resume_transitions: {resume_transitions}")
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

    if resume_transitions < args.min_resume_transitions:
        print(
            "[FAIL] resume transitions fewer than required: "
            f"observed={resume_transitions}, required={args.min_resume_transitions}"
        )
        failed = True

    if args.max_post_resume_drain_ticks >= 0 and resume_window_violations > 0:
        print(
            "[FAIL] post-resume drain window violated: "
            f"violations={resume_window_violations}, limit={args.max_post_resume_drain_ticks} running ticks"
        )
        failed = True

    if failed:
        return 1

    print("[OK] fairness checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
