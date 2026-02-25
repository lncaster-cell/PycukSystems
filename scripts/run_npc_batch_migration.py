#!/usr/bin/env python3
"""Batch migration helper for Ambient Life V3 phased rollout execution.

Works on top of readiness report and only auto-normalizes safe tiers
(READY/BRIDGEABLE by default) with strict safeguards.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

SAFE_TIERS = {"READY", "BRIDGEABLE"}
ALL_TIERS = {"READY", "BRIDGEABLE", "FALLBACK-RISK", "MANUAL", "CONFLICTED"}

DEFAULT_READINESS_JSON = Path("docs/reports/npc_rollout_readiness_report.json")
DEFAULT_EXECUTION_JSON = Path("docs/reports/npc_migration_execution_report.json")
DEFAULT_EXECUTION_MD = Path("docs/reports/npc_migration_execution_report.md")

# Runtime/bridge internals are not content migration targets.
PROTECTED_PATH_PATTERNS = (
    "src/modules/npc/*",
    "src/modules/module_skeleton/*",
    "src/controllers/*",
)

LEGACY_EXACT_MAP = {
    "al_slot": "npc_activity_slot",
    "al_route": "npc_activity_route",
    "al_schedule_enabled": "npc_activity_schedule_enabled",
    "al_schedule_critical_start": "npc_schedule_start_critical",
    "al_schedule_critical_end": "npc_schedule_end_critical",
    "al_schedule_priority_start": "npc_schedule_start_priority",
    "al_schedule_priority_end": "npc_schedule_end_priority",
    "al_route_default": "npc_route_profile_default",
    "al_route_priority": "npc_route_profile_priority",
    "al_route_critical": "npc_route_profile_critical",
}

LEGACY_PREFIX_MAP = {
    "al_route_count_": "npc_route_count_",
    "al_route_loop_": "npc_route_loop_",
    "al_route_tag_": "npc_route_tag_",
    "al_route_pause_": "npc_route_pause_ticks_",
    "al_route_activity_": "npc_route_activity_",
}


@dataclass
class MigrationResult:
    path: str
    status: str
    tier: str
    details: str
    replacements: int = 0


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run_audit(repo_root: Path, readiness_json: Path) -> None:
    subprocess.run(
        [
            "python3",
            str(repo_root / "scripts/audit_npc_rollout_readiness.py"),
            "--repo-root",
            str(repo_root),
            "--scan",
            "src",
            "--json-out",
            str(readiness_json),
            "--md-out",
            "docs/reports/npc_rollout_readiness_report.md",
        ],
        check=True,
        cwd=repo_root,
    )


def match_any(path: str, patterns: list[str]) -> bool:
    if not patterns:
        return True
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def is_protected(path: str) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in PROTECTED_PATH_PATTERNS)


def normalize_supported_legacy(text: str) -> tuple[str, int]:
    out = text
    replacements = 0

    for legacy, canonical in LEGACY_EXACT_MAP.items():
        out, count = re.subn(rf"\b{re.escape(legacy)}\b", canonical, out)
        replacements += count

    for legacy_prefix, canonical_prefix in LEGACY_PREFIX_MAP.items():
        out, count = re.subn(rf"\b{re.escape(legacy_prefix)}", canonical_prefix, out)
        replacements += count

    return out, replacements


def render_md(report: dict) -> str:
    lines = ["# Ambient Life V3 Batch Migration Execution Report", ""]
    summary = report["summary"]
    lines.extend(
        [
            f"- Mode: **{summary['mode']}**",
            f"- Selected tiers: `{', '.join(summary['tiers'])}`",
            f"- Candidates: **{summary['candidates_total']}**",
            f"- Changed files: **{summary['changed_files']}**",
            f"- Already canonical skips: **{summary['already_canonical']}**",
            f"- Manual/conflicted skips: **{summary['manual_conflicted_skips']}**",
            f"- Safe skips: **{summary['safe_skips']}**",
            f"- Bridge conversions applied: **{summary['bridge_conversions']}**",
            "",
            "## File actions",
        ]
    )
    if not report["results"]:
        lines.append("- none")
    else:
        for row in report["results"]:
            lines.append(
                f"- `{row['path']}` → **{row['status']}** (tier={row['tier']}; replacements={row['replacements']}; {row['details']})"
            )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run phased batch migration for Ambient Life V3")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--readiness-json", type=Path, default=DEFAULT_READINESS_JSON)
    parser.add_argument("--run-audit-if-missing", action="store_true")
    parser.add_argument("--tier", action="append", default=None, help="Tier(s) to process")
    parser.add_argument("--include-path", action="append", default=[])
    parser.add_argument("--exclude-path", action="append", default=[])
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--apply", action="store_true", help="Apply changes (default is dry-run)")
    parser.add_argument("--allow-unsafe-tiers", action="store_true", help="Allow selecting non-safe tiers (still skipped) for reporting")
    parser.add_argument("--execution-json", type=Path, default=DEFAULT_EXECUTION_JSON)
    parser.add_argument("--execution-md", type=Path, default=DEFAULT_EXECUTION_MD)
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    readiness_json = repo_root / args.readiness_json

    selected_tiers = []
    for tier in (args.tier or ["READY"]):
        if tier not in ALL_TIERS:
            raise SystemExit(f"[FAIL] unknown tier: {tier}")
        selected_tiers.append(tier)

    if any(t not in SAFE_TIERS for t in selected_tiers) and not args.allow_unsafe_tiers:
        raise SystemExit("[FAIL] unsafe tiers requested; use --allow-unsafe-tiers for report-only selection")

    if not readiness_json.exists():
        if args.run_audit_if_missing:
            run_audit(repo_root, args.readiness_json)
        else:
            raise SystemExit(f"[FAIL] readiness report missing: {readiness_json}")

    readiness = load_json(readiness_json)
    items = readiness.get("files", [])

    results: list[MigrationResult] = []
    changed_files = 0
    already_canonical = 0
    manual_conflicted = 0
    safe_skips = 0
    bridge_conversions = 0

    candidates = []
    for item in items:
        path = item.get("path", "")
        tier = item.get("tier", "")
        if tier not in selected_tiers:
            continue
        if args.include_path and not match_any(path, args.include_path):
            continue
        if args.exclude_path and match_any(path, args.exclude_path):
            continue
        candidates.append(item)

    if args.limit > 0:
        candidates = candidates[: args.limit]

    for item in candidates:
        path = item["path"]
        tier = item["tier"]
        file_path = repo_root / path

        if tier in {"MANUAL", "CONFLICTED"}:
            manual_conflicted += 1
            results.append(MigrationResult(path, "skip", tier, "manual/conflicted tier is never auto-fixed"))
            continue

        if item.get("legacy_unsupported") or item.get("legacy_ambiguous"):
            safe_skips += 1
            results.append(MigrationResult(path, "skip", tier, "unsupported or ambiguous legacy patterns present"))
            continue

        if is_protected(path):
            safe_skips += 1
            results.append(MigrationResult(path, "skip", tier, "protected runtime path; content migration not applied"))
            continue

        if not file_path.exists() or not file_path.is_file():
            safe_skips += 1
            results.append(MigrationResult(path, "skip", tier, "file missing; skipped safely"))
            continue

        original = file_path.read_text(encoding="utf-8", errors="ignore")
        normalized, replaced = normalize_supported_legacy(original)

        if replaced == 0 or normalized == original:
            already_canonical += 1
            results.append(MigrationResult(path, "skip", tier, "already canonical/no supported legacy keys", 0))
            continue

        bridge_conversions += replaced
        if args.apply:
            file_path.write_text(normalized, encoding="utf-8")
            changed_files += 1
            results.append(MigrationResult(path, "changed", tier, "canonical normalization applied", replaced))
        else:
            results.append(MigrationResult(path, "would-change", tier, "dry-run candidate", replaced))

    report = {
        "summary": {
            "mode": "apply" if args.apply else "dry-run",
            "tiers": selected_tiers,
            "candidates_total": len(candidates),
            "changed_files": changed_files,
            "already_canonical": already_canonical,
            "manual_conflicted_skips": manual_conflicted,
            "safe_skips": safe_skips,
            "bridge_conversions": bridge_conversions,
        },
        "results": [r.__dict__ for r in results],
    }

    execution_json = repo_root / args.execution_json
    execution_md = repo_root / args.execution_md
    execution_json.parent.mkdir(parents=True, exist_ok=True)
    execution_md.parent.mkdir(parents=True, exist_ok=True)
    execution_json.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    execution_md.write_text(render_md(report) + "\n", encoding="utf-8")

    print(f"[OK] execution report written: {execution_json.relative_to(repo_root)}")
    print(f"[OK] execution report written: {execution_md.relative_to(repo_root)}")
    print(f"[OK] mode={'apply' if args.apply else 'dry-run'} candidates={len(candidates)} changed={changed_files}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
