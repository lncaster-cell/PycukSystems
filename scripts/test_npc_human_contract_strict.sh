#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTHORING_DOC="$ROOT_DIR/docs/npc_toolset_authoring_contract.md"
RUNTIME_DOC="$ROOT_DIR/docs/npc_runtime_internal_contract.md"
README_DOC="$ROOT_DIR/src/modules/npc/README.md"

python3 - "$AUTHORING_DOC" "$RUNTIME_DOC" "$README_DOC" <<'PY'
import re
import sys
from pathlib import Path

authoring = Path(sys.argv[1]).read_text(encoding='utf-8')
runtime = Path(sys.argv[2]).read_text(encoding='utf-8')
readme = Path(sys.argv[3]).read_text(encoding='utf-8')
errors = []

required_authoring_keys = [
    'npc_cfg_role',
    'npc_cfg_identity_type',
    'npc_cfg_slot_dawn_route',
    'npc_cfg_slot_morning_route',
    'npc_cfg_slot_afternoon_route',
    'npc_cfg_slot_evening_route',
    'npc_cfg_slot_night_route',
    'npc_cfg_force_reactive',
    'npc_cfg_allow_physical_hide',
    'npc_cfg_alert_route',
]

for key in required_authoring_keys:
    if key not in authoring:
        errors.append(f"authoring contract missing canonical key: {key}")

required_authoring_guards = [
    'Строгие границы канонического пути (anti-drift)',
    'не является',
    'default|priority|critical',
    'npc_cfg_schedule',
    'compatibility-only / deprecated / migration-only',
    'respawn intentionally deferred',
    'role` отвечает за archetype поведения',
]
for marker in required_authoring_guards:
    if marker not in authoring:
        errors.append(f"authoring contract missing strict guard marker: {marker}")

if '## 0) Scope boundary (strict)' not in runtime:
    errors.append('runtime contract missing strict scope boundary section')
if 'не primary authoring path' not in runtime:
    errors.append('runtime contract must explicitly state non-user-facing runtime knobs')

if '### Канонический human-facing путь (strict)' not in readme:
    errors.append('README missing strict human-facing section')
if 'npc_cfg_schedule' not in readme or 'не являются primary authoring path' not in readme:
    errors.append('README must mark schedule/legacy/runtime knobs as non-primary')

if errors:
    print('[FAIL] strict human-facing contract checks failed')
    for e in errors:
        print(' -', e)
    raise SystemExit(1)

print('[OK] strict human-facing contract checks passed')
PY
