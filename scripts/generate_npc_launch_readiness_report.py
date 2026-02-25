#!/usr/bin/env python3
"""Generate final launch-readiness decision artifact for Ambient Life V3 pilot rollout."""

from __future__ import annotations

import argparse
import fnmatch
import json
from pathlib import Path

DEFAULT_READINESS_JSON = Path("docs/reports/npc_rollout_readiness_report.json")
DEFAULT_EXECUTION_JSON = Path("docs/reports/npc_migration_execution_report.json")
DEFAULT_BACKLOG_JSON = Path("docs/reports/npc_remediation_backlog_report.json")
DEFAULT_EXCEPTIONS_JSON = Path("docs/npc_migration_exception_registry.json")
DEFAULT_REPORT_JSON = Path("docs/reports/npc_launch_readiness_report.json")
DEFAULT_REPORT_MD = Path("docs/reports/npc_launch_readiness_report.md")
DEFAULT_PILOT_INCLUDE = ["src/integrations/nwnx_sqlite/*"]

REQUIRED_DOCS = [
    "docs/npc_toolset_authoring_contract.md",
    "docs/npc_rollout_readiness_checklist.md",
    "docs/npc_batch_migration_execution.md",
    "docs/npc_manual_remediation_governance.md",
    "docs/npc_go_live_checklist.md",
    "docs/npc_pilot_rollout_runbook.md",
]


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def is_safe_tier(tier: str) -> bool:
    return tier in {"READY", "BRIDGEABLE"}


def render_md(report: dict) -> str:
    s = report["summary"]
    lines = [
        "# Ambient Life V3 Launch Readiness Report",
        "",
        f"- Verdict: **{s['verdict']}**",
        f"- Smoke status: **{s['smoke_status']}**",
        f"- Open P1 backlog cases: **{s['open_p1_cases']}**",
        f"- Open total backlog cases: **{s['open_total_cases']}**",
        f"- Active exceptions: **{s['active_exceptions']}**",
        f"- Pilot candidate files: **{s['pilot_candidates_total']}**",
        f"- Pilot safe candidates (`READY/BRIDGEABLE`): **{s['pilot_safe_candidates']}**",
        "",
        "## Go/Stop criteria",
    ]
    for row in report["criteria"]:
        lines.append(f"- [{row['status']}] {row['name']}: {row['details']}")

    lines.extend(["", "## Recommendation", f"- {report['recommendation']}"])
    lines.extend(["", "## Pilot scope"])
    lines.append(f"- Include patterns: {', '.join(report['pilot_scope']['include_patterns'])}")
    if report["pilot_scope"]["matched"]:
        for row in report["pilot_scope"]["matched"][:30]:
            lines.append(f"  - `{row['path']}` ({row['tier']})")
    else:
        lines.append("  - none")

    lines.extend(["", "## Stop conditions triggered now"])
    if report["stop_conditions_now"]:
        for item in report["stop_conditions_now"]:
            lines.append(f"- {item}")
    else:
        lines.append("- none")

    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate pilot launch-readiness report")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--readiness-json", type=Path, default=DEFAULT_READINESS_JSON)
    parser.add_argument("--execution-json", type=Path, default=DEFAULT_EXECUTION_JSON)
    parser.add_argument("--backlog-json", type=Path, default=DEFAULT_BACKLOG_JSON)
    parser.add_argument("--exceptions-json", type=Path, default=DEFAULT_EXCEPTIONS_JSON)
    parser.add_argument("--pilot-include-path", action="append", default=None)
    parser.add_argument("--smoke-status", choices=["GREEN", "RED"], default="GREEN")
    parser.add_argument("--report-json", type=Path, default=DEFAULT_REPORT_JSON)
    parser.add_argument("--report-md", type=Path, default=DEFAULT_REPORT_MD)
    args = parser.parse_args()

    root = args.repo_root.resolve()
    include_patterns = args.pilot_include_path or DEFAULT_PILOT_INCLUDE

    readiness = load_json(root / args.readiness_json)
    execution = load_json(root / args.execution_json)
    backlog = load_json(root / args.backlog_json)
    exceptions = load_json(root / args.exceptions_json)

    criteria = []
    stop_now: list[str] = []

    open_cases = [c for c in backlog.get("cases", []) if c.get("status") == "OPEN"]
    open_p1 = [c for c in open_cases if c.get("priority") == "P1"]
    criteria.append({
        "name": "No OPEN/P1 blockers",
        "status": "PASS" if not open_p1 else "FAIL",
        "details": f"open_p1={len(open_p1)}",
    })
    if open_p1:
        stop_now.append("OPEN/P1 cases present in remediation backlog")

    criteria.append({
        "name": "No OPEN blockers",
        "status": "PASS" if not open_cases else "FAIL",
        "details": f"open_total={len(open_cases)}",
    })
    if open_cases:
        stop_now.append("OPEN remediation cases present")

    smoke_ok = args.smoke_status == "GREEN"
    criteria.append({"name": "Smoke/contracts green", "status": "PASS" if smoke_ok else "FAIL", "details": args.smoke_status})
    if not smoke_ok:
        stop_now.append("Smoke/contracts regression")

    active_exceptions = [e for e in exceptions.get("exceptions", []) if e.get("status") == "active"]
    criteria.append({
        "name": "Exception registry has active governed entries",
        "status": "PASS" if len(active_exceptions) >= 1 else "FAIL",
        "details": f"active_exceptions={len(active_exceptions)}",
    })

    required_report_files = [
        str(args.readiness_json),
        str(args.execution_json),
        str(args.backlog_json),
    ]
    missing_reports = [p for p in required_report_files if not (root / p).exists()]
    criteria.append({
        "name": "Required governance reports exist",
        "status": "PASS" if not missing_reports else "FAIL",
        "details": "missing=" + (", ".join(missing_reports) if missing_reports else "none"),
    })
    if missing_reports:
        stop_now.append("Required reports missing")

    missing_docs = [p for p in REQUIRED_DOCS if not (root / p).exists()]
    criteria.append({
        "name": "Required launch docs exist",
        "status": "PASS" if not missing_docs else "FAIL",
        "details": "missing=" + (", ".join(missing_docs) if missing_docs else "none"),
    })
    if missing_docs:
        stop_now.append("Required launch docs missing")

    readiness_files = readiness.get("files", [])
    pilot_matched = [
        {"path": row.get("path", ""), "tier": row.get("tier", "UNKNOWN")}
        for row in readiness_files
        if any(fnmatch.fnmatch(row.get("path", ""), pattern) for pattern in include_patterns)
    ]
    pilot_safe = [r for r in pilot_matched if is_safe_tier(r["tier"])]
    pilot_unsafe = [r for r in pilot_matched if not is_safe_tier(r["tier"])]
    criteria.append({
        "name": "Pilot target is READY/BRIDGEABLE",
        "status": "PASS" if pilot_matched and not pilot_unsafe else "FAIL",
        "details": f"matched={len(pilot_matched)}, unsafe={len(pilot_unsafe)}",
    })
    if not pilot_matched:
        stop_now.append("Pilot scope matched no files")
    elif pilot_unsafe:
        stop_now.append("Pilot scope includes MANUAL/CONFLICTED/FALLBACK-RISK files")

    execution_summary = execution.get("summary", {})
    dry_run_seen = execution_summary.get("mode") in {"dry-run", "apply"}
    criteria.append({
        "name": "Execution helper report available",
        "status": "PASS" if dry_run_seen else "FAIL",
        "details": f"mode={execution_summary.get('mode', 'unknown')}",
    })
    if not dry_run_seen:
        stop_now.append("Execution helper report invalid")

    verdict = "GO" if all(c["status"] == "PASS" for c in criteria) else "STOP"
    recommendation = (
        "Pilot rollout can proceed for the selected scope with standard monitoring and post-apply report regeneration."
        if verdict == "GO"
        else "Do not launch pilot yet. Resolve STOP conditions, regenerate reports, and rerun final readiness check."
    )

    report = {
        "summary": {
            "verdict": verdict,
            "smoke_status": args.smoke_status,
            "open_p1_cases": len(open_p1),
            "open_total_cases": len(open_cases),
            "active_exceptions": len(active_exceptions),
            "pilot_candidates_total": len(pilot_matched),
            "pilot_safe_candidates": len(pilot_safe),
        },
        "criteria": criteria,
        "pilot_scope": {
            "include_patterns": include_patterns,
            "matched": pilot_matched,
            "unsafe": pilot_unsafe,
        },
        "stop_conditions_now": stop_now,
        "recommendation": recommendation,
    }

    out_json = root / args.report_json
    out_md = root / args.report_md
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    out_md.write_text(render_md(report) + "\n", encoding="utf-8")

    print(f"[OK] launch-readiness report written: {out_json.relative_to(root)}")
    print(f"[OK] launch-readiness report written: {out_md.relative_to(root)}")
    print(f"[OK] verdict={verdict}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
