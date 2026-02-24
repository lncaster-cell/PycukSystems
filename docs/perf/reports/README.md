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

## Публикация baseline (обязательный SHA)

1. Перед публикацией baseline зафиксируйте commit и получите SHA из Git:
   - `git rev-parse --short HEAD`
   - `git rev-parse HEAD`
2. В `docs/perf/npc_baseline_report.md` поле `Commit SHA` обязательно и должно содержать реальные значения short/full SHA.
3. Псевдозначения (`WORKTREE`, `N/A`, `UNKNOWN`, `TBD`) запрещены для current baseline и archive baseline.
4. Для минимизации ручных ошибок используйте `scripts/run_npc_bench.sh`: скрипт автоматически подставляет SHA в baseline-отчёт, если находит псевдозначение.

## Правило синхронизации статус-блоков при обновлении baseline

При любом обновлении `docs/perf/npc_baseline_report.md` обязательно в том же PR синхронизируйте status-блоки:
- `docs/design.md` (раздел `7.4`, checklist `Perf-gate пороги не нарушены относительно baseline`),
- `src/modules/npc/README.md` (раздел `Current readiness snapshot`, пункт `Perf baseline/perf-gate`).

Source-of-truth для финального gate-статуса: `docs/perf/npc_baseline_report.md` (раздел `6. Вывод (go/no-go)`) + latest gate report (`docs/perf/reports/*_npc_gate_report.md` или `docs/perf/reports/npc_gate_summary_latest.md`).

Статическая проверка контракта: `bash scripts/check_npc_perf_status_contract.sh` — скрипт должен проходить перед merge и падать при расхождении baseline vs design checklist.
