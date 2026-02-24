#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path


def main() -> int:
    payload = json.loads(sys.stdin.read())
    out_dir = Path(payload["out_dir"])
    scenario = payload["scenario_id"]

    guardrails = payload["guardrails"]
    rows = [
        {
            "guardrail": "registry_overflow",
            "status": guardrails["overflow"]["status"],
            "scenario_id": scenario,
            "profile": scenario,
            "runs_passed": guardrails["overflow"]["runs_passed"],
            "runs_total": guardrails["overflow"]["runs_total"],
            "evidence": guardrails["overflow"]["evidence"],
        },
        {
            "guardrail": "tick_budget_degraded",
            "status": guardrails["budget"]["status"],
            "scenario_id": scenario,
            "profile": scenario,
            "runs_passed": guardrails["budget"]["runs_passed"],
            "runs_total": guardrails["budget"]["runs_total"],
            "evidence": guardrails["budget"]["evidence"],
        },
        {
            "guardrail": "automated_fairness",
            "status": guardrails["fairness"]["status"],
            "scenario_id": scenario,
            "profile": scenario,
            "runs_passed": guardrails["fairness"]["runs_passed"],
            "runs_total": guardrails["fairness"]["runs_total"],
            "evidence": guardrails["fairness"]["evidence"],
        },
        {
            "guardrail": "route_cache_warmup_rescan",
            "status": guardrails["warmup"]["status"],
            "scenario_id": scenario,
            "profile": scenario,
            "runs_passed": guardrails["warmup"]["runs_passed"],
            "runs_total": guardrails["warmup"]["runs_total"],
            "evidence": guardrails["warmup"]["evidence"],
        },
    ]

    csv_path = out_dir / "gate_summary.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["guardrail", "status", "scenario_id", "profile", "runs_passed", "runs_total", "evidence"],
        )
        writer.writeheader()
        writer.writerows(rows)

    json_path = out_dir / "gate_summary.json"
    json_payload = {
        "schema_version": "1.0.0",
        "timestamp": payload["timestamp"],
        "scenario_id": scenario,
        "source_fixture": payload["source_fixture"],
        "runs": payload["runs"],
        "baseline": payload["baseline"],
        "guardrails": [
            {
                "id": "registry_overflow",
                "status": guardrails["overflow"]["status"],
                "passed_runs": guardrails["overflow"]["runs_passed"],
                "total_runs": guardrails["overflow"]["runs_total"],
                "evidence": guardrails["overflow"]["evidence"],
            },
            {
                "id": "tick_budget_degraded",
                "status": guardrails["budget"]["status"],
                "passed_runs": guardrails["budget"]["runs_passed"],
                "total_runs": guardrails["budget"]["runs_total"],
                "evidence": guardrails["budget"]["evidence"],
            },
            {
                "id": "automated_fairness",
                "status": guardrails["fairness"]["status"],
                "passed_runs": guardrails["fairness"]["runs_passed"],
                "total_runs": guardrails["fairness"]["runs_total"],
                "evidence": guardrails["fairness"]["evidence"],
            },
            {
                "id": "route_cache_warmup_rescan",
                "status": guardrails["warmup"]["status"],
                "passed_runs": guardrails["warmup"]["runs_passed"],
                "total_runs": guardrails["warmup"]["runs_total"],
                "evidence": guardrails["warmup"]["evidence"],
            },
        ],
    }

    with json_path.open("w", encoding="utf-8") as f:
        json.dump(json_payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
