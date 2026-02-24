# NPC Bhvr Implementation Backlog

Документ фиксирует **исполняемый** бэклог для развития текущего модуля поведения NPC в active-контуре `src/modules/npc/*`.

---

## Текущий статус (обновлено: 2026-02-24)

- Runtime foundation в `src/modules/npc/*`: **READY** (core lifecycle/queue/activity/metrics + thin-entrypoints).
- Contract/self-check suite: **READY** (`scripts/test_npc_smoke.sh`, `scripts/check_npc_lifecycle_contract.sh`, `scripts/test_npc_fairness.sh`).
- Schedule-aware activity foundation: **READY/DONE** (runtime-resolve slot по расписанию + e2e shell-check покрытие `npc_activity_slot`, `npc_activity_route_effective`, `npc_activity_last_ts`, включено в one-command smoke/contract поток через `scripts/test_npc_activity_contract.sh` и `scripts/test_npc_smoke.sh`).
- Legacy cleanup milestone `tools/*`: **COMPLETED** (архив в `docs/legacy/tools_reference/*`).
- Perf/release gate: **FAIL** (baseline свежий, но gate в статусе **NO-GO/FAIL** из-за провала `tick-budget-degraded`).
- Source of truth для статуса gate: `docs/perf/reports/npc_gate_summary_latest.md`, `docs/perf/npc_baseline_report.md`.

---

## Source of truth

- Active runtime-контур: `src/modules/npc/` (единственный source of truth для исполнения и backlog).

---

## Phase A — Runtime Core (обязательно до feature-разработки)

### Task A1 — Скелет NPC Bhvr в `src/modules/npc/`
- **Артефакты:**
  - `src/modules/npc/npc_core.nss`
  - `src/modules/npc/npc_metrics_inc.nss`
  - `src/modules/npc/npc_activity_inc.nss`
  - `src/modules/npc/README.md`
- **Definition of Done:**
  - директория и базовые include-файлы добавлены;
  - README фиксирует thin-entrypoint правило;
  - namespace/ключи locals отделены от `npc_behavior` и `al_`.

### Task A2 — Area lifecycle контракт
- **Артефакты:**
  - функции lifecycle в `npc_core.nss` (`RUNNING/PAUSED/STOPPED`);
  - совместимый контракт auto-start/idle-stop.
- **Definition of Done:**
  - lifecycle переходы покрывают startup, pause, resume, stop;
  - area-loop один на область;
  - pause/resume не ломает очередь и pending counters.

### Task A3 — Priority queue и guardrails
- **Артефакты:**
  - bounded queue + приоритеты `CRITICAL/HIGH/NORMAL/LOW` в `npc_core.nss`.
- **Definition of Done:**
  - overflow guardrails реализованы;
  - starvation-window контролируется метриками;
  - CRITICAL события имеют гарантированный bypass-path.

---

## Phase B — Activity Layer (адаптация лучшего из AL)

- Контрактные инварианты и шаги валидации: `docs/npc_activity_contract_checklist.md`.

### Task B1 — Порт activity primitives
- **Артефакты:**
  - `npc_activity_inc.nss` с адаптированными AL activity primitives.
- **Definition of Done:**
  - поддержаны slot activities/route-driven activity;
  - нет прямого копирования legacy keyspace (`al_*`) в runtime API;
  - есть адаптерная прослойка для маршрутов и ограничений активностей.

### Task B2 — Dense area-registry helper (выполнено)
- **Артефакты:**
  - helper API для плотного реестра NPC на область в `npc_core.nss` (`NpcBhvrRegistryInsert/Remove/BroadcastIdleTick`).
  - метрики `npc_metric_registry_overflow_total` и `npc_metric_registry_reject_total` в `npc_metrics_inc.nss`.
- **Definition of Done:**
  - swap-remove compaction при remove/prune реализован;
  - массовый обход registry выполняется через `NpcBhvrRegistryBroadcastIdleTick` без tag-search;
  - переполнение и reject-path диагностируются отдельными метриками.

---

## Phase C — Metrics, tests, perf-gate

### Task C1 — Единый metrics API
- **Артефакты:**
  - `npc_metrics_inc.nss`.
- **Definition of Done:**
  - handlers не пишут `SetLocalInt` напрямую в entrypoints;
  - инкременты/агрегация идут через единый helper API;
  - ключи метрик документированы в README NPC Bhvr.

### Task C2 — Perf-plan и baseline
- **Артефакты:**
  - `docs/perf/npc_perf_gate.md`
  - `docs/perf/fixtures/npc/*`
- **Definition of Done:**
  - формализованы pass/fail пороги;
  - есть минимум 4 сценария (steady/burst/pause-resume stress + tick-budget degraded-mode);
  - tick-budget сценарий проверяет `npc_tick_max_events` (max events per tick), `npc_tick_soft_budget_ms` (soft tick budget), детерминированный tail-carryover между тиками, `tick_budget_exceeded_total`, `degraded_mode_total`, `processed_total`, `pending_age_ms`;
  - baseline зафиксирован и не старше 14 дней для сравнения.

### Task C3 — Автоматизированные fairness/lifecycle проверки
- **Артефакты:**
  - `scripts/test_npc_fairness.sh`
  - (опционально) универсальный `scripts/check_lifecycle_contract.sh`.
- **Definition of Done:**
  - starvation/pause-zero/post-resume drain проверки запускаются в один шаг;
  - check возвращает non-zero при нарушении контракта;
  - тестовые команды задокументированы в README NPC Bhvr.

---

## Release readiness checklist для старта разработки

- [x] Создан базовый runtime-каркас NPC Bhvr в `src/modules/npc/`.
- [x] Зафиксированы lifecycle/queue/metrics контракты.
- [x] Подготовлен perf-gate документ и фикстуры.
- [x] Автоматизирован fairness/lifecycle self-check.
- [x] Обновлены ссылки в README и рабочих чеклистах на актуальные пути runtime.
  - Артефакты: `src/modules/npc/README.md` (секция **Canonical runtime references**), `docs/npc_phase1_test_checklist.md` (раздел **Canonical runtime references**).

_Примечание: perf-gate (`docs/perf/npc_perf_gate.md`), фикстуры `docs/perf/fixtures/npc/*` и
fairness/lifecycle self-check (`scripts/test_npc_fairness.sh`, `scripts/check_*lifecycle_contract.sh`) готовы,
чеклисты обновлены под canonical paths; legacy-пути сохранены только в исторических отчётах._


---
