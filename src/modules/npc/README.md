# NPC Bhvr behavior runtime contour (skeleton)

Каталог содержит официальный подготовительный runtime-контур для NPC Bhvr.

## Статус runtime foundation (Phase A)

- Реализован lifecycle area-controller: `RUNNING/PAUSED/STOPPED`.
- Добавлены auto-start и auto-idle-stop механики area-loop.
- Реализована bounded queue (`NPC_BHVR_QUEUE_MAX=64`) с bucket-приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Включён starvation guard для неблокирующей ротации non-critical bucket-очередей.
- CRITICAL события обрабатываются через bypass fairness-бюджета.

## Базовые include-файлы

- `npc_core.nss` — lifecycle area-controller, bounded queue с приоритетами, routing хуков в core.
- `npc_activity_inc.nss` — контентные activity-primitives (адаптерный слой для будущего порта из AL).
- `npc_metrics_inc.nss` — единый helper API для метрик (`NpcBhvrMetricInc/Add`).


## Activity primitives runtime-контракт

`npc_activity_inc.nss` теперь фиксирует минимальный runtime-layer поверх AL-подхода через `npc_*` keyspace (без прямого использования `al_*` locals в core-flow):

- AL-понятия (`slot-group`, `route-profile`, `activity transition`) обязаны проходить через adapter-helpers include-файла:
  - `NpcBhvrActivityAdapterNormalizeSlot`,
  - `NpcBhvrActivityAdapterNormalizeRoute`,
  - `NpcBhvrActivityMapRouteHint`,
  - `NpcBhvrActivityAdapterStampTransition`.

- Spawn-инициализация профиля NPC (`NpcBhvrActivityOnSpawn`) обязана выставлять:
  - `npc_activity_slot` (по умолчанию `default`),
  - `npc_activity_route` (по умолчанию `default_route`),
  - `npc_activity_state` (начальное состояние `spawn_ready`),
  - `npc_activity_cooldown` (неотрицательный cooldown/state gate),
  - `npc_activity_last` (последняя activity transition),
  - `npc_activity_last_ts` (timestamp последнего transition в секундах игрового времени).
- Idle-dispatch (`NpcBhvrActivityOnIdleTick`) работает как адаптерный диспетчер `slot/route`:
  - CRITICAL-safe ветка (приоритет №1): `slot=critical` **или** route-map -> `critical_safe`;
  - priority-ветка (приоритет №2): `slot=priority` **или** route-map -> `priority_patrol`;
  - fallback: `default_route` c состоянием `idle_default`.
- Mapping-слой (`NpcBhvrActivityMapRouteHint`) выполняет трансляцию route-id -> activity hint, чтобы AL-семантика подключалась через адаптер, а не через прямой `al_*` namespace.
- Примитивы `NpcBhvrActivityApplyCriticalSafeRoute/NpcBhvrActivityApplyPriorityRoute/NpcBhvrActivityApplyDefaultRoute` задают только минимальные state/cooldown эффекты и могут расширяться в следующих фазах без изменения контракта entrypoint/core.

### Контракт входных/выходных состояний activity primitives

- **Вход для `NpcBhvrActivityOnSpawn`:** валидный `oNpc`; любые/пустые значения `npc_activity_slot|route`; `npc_activity_cooldown` может быть отрицательным.
- **Выход `NpcBhvrActivityOnSpawn`:**
  - `slot` и `route` нормализованы в поддерживаемые значения (`default|priority|critical`, `default_route|priority_patrol|critical_safe`),
  - `state=spawn_ready`,
  - `last=spawn_ready`,
  - `last_ts` обновлён,
  - `cooldown >= 0`.
- **Вход для `NpcBhvrActivityOnIdleTick`:** валидный `oNpc`; допускаются пустые/невалидные `slot/route` (будут нормализованы).
- **Выход `NpcBhvrActivityOnIdleTick`:**
  - при `cooldown > 0` выполняется только декремент cooldown на 1 и early-return;
  - при `cooldown == 0` выполняется ровно одна ветка диспетчера:
    1) `critical_safe` -> `state/last=idle_critical_safe`, `cooldown=1`;
    2) `priority_patrol` -> `state/last=idle_priority_patrol`, `cooldown=2`;
    3) `default` -> `state/last=idle_default`, `cooldown=1`;
  - после dispatch `last_ts` всегда отражает момент последнего transition.

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
