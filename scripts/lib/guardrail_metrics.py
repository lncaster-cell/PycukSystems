from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Mapping

PASS_TOKENS = {"1", "true", "pass"}


@dataclass(frozen=True)
class GuardrailMetrics:
    has_overflow: bool
    has_budget: bool
    has_warmup: bool
    running_rows: int
    overflow_hits: int
    budget_hits: int
    deferred_hits: int
    warmup_rows: int
    warmup_all_ok: bool
    rescan_all_ok: bool
    guardrail_all_ok: bool


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


def is_pass_token(raw: str | None) -> bool:
    return (raw or "").strip().lower() in PASS_TOKENS


def aggregate_guardrail_metrics(rows: Iterable[Mapping[str, str | None]], fieldnames: Iterable[str] | None) -> GuardrailMetrics:
    fields = set(fieldnames or [])
    has_overflow = "overflow_events" in fields
    has_budget = {"budget_overrun", "deferred_events"}.issubset(fields)
    has_warmup = {
        "route_cache_warmup_ok",
        "route_cache_rescan_ok",
        "route_cache_guardrail_status",
    }.issubset(fields)

    has_lifecycle_state = "lifecycle_state" in fields

    running_rows = 0
    overflow_hits = 0
    budget_hits = 0
    deferred_hits = 0
    warmup_rows = 0
    warmup_all_ok = True
    rescan_all_ok = True
    guardrail_all_ok = True

    for row_index, row in enumerate(rows, start=1):
        lifecycle_state = row.get("lifecycle_state") if has_lifecycle_state else "RUNNING"
        is_running = (lifecycle_state or "").strip().upper() == "RUNNING"
        if is_running and (has_overflow or has_budget):
            running_rows += 1

        if has_overflow:
            overflow_events = parse_int(row.get("overflow_events"), row_index, "overflow_events")
            if is_running and overflow_events > 0:
                overflow_hits += 1

        if has_budget:
            budget_overrun = parse_int(row.get("budget_overrun"), row_index, "budget_overrun")
            deferred_events = parse_int(row.get("deferred_events"), row_index, "deferred_events")
            if is_running:
                if budget_overrun > 0:
                    budget_hits += 1
                if deferred_events > 0:
                    deferred_hits += 1

        if has_warmup:
            warmup_rows += 1
            warmup_all_ok = warmup_all_ok and is_pass_token(row.get("route_cache_warmup_ok"))
            rescan_all_ok = rescan_all_ok and is_pass_token(row.get("route_cache_rescan_ok"))
            guardrail_all_ok = guardrail_all_ok and (row.get("route_cache_guardrail_status") or "").strip().upper() == "PASS"

    return GuardrailMetrics(
        has_overflow=has_overflow,
        has_budget=has_budget,
        has_warmup=has_warmup,
        running_rows=running_rows,
        overflow_hits=overflow_hits,
        budget_hits=budget_hits,
        deferred_hits=deferred_hits,
        warmup_rows=warmup_rows,
        warmup_all_ok=warmup_all_ok,
        rescan_all_ok=rescan_all_ok,
        guardrail_all_ok=guardrail_all_ok,
    )
