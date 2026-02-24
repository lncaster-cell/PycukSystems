# NPC baseline reports archive

В этой директории хранятся исторические baseline-отчёты и агрегированные итоги perf-gate.

## Что хранится в Git

- Агрегированные человекочитаемые отчёты:
  - `docs/perf/reports/*_npc_gate_report.md`
  - `docs/perf/reports/npc_gate_summary_latest.md`
  - исторические baseline-отчёты формата `YYYY-MM-DD_*`
- Это **архив-источник для чтения и аудита трендов** (human-readable source of truth).

## Что не хранится в Git (generated output)

- Сырые замеры и служебные machine-readable артефакты:
  - `raw/run_*.csv`
  - `gate_summary.json`
  - `gate_summary.csv`
- Generated-деревья вида `docs/perf/reports/*_artifacts/` исключены из Git и должны публиковаться:
  - либо в `benchmarks/npc_baseline/results/` (локально),
  - либо как CI artifacts.

## Current vs archive

- **Current baseline**: только `docs/perf/npc_baseline_report.md` (reference-point для perf-gate).
- **Archive baseline**: `docs/perf/reports/*` (исторические отчёты для трендов).
- При обновлении current baseline предыдущая версия переносится в архив с датой.
