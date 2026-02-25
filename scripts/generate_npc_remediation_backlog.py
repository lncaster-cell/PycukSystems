#!/usr/bin/env python3
"""Generate manual remediation backlog for Ambient Life V3 rollout governance."""

from __future__ import annotations

import argparse
import fnmatch
import json
from dataclasses import dataclass
from pathlib import Path

DEFAULT_READINESS_JSON = Path("docs/reports/npc_rollout_readiness_report.json")
DEFAULT_EXECUTION_JSON = Path("docs/reports/npc_migration_execution_report.json")
DEFAULT_EXCEPTION_REGISTRY = Path("docs/npc_migration_exception_registry.json")
DEFAULT_BACKLOG_JSON = Path("docs/reports/npc_remediation_backlog_report.json")
DEFAULT_BACKLOG_MD = Path("docs/reports/npc_remediation_backlog_report.md")

CATEGORY_ACTIONS = {
    "HOOK-WIRING": "Align hook script naming/wiring to canonical npc_* contract and verify include/entrypoint mapping.",
    "LEGACY-UNSUPPORTED": "Rewrite unsupported al_* keys to canonical npc_* keys; bridge extension only with approved case + tests.",
    "AMBIGUOUS-ROUTE": "Resolve route/tag naming ambiguity manually and set explicit canonical npc_route_* mapping.",
    "RUNTIME-PROTECTED": "Review protected runtime/content boundary; if content-owned, migrate manually; if runtime-owned, track as governed exception.",
    "CONFLICTED-CONFIG": "Split conflicting old/new patterns and converge on canonical contract before rollout.",
    "DOC/CONTRACT-DRIFT": "Fix drift between content wiring and docs/npc_toolset_authoring_contract.md, then rerun readiness audit.",
}

VALID_CATEGORIES = set(CATEGORY_ACTIONS)


@dataclass
class Case:
    path: str
    category: str
    priority: str
    source: str
    tier: str
    reason: str
    action: str
    status: str = "OPEN"
    exception_id: str = ""


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def determine_priority(category: str, tier: str, reason: str) -> str:
    if category in {"HOOK-WIRING", "CONFLICTED-CONFIG", "DOC/CONTRACT-DRIFT"}:
        return "P1"
    if category == "LEGACY-UNSUPPORTED":
        return "P1" if tier in {"MANUAL", "CONFLICTED"} else "P2"
    if category == "AMBIGUOUS-ROUTE":
        return "P2"
    if category == "RUNTIME-PROTECTED":
        if tier in {"MANUAL", "CONFLICTED", "FALLBACK-RISK"}:
            return "P2"
        if "bridge" in reason.lower() or "legacy" in reason.lower():
            return "P2"
        return "P3"
    return "P3"


def add_case(cases: dict[tuple[str, str], Case], path: str, category: str, source: str, tier: str, reason: str) -> None:
    key = (path, category)
    if key in cases:
        return
    cases[key] = Case(
        path=path,
        category=category,
        priority=determine_priority(category, tier, reason),
        source=source,
        tier=tier,
        reason=reason,
        action=CATEGORY_ACTIONS[category],
    )


def validate_registry(registry: dict) -> list[dict]:
    entries = registry.get("exceptions", [])
    if not isinstance(entries, list):
        raise SystemExit("[FAIL] exception registry: 'exceptions' must be a list")
    for idx, item in enumerate(entries):
        for req in ("id", "path_pattern", "category", "status", "rationale"):
            if req not in item:
                raise SystemExit(f"[FAIL] exception registry: missing '{req}' in entry #{idx}")
        if item["category"] not in VALID_CATEGORIES and item["category"] != "*":
            raise SystemExit(f"[FAIL] exception registry: unknown category '{item['category']}' in {item['id']}")
        if item["status"] not in {"active", "closed"}:
            raise SystemExit(f"[FAIL] exception registry: invalid status '{item['status']}' in {item['id']}")
    return entries


def apply_exceptions(cases: list[Case], entries: list[dict]) -> None:
    for case in cases:
        for item in entries:
            if item["status"] != "active":
                continue
            if item["category"] not in {"*", case.category}:
                continue
            if not fnmatch.fnmatch(case.path, item["path_pattern"]):
                continue
            case.status = "EXCEPTION"
            case.exception_id = item["id"]
            break


def render_md(report: dict) -> str:
    s = report["summary"]
    lines = [
        "# Ambient Life V3 Manual Remediation Backlog",
        "",
        f"- Total unresolved cases: **{s['total_cases']}**",
        f"- Open cases: **{s['open_cases']}**",
        f"- Exception-tracked cases: **{s['exception_cases']}**",
        "",
        "## By category",
    ]
    for c, n in sorted(s["by_category"].items()):
        lines.append(f"- **{c}**: {n}")
    lines.extend(["", "## By priority"])
    for p in ("P1", "P2", "P3"):
        lines.append(f"- **{p}**: {s['by_priority'].get(p, 0)}")
    lines.extend(["", "## Cases"])
    if not report["cases"]:
        lines.append("- none")
    else:
        for row in report["cases"]:
            exc = f"; exception={row['exception_id']}" if row.get("exception_id") else ""
            lines.append(
                f"- `{row['path']}` → **{row['category']}** / **{row['priority']}** / {row['status']} (tier={row['tier']}; {row['reason']}{exc})"
            )
    lines.extend(["", "## Recommended actions"])
    for category, action in CATEGORY_ACTIONS.items():
        lines.append(f"- **{category}**: {action}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate remediation backlog from readiness + execution reports")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--readiness-json", type=Path, default=DEFAULT_READINESS_JSON)
    parser.add_argument("--execution-json", type=Path, default=DEFAULT_EXECUTION_JSON)
    parser.add_argument("--exception-registry", type=Path, default=DEFAULT_EXCEPTION_REGISTRY)
    parser.add_argument("--backlog-json", type=Path, default=DEFAULT_BACKLOG_JSON)
    parser.add_argument("--backlog-md", type=Path, default=DEFAULT_BACKLOG_MD)
    args = parser.parse_args()

    root = args.repo_root.resolve()
    readiness_path = root / args.readiness_json
    if not readiness_path.exists():
        raise SystemExit(f"[FAIL] readiness report missing: {readiness_path}")
    readiness = load_json(readiness_path)

    execution = {"results": []}
    execution_path = root / args.execution_json
    if execution_path.exists():
        execution = load_json(execution_path)

    registry_path = root / args.exception_registry
    if not registry_path.exists():
        raise SystemExit(f"[FAIL] exception registry missing: {registry_path}")
    registry = load_json(registry_path)
    registry_entries = validate_registry(registry)

    cases_map: dict[tuple[str, str], Case] = {}

    # Readiness-driven unresolved cases.
    for item in readiness.get("files", []):
        path = item.get("path", "")
        tier = item.get("tier", "")
        reasons = item.get("reasons", [])
        reason_text = "; ".join(reasons) if reasons else "readiness finding"

        if tier == "MANUAL":
            if any("hook-like" in r for r in reasons):
                add_case(cases_map, path, "HOOK-WIRING", "readiness", tier, reason_text)
            if item.get("legacy_unsupported"):
                add_case(cases_map, path, "LEGACY-UNSUPPORTED", "readiness", tier, reason_text)
            if not item.get("legacy_unsupported") and not any("hook-like" in r for r in reasons):
                add_case(cases_map, path, "DOC/CONTRACT-DRIFT", "readiness", tier, reason_text)

        if tier == "CONFLICTED":
            add_case(cases_map, path, "CONFLICTED-CONFIG", "readiness", tier, reason_text)
            if item.get("legacy_unsupported"):
                add_case(cases_map, path, "LEGACY-UNSUPPORTED", "readiness", tier, reason_text)

        if item.get("legacy_ambiguous"):
            add_case(cases_map, path, "AMBIGUOUS-ROUTE", "readiness", tier or "FALLBACK-RISK", reason_text)

        if item.get("legacy_unsupported") and tier not in {"MANUAL", "CONFLICTED"}:
            add_case(cases_map, path, "LEGACY-UNSUPPORTED", "readiness", tier or "UNKNOWN", reason_text)

    # Repo-level contract drift case if detected.
    hook_wiring = readiness.get("hook_wiring", {})
    if not hook_wiring.get("canonical_contract_exists", False):
        add_case(
            cases_map,
            hook_wiring.get("canonical_contract_path", "docs/npc_toolset_authoring_contract.md"),
            "DOC/CONTRACT-DRIFT",
            "readiness",
            "MANUAL",
            "canonical contract document is missing",
        )

    for hook, info in (hook_wiring.get("canonical_hooks", {}) or {}).items():
        if info.get("status") != "ok":
            add_case(
                cases_map,
                info.get("path", f"src/modules/npc/{hook}.nss"),
                "DOC/CONTRACT-DRIFT",
                "readiness",
                "MANUAL",
                f"canonical hook drift detected: {hook}",
            )

    # Execution-driven unresolved cases.
    for row in execution.get("results", []):
        status = row.get("status", "")
        details = row.get("details", "")
        if status != "skip":
            continue
        tier = row.get("tier", "UNKNOWN")
        path = row.get("path", "")
        details_lower = details.lower()

        if "protected runtime path" in details_lower:
            add_case(cases_map, path, "RUNTIME-PROTECTED", "execution", tier, details)
        elif "unsupported or ambiguous" in details_lower:
            add_case(cases_map, path, "AMBIGUOUS-ROUTE", "execution", tier, details)
        elif "manual/conflicted" in details_lower:
            add_case(cases_map, path, "CONFLICTED-CONFIG", "execution", tier, details)

    cases = sorted(cases_map.values(), key=lambda c: (c.priority, c.category, c.path))
    apply_exceptions(cases, registry_entries)

    by_category: dict[str, int] = {}
    by_priority: dict[str, int] = {}
    open_cases = 0
    exception_cases = 0
    for case in cases:
        by_category[case.category] = by_category.get(case.category, 0) + 1
        by_priority[case.priority] = by_priority.get(case.priority, 0) + 1
        if case.status == "EXCEPTION":
            exception_cases += 1
        else:
            open_cases += 1

    report = {
        "summary": {
            "total_cases": len(cases),
            "open_cases": open_cases,
            "exception_cases": exception_cases,
            "by_category": by_category,
            "by_priority": by_priority,
        },
        "exception_registry": str(args.exception_registry),
        "cases": [case.__dict__ for case in cases],
        "recommended_actions": CATEGORY_ACTIONS,
    }

    backlog_json = root / args.backlog_json
    backlog_md = root / args.backlog_md
    backlog_json.parent.mkdir(parents=True, exist_ok=True)
    backlog_md.parent.mkdir(parents=True, exist_ok=True)

    backlog_json.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    backlog_md.write_text(render_md(report) + "\n", encoding="utf-8")

    print(f"[OK] remediation backlog written: {backlog_json.relative_to(root)}")
    print(f"[OK] remediation backlog written: {backlog_md.relative_to(root)}")
    print(f"[OK] unresolved={len(cases)} open={open_cases} exceptions={exception_cases}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
