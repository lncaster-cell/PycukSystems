#!/usr/bin/env python3
"""Analyze NPC Bhvr baseline CSV and validate gate metrics."""

from __future__ import annotations

import argparse
import csv
import math
import sys
from pathlib import Path


REQUIRED_COLUMNS = [
    "tick",
    "lifecycle_state",
    "area_tick_latency_ms",
    "queue_depth",
    "deferred_events",
    "overflow_events",
    "budget_overrun",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Path to NPC Bhvr baseline CSV")
    parser.add_argument("--latency-p95-max", type=float, default=20.0)
    parser.add_argument("--latency-p99-max", type=float, default=25.0)
    parser.add_argument("--queue-p95-max", type=float, default=64.0)
    parser.add_argument("--queue-p99-max", type=float, default=80.0)
    parser.add_argument("--deferred-rate-max", type=float, default=0.35)
    parser.add_argument("--overflow-rate-max", type=float, default=0.02)
    parser.add_argument("--budget-overrun-rate-max", type=float, default=0.10)
    return parser.parse_args()


def percentile(values: list[float], percent: float) -> float:
    if not values:
        return math.nan
    sorted_values = sorted(values)
    if len(sorted_values) == 1:
        return sorted_values[0]
    rank = (len(sorted_values) - 1) * percent
    lower = math.floor(rank)
    upper = math.ceil(rank)
    if lower == upper:
        return sorted_values[lower]
    weight = rank - lower
    return sorted_values[lower] * (1 - weight) + sorted_values[upper] * weight


def parse_int(raw: str, row_index: int, column_name: str) -> int:
    try:
        return int(raw)
    except (TypeError, ValueError):
        raise ValueError(
            f"[FAIL] invalid numeric value (row index={row_index}, column name={column_name}, raw value={raw!r})"
        )


def parse_float(raw: str, row_index: int, column_name: str) -> float:
    try:
        value = float(raw)
    except (TypeError, ValueError):
        raise ValueError(
            f"[FAIL] invalid numeric value (row index={row_index}, column name={column_name}, raw value={raw!r})"
        )

    if not math.isfinite(value):
        raise ValueError(
            f"[FAIL] invalid numeric value (row index={row_index}, column name={column_name}, raw value={raw!r})"
        )

    return value


def main() -> int:
    args = parse_args()
    path = Path(args.input)
    if not path.exists() or not path.is_file():
        print(f"[FAIL] input file not found: {path}")
        return 2

    try:
        with path.open("r", encoding="utf-8", newline="") as file:
            reader = csv.DictReader(file)
            rows = list(reader)
            fieldnames = reader.fieldnames or []
    except (OSError, UnicodeDecodeError) as exc:
        print(f"[FAIL] failed to read csv input: {path} ({exc})")
        return 2

    if not rows:
        print("[FAIL] csv is empty")
        return 2

    missing = [column for column in REQUIRED_COLUMNS if column not in fieldnames]
    if missing:
        print(f"[FAIL] csv missing required columns: {', '.join(missing)}")
        return 2

    running_rows = 0
    latency_values: list[float] = []
    queue_values: list[float] = []
    deferred_ticks = 0
    overflow_ticks = 0
    budget_overrun_ticks = 0

    try:
        for row_index, row in enumerate(rows, start=1):
            lifecycle_state = (row.get("lifecycle_state") or "").strip().upper()
            parse_int(row.get("tick"), row_index, "tick")

            if lifecycle_state != "RUNNING":
                continue

            running_rows += 1
            area_tick_latency_ms = parse_float(row.get("area_tick_latency_ms"), row_index, "area_tick_latency_ms")
            queue_depth = parse_float(row.get("queue_depth"), row_index, "queue_depth")
            deferred_events = parse_int(row.get("deferred_events"), row_index, "deferred_events")
            overflow_events = parse_int(row.get("overflow_events"), row_index, "overflow_events")
            budget_overrun = parse_int(row.get("budget_overrun"), row_index, "budget_overrun")

            latency_values.append(area_tick_latency_ms)
            queue_values.append(queue_depth)

            if deferred_events > 0:
                deferred_ticks += 1
            if overflow_events > 0:
                overflow_ticks += 1
            if budget_overrun > 0:
                budget_overrun_ticks += 1
    except ValueError as exc:
        print(str(exc))
        return 2

    if running_rows == 0:
        print("[FAIL] no RUNNING rows in input")
        return 2

    latency_p95 = percentile(latency_values, 0.95)
    latency_p99 = percentile(latency_values, 0.99)
    queue_p95 = percentile(queue_values, 0.95)
    queue_p99 = percentile(queue_values, 0.99)

    deferred_rate = deferred_ticks / running_rows
    overflow_rate = overflow_ticks / running_rows
    budget_overrun_rate = budget_overrun_ticks / running_rows

    print(f"[INFO] analyzed rows={len(rows)}, running_rows={running_rows}")
    print(f"[INFO] area_tick_latency_ms p95={latency_p95:.2f} p99={latency_p99:.2f}")
    print(f"[INFO] queue_depth p95={queue_p95:.2f} p99={queue_p99:.2f}")
    print(f"[INFO] deferred_rate={deferred_rate:.4f}")
    print(f"[INFO] overflow_rate={overflow_rate:.4f}")
    print(f"[INFO] budget_overrun_rate={budget_overrun_rate:.4f}")

    failures: list[str] = []
    if latency_p95 > args.latency_p95_max:
        failures.append(f"latency p95 {latency_p95:.2f} exceeds limit {args.latency_p95_max:.2f}")
    if latency_p99 > args.latency_p99_max:
        failures.append(f"latency p99 {latency_p99:.2f} exceeds limit {args.latency_p99_max:.2f}")
    if queue_p95 > args.queue_p95_max:
        failures.append(f"queue depth p95 {queue_p95:.2f} exceeds limit {args.queue_p95_max:.2f}")
    if queue_p99 > args.queue_p99_max:
        failures.append(f"queue depth p99 {queue_p99:.2f} exceeds limit {args.queue_p99_max:.2f}")
    if deferred_rate > args.deferred_rate_max:
        failures.append(f"deferred rate {deferred_rate:.4f} exceeds limit {args.deferred_rate_max:.4f}")
    if overflow_rate > args.overflow_rate_max:
        failures.append(f"overflow rate {overflow_rate:.4f} exceeds limit {args.overflow_rate_max:.4f}")
    if budget_overrun_rate > args.budget_overrun_rate_max:
        failures.append(
            f"budget overrun rate {budget_overrun_rate:.4f} exceeds limit {args.budget_overrun_rate_max:.4f}"
        )

    if failures:
        for failure in failures:
            print(f"[FAIL] {failure}")
        return 1

    print("[OK] NPC Bhvr gate checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
