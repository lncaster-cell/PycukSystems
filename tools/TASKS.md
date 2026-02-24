# Tasks

## NPC Bhvr Preparation (execution backlog)

### Phase A — Runtime foundation
- [x] A1. Создать `src/modules/npc/` и базовые файлы (`npc_core.nss`, `npc_metrics_inc.nss`, `npc_activity_inc.nss`, `README.md`).
  - **DoD:** есть thin-entrypoint контракт, namespace изолирован от `npc_behavior`/`al_`.
- [x] A2. Реализовать lifecycle `RUNNING/PAUSED/STOPPED` + auto-start/idle-stop.
  - **DoD:** pause/resume/stop не ломают queue depth и pending counters.
- [x] A3. Реализовать bounded queue и приоритеты (`CRITICAL/HIGH/NORMAL/LOW`) с overflow guardrails.
  - **DoD:** есть starvation guard и CRITICAL bypass.

### Phase B — AL activity adaptation
- [x] B1. Портировать AL activity primitives в `npc_activity_inc.nss` через адаптеры.
  - **DoD:** slot/route активности работают без legacy keyspace drift.
- [x] B2. Добавить dense area-registry helper (swap-remove, массовые сигналы).
  - **DoD:** insert/remove + swap-remove compaction реализованы, overflow/reject диагностируются метриками `npc_metric_registry_overflow_total` и `npc_metric_registry_reject_total`.

### Phase C — Metrics and perf gate
- [x] C1. Ввести единый metrics API (`npc_metrics_inc.nss`).
  - **DoD:** entrypoints не используют прямые `SetLocalInt` для метрик.
- [x] C2. Подготовить `docs/perf/npc_perf_gate.md` + фикстуры `docs/perf/fixtures/npc/`.
  - **DoD:** минимум 3 сценария и формальные pass/fail пороги.
- [x] C3. Добавить `scripts/test_npc_fairness.sh` и подключить starvation/pause-zero/post-resume проверки.
  - **DoD:** один скрипт self-check с non-zero при нарушениях.

### Dependencies / order
1. Сначала A1-A3 (runtime контракт).
2. Затем B1-B2 (activity слой).
3. После этого C1-C3 (метрики + perf-gate).
