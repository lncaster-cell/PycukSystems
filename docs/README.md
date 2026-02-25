# Документация PycukSystems

Этот индекс фиксирует **актуальную структуру документации** и разделяет рабочие документы на:
- **активные** (используются в текущем цикле разработки и тестирования);
- **справочные** (архитектурный/долгоживущий контекст);
- **отчёты/артефакты** (генерируемые файлы).

## 1) Активные документы (основной контур)

- `docs/npc_implementation_backlog.md` — исполняемый backlog по NPC runtime.
- `docs/npc_runtime_orchestration.md` — runtime/lifecycle контракт.
- `docs/npc_activity_contract_checklist.md` — инварианты activity-layer и проверки.
- `docs/testing_contracts.md` — контракты и команды тестовых прогонов.
- `docs/npc_behavior_audit.md` — полный аудит поведения NPC.
- `docs/npc_persistence.md` — хранение состояния NPC (SQLite/NWNX).
- `docs/perf/npc_perf_plan.md` — perf-план и сценарии baseline.
- `docs/perf/npc_perf_gate.md` — правила perf-gate и формат verdict.
- `docs/perf/npc_baseline_report.md` — текущая baseline reference-point.

## 2) Операционный rollout-контур

Документы ниже используются для миграций/rollout-процесса и launch-checkpoint:

- `docs/npc_rollout_readiness_checklist.md`
- `docs/npc_batch_migration_execution.md`
- `docs/npc_manual_remediation_governance.md`
- `docs/npc_go_live_checklist.md`
- `docs/npc_pilot_rollout_runbook.md`
- `docs/npc_phase1_test_checklist.md`
- `docs/npc_toolset_authoring_contract.md`

## 3) Справочные документы

- `docs/design.md` — платформенный дизайн-документ.
- `docs/module_contract.md` — общий контракт модульного runtime.
- `docs/compile_bugscan_contract.md` — контракт compile/bugscan пайплайна.
- `docs/area_cluster_streaming_strategy.md` — стратегия area-cluster/streaming.
- `docs/dead_code_audit.md` — актуальный аудит dead code.

## 4) Отчёты и автогенерируемые артефакты

- `docs/reports/*` — JSON/Markdown отчёты readiness/execution/backlog/launch.
- `docs/perf/reports/*` — perf/gate исторические отчёты и latest summary.
- `docs/perf/fixtures/*` — фикстуры для perf/fairness анализаторов.

## 5) Что удалено как устаревшее

- Удалён дублирующий файл `docs/dead_code_audit_2026-02-24.md`.
- Удалены устаревшие отчёты next-batch: `docs/reports/npc_next_batch_outcome_report.md` и `docs/reports/npc_next_batch_outcome_report.json`.
- Источник истины для dead-code проверки: `docs/dead_code_audit.md`.
