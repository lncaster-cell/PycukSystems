# NPC Bhvr Implementation Backlog

Документ фиксирует **исполняемый** бэклог для старта третьего итогового модуля поведения NPC в active-контуре `src/modules/npc/*` с переносом нужных решений из legacy/reference `tools/*`.

---

## Source of truth

- Active runtime-контур: `src/modules/npc/` (единственный source of truth для исполнения и backlog).
- Legacy/reference источники для точечной миграции: `tools/npc_behavior_system/`, `tools/al_system/`.
- Стратегическая матрица решений для NPC Bhvr: `docs/npc_al_vs_npc_behavior_matrix.md`.

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
- [ ] Подготовлен perf-gate документ и фикстуры.
- [ ] Автоматизирован fairness/lifecycle self-check.
- [ ] Обновлены ссылки в README и рабочих чеклистах на актуальные пути runtime.


---

## Phase D — Legacy cleanup (`tools/*`)

### Task D1 — Cleanup readiness gate
- **Артефакты:**
  - `docs/npc_toolset_cleanup_report.md`
  - `docs/npc_toolset_post_cleanup_validation.md`
- **Definition of Done:**
  - подтверждено отсутствие runtime hooks/include-зависимостей active-контура на `tools/*`;
  - execution backlog не содержит открытых задач, требующих исполнения legacy-кода;
  - parity/perf проверки пройдены относительно baseline на `src/modules/npc/*`.

### Task D2 — Удаление legacy-каталогов
- **Артефакты:**
  - PR(ы) на удаление `tools/al_system/*`, `tools/npc_behavior_system/*` (или их части)
  - migration notes в `docs/`
- **Definition of Done:**
  - удаляются только каталоги, для которых есть зафиксированная миграционная заметка (перенесено/отброшено);
  - после удаления проходят контрактные проверки и perf-gate;
  - в README остаётся однозначный статус: `tools/*` не active runtime.
