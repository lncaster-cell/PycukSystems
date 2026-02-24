#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

BUCKET_COLUMN = {
    "LOW": "processed_low",
    "NORMAL": "processed_normal",
    "HIGH": "processed_high",
    "CRITICAL": "processed_critical",
}
PASS_TOKENS = {"1", "true", "pass"}


def safe_int(value: str | None) -> int:
    return int((value or "").strip())


def pass_bool(raw: str | None) -> bool:
    return (raw or "").strip().lower() in PASS_TOKENS


def fail_payload(reason: str) -> dict:
    return {"status": "INVALID", "error": reason}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Analyze fairness/overflow/budget/warmup in one CSV pass")
    p.add_argument("--input", required=True)
    p.add_argument("--max-starvation-window", type=int, default=3)
    p.add_argument("--buckets", default="LOW,NORMAL")
    p.add_argument("--enforce-pause-zero", action="store_true")
    p.add_argument("--max-post-resume-drain-ticks", type=int, default=1)
    p.add_argument("--min-resume-transitions", type=int, default=2)
    return p.parse_args()


def evaluate_post_resume_window(limit: int, buckets: list[str], parsed_numbers: dict[str, int], tick: int, violations: int) -> tuple[int, int]:
    if tick < 0 or limit < 0:
        return tick, violations

    if any(parsed_numbers.get(BUCKET_COLUMN[b], 0) > 0 for b in buckets):
        return -1, violations

    tick += 1
    if tick > limit:
        return -1, violations + 1
    return tick, violations


def main() -> int:
    args = parse_args()
    path = Path(args.input)
    if not path.exists() or not path.is_file():
        print(json.dumps(fail_payload(f"input file not found: {path}"), ensure_ascii=False))
        return 2

    buckets = [b.strip().upper() for b in args.buckets.split(",") if b.strip()]
    if not buckets or any(b not in BUCKET_COLUMN for b in buckets):
        print(json.dumps(fail_payload("invalid buckets"), ensure_ascii=False))
        return 2

    try:
        with path.open("r", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            if fieldnames is None:
                print(json.dumps(fail_payload("csv is empty"), ensure_ascii=False))
                return 2

            fields = set(fieldnames)
            has_fairness = {"tick", *[BUCKET_COLUMN[b] for b in buckets]}.issubset(fields)
            has_overflow = "overflow_events" in fields
            has_budget = {"budget_overrun", "deferred_events"}.issubset(fields)
            has_warmup = {
                "route_cache_warmup_ok",
                "route_cache_rescan_ok",
                "route_cache_guardrail_status",
            }.issubset(fields)

            total_rows = 0
            running_rows = 0

            # fairness
            streak = {b: 0 for b in buckets}
            worst = {b: 0 for b in buckets}
            pause_zero_columns = [c for c in ("processed_low", "processed_normal", "processed_high", "processed_critical") if c in fields]
            pause_violation_rows = 0
            resume_transitions = 0
            resume_window_tick = -1
            resume_window_violations = 0
            previous_state = "RUNNING"

            # overflow/budget
            overflow_hits = 0
            budget_hits = 0
            deferred_hits = 0

            # warmup
            warmup_rows = 0
            warmup_all_ok = True
            rescan_all_ok = True
            guardrail_all_ok = True

            for row_index, row in enumerate(reader, start=1):
                total_rows += 1
                state = (row.get("lifecycle_state") or "RUNNING").strip().upper()
                is_running = state == "RUNNING"
                if is_running:
                    running_rows += 1

                parsed_numbers: dict[str, int] = {}
                if has_fairness:
                    numeric_columns = {"tick", *[BUCKET_COLUMN[b] for b in buckets]}
                    if args.enforce_pause_zero:
                        numeric_columns.update(pause_zero_columns)
                    for column in numeric_columns:
                        try:
                            parsed_numbers[column] = safe_int(row.get(column))
                        except Exception:
                            print(
                                json.dumps(
                                    fail_payload(
                                        f"invalid numeric value (row index={row_index}, column name={column}, raw value={row.get(column)!r})"
                                    ),
                                    ensure_ascii=False,
                                )
                            )
                            return 2

                if has_fairness:
                    if previous_state == "PAUSED" and state == "RUNNING":
                        resume_transitions += 1
                        resume_window_tick = 0

                    if state == "PAUSED" and args.enforce_pause_zero:
                        if any(parsed_numbers.get(c, 0) > 0 for c in pause_zero_columns):
                            pause_violation_rows += 1

                    if is_running:
                        resume_window_tick, resume_window_violations = evaluate_post_resume_window(
                            args.max_post_resume_drain_ticks,
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

                if has_overflow and is_running:
                    try:
                        if safe_int(row.get("overflow_events")) > 0:
                            overflow_hits += 1
                    except Exception:
                        print(json.dumps(fail_payload("invalid numeric overflow_events"), ensure_ascii=False))
                        return 2

                if has_budget and is_running:
                    try:
                        if safe_int(row.get("budget_overrun")) > 0:
                            budget_hits += 1
                        if safe_int(row.get("deferred_events")) > 0:
                            deferred_hits += 1
                    except Exception:
                        print(json.dumps(fail_payload("invalid numeric budget/deferred values"), ensure_ascii=False))
                        return 2

                if has_warmup:
                    warmup_rows += 1
                    warmup_all_ok = warmup_all_ok and pass_bool(row.get("route_cache_warmup_ok"))
                    rescan_all_ok = rescan_all_ok and pass_bool(row.get("route_cache_rescan_ok"))
                    guardrail_all_ok = guardrail_all_ok and (row.get("route_cache_guardrail_status") or "").strip().upper() == "PASS"

            if total_rows == 0:
                print(json.dumps(fail_payload("csv is empty"), ensure_ascii=False))
                return 2

    except (OSError, UnicodeDecodeError) as exc:
        print(json.dumps(fail_payload(f"failed to read csv: {exc}"), ensure_ascii=False))
        return 2

    if has_fairness and args.max_post_resume_drain_ticks >= 0 and resume_window_tick >= 0:
        resume_window_tick, resume_window_violations = evaluate_post_resume_window(
            args.max_post_resume_drain_ticks,
            buckets,
            {},
            resume_window_tick,
            resume_window_violations,
        )

    if has_fairness:
        for b in buckets:
            worst[b] = max(worst[b], streak[b])

    fairness_status = "NA"
    fairness_reason = "processed_* columns absent in fixture"
    if has_fairness:
        failures: list[str] = []
        if running_rows == 0:
            failures.append("no RUNNING rows in input")
        for b in buckets:
            if worst[b] > args.max_starvation_window:
                failures.append(f"bucket={b} starvation window {worst[b]} exceeds limit {args.max_starvation_window}")
        if args.enforce_pause_zero and pause_violation_rows > 0:
            failures.append(f"pause-zero invariant violated on {pause_violation_rows} rows")
        if resume_transitions < args.min_resume_transitions:
            failures.append(f"resume transitions fewer than required: observed={resume_transitions}, required={args.min_resume_transitions}")
        if args.max_post_resume_drain_ticks >= 0 and resume_window_violations > 0:
            failures.append(f"post-resume drain window violated: violations={resume_window_violations}, limit={args.max_post_resume_drain_ticks} running ticks")

        if failures:
            fairness_status = "FAIL"
            fairness_reason = "; ".join(failures)
        else:
            fairness_status = "PASS"
            fairness_reason = "fairness checks passed"

    overflow_status = "NA"
    overflow_reason = "overflow_events data absent in fixture"
    if has_overflow:
        if running_rows == 0:
            overflow_status = "FAIL"
            overflow_reason = "no RUNNING rows in input"
        elif overflow_hits > 0:
            overflow_status = "PASS"
            overflow_reason = f"overflow events observed on {overflow_hits}/{running_rows} RUNNING rows"
        else:
            overflow_status = "FAIL"
            overflow_reason = "overflow events were not observed"

    budget_status = "NA"
    budget_reason = "budget_overrun/deferred_events data absent in fixture"
    if has_budget:
        if running_rows == 0:
            budget_status = "FAIL"
            budget_reason = "no RUNNING rows in input"
        elif budget_hits > 0 and deferred_hits > 0:
            budget_status = "PASS"
            budget_reason = f"budget_overrun={budget_hits}/{running_rows}, deferred_events={deferred_hits}/{running_rows}"
        else:
            budget_status = "FAIL"
            budget_reason = "budget_overrun or deferred_events signals were not observed"

    warmup_status = "NA"
    warmup_reason = "route_cache_* columns absent in fixture"
    if has_warmup:
        if warmup_rows > 0 and warmup_all_ok and rescan_all_ok and guardrail_all_ok:
            warmup_status = "PASS"
            warmup_reason = f"all warmup/rescan checks passed on {warmup_rows} rows"
        else:
            warmup_status = "FAIL"
            warmup_reason = "warmup/rescan/guardrail contains non-PASS signal"

    payload = {
        "schema_version": "1.0.0",
        "status": "OK",
        "input": str(path),
        "rows": {"total": total_rows, "running": running_rows},
        "fairness": {
            "status": fairness_status,
            "reason": fairness_reason,
            "resume_transitions": resume_transitions if has_fairness else 0,
            "resume_window_violations": resume_window_violations if has_fairness else 0,
            "worst_starvation_window": {b: worst[b] for b in buckets} if has_fairness else {},
        },
        "overflow": {"status": overflow_status, "reason": overflow_reason, "hits": overflow_hits if has_overflow else 0},
        "budget": {
            "status": budget_status,
            "reason": budget_reason,
            "budget_overrun_hits": budget_hits if has_budget else 0,
            "deferred_hits": deferred_hits if has_budget else 0,
        },
        "warmup": {"status": warmup_status, "reason": warmup_reason, "rows": warmup_rows if has_warmup else 0},
    }
    print(json.dumps(payload, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
