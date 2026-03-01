# NPC Runtime Orchestration

Документ фиксирует **актуальный runtime-контракт** оркестрации NPC на текущей реализации в `src/modules/npc/`.

## 1. Архитектурный контур

- Area-local lifecycle controller (`RUNNING/PAUSED/STOPPED`).
- Bounded priority queue (`CRITICAL/HIGH/NORMAL/LOW`).
- Budgeted tick pipeline (event budget + soft time budget).
- Registry-based idle fan-out для фонового поведения NPC.
- Maintenance watchdog для reconcile/compaction вне hot-path.

## 2. Lifecycle области

### Состояния

- `RUNNING` — рабочий тиковый цикл (интервал 1s), queue drain, activity dispatch, write-behind flush.
- `PAUSED` — редкий watchdog-тик (30s), состояние/метрики сохраняются.
- `STOPPED` — таймеры сняты, queue/registry очищены, область деактивирована.

### Переходы

- `Activate`:
  - применение runtime-budget конфигов (`area cfg -> module cfg -> defaults`),
  - warmup route cache,
  - запуск `npc_area_tick` и `npc_area_maintenance`.
- `Pause`:
  - перевод в `PAUSED`,
  - запуск maintenance watchdog.
- `Stop`:
  - maintenance pass,
  - state=`STOPPED`,
  - сброс maintenance/tick flags,
  - invalidate route cache,
  - reset idle cursor,
  - clear queue.

## 3. Тиковая оркестрация (`npc_area_tick`)

В `RUNNING` применяется pipeline:

1. `Idle gate`: idle fan-out запускается только если `queue_pending_total <= 0`.
2. `Budget prepare`: нормализация `tick_max_events`, `tick_soft_budget_ms`, `carryover`.
3. `ProcessBudgetedWork`: dequeue/dispatch до исчерпания бюджетов.
4. `ApplyDegradationAndCarryover`: фиксация degraded reason + carryover при pressure.
5. `ReconcileDeferredAndTrim`: deferred reconcile и trim overflow.
6. `Telemetry/flush/idle-stop`: метрики, write-behind flush, auto-stop при пустой очереди и отсутствии игроков.

В `PAUSED` тикается watchdog, в `STOPPED` loop-флаг снимается.

## 4. Очередь, коалесc и fairness

### Queue

- Capacity: `NPC_BHVR_QUEUE_MAX = 64`.
- Duplicate enqueue не создаёт второй элемент: выполняется coalesce.
- При coalesce приоритет пересчитывается через escalation.
- Для `damage` действует форс-эскалация до `CRITICAL`.

### Overflow guardrails

- Для non-critical входящих событий возможен controlled drop хвоста низшего bucket.
- Для критичных сигналов применяется более строгий путь (без обычного non-critical вытеснения).

### Fairness

- `CRITICAL` обрабатывается первым.
- `HIGH/NORMAL/LOW` обслуживаются по cursor rotation.
- Starvation guard (`streak limit`) принудительно ротацирует курсор при длительной серии.

## 5. Registry и idle-поведение

- Registry хранит валидных NPC области (slot/index).
- Budgeted idle broadcast обходит registry по курсору.
- При queue pressure idle broadcast отключается на текущий тик.
- Maintenance периодически compact-ит invalid registry entries.

## 6. Activity runtime

`NpcBhvrActivityOnIdleTick` — единая точка применения игрового поведения NPC:

- slot/route resolution,
- schedule-aware выбор слота,
- waypoint progression и loop-policy,
- cooldown и last-transition timestamps,
- action/emote/activity_id для внешней интеграции команд поведения.

Валидаторы route/tag ограничивают допустимые значения и включают deterministic fallback (`default_route`, `default`) при нарушении.

## 7. Maintenance watchdog (`npc_area_maintenance`)

Периодические задачи:

- reconcile `deferred_total`,
- compact invalid registry entries,
- self-heal консистентности area-local runtime состояния.

Вынесено из hot-path для снижения стоимости рабочего тика.

## 8. Наблюдаемость и деградация

Система фиксирует:

- processed/pending/deferred/dropped,
- queue overflow/coalesce/fairness guard,
- tick budget exceeded/degraded mode,
- last degradation reason,
- idle throttling/idle skipped under pressure,
- paused watchdog ticks.

Это позволяет эксплуатировать модуль как наблюдаемый production runtime-контур, а не как «чёрный ящик».

## 9. Связанный полный аудит

Для подробной карты «механизм → где используется в игре» и развёрнутого описания всех подсистем см.:

- `docs/npc_behavior_audit.md`;
- `docs/npc_behavior_setup_faq.md` (практическая настройка и FAQ).

