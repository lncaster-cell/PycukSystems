#!/usr/bin/env python3
"""Ambient Life V3 rollout-readiness audit.

Scans repository content for canonical npc_* adoption, legacy al_* usage,
unsupported bridge patterns, and hook wiring drift against
`docs/npc_toolset_authoring_contract.md`.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

CANONICAL_HOOKS = {
    "npc_module_load",
    "npc_area_enter",
    "npc_area_exit",
    "npc_area_tick",
    "npc_area_maintenance",
    "npc_spawn",
    "npc_perception",
    "npc_damaged",
    "npc_death",
    "npc_dialogue",
}

HOOK_TOKENS = (
    "module_load",
    "area_enter",
    "area_exit",
    "area_tick",
    "area_maintenance",
    "spawn",
    "perception",
    "damaged",
    "death",
    "dialogue",
    "heartbeat",
)

SUPPORTED_LEGACY_EXACT = {
    "al_slot",
    "al_route",
    "al_schedule_enabled",
    "al_schedule_critical_start",
    "al_schedule_critical_end",
    "al_schedule_priority_start",
    "al_schedule_priority_end",
    "al_route_default",
    "al_route_priority",
    "al_route_critical",
}

SUPPORTED_LEGACY_PREFIXES = (
    "al_route_count_",
    "al_route_loop_",
    "al_route_tag_",
    "al_route_pause_",
    "al_route_activity_",
)

VANILLA_HOOK_KEYWORDS = (
    "x0_",
    "x2_",
    "ga_",
    "gb_",
    "nw_c2_",
    "nw_s",
)

NPC_RUNTIME_DIR = Path("src/modules/npc")
CANONICAL_CONTRACT_PATH = Path("docs/npc_toolset_authoring_contract.md")


@dataclass
class FileAudit:
    path: Path
    canonical_keys: set[str] = field(default_factory=set)
    legacy_supported: set[str] = field(default_factory=set)
    legacy_ambiguous: set[str] = field(default_factory=set)
    legacy_unsupported: set[str] = field(default_factory=set)
    vanilla_hook_refs: set[str] = field(default_factory=set)
    mixed_hook_policy_warning: bool = False
    tier: str = "READY"
    reasons: list[str] = field(default_factory=list)


def classify_legacy_key(key: str) -> str:
    if key in SUPPORTED_LEGACY_EXACT:
        return "supported"
    if any(key.startswith(prefix) for prefix in SUPPORTED_LEGACY_PREFIXES):
        return "supported"
    if key.startswith("al_route_"):
        return "ambiguous"
    return "unsupported"


def find_nss_files(scan_roots: Iterable[Path]) -> list[Path]:
    files: list[Path] = []
    for root in scan_roots:
        if root.is_file() and root.suffix.lower() == ".nss":
            files.append(root)
            continue
        if root.is_dir():
            files.extend(root.rglob("*.nss"))
    return sorted(set(files))


def has_migration_policy(text: str) -> bool:
    return (
        "npc_legacy_al_bridge_inc" in text
        or "migration-only" in text.lower()
        or "legacy bridge" in text.lower()
    )


def assess_tier(audit: FileAudit, is_hooklike_noncanonical: bool, has_canonical_hook: bool) -> None:
    has_legacy = bool(audit.legacy_supported or audit.legacy_ambiguous or audit.legacy_unsupported)
    has_unsupported = bool(audit.legacy_unsupported)
    has_ambiguous = bool(audit.legacy_ambiguous)

    if (has_canonical_hook and (has_legacy or audit.vanilla_hook_refs) and audit.mixed_hook_policy_warning) or (
        audit.canonical_keys and (has_unsupported or is_hooklike_noncanonical)
    ):
        audit.tier = "CONFLICTED"
        audit.reasons.append("mixed canonical + legacy/vanilla patterns without explicit migration policy")
        return

    if has_unsupported or is_hooklike_noncanonical:
        audit.tier = "MANUAL"
        if has_unsupported:
            audit.reasons.append("unsupported al_* patterns detected")
        if is_hooklike_noncanonical:
            audit.reasons.append("noncanonical hook-like script naming or wiring")
        return

    if has_ambiguous:
        audit.tier = "FALLBACK-RISK"
        audit.reasons.append("ambiguous legacy al_route_* pattern may route to fallback")
        return

    if has_legacy and not has_unsupported and not has_ambiguous:
        audit.tier = "BRIDGEABLE"
        audit.reasons.append("legacy usage fits supported bridge subset")
        return

    audit.tier = "READY"
    if audit.canonical_keys or has_canonical_hook:
        audit.reasons.append("canonical npc_* contract usage detected")
    else:
        audit.reasons.append("no legacy risk markers detected")


def analyze_file(path: Path, repo_root: Path) -> FileAudit:
    text = path.read_text(encoding="utf-8", errors="ignore")
    rel_path = path.relative_to(repo_root)
    audit = FileAudit(path=rel_path)

    audit.canonical_keys = set(re.findall(r"\bnpc_[a-z0-9_]+\b", text))

    legacy_keys = set(re.findall(r"\bal_[a-z0-9_]+\b", text))
    for key in legacy_keys:
        classification = classify_legacy_key(key)
        if classification == "supported":
            audit.legacy_supported.add(key)
        elif classification == "ambiguous":
            audit.legacy_ambiguous.add(key)
        else:
            audit.legacy_unsupported.add(key)

    for token in VANILLA_HOOK_KEYWORDS:
        if token in text:
            audit.vanilla_hook_refs.add(token)

    stem = path.stem.lower()
    is_hooklike = any(token in stem for token in HOOK_TOKENS)
    has_canonical_hook = stem in CANONICAL_HOOKS
    is_hooklike_noncanonical = is_hooklike and not has_canonical_hook

    if has_canonical_hook and (legacy_keys or audit.vanilla_hook_refs):
        if not has_migration_policy(text):
            audit.mixed_hook_policy_warning = True

    assess_tier(audit, is_hooklike_noncanonical=is_hooklike_noncanonical, has_canonical_hook=has_canonical_hook)
    return audit


def collect_hook_wiring(repo_root: Path) -> dict[str, object]:
    hook_dir = repo_root / NPC_RUNTIME_DIR
    details: dict[str, dict[str, object]] = {}
    canonical_present = 0

    for hook in sorted(CANONICAL_HOOKS):
        file_path = hook_dir / f"{hook}.nss"
        exists = file_path.exists()
        includes_core = False
        if exists:
            text = file_path.read_text(encoding="utf-8", errors="ignore")
            includes_core = '#include "npc_core"' in text
            canonical_present += 1
        details[hook] = {
            "path": str(file_path.relative_to(repo_root)),
            "exists": exists,
            "includes_npc_core": includes_core,
            "status": "ok" if exists and includes_core else "drift",
        }

    noncanonical_hooklike: list[str] = []
    if hook_dir.exists():
        for candidate in hook_dir.glob("*.nss"):
            stem = candidate.stem.lower()
            if any(token in stem for token in HOOK_TOKENS) and stem not in CANONICAL_HOOKS:
                noncanonical_hooklike.append(str(candidate.relative_to(repo_root)))

    return {
        "canonical_contract_path": str(CANONICAL_CONTRACT_PATH),
        "canonical_contract_exists": (repo_root / CANONICAL_CONTRACT_PATH).exists(),
        "canonical_hooks_expected": len(CANONICAL_HOOKS),
        "canonical_hooks_present": canonical_present,
        "canonical_hooks": details,
        "noncanonical_hooklike_in_npc_runtime": sorted(noncanonical_hooklike),
    }


def render_markdown(summary: dict[str, object]) -> str:
    lines: list[str] = []
    lines.append("# Ambient Life V3 Rollout Readiness Report")
    lines.append("")
    lines.append(f"Scanned files: **{summary['scanned_files']}**")
    lines.append("")

    tiers: dict[str, int] = summary["tier_counts"]
    lines.append("## Readiness tiers")
    for tier in ("READY", "BRIDGEABLE", "FALLBACK-RISK", "MANUAL", "CONFLICTED"):
        lines.append(f"- **{tier}**: {tiers.get(tier, 0)}")
    lines.append("")

    lines.append("## Legacy bridge coverage")
    coverage = summary["legacy_coverage"]
    lines.append(f"- Supported `al_*` usages: {coverage['supported_total']}")
    lines.append(f"- Ambiguous `al_*` usages: {coverage['ambiguous_total']}")
    lines.append(f"- Unsupported `al_*` usages: {coverage['unsupported_total']}")
    if coverage["unsupported_keys"]:
        lines.append("- Unsupported keys:")
        for key, count in sorted(coverage["unsupported_keys"].items()):
            lines.append(f"  - `{key}` × {count}")
    lines.append("")

    lines.append("## Hook wiring vs canonical contract")
    hw = summary["hook_wiring"]
    lines.append(f"- Canonical contract exists: **{hw['canonical_contract_exists']}** (`{hw['canonical_contract_path']}`)")
    lines.append(f"- Canonical hooks present: **{hw['canonical_hooks_present']}/{hw['canonical_hooks_expected']}**")
    drift = [name for name, info in hw["canonical_hooks"].items() if info["status"] != "ok"]
    lines.append(f"- Hook drift count: **{len(drift)}**")
    if hw["noncanonical_hooklike_in_npc_runtime"]:
        lines.append("- Noncanonical hook-like scripts in npc runtime:")
        for item in hw["noncanonical_hooklike_in_npc_runtime"]:
            lines.append(f"  - `{item}`")
    lines.append("")

    lines.append("## Top files requiring attention")
    risky = [r for r in summary["files"] if r["tier"] in {"CONFLICTED", "MANUAL", "FALLBACK-RISK"}]
    if not risky:
        lines.append("- none")
    else:
        for row in risky[:30]:
            reason = "; ".join(row["reasons"])
            lines.append(f"- `{row['path']}` → **{row['tier']}** ({reason})")
    lines.append("")

    lines.append("## Controlled fallback expectations")
    fallback_candidates = [r for r in summary["files"] if r["tier"] == "FALLBACK-RISK"]
    lines.append(f"- Files with fallback risk: {len(fallback_candidates)}")
    for row in fallback_candidates[:20]:
        lines.append(f"  - `{row['path']}`")
    lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit rollout readiness for Ambient Life V3")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--scan", action="append", default=None, help="Path(s) relative to repo root to scan")
    parser.add_argument("--json-out", type=Path, default=Path("docs/reports/npc_rollout_readiness_report.json"))
    parser.add_argument("--md-out", type=Path, default=Path("docs/reports/npc_rollout_readiness_report.md"))
    parser.add_argument("--fail-on-manual", action="store_true", help="Exit non-zero when MANUAL/CONFLICTED files exist")
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    scan_inputs = args.scan or ["src"]
    scan_roots = [repo_root / item for item in dict.fromkeys(scan_inputs)]
    files = find_nss_files(scan_roots)

    audits = [analyze_file(path, repo_root) for path in files]
    tier_counts = Counter(a.tier for a in audits)

    legacy_supported = Counter()
    legacy_ambiguous = Counter()
    legacy_unsupported = Counter()
    for audit in audits:
        legacy_supported.update(audit.legacy_supported)
        legacy_ambiguous.update(audit.legacy_ambiguous)
        legacy_unsupported.update(audit.legacy_unsupported)

    files_payload = []
    for audit in audits:
        files_payload.append(
            {
                "path": str(audit.path),
                "tier": audit.tier,
                "canonical_keys": len(audit.canonical_keys),
                "legacy_supported": sorted(audit.legacy_supported),
                "legacy_ambiguous": sorted(audit.legacy_ambiguous),
                "legacy_unsupported": sorted(audit.legacy_unsupported),
                "vanilla_hook_refs": sorted(audit.vanilla_hook_refs),
                "reasons": audit.reasons,
            }
        )

    hook_wiring = collect_hook_wiring(repo_root)

    summary: dict[str, object] = {
        "scanned_files": len(files),
        "scan_roots": [str(path.relative_to(repo_root)) for path in scan_roots],
        "tier_counts": dict(tier_counts),
        "legacy_coverage": {
            "supported_total": sum(legacy_supported.values()),
            "ambiguous_total": sum(legacy_ambiguous.values()),
            "unsupported_total": sum(legacy_unsupported.values()),
            "supported_keys": dict(legacy_supported),
            "ambiguous_keys": dict(legacy_ambiguous),
            "unsupported_keys": dict(legacy_unsupported),
        },
        "hook_wiring": hook_wiring,
        "files": sorted(files_payload, key=lambda r: (r["tier"], r["path"])),
    }

    json_path = repo_root / args.json_out
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    md_path = repo_root / args.md_out
    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text(render_markdown(summary) + "\n", encoding="utf-8")

    print(f"[OK] readiness audit written: {json_path.relative_to(repo_root)}")
    print(f"[OK] readiness report written: {md_path.relative_to(repo_root)}")
    print(f"[OK] tiers: {dict(tier_counts)}")

    if args.fail_on_manual and (tier_counts.get("MANUAL", 0) > 0 or tier_counts.get("CONFLICTED", 0) > 0):
        print("[FAIL] MANUAL or CONFLICTED findings detected")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
