# NPC Bhvr behavior runtime contour (skeleton)

Каталог содержит официальный подготовительный runtime-контур для NPC Bhvr.

## Статус runtime foundation (Phase A)

- Реализован lifecycle area-controller: `RUNNING/PAUSED/STOPPED`.
- Добавлены auto-start и auto-idle-stop механики area-loop.
- RUNNING loop рескейджулится только в состоянии `RUNNING`; в `PAUSED` используется отдельный редкий watchdog-тик (`30s`) с отдельной метрикой.
- Реализована bounded queue (`NPC_BHVR_QUEUE_MAX=64`) с bucket-приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Включён starvation guard для неблокирующей ротации non-critical bucket-очередей.
- CRITICAL события обрабатываются через bypass fairness-бюджета.
- `npc_pending_updated_at` хранится как `int`-timestamp с секундной точностью (на базе календарного дня и `HH:MM:SS`) и при частых обновлениях монотонно увеличивается минимум на 1.

## Базовые include-файлы

- `npc_core.nss` — lifecycle area-controller, bounded queue с приоритетами, routing хуков в core.
- `npc_activity_inc.nss` — контентные activity-primitives (адаптерный слой для будущего порта из AL).
- `npc_metrics_inc.nss` — единый helper API для метрик (`NpcBhvrMetricInc/Add`).

Tick/degraded telemetry в runtime включает:
- `npc_metric_processed_total` (обработанные события за тик без двойного инкремента),
- `npc_metric_tick_budget_exceeded_total`, `npc_metric_degraded_mode_total`,
- `npc_metric_degradation_events_total`,
- reason-specific: `npc_metric_degradation_by_reason_event_budget_total`, `npc_metric_degradation_by_reason_soft_budget_total`, `npc_metric_degradation_by_reason_empty_queue_total`,
- `npc_metric_diagnostic_dropped_total` для нераспознанных reason-code.


## Activity primitives runtime-контракт

`npc_activity_inc.nss` теперь фиксирует минимальный runtime-layer поверх AL-подхода через `npc_*` keyspace (без прямого использования `al_*` locals в core-flow):

- AL-понятия (`slot-group`, `route-profile`, `activity transition`) обязаны проходить через adapter-helpers include-файла:
  - `NpcBhvrActivityAdapterNormalizeSlot`,
  - `NpcBhvrActivityAdapterNormalizeRoute`,
  - `NpcBhvrActivityMapRouteHint`,
  - `NpcBhvrActivityResolveRouteProfile`,
  - `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty`,
  - `NpcBhvrActivityAdapterStampTransition`.

- Spawn-инициализация профиля NPC (`NpcBhvrActivityOnSpawn`) обязана выставлять:
  - `npc_activity_slot` (по умолчанию `default`),
  - `npc_activity_route` (явно сконфигурированный route-profile на NPC; если пусто — используется fallback-цепочка),
  - `npc_activity_route_effective` (диагностическое зеркало effective route-profile после fallback-резолва),
  - `npc_activity_state` (начальное состояние `spawn_ready`),
  - `npc_activity_cooldown` (неотрицательный cooldown/state gate),
  - `npc_activity_last` (последняя activity transition),
  - `npc_activity_last_ts` (timestamp последнего transition в секундах игрового времени).
- Резолв route-profile (`NpcBhvrActivityResolveRouteProfile`) выполняется по цепочке fallback без `al_*` keyspace:
  1) `npc_activity_route` на NPC (если явно задан);
  2) `npc_route_profile_slot_<slot>` на NPC;
  3) `npc_route_profile_default` на NPC;
  4) `npc_route_profile_slot_<slot>` на area;
  5) `npc_route_profile_default` на area;
  6) `default_route`.
- `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty` отбрасывает невалидные route-id (не входящие в `default_route|priority_patrol|critical_safe`), чтобы fallback-цепочка не блокировалась мусорными значениями.
- Idle-dispatch (`NpcBhvrActivityOnIdleTick`) работает как адаптерный диспетчер `slot/route`:
  - CRITICAL-safe ветка (приоритет №1): `slot=critical` **или** route-map -> `critical_safe`;
  - priority-ветка (приоритет №2): `slot=priority` **или** route-map -> `priority_patrol`;
  - fallback: `default_route` c состоянием `idle_default`.
- Mapping-слой (`NpcBhvrActivityMapRouteHint`) выполняет трансляцию route-id -> activity hint, чтобы AL-семантика подключалась через адаптер, а не через прямой `al_*` namespace.
- Примитивы `NpcBhvrActivityApplyCriticalSafeRoute/NpcBhvrActivityApplyPriorityRoute/NpcBhvrActivityApplyDefaultRoute` задают только минимальные state/cooldown эффекты и могут расширяться в следующих фазах без изменения контракта entrypoint/core.

### Контракт входных/выходных состояний activity primitives

- **Вход для `NpcBhvrActivityOnSpawn`:** валидный `oNpc`; любые/пустые значения `npc_activity_slot|route`; опциональные route-profile fallback locals `npc_route_profile_slot_<slot>` и `npc_route_profile_default` на NPC/area; `npc_activity_cooldown` может быть отрицательным.
- **Выход `NpcBhvrActivityOnSpawn`:**
  - `slot` нормализован в поддерживаемые значения (`default|priority|critical`),
  - `npc_activity_route` сохраняет только явно заданный route (или очищается, если route не задан),
  - `npc_activity_route_effective` выставляется как effective route-profile (`default_route|priority_patrol|critical_safe`) после fallback-резолва,
  - `state=spawn_ready`,
  - `last=spawn_ready`,
  - `last_ts` обновлён,
  - `cooldown >= 0`.
- **Вход для `NpcBhvrActivityOnIdleTick`:** валидный `oNpc`; допускаются пустые/невалидные `slot/route` (slot нормализуется, невалидный route отбрасывается и заменяется fallback-резолвом).
- **Выход `NpcBhvrActivityOnIdleTick`:**
  - при `cooldown > 0` выполняется только декремент cooldown на 1 и early-return;
  - при `cooldown == 0` выполняется ровно одна ветка диспетчера:
    1) `critical_safe` -> `state/last=idle_critical_safe`, `cooldown=1`;
    2) `priority_patrol` -> `state/last=idle_priority_patrol`, `cooldown=2`;
    3) `default` -> `state/last=idle_default`, `cooldown=1`;
  - после dispatch `last_ts` всегда отражает момент последнего transition.


## Контракт pending-состояний (NPC-local и area-local)

- Источник истины для pending-статуса — `NPC-local` (`npc_pending_*` на объекте NPC).
- `area-local` (`npc_queue_pending_*` на area) — диагностическое/наблюдаемое зеркало последнего состояния, обновляется через `NpcBhvrPendingAreaTouch`.
- `deferred` при `GetArea(oSubject) != oArea` фиксируется **в обоих хранилищах** и не очищается неявно в этом же шаге.
- Очистка pending (`NpcBhvrPendingNpcClear` и `NpcBhvrPendingAreaClear`) допустима только на явных terminal-переходах (`processed`, `dropped`, удаление/смерть NPC, очистка очереди/area shutdown).
- Следствие: deferred является краткоживущим состоянием до следующего события/terminal-перехода, но в течение этого окна наблюдается консистентно и в NPC-local, и в area-local.

## Карта hook-скриптов (thin entrypoints)

| Hook | Script | Core handler |
| --- | --- | --- |
| OnSpawn | `npc_spawn.nss` | `NpcBhvrOnSpawn` |
| OnPerception | `npc_perception.nss` | `NpcBhvrOnPerception` |
| OnDamaged | `npc_damaged.nss` | `NpcBhvrOnDamaged` |
| OnDeath | `npc_death.nss` | `NpcBhvrOnDeath` |
| OnDialogue | `npc_dialogue.nss` | `NpcBhvrOnDialogue` |
| Area OnEnter | `npc_area_enter.nss` | `NpcBhvrOnAreaEnter` |
| Area OnExit | `npc_area_exit.nss` | `NpcBhvrOnAreaExit` |
| OnModuleLoad | `npc_module_load.nss` | `NpcBhvrOnModuleLoad` |
| Area tick loop | `npc_area_tick.nss` | `NpcBhvrOnAreaTick` |

## Норматив

**Правило:** entrypoint-скрипт не содержит бизнес-логики.

Допустимо только:
- подключение `npc_core`;
- получение event-context (`OBJECT_SELF`, `GetEnteringObject()`, `GetExitingObject()`);
- прямой вызов одного core-handler.

Недопустимо:
- прямые `SetLocal*`/`GetLocal*` для доменной логики в entrypoints;
- манипуляции очередью/lifecycle вне `npc_core.nss`;
- запись метрик вне `NpcBhvrMetricInc/Add`.
