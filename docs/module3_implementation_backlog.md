# Module 3 Implementation Backlog

Документ фиксирует **исполняемый** бэклог для старта третьего итогового модуля поведения NPC, который собирает лучшие runtime-паттерны из `tools/npc_behavior_system` и контентные примитивы из `tools/al_system`.

---

## Source of truth

- Runtime-контур текущей системы NPC: `tools/npc_behavior_system/`.
- AL-материалы и activity-примитивы: `tools/al_system/`.
- Стратегическая матрица решений для Module 3: `docs/module3_al_vs_npc_behavior_matrix.md`.

---

## Phase A — Runtime Core (обязательно до feature-разработки)

### Task A1 — Скелет Module 3 в `tools/`
- **Артефакты:**
  - `src/modules/module3_behavior/module3_core.nss`
  - `src/modules/module3_behavior/module3_metrics_inc.nss`
  - `src/modules/module3_behavior/module3_activity_inc.nss`
  - `src/modules/module3_behavior/README.md`
- **Definition of Done:**
  - директория и базовые include-файлы добавлены;
  - README фиксирует thin-entrypoint правило;
  - namespace/ключи locals отделены от `npc_behavior` и `al_`.

### Task A2 — Area lifecycle контракт
- **Артефакты:**
  - функции lifecycle в `module3_core.nss` (`RUNNING/PAUSED/STOPPED`);
  - совместимый контракт auto-start/idle-stop.
- **Definition of Done:**
  - lifecycle переходы покрывают startup, pause, resume, stop;
  - area-loop один на область;
  - pause/resume не ломает очередь и pending counters.

### Task A3 — Priority queue и guardrails
- **Артефакты:**
  - bounded queue + приоритеты `CRITICAL/HIGH/NORMAL/LOW` в `module3_core.nss`.
- **Definition of Done:**
  - overflow guardrails реализованы;
  - starvation-window контролируется метриками;
  - CRITICAL события имеют гарантированный bypass-path.

---

## Phase B — Activity Layer (адаптация лучшего из AL)

### Task B1 — Порт activity primitives
- **Артефакты:**
  - `module3_activity_inc.nss` с адаптированными AL activity primitives.
- **Definition of Done:**
  - поддержаны slot activities/route-driven activity;
  - нет прямого копирования legacy keyspace (`al_*`) в runtime API;
  - есть адаптерная прослойка для маршрутов и ограничений активностей.

### Task B2 — Dense area-registry helper (опционально, но рекомендовано)
- **Артефакты:**
  - helper API для плотного реестра NPC на область.
- **Definition of Done:**
  - swap-remove compaction при невалидных ссылках;
  - массовые сигналы/broadcast выполняются без tag-search;
  - переполнение реестра диагностируется метрикой/логом.

---

## Phase C — Metrics, tests, perf-gate

### Task C1 — Единый metrics API
- **Артефакты:**
  - `module3_metrics_inc.nss`.
- **Definition of Done:**
  - handlers не пишут `SetLocalInt` напрямую в entrypoints;
  - инкременты/агрегация идут через единый helper API;
  - ключи метрик документированы в README Module 3.

### Task C2 — Perf-plan и baseline
- **Артефакты:**
  - `docs/perf/module3_perf_gate.md`
  - `docs/perf/fixtures/module3/*`
- **Definition of Done:**
  - формализованы pass/fail пороги;
  - есть минимум 4 сценария (steady/burst/pause-resume stress + tick-budget degraded-mode);
  - tick-budget сценарий проверяет `module3_tick_max_events`, `module3_tick_soft_budget_ms`, `tick_budget_exceeded_total`, `degraded_mode_total`, `processed_total`, `pending_age_ms`;
  - baseline зафиксирован и не старше 14 дней для сравнения.

### Task C3 — Автоматизированные fairness/lifecycle проверки
- **Артефакты:**
  - `scripts/test_module3_fairness.sh`
  - (опционально) универсальный `scripts/check_lifecycle_contract.sh`.
- **Definition of Done:**
  - starvation/pause-zero/post-resume drain проверки запускаются в один шаг;
  - check возвращает non-zero при нарушении контракта;
  - тестовые команды задокументированы в README Module 3.

---

## Release readiness checklist для старта разработки

- [ ] Создан базовый runtime-каркас Module 3 в `src/modules/module3_behavior/`.
- [ ] Зафиксированы lifecycle/queue/metrics контракты.
- [ ] Подготовлен perf-gate документ и фикстуры.
- [ ] Автоматизирован fairness/lifecycle self-check.
- [ ] Обновлены ссылки в README и рабочих чеклистах на актуальные пути runtime.
