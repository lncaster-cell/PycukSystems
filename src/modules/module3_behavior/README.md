# Module 3 behavior runtime contour (skeleton)

Каталог содержит официальный подготовительный runtime-контур для Module 3.

## Статус runtime foundation (Phase A)

- Реализован lifecycle area-controller: `RUNNING/PAUSED/STOPPED`.
- Добавлены auto-start и auto-idle-stop механики area-loop.
- Реализована bounded queue (`MODULE3_QUEUE_MAX=64`) с bucket-приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Включён starvation guard для неблокирующей ротации non-critical bucket-очередей.
- CRITICAL события обрабатываются через bypass fairness-бюджета.

## Базовые include-файлы

- `module3_core.nss` — lifecycle area-controller, bounded queue с приоритетами, routing хуков в core.
- `module3_activity_inc.nss` — контентные activity-primitives (адаптерный слой для будущего порта из AL).
- `module3_metrics_inc.nss` — единый helper API для метрик (`Module3MetricInc/Add`).


## Activity primitives runtime-контракт

`module3_activity_inc.nss` теперь фиксирует минимальный runtime-layer поверх AL-подхода через `module3_*` keyspace (без прямого использования `al_*` locals в core-flow):

- AL-понятия (`slot-group`, `route-profile`, `activity transition`) обязаны проходить через adapter-helpers include-файла:
  - `Module3ActivityAdapterNormalizeSlot`,
  - `Module3ActivityAdapterNormalizeRoute`,
  - `Module3ActivityMapRouteHint`,
  - `Module3ActivityAdapterStampTransition`.

- Spawn-инициализация профиля NPC (`Module3ActivityOnSpawn`) обязана выставлять:
  - `module3_activity_slot` (по умолчанию `default`),
  - `module3_activity_route` (по умолчанию `default_route`),
  - `module3_activity_state` (начальное состояние `spawn_ready`),
  - `module3_activity_cooldown` (неотрицательный cooldown/state gate),
  - `module3_activity_last` (последняя activity transition),
  - `module3_activity_last_ts` (timestamp последнего transition в секундах игрового времени).
- Idle-dispatch (`Module3ActivityOnIdleTick`) работает как адаптерный диспетчер `slot/route`:
  - CRITICAL-safe ветка (приоритет №1): `slot=critical` **или** route-map -> `critical_safe`;
  - priority-ветка (приоритет №2): `slot=priority` **или** route-map -> `priority_patrol`;
  - fallback: `default_route` c состоянием `idle_default`.
- Mapping-слой (`Module3ActivityMapRouteHint`) выполняет трансляцию route-id -> activity hint, чтобы AL-семантика подключалась через адаптер, а не через прямой `al_*` namespace.
- Примитивы `Module3ActivityApplyCriticalSafeRoute/Module3ActivityApplyPriorityRoute/Module3ActivityApplyDefaultRoute` задают только минимальные state/cooldown эффекты и могут расширяться в следующих фазах без изменения контракта entrypoint/core.

### Контракт входных/выходных состояний activity primitives

- **Вход для `Module3ActivityOnSpawn`:** валидный `oNpc`; любые/пустые значения `module3_activity_slot|route`; `module3_activity_cooldown` может быть отрицательным.
- **Выход `Module3ActivityOnSpawn`:**
  - `slot` и `route` нормализованы в поддерживаемые значения (`default|priority|critical`, `default_route|priority_patrol|critical_safe`),
  - `state=spawn_ready`,
  - `last=spawn_ready`,
  - `last_ts` обновлён,
  - `cooldown >= 0`.
- **Вход для `Module3ActivityOnIdleTick`:** валидный `oNpc`; допускаются пустые/невалидные `slot/route` (будут нормализованы).
- **Выход `Module3ActivityOnIdleTick`:**
  - при `cooldown > 0` выполняется только декремент cooldown на 1 и early-return;
  - при `cooldown == 0` выполняется ровно одна ветка диспетчера:
    1) `critical_safe` -> `state/last=idle_critical_safe`, `cooldown=1`;
    2) `priority_patrol` -> `state/last=idle_priority_patrol`, `cooldown=2`;
    3) `default` -> `state/last=idle_default`, `cooldown=1`;
  - после dispatch `last_ts` всегда отражает момент последнего transition.

## Карта hook-скриптов (thin entrypoints)

| Hook | Script | Core handler |
| --- | --- | --- |
| OnSpawn | `module3_behavior_spawn.nss` | `Module3OnSpawn` |
| OnPerception | `module3_behavior_perception.nss` | `Module3OnPerception` |
| OnDamaged | `module3_behavior_damaged.nss` | `Module3OnDamaged` |
| OnDeath | `module3_behavior_death.nss` | `Module3OnDeath` |
| OnDialogue | `module3_behavior_dialogue.nss` | `Module3OnDialogue` |
| Area OnEnter | `module3_behavior_area_enter.nss` | `Module3OnAreaEnter` |
| Area OnExit | `module3_behavior_area_exit.nss` | `Module3OnAreaExit` |
| OnModuleLoad | `module3_behavior_module_load.nss` | `Module3OnModuleLoad` |
| Area tick loop | `module3_behavior_area_tick.nss` | `Module3OnAreaTick` |

## Норматив

**Правило:** entrypoint-скрипт не содержит бизнес-логики.

Допустимо только:
- подключение `module3_core`;
- получение event-context (`OBJECT_SELF`, `GetEnteringObject()`, `GetExitingObject()`);
- прямой вызов одного core-handler.

Недопустимо:
- прямые `SetLocal*`/`GetLocal*` для доменной логики в entrypoints;
- манипуляции очередью/lifecycle вне `module3_core.nss`;
- запись метрик вне `Module3MetricInc/Add`.
